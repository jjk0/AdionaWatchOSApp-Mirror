import HealthKit
import SwiftUI
//

var dummyData: Session = {
        Session(
            name: "Collecting Data",
            longDescription: "In progress...",
            workoutSession: WorkoutFactory().workout())
}()

struct WorkoutFactory {
    func workout() -> HKWorkoutSession {
        guard let healthStore = healthStore else {
            fatalError("Health Store not established")
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            let authorizationStatus = healthStore.authorizationStatus(for: HKSampleType.workoutType())

            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                         workoutConfiguration: configuration)
            
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }

            return session
        } catch {
            // Handle failure here.
            fatalError("Unable to create workout session")
        }
    }
    
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

struct Session: Identifiable {
    var id = UUID()
    var name: String
    var longDescription: String
    var workoutSession: HKWorkoutSession
    var date: Date {
        workoutSession.startDate ?? Date()
    }
}

extension Session {
    func minutesRemaining() -> Double {
        guard let date = workoutSession.startDate else { return 0.0 }
        return (15 * 60) - date.timeIntervalSinceNow / 60.0
    }

    func progress() -> Double {
        let remaining = minutesRemaining()
        return max(0, min(1.0, remaining > 0 ? remaining / (15 * 60) : 0))
    }

    func rationalizedFractionCompleted() -> Double {
        progress()
    }

    func rationalizedTimeRemaining() -> String {
        let mins = minutesRemaining()
        return "\(mins)m"
    }
}

extension Session {
    static let oneHour = 3600.0

}
