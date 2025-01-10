//
//  OnboardingView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//
// OnboardingView.swift
import SwiftUI
import StoreKit

// OnboardingView.swift
struct OnboardingView: View {
    @StateObject private var onboardingState = OnboardingState()
    @EnvironmentObject var userSettings: UserSettings
    @Binding var showLogin: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Welcome to Wha7",
            description: """
            Wha7 Outfit is a fashion discovery app that uses AI to help you find where to buy the clothes you love. Simply share screenshots from TikTok or Instagram fashion content, and our AI will analyze the outfit and find similar items available for purchase.
            
            Key Features:
            - Instant outfit analysis from your screenshots
            - Share directly from Instagram via DM
            - Shop similar items from multiple retailers
            - Discover trending styles from other users
            - Get fashion advice with our consultant feature

            This version lets you:
            - Upload fashion screenshots for analysis
            - View product matches with direct shopping links
            - Browse a feed of outfits shared by other users
            - Maintain your personal collection of saved outfits
            - Use our bespoke fashion consultant
            - Ask key fashion questions
            """,
            gifName: "welcome_placeholder"
        ),
        OnboardingPage(
            title: "Search based on uploaded photos or images",
            description: "Use images to shop for various items in a look!",
            gifName: "tryon_placeholder"
        ),
        OnboardingPage(
            title: "Let's Set Up Your Try-On",
            description: "Try on clothes directly in app. To start upload a photo of yourself!",
            gifName: "tryon_placeholder",
            hasPhotoUpload: true
        ),
        OnboardingPage(
            title: "Connect Instagram",
            description: "Link your Instagram and DM reels or photos to @wha7_outfit to automatically upload them to the app",
            gifName: "instagram_placeholder",
            hasInstagramLink: true
        ),
        OnboardingPage(
            title: "Get tailored fashion advice",
            description: "Message the consultant to get tailored fashion advice and specific items to wear",
            gifName: "instagram_placeholder"
        ),
        OnboardingPage(
            title: "You're All Set!",
            description: "Start exploring outfits and trying them on virtually",
            gifName: "complete_placeholder"
        )
    ]
    
    var body: some View {
        NavigationView {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 20) {
                        Text(page.title)
                            .font(.title2)
                            .bold()
                        
                        Text(page.description)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        if page.hasPhotoUpload {
                            BodyImageSetupView()
                        } else if page.hasInstagramLink {
                            InstagramLinkingSection()
                        } else {
                            GIFImage(name: page.gifName)
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        if currentPage < pages.count - 1 {
                            Button("Skip") {
                                withAnimation {
                                    currentPage = pages.count - 1
                                }
                            }
                            .padding()
                        }
                        
                        Spacer()
                        
                        if currentPage == pages.count - 1 {
                            Button("Get Started") {
                                // Request review when completing onboarding
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    SKStoreReviewController.requestReview(in: scene)
                                }
                                
                                onboardingState.hasSeenOnboarding = true
                                showLogin = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        } else {
                            Button("Next") {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    }
                }
            )
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let gifName: String // Changed from image to gifName
    var hasPhotoUpload: Bool = false
    var hasInstagramLink: Bool = false
}
