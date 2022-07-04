import ClockKit
import CoreMotion
import HealthKit
//import Sentry
import SwiftUI

var dummyData: HealthDataManager = {
    HealthDataManager()
}()

//     HKQuantityType.quantityType(forIdentifier: .appleMoveTime)!,
//     HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness)!,

let quantityTypes: [HKQuantityTypeIdentifier] = [
    .heartRateVariabilitySDNN,
    .heartRate,
    .restingHeartRate,
    .stepCount,
    .activeEnergyBurned,
    .oxygenSaturation,
    .stairAscentSpeed,
    .stairDescentSpeed,
    .sixMinuteWalkTestDistance,
    .respiratoryRate
]

let typesToRead: Set = [
    HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
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

var healthStore: HKHealthStore = {
    let healthStore = HKHealthStore()
    return healthStore
}()

class HealthDataManager: NSObject, ObservableObject {
    static var shared = HealthDataManager()
    var adionaData = AdionaData()
    var timer: Timer?
    var acclerometerData = AccelerometerData()
    lazy var motion: CMMotionManager = {
        let m = CMMotionManager()
        m.accelerometerUpdateInterval = 1.0 / 32.0 // 32 Hz
        return m
    }()
    
    lazy var accelerometerQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.maxConcurrentOperationCount = 1
        oq.qualityOfService = .background
        
        return oq
    }()
    
    let recorder = CMSensorRecorder()

    override init() {
        super.init()

        NotificationCenter.default.addObserver(forName: .healthKitPermissionsChanged, object: nil, queue: nil) { _ in
            for sampleType in quantityTypes {
                // A query that returns changes to the HealthKit store, including a snapshot of new changes and continuous monitoring as a long-running query.
            }
            self.startAccelerometer()
        }
    }

    func collectSamples() {
        HealthDataManager.shared.adionaData.metaData.end_date = Date()
        for sampleType in typesToRead {
            self.adionaData.addSamples(for: sampleType)
        }
    }

    func setupAnchoredQuery(sampleType: HKSampleType) {
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            _, samples, _, _, error in
                
                if let samples = samples as? [HKQuantitySample] {
                    self.adionaData.addQuantitySamples(for: samples)
                }
                if let error = error {
                    track(error)
                }
            }

        // It provides us with both the ability to receive a snapshot of data, and then on subsequent calls, a snapshot of what has changed.\
        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: Date().addingTimeInterval(.greatestFiniteMagnitude), options: [.strictStartDate])

        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [devicePredicate, datePredicate]), anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    func setupQueryMethod(for sampleType: HKSampleType) {
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, errorOrNil in
            if let error = errorOrNil {
                track(error)
            } else {
                self.adionaData.addSamples(for: sampleType)
            }

            completionHandler()
        }

        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in }
    }
    
    func resetCollectors() {
        adionaData = AdionaData()
    }
    
    func updateSummary() {
        DispatchQueue.main.async {
        }
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
}

extension HealthDataManager {
    static let oneHour = 3600.0
    static let fifteenMinutes = 900.0
}

extension HealthDataManager {
    func startAccelerometer() {
        print("Start Acceleromter?")
        
        if motion.isAccelerometerAvailable {
            motion.stopAccelerometerUpdates()
            
            print("Starting Acceleromter")
            motion.startAccelerometerUpdates(to: accelerometerQueue) { [weak self] reading, error in
                guard let self = self else { return }
                guard error == nil else { return }
                guard let reading = reading else { return }

                self.adionaData.acceleration.x_val.append(reading.acceleration.x)
                self.adionaData.acceleration.y_val.append(reading.acceleration.y)
                self.adionaData.acceleration.z_val.append(reading.acceleration.z)
            }
        } else {
            print("Acceleromter not Available")
        }
    }

    func stopAccelerometer() {
        guard motion.isAccelerometerActive else { return }
        motion.stopAccelerometerUpdates()
    }
}


//        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
//            recorder.recordAccelerometer(forDuration: 20 * 60)
//        }

