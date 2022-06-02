import ClockKit
import HealthKit
import Sentry
import WatchKit
import SotoS3

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let healthDataManager = HealthDataManager.shared
    private let backgroundWorker = BackgroundWorker()
    private var downloads: [String: UrlDownloader] = [:]

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
            let status = healthStore.authorizationStatus(for: typesToRead.first!)
            
            NotificationCenter.default.post(name: .healthKitPermissionsChanged, object: nil)
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)

            case let task as WKApplicationRefreshBackgroundTask:
                Self.updateActiveComplications()

                healthDataManager.collectSamples()
                
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

    private func downloader(for identifier: String) -> UrlDownloader {
        guard let download = downloads[identifier] else {
            let downloader = UrlDownloader(identifier: identifier)
            downloads[identifier] = downloader
            return downloader
        }

        return download
    }

    public static func updateActiveComplications() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach {
            server.reloadTimeline(for: $0)
        }
    }
}
