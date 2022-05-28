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
            let workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = workoutSession.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                         workoutConfiguration: configuration)
            return workoutSession
        } catch {
            print(error.localizedDescription)
            track(error)
fatalError("Couldnt create WorkoutSession")
            
        }
    }
}
