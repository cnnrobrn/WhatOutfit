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
                .onOpenURL { url in
                    handleUniversalLink(url)
                }
        }
    }
    
    private func handleUniversalLink(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let path = components?.path
        
        print("Received Universal Link path: \(path ?? "no path")")
        // Your app will handle navigation based on your existing structure
    }
}
