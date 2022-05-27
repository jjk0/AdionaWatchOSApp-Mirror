import HealthKit
import Sentry
import SwiftUI

var dummyData: Session = {
    Session()
}()

class SessionDelegate: NSObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        NotificationCenter.default.post(name: .workoutStateChanged, object: nil)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        track(error)
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)
            // let label = labelForQuantityType(quantityType)

            DispatchQueue.main.async {
                // Update the user interface.
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

class Session: Identifiable, CustomStringConvertible, ObservableObject {
    var id = UUID()
    @Published var description: String
    @Published var percentageComplete: Double = 0

    var workoutDelegate = SessionDelegate()
    var timer: Timer?

    private var workoutSession: HKWorkoutSession
    var date: Date {
        workoutSession.startDate ?? Date()
    }

    init() {
        description = "Unknown"
        workoutSession = WorkoutFactory().workout()
        workoutSession.delegate = workoutDelegate
        workoutSession.associatedWorkoutBuilder().delegate = workoutDelegate
        updateDescription()

        NotificationCenter.default.addObserver(forName: .workoutStateChanged, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDescription()
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] _ in
            self?.percentageComplete = self?.progress() ?? 0.0
        })
    }

    func updateDescription() {
        switch workoutSession.state {
        case .prepared:
            description = "Prepared"
        case .notStarted:
            description = "Not Started"
        case .running:
            description = "Running"
        case .ended:
            description = "Ended"
        case .paused:
            description = "Paused"
        case .stopped:
            description = "Stopped"
        @unknown default:
            description = "Unknown"
        }
    }
}

struct Action: Identifiable, Hashable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id = UUID()
    let name: String
    let block: () -> Void
}

extension Session {
    func start() {
        workoutSession.startActivity(with: Date())
        workoutSession.associatedWorkoutBuilder().beginCollection(withStart: Date()) { _, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        updateDescription()
    }

    func pause() {
        workoutSession.pause()
        updateDescription()
    }

    func resume() {
        workoutSession.resume()
        updateDescription()
    }

    func end() {
        workoutSession.end()
        updateDescription()
    }

    func upload() {}

    func validActions() -> [Action] {
        switch workoutSession.state {
        case .prepared:
            return [Action(name: "Start", block: { [weak self] in self?.start() })]
        case .notStarted:
            return [Action(name: "Start", block: { [weak self] in self?.start() })]
        case .running:
            return [Action(name: "Pause", block: { [weak self] in self?.pause() }),
                    Action(name: "End", block: { [weak self] in self?.end() })]
        case .ended:
            return [Action(name: "Upload", block: { [weak self] in self?.upload() })]
        case .paused:
            return [Action(name: "Resume", block: { [weak self] in self?.resume() }),
                    Action(name: "End", block: { [weak self] in self?.end() })]
        case .stopped:
            return [Action(name: "Start", block: { [weak self] in self?.start() })]
        @unknown default:
            return []
        }
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
