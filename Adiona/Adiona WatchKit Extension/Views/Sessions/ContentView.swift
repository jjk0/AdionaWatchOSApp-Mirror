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
            .environmentObject(HealthDataManager.shared)
    }
}

struct SessionView_Previews: PreviewProvider {    
    static var previews: some View {
        SessionView()
            .environmentObject(HealthDataManager.shared)
    }
}
