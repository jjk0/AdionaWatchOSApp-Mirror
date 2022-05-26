//
//  AdionaApp.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 5/26/22.
//

import SwiftUI
import HealthKit


// The quantity types to read from the health store.
@main
struct AdionaApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self)
    private var extensionDelegate

    init() {
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                SessionView()
            }
        }
    }
}
