import ClockKit
import HealthKit
import Sentry
import SwiftUI
import CoreMotion

var dummyData: HealthDataManager = {
    HealthDataManager()
}()


class AccelerometerData: Encodable {
    let startQueryTime = Date()
    let frequency = 32
    var x_val: [Double] = []
    var y_val: [Double] = []
    var z_val: [Double] = []
}

//     HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
//     HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
//     HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness)!,


let typesToRead: Set = [
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
    HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
    HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
    HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
]

let typesToWrite = Set<HKQuantityType>()
//= [
//    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
//    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
//    HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
//    HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed)!,
//    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
//    HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed)!,
//    HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
//    HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
//    HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
//    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
//]

var healthStore: HKHealthStore = {
    let healthStore = HKHealthStore()
    return healthStore
}()

class HealthDataManager: NSObject, ObservableObject {
    static var shared = HealthDataManager()
    @Published var stateDescription: String = "Adiona"
    @Published var lastUpload = Date().addingTimeInterval(-HealthDataManager.fifteenMinutes)
    var collectedJSON = [String: (String, Date)]()
    var acclerometerData = AccelerometerData()
    let motion = CMMotionManager()
    let accelerometerQueue = OperationQueue()
    let recorder = CMSensorRecorder()

    override init() {
        super.init()

        updateDescription()

        NotificationCenter.default.addObserver(forName: .healthKitPermissionsChanged, object: nil, queue: nil) { _ in
            for sampleType in typesToRead {
                let authStatus = healthStore.authorizationStatus(for: sampleType)
                
                if authStatus != .sharingAuthorized {
                    print("Not authorized for \(sampleType.identifier)")
                    continue
                }
                                                                 
                self.collectedJSON[sampleType.identifier] = ("", Date())

                let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, errorOrNil in
                    if let _ = errorOrNil {
                        completionHandler()
                    } else {
                        self.collectSamples(for: sampleType)
                        completionHandler()
                    }
                }
                healthStore.execute(query)
                healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in
                }
            }
            
            self.startAccelerometer()
        }
    }

    func updateSummary() {
        let jsonItems = collectedJSON.compactMap { _, v in
            v.0.count > 0 ? v.0 : nil
        }

        let summary = jsonItems.reduce(0) { partialResult, json in
            partialResult + json.count
        }

        DispatchQueue.main.async {
            self.stateDescription = "\(summary) bytes"
        }
    }

    func collectSamples(for sample: HKSampleType) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("No data available!")
            return
        }

        let collectionDate = Date()
        guard var existingSampleData = collectedJSON[sample.identifier] else { fatalError() }

        let predicate = HKQuery.predicateForSamples(withStart: existingSampleData.1, end: collectionDate, options: [.strictStartDate, .strictEndDate])

        let sampleQueryHR = HKSampleQuery(sampleType: sample, predicate: predicate, limit: 0, sortDescriptors: nil)
            { (_, samples, _) -> Void in
                guard let samples = samples else { return }
                let serializer = OMHSerializer()

                var JSON = ""

                for s in samples {
                    do {
                        JSON.append(contentsOf: try serializer.json(for: s))
                    } catch {
                        track(error)
                    }
                }

                existingSampleData.0.append(JSON)
                existingSampleData.1 = collectionDate
                self.collectedJSON[sample.identifier] = existingSampleData

                self.updateSummary()
            }

        healthStore.execute(sampleQueryHR)
    }

    func reloadComplication() {
        DispatchQueue.main.async {
            let complicationServer = CLKComplicationServer.sharedInstance()
            if let complications = complicationServer.activeComplications {
                for complication in complications {
                    complicationServer.reloadTimeline(for: complication)
                }
            }
        }
    }

    func updateDescription() {
//        switch workoutSession.state {
//        case .prepared:
//            stateDescription = "Prepared"
//        case .notStarted:
//            stateDescription = "Not Started"
//        case .running:
//            stateDescription = "Running"
//        case .ended:
//            stateDescription = "Ended"
//        case .paused:
//            stateDescription = "Paused"
//        case .stopped:
//            stateDescription = "Stopped"
//        @unknown default:
//            stateDescription = "Unknown"
//        }

        reloadComplication()
    }
}

extension HealthDataManager {
    func start() {
        updateDescription()
    }

    func pause() {
        updateDescription()
    }

    func resume() {
        updateDescription()
    }

    func end() {
        updateDescription()
    }

    func upload() {}

    func validActions() -> [Action] {
        return []
//
//        switch workoutSession.state {
//        case .prepared:
//            return [Action(name: "Start", block: { [weak self] in self?.start() })]
//        case .notStarted:
//            return [Action(name: "Start", block: { [weak self] in self?.start() })]
//        case .running:
//            return [Action(name: "Pause", block: { [weak self] in self?.pause() }),
//                    Action(name: "End", block: { [weak self] in self?.end() })]
//        case .ended:
//            return [Action(name: "Upload", block: { [weak self] in self?.upload() })]
//        case .paused:
//            return [Action(name: "Resume", block: { [weak self] in self?.resume() }),
//                    Action(name: "End", block: { [weak self] in self?.end() })]
//        case .stopped:
//            return [Action(name: "Start", block: { [weak self] in self?.start() })]
//        @unknown default:
//            return []
//        }
    }
}

extension HealthDataManager {
    func minutesSince() -> Double {
        return abs(lastUpload.timeIntervalSinceNow / 60.0)
    }

    func progress() -> Double {
        let remaining = minutesSince()
        return max(0, min(0, remaining > 0 ? remaining / HealthDataManager.fifteenMinutes : 0))
    }

    func fractionComplete() -> Double {
        progress()
    }

    func timeSince(_ from: Date? = nil) -> String {
        let mins = minutesSince()
        return "\(Int(mins))m"
    }

    private func startTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        return dateFormatter.string(from: lastUpload)
    }

    private func endTime() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        return dateFormatter.string(from: lastUpload)
    }

    func dateRange() -> String {
        let start = startTime()
        let end = endTime()

        return end == nil ? start : "\(start) - \(end!)"
    }
}

extension HealthDataManager {
    static let oneHour = 3600.0
    static let fifteenMinutes = 900.0
}

extension HealthDataManager {
    func startAccelerometer() {
        
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            recorder.recordAccelerometer(forDuration: 20 * 60)
        }
        
       if self.motion.isAccelerometerAvailable {
           motion.stopAccelerometerUpdates()

           self.motion.accelerometerUpdateInterval = 1.0 / 32.0  // 32 Hz
           self.motion.startAccelerometerUpdates(to: accelerometerQueue) { accelerometerData, error in
               guard let accelerometerData = accelerometerData else { return }
               
               self.acclerometerData.x_val.append(accelerometerData.acceleration.x)
               self.acclerometerData.y_val.append(accelerometerData.acceleration.y)
               self.acclerometerData.z_val.append(accelerometerData.acceleration.z)
           }
       }
    }
    
    func stopAccelerometer() {
        guard motion.isAccelerometerActive else { return }
        motion.stopAccelerometerUpdates()
    }
}
