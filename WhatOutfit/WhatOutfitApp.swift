import SwiftUI

@main
struct WhatOutfitApp: App {
    @StateObject private var userSettings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .preferredColorScheme(.light)  // Add this line
        }
    }
}
