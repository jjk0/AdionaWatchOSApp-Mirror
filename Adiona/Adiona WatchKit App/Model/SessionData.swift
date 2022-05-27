

import Combine
import Foundation

class SessionData: ObservableObject {
    static var shared = SessionData()
    @Published var sessions: [Session]

    init(sessions: [Session] = [Session()]) {
        self.sessions = sessions
    }

    var activeSession: Session? {
        orderedSessions.first
    }
    
    var orderedSessions: [Session] {
        return sessions.sorted { $0.date < $1.date }
    }

    func removeSession(session: Session) {
    }
}
