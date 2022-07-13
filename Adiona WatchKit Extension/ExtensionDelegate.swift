import ClockKit
import WatchKit
import HealthKit
import CoreMotion
import Sentry

var gExtensionDelegate: ExtensionDelegate!

final class ExtensionDelegate: NSObject, WKExtensionDelegate, ObservableObject {
    private let healthDataManager = HealthDataManager.shared
    private let location = Location.shared
    
    func applicationDidFinishLaunching() {
        SentrySDK.start { options in
            options.dsn = "https://eadde9c57a2542d5a123b338aacd0441@o824011.ingest.sentry.io/6447191"
            options.debug = false // Enabled debug when first installing is always helpful
            options.sessionTrackingIntervalMillis = 6000
        }

        schedule(firstTime: true)
    }
    
    func applicationDidBecomeActive() {
        if let data = UserDefaults.standard.string(forKey: "JSON") {
            print("Data count: \(data.count)")
        }
    }
    
    func applicationWillResignActive() {
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
                    print("Unable to schedule: \(error.localizedDescription)")
                }
            }
        
        print("Background Schedule for: \(when)")
    }
    
    func applicationDidEnterBackground() {
        schedule()
        HealthDataManager.shared.restart()
    }

    func sendHealthData(completion: @escaping () -> Void) {
        self.healthDataManager.collectSamples()
        do {
            let json = try self.healthDataManager.adionaData.toJSON()
            
            let filename = "\(UUID().uuidString).txt"
            
            Uploader.shared.sendToS3(filename: filename, json: json as String) {
                self.healthDataManager.resetCollectors()
                self.schedule()
                completion()
            }
        } catch {
            track(error)
            completion()
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)
            case let task as WKApplicationRefreshBackgroundTask:
                sendHealthData() {
                    task.setTaskCompletedWithSnapshot(false)
                }
            case let task as WKURLSessionRefreshBackgroundTask:
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
