//
//  SessionList.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI

struct SessionList: View {
    @EnvironmentObject var sessionData: SessionData

    var body: some View {
        NavigationView {
            List {
                ForEach(sessionData.sessions) { session in
                    NavigationLink {
                        SessionDetail(session: session)
                    } label: {
                        SessionRow(session: session)
                    }
                }
            }
            .navigationTitle("Sessions")
        }
    }
}

struct SessionList_Previews: PreviewProvider {
    static var previews: some View {
        SessionList()
            .environmentObject(SessionData())
    }
}
