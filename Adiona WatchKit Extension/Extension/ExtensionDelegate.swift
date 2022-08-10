import ClockKit
import CoreMotion
import Foundation
import HealthKit
import Sentry
import UIKit
import WatchKit

struct DeviceToken: Encodable {
    let device_token: String
}

final class ExtensionDelegate: NSObject, WKExtensionDelegate, ObservableObject, URLSessionDownloadDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, CMFallDetectionDelegate {
    private let healthDataManager = HealthDataManager.shared
    var refreshBackgroundTask: WKApplicationRefreshBackgroundTask?
    var sessionBackgroundTask: WKURLSessionRefreshBackgroundTask?
    let fallDetector = CMFallDetectionManager()
    var location: Location?

    func applicationDidFinishLaunching() {
        SentrySDK.start { options in
            options.dsn = "https://eadde9c57a2542d5a123b338aacd0441@o824011.ingest.sentry.io/6447191"
            options.debug = false // Enabled debug when first installing is always helpful
            options.sessionTrackingIntervalMillis = 6000
        }

        if healthDataManager.profileData == nil {
            getProfileData()
        }

#if targetEnvironment(simulator)
  // your simulator code
#else
        WKExtension.shared().registerForRemoteNotifications()
#endif


        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true

        fallDetector.delegate = self
        fallDetector.requestAuthorization { _ in }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("geofence_breached"), object: nil, queue: nil) { _ in
            self.sendHealthData()
        }
    }

    func fallDetectionManager(_ fallDetectionManager: CMFallDetectionManager, didDetect event: CMFallDetectionEvent, completionHandler handler: @escaping () -> Void) {
        healthDataManager.adionaData.last_fall_time = Date()
        healthDataManager.adionaData.last_fall_resolution = event.resolution.rawValue
        sendHealthData()
    }

    func fallDetectionManagerDidChangeAuthorization(_ fallDetectionManager: CMFallDetectionManager) {
        switch fallDetectionManager.authorizationStatus {
        case .notDetermined:
            track("Falldetection Authorization not determined")
        case .restricted:
            track("Falldetection Authorization restricted")
        case .denied:
            track("Falldetection Authorization denied")
        case .authorized:
            track("Falldetection Authorized")
        @unknown default:
            track("Falldetection Authorization unknown")
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let deviceToken = DeviceToken(device_token: deviceToken.map { String(format: "%02x", $0) }.joined())
        HealthDataManager.shared.adionaData.metaData.device_ID = deviceToken.device_token
        sendHealthData()
    }

    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        track(error)
    }

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any],
                                      fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void)
    {
        if userInfo["content-available"] as? Int == 1 {
            // Silent notification
            if let _ = healthDataManager.location?.lastReportedLocation {
                // Send current location to API
            }
        }

        completionHandler(.newData)
    }

    func applicationDidBecomeActive() {
    }

    public func schedule(firstTime: Bool = false) {
#if targetEnvironment(simulator)
        let minutes = 1
#else
        let minutes = 15
#endif


        let when = Calendar.current.date(
            byAdding: .minute,
            value: firstTime ? 1 : minutes,
            to: Date.now
        )!

        WKExtension
            .shared()
            .scheduleBackgroundRefresh(
                withPreferredDate: when,
                userInfo: nil
            ) { error in
                track(error)
            }

        print("Background Schedule for: \(when)")
    }

    func sendHealthData() {
        do {
            healthDataManager.adionaData.metaData.battery_level = WKInterfaceDevice.current().batteryLevel

            let json = try healthDataManager.adionaData.toJSON()

            upload(json: json)
        } catch {
            track(error)
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)
            case let task as WKApplicationRefreshBackgroundTask:
                sendHealthData()
                refreshBackgroundTask = task
            case let task as WKURLSessionRefreshBackgroundTask:
                _ = URLSession(configuration: config(with: task.sessionIdentifier), delegate: self, delegateQueue: nil)
                task.setTaskCompletedWithSnapshot(false)
                //sessionBackgroundTask = task
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func config(with identifier: String) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true

        return config
    }
    
    func upload(json: String) {
        guard let fileURL = tempFileFor(json: json) else { return }

        let url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(json.count)", forHTTPHeaderField: "Content-Length")
        request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "filename")

        let session = URLSession(configuration: config(with: "adiona_data_" + UUID().uuidString), delegate: self, delegateQueue: nil)
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
    }
    
    func getProfileData() {
        do {
            var json = try healthDataManager.adionaData.metaData.toJSON()

            json = "{ \"metaData\" : \(json) }"
            guard let fileURL = tempFileFor(json: json) else { return }

            let url = URL(string: "https://vbar9mhxvd.execute-api.us-east-1.amazonaws.com/default/adiona-watch-api-get-profile-trigger")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("\(json.count)", forHTTPHeaderField: "Content-Length")
            request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "filename")

            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.uploadTask(with: request, fromFile: fileURL)
            task.resume()
        } catch {
            track(error)
        }
    }

    func tempFileFor(json: String) -> URL? {
        guard let userID = UserDefaults.standard.string(forKey: "bucket_name"),
              let data = json.data(using: .ascii) else { return nil }

        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: Date()).replacingOccurrences(of: "/", with: "_")
        let filename = userID + "_" + dateString + ".json"

        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent(filename)
        try? data.write(to: localURL)

        return localURL
    }
}

extension ExtensionDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            if let json = String(data: data, encoding: .utf8) {
                if json.contains("profile_info") {
                    let profile: ProfileData = try JSONDecoder().decode(ProfileData.self, from: data)
                    healthDataManager.profileData = profile
                } else if json.contains("geofences") {
                    let geoFenceData: GeofenceData = try JSONDecoder().decode(GeofenceData.self, from: data)
                    healthDataManager.location?.resetGeofence(with: geoFenceData)
                }
            }
        } catch {
            track(error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if refreshBackgroundTask != nil || sessionBackgroundTask != nil {
            refreshBackgroundTask?.setTaskCompletedWithSnapshot(false)
            refreshBackgroundTask = nil

            sessionBackgroundTask?.setTaskCompletedWithSnapshot(false)
            sessionBackgroundTask = nil
            schedule()
        }

        // Need to handle error here and store off data to retry, at least not resetting the collectors on error prevents any data loss.
        if error == nil, session.configuration.identifier?.contains("adiona_data") ?? false {
            healthDataManager.resetCollectors()
        }

        track(error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {}

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let result = try String(contentsOf: location)
            print(result)
        } catch {
            track(error)
        }
    }
}
