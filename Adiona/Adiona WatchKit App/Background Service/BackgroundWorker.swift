import Foundation
import WatchKit

final class BackgroundWorker {
    public func schedule(firstTime: Bool = false) {
        let minutes = 15

        let when = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date.now
        )!

        WKExtension
            .shared()
            .scheduleBackgroundRefresh(
                withPreferredDate: when,
                userInfo: nil
            ) { error in
                if let error = error {
                    print("Unable to schedule: \(error.localizedDescription)")
                }
            }
    }
}
