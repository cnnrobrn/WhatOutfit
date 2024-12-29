//
//  SettingsView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isAuthenticated: Bool
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            ScrollingBanner(text: "🎉 Connect your Instagram to send posts directly to the Wha7_Outfit Instagram. Responses are displayed in app! 🎉")
            NavigationView {
                List {
                    Section(header: Text("Account Information")) {
                        HStack {
                            Text("Phone Number")
                            Spacer()
                            Text(userSettings.phoneNumber)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Subscription Status")
                            Spacer()
                            Text(userSettings.isPremium ? "Premium" : "Free")
                                .foregroundColor(userSettings.isPremium ? .green : .gray)
                        }
                    }
                    if !userSettings.isPremium {
                        Section(header: Text("Premium Features")) {
                            Button(action: {
                                Task {
                                    if let product = subscriptionManager.subscriptions.first {
                                        do {
                                            let success = try await subscriptionManager.purchase(product)
                                            if success {
                                                await userSettings.checkSubscriptionStatus()
                                            }
                                        } catch {
                                            print("Error purchasing subscription: \(error)")
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Upgrade to Premium")
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    Section(header: Text("Virtual Try-On")) {
                        NavigationLink("Body Image Settings") {
                            BodyImageSettingsView()
                        }
                    }
                    InstagramLinkingSection()
                    
                    Section {
                        Link(destination: URL(string: "https://www.wha7.com/f/eac6ab97-f56b-447a-8d12-90ce7fe417d2")!) {
                            HStack {
                                Text("Delete Account")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            userSettings.clearPhoneNumber()
                            isAuthenticated = false
                        }) {
                            HStack {
                                Text("Log Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Settings")
                .task {
                    // Load subscription products
                    try? await subscriptionManager.loadProducts()
                    // Check subscription status
                    await userSettings.checkSubscriptionStatus()
                }
            }
        }
    }
}
