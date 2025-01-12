//
//  SubscriptionView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/10/25.
//
import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 12) {
                Text("Unlock the full Wha7 experience")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Get personalized style recommendations, virtual try-ons, and AI-powered outfit advice")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Features List
            VStack(alignment: .leading, spacing: 40) {
                FeatureRow(icon: "play.square.fill", title: "Insta-Share", description: "Share outfits from Instagram")
                FeatureRow(icon: "tshirt", title: "Virtual Try-On", description: "See how clothes look before you buy")
                FeatureRow(icon: "person.2", title: "AI Consultant", description: "Get personalized style advice")
                FeatureRow(icon: "camera", title: "Photo Analysis", description: "Upload outfits for instant feedback")
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited Access", description: "No restrictions on features")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Subscription Button
            if let product = subscriptionManager.subscriptions.first {
                Button(action: {
                    Task {
                        do {
                            let success = try await subscriptionManager.purchase(product)
                            if success {
                                await userSettings.checkSubscriptionStatus()
                            }
                        } catch {
                            print("Error purchasing subscription: \(error)")
                        }
                    }
                }) {
                    Text("Subscribe - \(product.displayPrice) per week")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 40)
        .onChange(of: userSettings.isPremium) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}
