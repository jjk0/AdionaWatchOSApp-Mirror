//
//  AdionaApp.swift
//  Adiona WatchKit Extension
//
//  Created by Ken Franklin on 6/22/22.
//

import SwiftUI

@main
struct AdionaApp: App {
    @Environment(\.scenePhase) var scenePhase

    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            DeveloperView()
        }.onChange(of: scenePhase) { phase in
            switch phase {
                case .active:
                    print("\(#function) REPORTS - App change of scenePhase to ACTIVE")
                case .inactive:
                    print("\(#function) REPORTS - App change of scenePhase Inactive")
                case .background:
                    extensionDelegate.schedule()
                    HealthDataManager.shared.location?.restart()
                default:
                    print("\(#function) REPORTS - App change of scenePhase Default")
            }
        }
    }
}
