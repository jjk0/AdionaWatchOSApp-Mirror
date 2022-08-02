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

        getProfileData()

        WKExtension.shared().registerForRemoteNotifications()

        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true

        fallDetector.delegate = self
        // fallDetector.requestAuthorization { _ in }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("geofence_breached"), object: nil, queue: nil) { _ in
            self.sendHealthData()
        }
    }

    func fallDetectionManager(_ fallDetectionManager: CMFallDetectionManager, didDetect event: CMFallDetectionEvent, completionHandler handler: @escaping () -> Void) {
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
            fallDetector.delegate = self
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
        if let data = UserDefaults.standard.string(forKey: "JSON") {
            print("Data count: (data.count)")
        }
    }

    func getProfileData() {
        do {
            let json = try healthDataManager.adionaData.metaData.toJSON()
            let fileURL = tempFileFor(json: json)!

            let url = URL(string: "https://vbar9mhxvd.execute-api.us-east-1.amazonaws.com/default/adiona-watch-api-get-profile-trigger")!
//
//            let url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("(json.count)", forHTTPHeaderField: "Content-Length")
            request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "filename")

            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.uploadTask(with: request, fromFile: fileURL)
            task.resume()
        } catch {
            
        }
        
//        do {
//            let json = try healthDataManager.adionaData.metaData.toJSON()
//
//            let url = URL(string: "https://vbar9mhxvd.execute-api.us-east-1.amazonaws.com/default/adiona-watch-api-get-profile-trigger")!
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.setValue("(json.count)", forHTTPHeaderField: "Content-Length")
//            request.httpBody = json.data(using: .utf8)
//
//            let config = URLSessionConfiguration.default
//            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
//            let task = session.downloadTask(with: request)
//            task.resume()
//        } catch {
//            track(error)
//        }
    }

    public func schedule(firstTime: Bool = false) {
        let minutes = 15

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
                if let error = error {
                    track("Unable to schedule: (error.localizedDescription)")
                }
            }

        print("Background Schedule for: (when)")
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

    func config(with identifier: String) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true

        return config
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
                sessionBackgroundTask = task
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        do {
            let geoFenceData: GeofenceData = try JSONDecoder().decode(GeofenceData.self, from: data)
            healthDataManager.location?.resetGeofence(with: geoFenceData)
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

    func upload(json: String) {
        let fileURL = tempFileFor(json: json)!

        let url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("(json.count)", forHTTPHeaderField: "Content-Length")
        request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "filename")

        let session = URLSession(configuration: config(with: "adiona_data_" + UUID().uuidString), delegate: self, delegateQueue: nil)
        let task = session.uploadTask(with: request, fromFile: fileURL)
        task.resume()
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

//    func download(filename: String) {
//        var url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
//        url = url.appendingPathComponent(filename)
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(filename, forHTTPHeaderField: "filename")
//
//        let config = URLSessionConfiguration.background(withIdentifier: filename)
//        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
//        let backgroundTask = session.downloadTask(with: url)
//        backgroundTask.earliestBeginDate = Date().addingTimeInterval(1) // 4 * 60)
//        backgroundTask.resume()
//    }
}


"{"statusCodee": 200, "body": "{"version": "2.0", "routeKey": "ANY /adiona-watch-api-get-profile-trigger", "rawPath": "/default/adiona-watch-api-get-profile-trigger", "rawQueryString": "", "headers": {"accept": "*/*", "accept-encoding": "gzip, deflate, br", "accept-language": "en-US,en;q=0.9", "content-length": "162", "content-type": "application/json", "filename": "12345_2022-08-02T15:17:28Z.json", "host": "vbar9mhxvd.execute-api.us-east-1.amazonaws.com", "user-agent": "Adiona%20WatchKit%20Extension/4 CFNetwork/1331.0.7 Darwin/21.5.0", "x-amzn-trace-id": "Root=1-62e9400b-614b89734c71820b1130fe4a", "x-forwarded-for": "72.186.203.223", "x-forwarded-port": "443", "x-forwarded-proto": "https"}, "requestContext": {"accountId": "779792650170", "apiId": "vbar9mhxvd", "domainName": "vbar9mhxvd.execute-api.us-east-1.amazonaws.com", "domainPrefix": "vbar9mhxvd", "http": {"method": "POST", "path": "/default/adiona-watch-api-get-profile-trigger", "protocol": "HTTP/1.1", "sourceIp": "72.186.203.223", "userAgent": "Adiona%20WatchKit%20Extension/4 CFNetwork/1331.0.7 Darwin/21.5.0"}, "requestId": "WPbxyg8voAMEMDg=", "routeKey": "ANY /adiona-watch-api-get-profile-trigger", "stage": "default", "time": "02/Aug/2022:15:17:31 +0000", "timeEpoch": 1659453451295}, "body": "{n  "has_cellular_capabilities" : "false",n  "user_id" : "12345",n  "device_ID" : "undetermined",n  "battery_level" : 0,n  "start_date" : "2022-08-02T15:17:28Z"n}", "isBase64Encoded": false}"}"
