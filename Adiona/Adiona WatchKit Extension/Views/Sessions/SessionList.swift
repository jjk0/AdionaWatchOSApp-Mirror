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
            if let session = sessionData.activeSession {
                NavigationLink {
                    SessionDetail(session: session)
                } label: {
                    SessionRow(session: session)
                }
            }
            Divider()
            List {
                ForEach(sessionData.backlog) { session in
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

let sessionData: SessionData = {
    SessionData.shared.activeSession = Session()
    SessionData.shared.addToBacklog(session: Session())
    SessionData.shared.addToBacklog(session: Session())
    SessionData.shared.addToBacklog(session: Session())
    return SessionData.shared
}()

struct SessionList_Previews: PreviewProvider {
    
    static var previews: some View {

        SessionList()
            .environmentObject(sessionData)
    }
}
