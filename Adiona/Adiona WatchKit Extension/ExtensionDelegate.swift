import ClockKit
import HealthKit
import Sentry
import WatchKit

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let healthDataManager = HealthDataManager.shared
    private let backgroundWorker = BackgroundWorker()

    func applicationDidFinishLaunching() {
        SentrySDK.start { options in
            options.dsn = "https://eadde9c57a2542d5a123b338aacd0441@o824011.ingest.sentry.io/6447191"
            options.debug = false // Enabled debug when first installing is always helpful
            options.sessionTrackingIntervalMillis = 6000
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.backgroundWorker.schedule(firstTime: true)
        }
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { _, _ in
            NotificationCenter.default.post(name: .healthKitPermissionsChanged, object: nil)
        }
    }

    func applicationDidEnterBackground() {
        healthDataManager.startAccelerometer()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)

            case let task as WKApplicationRefreshBackgroundTask:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted

                let data = try! encoder.encode(healthDataManager.acclerometerData)
                
                var json = ""
                for (_,v) in healthDataManager.collectedJSON {
                    json.append(v.0)
                }
                
                if json.count > 0,
                   let rpos = json.range(of:"}", options:.backwards) {
                        json.removeSubrange(rpos)
                    json.append("\"acceleration\": { \(String(data: data, encoding: .utf8)!) }")
                } else {
                    json.append("{\"acceleration\": { \(String(data: data, encoding: .utf8)!) }}")
                }


                Uploader.shared.sendToS3(filename: "\(UUID().uuidString).txt", json: json)
                for k in healthDataManager.collectedJSON.keys {
                    healthDataManager.collectedJSON[k]?.0 = ""
                }
                
                healthDataManager.acclerometerData = AccelerometerData()
                
                backgroundWorker.schedule()
                task.setTaskCompletedWithSnapshot(false)
            case let task as WKURLSessionRefreshBackgroundTask:
                backgroundWorker.schedule()
                task.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    public static func updateActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach {
            server.reloadTimeline(for: $0)
        }
    }
}
