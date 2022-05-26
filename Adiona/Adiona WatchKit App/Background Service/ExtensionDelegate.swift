import ClockKit
import HealthKit
import WatchKit

let typesToRead: Set = [
    HKObjectType.workoutType(),
    HKSeriesType.workoutRoute(),
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
    HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
    HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
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
    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
    HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

]


var healthStore: HKHealthStore!

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
    private let backgroundWorker = BackgroundWorker()
    private var downloads: [String: UrlDownloader] = [:]

    func applicationDidFinishLaunching() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.backgroundWorker.schedule(firstTime: true)
        }
        
        requestAccessToHealthKit()
    }

    private func requestAccessToHealthKit() {
//        let healthKitTypesToWrite: Set<HKSampleType> = [
//            HKObjectType.workoutType(),
//            HKSeriesType.workoutRoute(),
//            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .heartRate)!,
//            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
//            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
//            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
//            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
//        ]

//        let healthKitTypesToRead: Set<HKObjectType> = [
//            HKObjectType.workoutType(),
//            HKSeriesType.workoutRoute(),
//            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
//            HKObjectType.quantityType(forIdentifier: .heartRate)!,
//            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
//            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
//            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
//            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
//            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
//        ]

        healthStore = HKHealthStore()

        let authorizationStatus = healthStore.authorizationStatus(for: HKSampleType.workoutType())

        switch authorizationStatus {
        case .sharingAuthorized: print("sharing authorized")
            print("sharing authorized this message is from Watch's extension delegate")

        case .sharingDenied: print("sharing denied")
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { _, _ in
                print("Successful HealthKit Authorization from Watch's extension Delegate")
            }

        default: print("not determined")
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { _, _ in
                print("Successful HealthKit Authorization from Watch's extension Delegate")
            }
        }
    }

    override init() {
        super.init()
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
