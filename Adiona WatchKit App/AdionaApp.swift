//
//  AdionaApp.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import SwiftUI

@main
struct AdionaApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self)
    private var extensionDelegate

    init() {
        gExtensionDelegate = extensionDelegate
    }
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView(location: Location.shared)
        }
    }
}
