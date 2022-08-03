//
//  SampleTypes.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/25/22.
//

import Foundation
import CoreLocation
import HealthKit

struct DataPoints<T>: Encodable where T: Encodable {
    var values = [T]()
    var timestamps = [Date]()
}

class LocationData: Encodable {
    var latitude = Array<CLLocationDegrees>()
    var longitude = Array<CLLocationDegrees>()
    var timestamp = Array<Date>()
}

class AccelerometerData: Encodable {
    let frequency = 32
    var x_val = Array<Double>()
    var y_val = Array<Double>()
    var z_val = Array<Double>()
    let startQueryTime = Date()

}

class MetaData: Encodable {
    var battery_level: Float = 0.0
    var geofences: GeofenceData?
    var device_ID: String = "undetermined"
    let has_cellular_capabilities = NetworkTools.hasCellularCapabilites() ? "true" : "false"
    let start_date = Date()
    var end_date: Date?
    var user_id = "12345"//UserDefaults.standard.string(forKey: "bucket_name")
    
    init() {}
}

class AdionaData: Encodable {
    var metaData = MetaData()
    var geofence_breaches = [String]()
    let acceleration = AccelerometerData()
    var heart_rate = DataPoints<Double>()
    var heart_rate_variability = DataPoints<Double>()
    var resting_heart_rate = DataPoints<Double>()
    var step_count = DataPoints<Double>()
    var active_energy_burned = DataPoints<Double>()
    var stair_ascent_speed = DataPoints<Double>()
    var stair_descent_speed = DataPoints<Double>()
    var distance_walking_running = DataPoints<Double>()
    var six_minute_walk_test = DataPoints<Double>()
    var respiratory_rate = DataPoints<Double>()
    var oxygen_saturation = DataPoints<Double>()
    var number_of_times_fallen = DataPoints<Double>()
    var last_fall_time: Date?
    var locations = LocationData()
    
    func addQuantitySamples(for samples: [HKQuantitySample]) {
        for s in samples {
            switch s.sampleType.identifier {
            case "HKQuantityTypeIdentifierNumberOfTimesFallen":
                let value = s.quantity.doubleValue(for: HKUnit.count())
                self.number_of_times_fallen.values.append(value)
                self.number_of_times_fallen.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierHeartRateVariabilitySDNN":
                let value = s.quantity.doubleValue(for: HKUnit.second())
                self.heart_rate_variability.values.append(value)
                self.heart_rate_variability.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierHeartRate":
                let value = s.quantity.doubleValue(for: HKUnit(from: "count/min"))
                HealthDataManager.shared.heartrate = "\(Int(value))"
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierRestingHeartRate":
                let unit = HKUnit(from: "count/min")
                let value = s.quantity.doubleValue(for: unit)
                self.resting_heart_rate.values.append(value)
                self.resting_heart_rate.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierStepCount":
                let value = s.quantity.doubleValue(for: .count())
                self.step_count.values.append(value)
                self.step_count.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierActiveEnergyBurned":
                let unit = HKUnit(from: "kcal")
                let value = s.quantity.doubleValue(for: unit)
                self.active_energy_burned.values.append(value)
                self.active_energy_burned.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierDistanceWalkingRunning":
                let value = self.valueFromGenericQuantitySample(sample: s)
                self.distance_walking_running.values.append(value)
                self.distance_walking_running.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierOxygenSaturation":
                let value = s.quantity.doubleValue(for: .percent())
                self.oxygen_saturation.values.append(value)
                self.oxygen_saturation.timestamps.append(s.startDate)
            case "HKQuantityTypeIdentifierRespiratoryRate":
                let unit = HKUnit(from: "count/min")
                let value = s.quantity.doubleValue(for: unit)
                self.respiratory_rate.values.append(value)
                self.respiratory_rate.timestamps.append(s.startDate)
            default:
                break
            }
        }
    }
    
    func addSamples(for sampleType: HKSampleType) {
        let predicate = HKQuery.predicateForSamples(withStart: metaData.start_date, end: metaData.end_date, options: [.strictStartDate, .strictEndDate])

        let sampleQueryHR = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 1000, sortDescriptors: nil)
            { [weak self] (_, samples, _) -> Void in
                guard let samples = samples as? [HKQuantitySample],
                        samples.count > 0,
                        let self = self else { return }
                self.addQuantitySamples(for: samples)
            }

        healthStore.execute(sampleQueryHR)
    }
    
    func parseUnitFromQuantity(quantity: HKQuantity) -> String {
        let components = quantity.description.components(separatedBy: .whitespaces)
        return components[1]
    }
    
    func valueFromGenericQuantitySample(sample: HKQuantitySample) -> Double {
        if parseUnitFromQuantity(quantity: sample.quantity) == "%" {
            return sample.quantity.doubleValue(for: .percent())
        }
        else if sample.quantity.is(compatibleWith: .count()) {
            return sample.quantity.doubleValue(for: .count())
        }
        else {
            let unitString = parseUnitFromQuantity(quantity: sample.quantity)
            return sample.quantity.doubleValue(for: HKUnit(from: unitString))
        }
    }
}

extension Encodable {
    /// Converting object to postable JSON
    func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> String {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}
