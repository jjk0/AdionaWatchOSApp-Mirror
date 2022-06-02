//
//  SessionRow.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI

struct SessionRow: View {
    @StateObject var session: HealthDataManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Adriona")
            Text(session.dateRange())
                .fontWeight(.light)
                .font(.caption)
        }
    }
}

struct SessionRow_Previews: PreviewProvider {
    static var sessions = [dummyData]

    static var previews: some View {
        Group {
            SessionRow(session: sessions[0])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
