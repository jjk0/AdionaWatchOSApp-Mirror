//
//  ContentView.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import SwiftUI

struct ContentView: View {
    @State var showingKeypard = false
    @StateObject var location: Location

    var body: some View {
        VStack {
            Text(location.geoFenceStatus)
            Button("Send It") {
                gExtensionDelegate.sendHealthData() {
                    print("Sent")
                }
            }
            Button("Enter Code") {
                showingKeypard.toggle()
            }
            Button("Set Fence") {
                Location.shared.geoFence = nil
            }
//            .sheet(isPresented: $showingKeypard) {
//                KeypadView(enteredDigits: "")
//            }
        }.fullScreenCover(isPresented: $showingKeypard) {
            KeypadView(enteredDigits: "")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(location: Location.shared)
    }
}
