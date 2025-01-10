import SwiftUI
import StoreKit

@main
struct WhatOutfitApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var onboardingState = OnboardingState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(subscriptionManager)
                .environmentObject(onboardingState)
                .preferredColorScheme(.light)
                .task {
                    try? await subscriptionManager.loadProducts()
                }
        }
    }
}
