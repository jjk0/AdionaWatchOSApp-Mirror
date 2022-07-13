//
//  ContentView.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import SwiftUI

struct ContentView: View {
    @State var showingKeypard = Uploader.shared.bucketName == nil
    @StateObject var location: Location

    var buildNumber: String = {
        if let info = Bundle.main.infoDictionary {
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "x.x"
            return "(\(appBuild))"
        }
        
        return "X.X"
    }()
    
    var body: some View {
        VStack {
            Text(buildNumber)
            Button("Upload") {
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
