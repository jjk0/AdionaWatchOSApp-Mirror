//
//  SessionList.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI

struct SessionList: View {
    @EnvironmentObject var healthData: HealthDataManager

    var body: some View {
        NavigationView {
            NavigationLink {
                SessionDetail(session: healthData)
            } label: {
                SessionRow(session: healthData)
            }
//            Divider()
//            List {
//                ForEach(sessionData.backlog) { session in
//                    NavigationLink {
//                        SessionDetail(session: session)
//                    } label: {
//                        SessionRow(session: session)
//                    }
//                }
//            }
        }.navigationTitle("Sessions")
    }
}

struct SessionList_Previews: PreviewProvider {
    static var previews: some View {
        SessionList()
            .environmentObject(HealthDataManager.shared)
    }
}
