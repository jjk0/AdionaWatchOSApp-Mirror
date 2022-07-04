//
//  SampleTypes.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/25/22.
//

import Foundation
import CoreLocation

struct DataPoints<T>: Encodable where T: Encodable {
    var values = [T]()
    var timestamps = [Date]()

    var lastQueryTime = Date()
    
    private enum CodingKeys: String, CodingKey {
        case values, timestamps
    }
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
}

class MetaData: Encodable {
    let connectivity_status: String
    let device_ID: String
    let start_date = Date()
    var end_date: Date?
    
    init(connectivity_status: String, device_ID: String, end_date: Date? = nil) {
        self.connectivity_status = connectivity_status
        self.device_ID = device_ID
        self.end_date = end_date
    }
}

class AdionaData: Encodable {
    var metaData = MetaData(connectivity_status: "wifi", device_ID: UUID().uuidString)
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
    var locations = LocationData()
    
    func addQuantitySamples(for samples: [HKQuantitySample]) {
        let collectionDate = Date().addingTimeInterval(1.0)
        for s in samples {
            switch s.sampleType.identifier {
            case "HKQuantityTypeIdentifierHeartRateVariabilitySDNN":
                let value = s.quantity.doubleValue(for: HKUnit.second())
                self.heart_rate_variability.values.append(value)
                self.heart_rate_variability.timestamps.append(s.startDate)
                self.heart_rate_variability.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierHeartRate":
                let value = s.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.heart_rate.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierRestingHeartRate":
                let unit = HKUnit(from: "count/min")
                let value = s.quantity.doubleValue(for: unit)
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.resting_heart_rate.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierStepCount":
                let value = s.quantity.doubleValue(for: .count())
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.step_count.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierActiveEnergyBurned":
                let unit = HKUnit(from: "kcal")
                let value = s.quantity.doubleValue(for: unit)
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.active_energy_burned.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierDistanceWalkingRunning":
                let value = self.valueFromGenericQuantitySample(sample: s)
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.distance_walking_running.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierOxygenSaturation":
                let value = s.quantity.doubleValue(for: .percent())
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.oxygen_saturation.lastQueryTime = collectionDate
            case "HKQuantityTypeIdentifierRespiratoryRate":
                let unit = HKUnit(from: "count/min")
                let value = s.quantity.doubleValue(for: unit)
                self.heart_rate.values.append(value)
                self.heart_rate.timestamps.append(s.startDate)
                self.respiratory_rate.lastQueryTime = collectionDate
            default:
                break
            }
        }
    }
    
    func addSamples(for sampleType: HKSampleType) {
        let predicate = HKQuery.predicateForSamples(withStart: metaData.start_date, end: metaData.end_date, options: [.strictStartDate, .strictEndDate])

        let sampleQueryHR = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 1000, sortDescriptors: nil)
            { [weak self] (_, samples, _) -> Void in
                guard let samples = samples as? [HKQuantitySample], let self = self else { return }
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
    func toJSON(_ encoder: JSONEncoder = JSONEncoder()) throws -> NSString {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        let result = String(decoding: data, as: UTF8.self)
        return NSString(string: result)
    }
}
