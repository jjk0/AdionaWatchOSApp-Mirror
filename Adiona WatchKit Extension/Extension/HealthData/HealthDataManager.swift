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
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
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
        // Note the stop/start code here is intended to make this call
        // safe to make multiple times without worrying about current state (Re-entrant)
        
        self.stopAccelerometer()
        self.startAccelerometer()

        self.activeDataQueries.forEach { healthStore.stop($0) }
        self.activeDataQueries.removeAll()

        for sampleType in typesToRead {
            self.setupObserverQuery(for: sampleType)
        }
        
        location?.restart()
    }
    
    func collectSamples() {
        HealthDataManager.shared.adionaData.metaData.end_date = Date()
        for sampleType in typesToRead {
            self.adionaData.addSamples(for: sampleType)
        }
    }

    func setupObserverQuery(for sampleType: HKSampleType) {
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, errorOrNil in
            if let error = errorOrNil {
                track(error)
            } else {
                self.adionaData.addSamples(for: sampleType)
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
                guard let self = self,
                      error == nil,
                      let reading = reading else { return }

                self.adionaData.acceleration.x_val.append(reading.acceleration.x)
                self.adionaData.acceleration.y_val.append(reading.acceleration.y)
                self.adionaData.acceleration.z_val.append(reading.acceleration.z)
                self.adionaData.acceleration.timestamp.append(Date())
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
