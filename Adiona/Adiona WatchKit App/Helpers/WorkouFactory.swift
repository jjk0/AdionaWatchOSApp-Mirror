//
//  WorkouFactory.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/27/22.
//

import Foundation
import HealthKit
import Sentry

struct WorkoutFactory {
    func workout() -> HKWorkoutSession {
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                         workoutConfiguration: configuration)
            return session
        } catch {
            print(error.localizedDescription)
            track(error)
fatalError("Couldnt create WorkoutSession")
            
        }
    }
    
    // This needs to go somewhere else, like on the session
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)
            //let label = labelForQuantityType(quantityType)
            
            DispatchQueue.main.async() {
                // Update the user interface.
            }
        }
    }

}
