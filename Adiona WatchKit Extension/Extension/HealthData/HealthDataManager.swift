import ClockKit
import CoreMotion
import HealthKit
//import Sentry
import SwiftUI

var dummyData: HealthDataManager = {
    HealthDataManager()
}()

let quantityTypes: Set<HKQuantityTypeIdentifier> = [
    .heartRateVariabilitySDNN,
    .heartRate,
    .restingHeartRate,
    .stepCount,
    .activeEnergyBurned,
    .oxygenSaturation,
    .stairAscentSpeed,
    .stairDescentSpeed,
    .sixMinuteWalkTestDistance,
    .respiratoryRate,
    .distanceWalkingRunning
]

var typesToRead: Set<HKQuantityType> = {
    let mapping = quantityTypes.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
    return Set<HKQuantityType>(mapping)
}()

let typesToWrite = Set<HKQuantityType>()

var healthStore: HKHealthStore = {
    let healthStore = HKHealthStore()
    return healthStore
}()

class HealthDataManager: NSObject, ObservableObject {
    static var shared = HealthDataManager()
    @Published var stepsToday: String = "-"
    @Published var heartrate: String = "-"
    
    var profileData: ProfileData?
    var adionaData = AdionaData()
    var activeDataQueries = [HKQuery]()
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
    
    override init() {
        super.init()
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            track(error)
            self.restart()
        }
    }

    func restart() {
        activeDataQueries.forEach { healthStore.stop($0) }
        activeDataQueries.removeAll()
        DispatchQueue.main.async {
            Location.shared.manager.stopUpdatingLocation()
        }
        stopAccelerometer()
        
        for sampleType in quantityTypes {
            self.startQuery(quantityTypeIdentifier: sampleType)
        }
        
        for sampleType in typesToRead {
            self.setupQueryMethod(for: sampleType)
        }
        
        self.startAccelerometer()
        
        DispatchQueue.main.async {
            Location.shared.manager.startUpdatingLocation()
        }
    }
    
    func collectSamples() {
        HealthDataManager.shared.adionaData.metaData.end_date = Date()
        for sampleType in typesToRead {
            self.adionaData.addSamples(for: sampleType, from: "cs")
        }
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
           let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
           let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
           let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
           
           let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?,
               [HKDeletedObject]?,
               HKQueryAnchor?,
               Error?) -> Void) = { query,
               samples,
               deletedObjects,
               queryAnchor,
               error in
               if let samples = samples as? [HKQuantitySample],
                  samples.count > 0 {
                   self.adionaData.addQuantitySamples(for: samples, source: "aq")
               }
           }
           
           let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                             predicate: queryPredicate,
                                             anchor: nil,
                                             limit: HKObjectQueryNoLimit,
                                             resultsHandler: updateHandler)
           query.updateHandler = updateHandler
            activeDataQueries.append(query)
           healthStore.execute(query)
       }

    func setupQueryMethod(for sampleType: HKSampleType) {
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, errorOrNil in
            if let error = errorOrNil {
                track(error)
                print(sampleType)
            } else {
                self.adionaData.addSamples(for: sampleType, from: "qm")
            }

            completionHandler()
        }

        activeDataQueries.append(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            track(error)
            if let _ = error {
                print(sampleType)
            }
        }
        
        healthStore.execute(query)
    }
    
    func resetCollectors() {
        adionaData = AdionaData()
    }
}

extension HealthDataManager {
    func startAccelerometer() {
        if motion.isAccelerometerAvailable {
            motion.stopAccelerometerUpdates()
            
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

