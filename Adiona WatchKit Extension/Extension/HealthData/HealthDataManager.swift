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
    var location: Location?
    
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
        
        healthStore.requestAuthorization(toShare: typesToRead, read: typesToRead) { success, error in
            track(error)
            if self.location == nil {
                DispatchQueue.main.async {
                    self.location = Location()
                }
            }
            
            self.start()
        }
    }

    func start() {
        self.stopAccelerometer()
        self.startAccelerometer()

        self.activeDataQueries.forEach { healthStore.stop($0) }
        self.activeDataQueries.removeAll()

        // Start everything up
        for sampleType in typesToRead {
            self.setupObserverQuery(for: sampleType)
        }
        
        location?.restart()
    }
    
    func collectSamples() {
        HealthDataManager.shared.adionaData.metaData.end_date = Date()
        for sampleType in typesToRead {
            self.adionaData.addSamples(for: sampleType, from: "cs")
        }
    }

    func setupObserverQuery(for sampleType: HKSampleType) {
        
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
