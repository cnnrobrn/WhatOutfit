import SwiftUI

// ContentView.swift
struct ContentView: View {
    @StateObject private var viewModel = OutfitViewModel()
    @StateObject private var onboardingState = OnboardingState()
    @State private var phoneNumber: String = ""
    @EnvironmentObject var userSettings: UserSettings
    @State private var isAuthenticated: Bool = false
    @State private var showLogin: Bool = false
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !isAuthenticated {
                LoginView(phoneNumber: $phoneNumber) { success in
                    isAuthenticated = success
                }
            } else if !onboardingState.hasSeenOnboarding {
                OnboardingView(showLogin: $showLogin)
            } else {
                MainTabView(
                    viewModel: viewModel,
                    phoneNumber: phoneNumber,
                    selectedTab: $selectedTab,
                    isAuthenticated: $isAuthenticated
                )
            }
        }
        .onChange(of: showLogin) { newValue in
            if newValue {
                // User has completed or skipped onboarding
                onboardingState.hasSeenOnboarding = true
            }
        }
    }
}
