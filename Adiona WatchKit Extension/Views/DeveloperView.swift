//
//  ContentView.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import SwiftUI

struct DeveloperView: View {
    @State var showingKeypard = S3Session.dataBucket.bucketName == nil
    @EnvironmentObject private var extensionDelegate: ExtensionDelegate

    var buildNumber: String = {
        if let info = Bundle.main.infoDictionary {
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "x.x"
            return "(\(appBuild))"
        }
        
        return "X.X"
    }()
    
    var body: some View {
        VStack {
            Text(extensionDelegate.receivedPN ? "Recieved" : "None")
            Button("Upload") {
                extensionDelegate.sendHealthData() {
                    print("Sent")
                }
            }
            Button("Enter Code") {
                showingKeypard.toggle()
            }
            Button("Set Fence") {
                HealthDataManager.shared.location?.resetGeofence()
            }
        }.fullScreenCover(isPresented: $showingKeypard) {
            KeypadView(dismissFlag: $showingKeypard)
        }
    }
}

struct DeveloperView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperView()
    }
}
