//
//  SessionDetail.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI
import HealthKit

// A view that shows the data for one Restaurant.
struct ActionRow: View {
    var action: Action

    var body: some View {
        Button(action.name) {
            action.block()
        }
    }
}

struct SessionDetail: View {
    @EnvironmentObject var sessionData: HealthDataManager
    @StateObject var session: HealthDataManager

    var body: some View {

        ScrollView {
            VStack {
                Text(session.stateDescription)
                    .font(.headline)
                    .lineLimit(0)
                Button("Update") {
                    //session.updateSummary()
                }
            }.padding(16)
            
            ForEach(session.validActions(), id: \.self) { action in
                ActionRow(action: action)
            }
        }
    }
}

struct SessionDetail_Previews: PreviewProvider {
    static var previews: some View {
        let sessionData = HealthDataManager()
        
        return Group {
            SessionDetail(session: sessionData)
                .environmentObject(sessionData)
                .previewDevice("Apple Watch Series 5 - 44mm")

            SessionDetail(session: sessionData)
                .environmentObject(sessionData)
                .previewDevice("Apple Watch Series 5 - 40mm")
        }
    }
}
