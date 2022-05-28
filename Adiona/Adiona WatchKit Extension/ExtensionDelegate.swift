import ClockKit
import HealthKit
import WatchKit
import Sentry

let typesToRead: Set = [
    HKObjectType.workoutType(),
    HKSeriesType.workoutRoute(),
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
    HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
    HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness)!,
    HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness)!,
    HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
    HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
]

let typesToWrite: Set = [
    HKObjectType.workoutType(),
    HKSeriesType.workoutRoute(),
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
    HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
    HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
]

var healthStore: HKHealthStore = {
    let healthStore = HKHealthStore()
    healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { _, _ in
        NotificationCenter.default.post(name: .healthKitPermissionsChanged, object: nil)
    }
    return healthStore
}()

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
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
        
        SessionData.shared.activeSession = Session()
        
        NotificationCenter.default.addObserver(forName: .healthKitPermissionsChanged, object: nil, queue: nil) { notification in
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        backgroundTasks.forEach { task in
            switch task {
            case let task as WKSnapshotRefreshBackgroundTask:
                task.setTaskCompletedWithSnapshot(false)

            case let task as WKApplicationRefreshBackgroundTask:
                backgroundWorker.perform { updateComplications in
                    if updateComplications {
                        Self.updateActiveComplications()
                    }
                    
                    if let activeSession = SessionData.shared.activeSession {
                        activeSession.end()
                        SessionData.shared.addToBacklog(session: activeSession)
                    }
                    
                    let nextSession = Session()
                    SessionData.shared.activeSession = nextSession
                    nextSession.start()
                    
                    backgroundWorker.schedule()
                    task.setTaskCompletedWithSnapshot(false)
                }

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
