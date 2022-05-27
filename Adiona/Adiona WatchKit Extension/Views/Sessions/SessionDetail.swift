//
//  SessionDetail.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI
import HealthKit

struct SessionDetail: View {
    @EnvironmentObject var sessionData: SessionData
    var session: Session

    var sessionIndex: Int {
        sessionData.sessions.firstIndex(where: { $0.id == session.id })!
    }

    var body: some View {
        ScrollView {
            VStack {
                Text(session.description)
                    .font(.headline)
                    .lineLimit(0)
                Divider()

                Text(session.date.description)
                    .font(.caption)
                    .bold()
                    .lineLimit(0)

                Text(session.timeRemaining())
                    .font(.caption)
            }
            .padding(16)
        }
        .navigationTitle("Sessions")
    }
}

struct SessionDetail_Previews: PreviewProvider {
    static var previews: some View {
        let sessionData = SessionData()
        return Group {
            SessionDetail(session: sessionData.sessions[0])
                .environmentObject(sessionData)
                .previewDevice("Apple Watch Series 5 - 44mm")

            SessionDetail(session: sessionData.sessions[1])
                .environmentObject(sessionData)
                .previewDevice("Apple Watch Series 5 - 40mm")
        }
    }
}
