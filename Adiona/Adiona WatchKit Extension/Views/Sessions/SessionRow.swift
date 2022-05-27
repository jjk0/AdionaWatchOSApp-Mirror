//
//  SessionRow.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI

struct SessionRow: View {
    @StateObject var session: Session

    var body: some View {
        HStack {
            Text(session.description)
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
