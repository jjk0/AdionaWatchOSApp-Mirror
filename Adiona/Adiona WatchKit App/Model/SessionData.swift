

import Combine
import Foundation

class SessionData: ObservableObject {
    static var shared = SessionData()
    @Published var backlog = [Session]()
    @Published var activeSession: Session?

    func addToBacklog(session: Session) {
        backlog.append(session)
        backlog.sort { lhs, rhs in
            lhs.date > rhs.date
        }
    }
    
    func removeFromBacklog(session: Session) {
    }
}
