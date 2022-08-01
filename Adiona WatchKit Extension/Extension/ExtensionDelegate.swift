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
    private let networkConnectivity = NetworkConnectivity()
    var refreshBackgroundTask: WKApplicationRefreshBackgroundTask?
    var sessionBackgroundTask: WKURLSessionRefreshBackgroundTask?
    let fallDetector = CMFallDetectionManager()

    func applicationDidFinishLaunching() {
        SentrySDK.start { options in
            options.dsn = "https://eadde9c57a2542d5a123b338aacd0441@o824011.ingest.sentry.io/6447191"
            options.debug = false // Enabled debug when first installing is always helpful
            options.sessionTrackingIntervalMillis = 6000
        }

        getProfileData()

        WKExtension.shared().registerForRemoteNotifications()

        networkConnectivity.startMonitoring { path in
            switch path.status {
            case .requiresConnection:
                HealthDataManager.shared.adionaData.metaData.connectivity_status.append("no-connection")
            case .satisfied:
                if path.isExpensive {
                    HealthDataManager.shared.adionaData.metaData.connectivity_status.append("cellular")
                } else {
                    HealthDataManager.shared.adionaData.metaData.connectivity_status.append("WiFi")
                }
            case .unsatisfied:
                HealthDataManager.shared.adionaData.metaData.connectivity_status.append("unsatisfied")
            @unknown default:
                print("Unknown case")
            }
        }

        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        
        fallDetector.delegate = self
        //fallDetector.requestAuthorization { _ in }
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
            self.fallDetector.delegate = self
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
            print("Data count: \(data.count)")
        }
    }

    func getProfileData() {
        download(filename: "profileData.json")
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
                    track("Unable to schedule: \(error.localizedDescription)")
                }
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
        
        track(error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    }

    func upload(json: String) {
        let fileURL = tempFileFor(json: json)!
        
        let url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(json.count)", forHTTPHeaderField: "Content-Length")
        request.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "filename")

        let session = URLSession(configuration: config(with: UUID().uuidString), delegate: self, delegateQueue: nil)
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

    func download(filename: String) {
        var url = URL(string: "https://8b5wq9o68d.execute-api.us-east-1.amazonaws.com/adiona-watch-api-trigger")!
        url = url.appendingPathComponent(filename)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(filename, forHTTPHeaderField: "filename")

        let config = URLSessionConfiguration.background(withIdentifier: filename)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let backgroundTask = session.downloadTask(with: url)
        backgroundTask.earliestBeginDate = Date().addingTimeInterval(1) // 4 * 60)
        backgroundTask.resume()
    }
}
//        upload2(json: """
//            {
//              "oxygen_saturation" : {
//                "values" : [
//                  50, 60
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "respiratory_rate" : {
//                "values" : [
//                  14, 15
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "distance_walking_running" : {
//                "values" : [
//                  123, 156
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "active_energy_burned" : {
//                "values" : [
//                  123, 134
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "acceleration" : {
//                "frequency" : 32,
//                "z_val" : [
//                  -0.0009765625
//                ],
//                "y_val": [
//                  -0.0009765625
//                ],
//                "x_val" : [
//                  -0.0009765625
//                ],
//                "startQueryTime": "2022-07-22T02:46:43Z"
//              },
//              "six_minute_walk_test" : {
//                "values" : [
//
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//
//                ]
//              },
//              "heart_rate" : {
//                "values" : [
//                  80, 71
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "heart_rate_variability" : {
//                "values" : [
//                  0.115, 1.1
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "metaData" : {
//                "device_ID" : "A01FF30D-288E-4B15-89FE-25A8F7071D92",
//                "connectivity_status" : ["wifi"],
//                "start_date" : "2022-07-22T02:46:43Z",
//                "user_id" : 12345
//              },
//              "step_count" : {
//                "values" : [
//                  24, 25
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                    "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "resting_heart_rate" : {
//                "values" : [
//                  0.115, 1.1
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//                  "2022-07-22T02:46:43Z", "2022-07-23T02:46:43Z"
//                ]
//              },
//              "stair_descent_speed" : {
//                "values" : [
//
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//
//                ]
//              },
//              "stair_ascent_speed" : {
//                "values" : [
//
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//
//                ]
//              },
//              "number_of_times_fallen" : {
//                "values" : [
//
//                ],
//                "sources" : [
//
//                ],
//                "timestamps" : [
//
//                ]
//              },
//              "locations" : {
//                "longitude" : [
//                  71.11
//                ],
//                "latitude" : [
//                  74.11
//                ],
//                "timestamp" : [
//                  "2022-07-22T02:46:43Z"
//                ]
//              }
//            }
//            """
//        )
//        upload(json: "{'foo':'dog'}")
