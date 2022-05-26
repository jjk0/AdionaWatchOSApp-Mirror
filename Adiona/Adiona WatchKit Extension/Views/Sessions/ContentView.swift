//
//  ContentView.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI

struct SessionView: View {
    var body: some View {
        SessionList()
            .environmentObject(SessionData.shared)
    }
}

struct SessionView_Previews: PreviewProvider {    
    static var previews: some View {
        SessionView()
            .environmentObject(SessionData.shared)
    }
}
