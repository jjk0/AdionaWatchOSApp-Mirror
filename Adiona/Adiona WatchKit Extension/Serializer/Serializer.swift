//
//  Serializer.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/28/22.
//

import Foundation
import HealthKit

class Serializer {
    class func serialize(workout: HKWorkout?, completion:@escaping ((Data?)->Void)) {
        guard let workout = workout else { completion(nil)
            return }
        let forWorkout = HKQuery.predicateForObjects(from: workout)

        guard let activeEnergyBurnedType = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned) else { completion(nil)
            return }
        guard let stepsSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else { completion(nil)
            return }
        guard let heartRateSampleType = HKSampleType.quantityType(forIdentifier: .heartRate) else { completion(nil)
            return }

        let stepsDescriptor = HKQueryDescriptor(sampleType: stepsSampleType,
                                                predicate: forWorkout)

        let activeEnergyDescriptor = HKQueryDescriptor(sampleType: activeEnergyBurnedType,
                                                predicate: forWorkout)

        // Create the heart-rate descriptor.
        let heartRateDescriptor = HKQueryDescriptor(sampleType: heartRateSampleType,
                                                    predicate: forWorkout)

        // Create the query.
        var JSON: String = String()
        let query = HKSampleQuery(queryDescriptors: [heartRateDescriptor, stepsDescriptor, activeEnergyDescriptor],
                                  limit: HKObjectQueryNoLimit) { _, samples, _ in
            guard let samples = samples else { return }
            
            do {
                for sample in samples {
                    let serializer = OMHSerializer()
                    JSON.append(contentsOf: try serializer.json(for: sample))
                }
                
                let data = Data(JSON.utf8)
                completion(data)
            } catch {
                completion(nil)
            }
        }

        healthStore.execute(query)
    }
}
