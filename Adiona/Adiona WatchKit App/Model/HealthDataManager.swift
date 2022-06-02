import ClockKit
import HealthKit
import Sentry
import SwiftUI

var dummyData: HealthDataManager = {
    HealthDataManager()
}()

let typesToRead: Set = [
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
    return healthStore
}()

class HealthDataManager: NSObject, ObservableObject {
    static var shared = HealthDataManager()
    @Published var stateDescription: String = "Adiona"
    @Published var lastUpload = Date().addingTimeInterval(-HealthDataManager.fifteenMinutes)
    var heartRateArray = [Double]()

    override init() {
        super.init()

        updateDescription()

        NotificationCenter.default.addObserver(forName: .healthKitPermissionsChanged, object: nil, queue: nil) { _ in
            for sampleType in typesToRead {
                let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, errorOrNil in
                    if let _ = errorOrNil {
                        completionHandler()
                    } else {
                        self.collectSamples()
                        completionHandler()
                    }
                }
                healthStore.execute(query)
                healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in
                }
            }
        }

//        Serializer.serialize(workout: workout) { data in
//            if let data = data {
//                BackgroundService.shared.updateContent(content: data, identifier: workout.uuid.uuidString)
//            }
//        }
    }

    func collectSamples() {
        guard HKHealthStore.isHealthDataAvailable() else {
          print("No data available!")
          return
        }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicateHR = HKQuery.predicateForSamples(withStart: lastUpload, end: Date(), options: [.strictStartDate, .strictEndDate])
        
        DispatchQueue.main.async {
            self.lastUpload = Date()
        }
        
        let sampleQueryHR = HKSampleQuery(sampleType: heartRateType, predicate: predicateHR, limit: 0, sortDescriptors: nil)
            { (_, result, _) -> Void in
                if result == nil {
                } else {
                    for quantitySample in result! {
                        let quantity = (quantitySample as! HKQuantitySample).quantity
                        let quantityString = "\(quantity)"
                        let quantityStringNumber = quantityString.replacingOccurrences(of: " count/s", with: "")

                        if let doubleVersion = Double(quantityStringNumber) {
                            let doubleVersion60 = doubleVersion * 60
                            self.heartRateArray.append(doubleVersion60)
                        } else {
                            print("String can't be converted")
                        }
                    }

                    print(self.heartRateArray)
                }
            }

        healthStore.execute(sampleQueryHR)
        
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let sampleQueryActiveEnergy = HKSampleQuery(sampleType: activeEnergyType, predicate: predicateHR, limit: 0, sortDescriptors: nil)
            { (_, result, _) -> Void in
                if result == nil {
                } else {
                    for quantitySample in result! {
                        let quantity = (quantitySample as! HKQuantitySample).quantity
                        let quantityString = "\(quantity)"
                        let quantityStringNumber = quantityString.replacingOccurrences(of: " count/s", with: "")

                        if let doubleVersion = Double(quantityStringNumber) {
                            let doubleVersion60 = doubleVersion * 60
                            self.heartRateArray.append(doubleVersion60)
                        } else {
                            print("String can't be converted")
                        }
                    }

                    print(self.heartRateArray)
                }
            }

        healthStore.execute(sampleQueryActiveEnergy)

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
    func minutesRemaining() -> Double {
        return (HealthDataManager.fifteenMinutes + lastUpload.timeIntervalSinceNow) / 60.0
    }

    func progress() -> Double {
        let remaining = minutesRemaining()
        return max(0, min(0, remaining > 0 ? remaining / HealthDataManager.fifteenMinutes : 0))
    }

    func fractionComplete() -> Double {
        progress()
    }

    func timeRemaining(_ from: Date? = nil) -> String {
        let mins = minutesRemaining()
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
