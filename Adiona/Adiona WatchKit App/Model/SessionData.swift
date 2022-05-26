

import Combine
import Foundation

class SessionData: ObservableObject {
    static var shared = SessionData()
    @Published var sessions: [Session]

    init(sessions: [Session] = [dummyData]) {
        self.sessions = sessions
    }

    var orderedSessions: [Session] {
        return sessions.sorted { $0.date < $1.date }
    }

    func nextSession(from date: Date) -> Session? {
        return orderedSessions.first { $0.date > date }
    }

    func sessions(after date: Date) -> [Session] {
        return orderedSessions.filter { $0.date > date }
    }

    func sessionBefore(_ session: Session) -> Session? {
        if let index = orderedSessions.firstIndex(where: { $0.id == session.id }) {
            guard index != 0 else {
                return nil
            }
            return orderedSessions[index - 1]
        }
        return nil
    }

    func timeUntilNextSession(from date: Date) -> TimeInterval? {
        if let next = nextSession(from: date) {
            return next.date.timeIntervalSince(date)
        }
        return nil
    }

    func removeSession(session: Session) {
    }
}
