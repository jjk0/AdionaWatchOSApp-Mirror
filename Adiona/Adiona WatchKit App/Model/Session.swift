import HealthKit
import SwiftUI
//

var dummyData: Session = {
    Session()
}()

class SessionDelegate: NSObject, HKLiveWorkoutBuilderDelegate {
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

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}

struct Session: Identifiable, CustomStringConvertible  {
    var id = UUID()
    var description: String {
        date.description
    }
    
    var workoutDelegate = SessionDelegate()
    
    private var workoutSession: HKWorkoutSession
    var date: Date {
        workoutSession.startDate ?? Date()
    }
    
    init() {
        workoutSession = WorkoutFactory().workout()
        workoutSession.associatedWorkoutBuilder().delegate = workoutDelegate
    }
}

extension Session {
    func start() {
        workoutSession.startActivity(with: Date())
        workoutSession.associatedWorkoutBuilder().beginCollection(withStart: Date()) { (success, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func pause() {
        workoutSession.pause()
    }
    
    func end() {
        workoutSession.end()
    }
}

extension Session {
    func minutesRemaining() -> Double {
        guard let date = workoutSession.startDate else { return 0.0 }
        return (Session.fifteenMinutes + date.timeIntervalSinceNow) / 60.0
    }

    func progress() -> Double {
        let remaining = minutesRemaining()
        return max(0, min(0, remaining > 0 ? remaining / Session.fifteenMinutes : 0))
    }

    func fractionComplete() -> Double {
        progress()
    }

    func timeRemaining() -> String {
        let mins = minutesRemaining()
        return "\(Int(mins))m"
    }
}

extension Session {
    static let oneHour = 3600.0
    static let fifteenMinutes = 900.0
}
