import ClockKit
import HealthKit
import Sentry
import SwiftUI

var dummyData: Session = {
    Session()
}()

class Session: NSObject, Identifiable, ObservableObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate {
    var id = UUID()
    @Published var stateDescription: String = "Unknown"
    @Published var percentageComplete: Double = 0

    var timer: Timer?
    var workoutSession: HKWorkoutSession
    var date: Date {
        workoutSession.startDate ?? Date()
    }

    override init() {
        workoutSession = WorkoutFactory().workout()

        super.init()

        stateDescription = "Unknown"
        workoutSession.delegate = self
        workoutSession.associatedWorkoutBuilder().delegate = self
        updateDescription()
        
        NotificationCenter.default.addObserver(forName: .workoutStateChanged, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDescription()
                
                if self?.workoutSession.state == .stopped {
                    self?.workoutSession.end()
                }
                
                if self?.workoutSession.state == .ended {
                    self?.workoutSession.associatedWorkoutBuilder().endCollection(withEnd: Date()) { (success, error) in
                        self?.workoutSession.associatedWorkoutBuilder().finishWorkout { workout, error in
                            guard let workout = workout else { return } // Error handler
                            Serializer.serialize(workout: workout) { data in
                                if let data = data {
                                    BackgroundService.shared.updateContent(content: data, identifier: workout.uuid.uuidString)
                                }
                            }
                        }
                    }
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] _ in
            self?.percentageComplete = self?.progress() ?? 0.0
            self?.reloadComplication()
        })
    }

    func reloadComplication() {
        DispatchQueue.main.async {
            let complicationServer = CLKComplicationServer.sharedInstance()
            if let complications = complicationServer.activeComplications {
                for complication in complications {
                    complicationServer.reloadTimeline(for: complication)
                }
            }
        }
    }

    func updateDescription() {
        switch workoutSession.state {
        case .prepared:
            stateDescription = "Prepared"
        case .notStarted:
            stateDescription = "Not Started"
        case .running:
            stateDescription = "Running"
        case .ended:
            stateDescription = "Ended"
        case .paused:
            stateDescription = "Paused"
        case .stopped:
            stateDescription = "Stopped"
        @unknown default:
            stateDescription = "Unknown"
        }

        reloadComplication()
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
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        NotificationCenter.default.post(name: .workoutStateChanged, object: nil)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        track(error)
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for sampleType in collectedTypes {
            if let quantityType = sampleType as? HKQuantityType {
                guard let statistic = workoutBuilder.statistics(for: quantityType) else {
                    continue
                }

                guard let quantity = statistic.mostRecentQuantity() else {
                    continue
                }

                print("\(quantityType) \(statistic) \(quantity)")
                DispatchQueue.main.async {
                    // update the UI based on the most recent quantitiy
                }
            } else if let quantityType = sampleType as? HKSeriesType {
                print("SERIES: \(quantityType)")

            } else {
                print("OBJECT: \(sampleType)")
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
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
        if workoutSession.state == .running {
            workoutSession.stopActivity(with: Date())
        }
        
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

    func timeRemaining(_ from: Date? = nil) -> String {
        let mins = minutesRemaining()
        return "\(Int(mins))m"
    }

    private func startTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        return dateFormatter.string(from: date)
    }

    private func endTime() -> String? {
        guard let date = workoutSession.endDate else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        return dateFormatter.string(from: date)
    }

    func dateRange() -> String {
        let start = startTime()
        let end = endTime()

        return end == nil ? start : "\(start) - \(end!)"
    }
}

extension Session {
    static let oneHour = 3600.0
    static let fifteenMinutes = 900.0
}
