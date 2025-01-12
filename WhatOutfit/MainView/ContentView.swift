import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = OutfitViewModel()
    @StateObject private var onboardingState = OnboardingState()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var phoneNumber: String = ""
    @EnvironmentObject var userSettings: UserSettings
    @State private var isAuthenticated: Bool = false
    @State private var showLogin: Bool = false
    @State private var selectedTab = 0
    @State private var isCheckingSubscription = false
    
    var body: some View {
        Group {
            if !isAuthenticated {
                LoginView(phoneNumber: $phoneNumber) { success in
                    isAuthenticated = success
                }
            } else if !onboardingState.hasSeenOnboarding {
                OnboardingView(showLogin: $showLogin)
            } else if isCheckingSubscription {
                LoadingView()
                    .task {
                        await checkSubscriptionStatus()
                    }
            } else {
                MainTabView(
                    viewModel: viewModel,
                    phoneNumber: phoneNumber,
                    selectedTab: $selectedTab,
                    isAuthenticated: $isAuthenticated
                )
            }
        }
        .onChange(of: showLogin) { oldValue, newValue in
            if newValue {
                onboardingState.hasSeenOnboarding = true
            }
        }
        .onChange(of: onboardingState.hasSeenOnboarding) { oldValue, newValue in
            if newValue {
                isCheckingSubscription = true
            }
        }
    }
    
    private func checkSubscriptionStatus() async {
        try? await subscriptionManager.loadProducts()
        await userSettings.checkSubscriptionStatus()
        isCheckingSubscription = false
    }
}
