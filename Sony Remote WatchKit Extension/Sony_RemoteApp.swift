//
//  Sony_RemoteApp.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 05.12.2020.
//

import SwiftUI

@main
struct Sony_RemoteApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
