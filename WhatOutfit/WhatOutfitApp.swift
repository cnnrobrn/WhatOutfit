import SwiftUI
import StoreKit

@main
struct WhatOutfitApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(subscriptionManager)  // Make subscription manager available throughout the app
                .preferredColorScheme(.light)
                .task {
                    // Load subscription products when app launches
                    try? await subscriptionManager.loadProducts()
                }
        }
    }
}
