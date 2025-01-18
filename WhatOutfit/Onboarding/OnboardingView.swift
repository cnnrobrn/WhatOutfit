import SwiftUI
import StoreKit

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let gifName: String
    var hasInstagramLink: Bool = false
    var hasPhotoUpload: Bool = false
    var isRatingPage: Bool = false
    var isLastPage: Bool = false
}

struct OnboardingView: View {
    @StateObject private var onboardingState = OnboardingState()
    @EnvironmentObject var userSettings: UserSettings
    @Binding var showLogin: Bool
    @State private var currentPage = 0
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.requestReview) var requestReview
    @State private var hasShownReview = false
    @State private var showPhotoUpload = false
    @State private var showInstagramLink = false
    
    let pages = [
        OnboardingPage(
            title: "Dress better, look better, feel better",
            subtitle: "Use AI to find, question, and upgrade your style",
            gifName: "Demo for Onboarding"
        ),
        OnboardingPage(
            title: "Share from Instagram",
            subtitle: "DM photos and reels to the Instagram account @wha7_outfit and see them in app",
            gifName: "Send from Instagram",
            hasInstagramLink: true
        ),
        OnboardingPage(
            title: "Search outfits from uploaded content",
            subtitle: "Upload images and get recommendations to shop similar looks",
            gifName: "Shop a look"
        ),
        OnboardingPage(
            title: "Try before you buy",
            subtitle: "See how clothes look by trying them on in app",
            gifName: "Try it on",
            hasPhotoUpload: true
        ),
        OnboardingPage(
            title: "Use AI as your consultant",
            subtitle: "Get tailored advice on how to improve your style",
            gifName: "Consultant Onboarding"
        ),
        OnboardingPage(
            title: "Rate us",
            subtitle: "Your ratings help us grow!",
            gifName: "wha7_logo",
            isRatingPage: true
        ),
        OnboardingPage(
            title: "Get started",
            subtitle: "Sign up and get the full suite of features from Wha7",
            gifName: "features_summary",
            isLastPage: true
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: geometry.size.width * (CGFloat(currentPage + 1) / CGFloat(pages.count)), height: 4)
                                .animation(.linear, value: currentPage)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top)
                    
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            GeometryReader { geometry in
                                VStack(spacing: 0) {
                                    // Title and Subtitle
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(page.title)
                                            .font(.system(size: 32, weight: .bold))
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 24)
                                        
                                        Text(page.subtitle)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 24)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                                    
                                    Spacer()
                                    
                                    // Content Area with GIF
                                    if page.isRatingPage {
                                        RatingPageContent()
                                    } else if page.isLastPage {
                                        VStack(alignment: .leading, spacing: 40) {
                                            FeatureRow(icon: "play.square.fill", title: "Insta-Share", description: "Share outfits from Instagram")
                                            FeatureRow(icon: "tshirt", title: "Virtual Try-On", description: "See how clothes look before you buy")
                                            FeatureRow(icon: "person.2", title: "AI Consultant", description: "Get personalized style advice")
                                            FeatureRow(icon: "camera", title: "Photo Analysis", description: "Upload outfits for instant feedback")
                                            FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Unlimited Access", description: "No restrictions on features")
                                        }
                                        .padding(.horizontal)
                                        
                                        Spacer()
                                    } else {
                                        // Calculate the scaled height based on the original aspect ratio
                                        let originalAspectRatio = 2097.0 / 967.0
                                        let availableWidth = geometry.size.width - 200 // Account for padding
                                        let scaledHeight = availableWidth * originalAspectRatio
                                        
                                        HStack {
                                            Spacer()
                                            GIFImage(name: page.gifName)
                                                .frame(width: availableWidth, height: min(scaledHeight, geometry.size.height * 0.6))
                                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 4)  // Subtle shadow
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 25)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)  // Subtle white border
                                                )
                                                .background(
                                                    RoundedRectangle(cornerRadius: 25)
                                                        .fill(Color.white.opacity(0.1))  // Subtle glow effect
                                                        .blur(radius: 8)
                                                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
                                                )
                                            Spacer()
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Bottom Button Section
                                    bottomButtons(for: page)
                                        .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // Sheets
                .sheet(isPresented: $showInstagramLink) {
                    DirectInstagramLinkView {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .sheet(isPresented: $showPhotoUpload) {
                    NavigationView {
                        BodyImageSetupView()
                            .navigationBarItems(
                                trailing: Button("Done") {
                                    showPhotoUpload = false
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                            )
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            try? await subscriptionManager.loadProducts()
        }
    }
    
    @ViewBuilder
    private func bottomButtons(for page: OnboardingPage) -> some View {
        if page.hasInstagramLink {
            HStack(spacing: 12) {
                Button(action: {
                    showInstagramLink = true
                }) {
                    Text("Link Instagram")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Button(action: {
                    withAnimation {
                        currentPage += 1
                    }
                }) {
                    Text("Skip")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
            .padding()
        } else if page.hasPhotoUpload {
            HStack(spacing: 12) {
                Button(action: {
                    showPhotoUpload = true
                }) {
                    Text("Upload Photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                
                Button(action: {
                    withAnimation {
                        currentPage += 1
                    }
                }) {
                    Text("Skip")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
            .padding()
        } else if page.isRatingPage {
            Button(action: {
                requestReview()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        currentPage += 1
                    }
                }
            }) {
                Text("Rate Now")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .padding()
            }
        } else if page.isLastPage {
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        if let product = subscriptionManager.subscriptions.first {
                            do {
                                let success = try await subscriptionManager.purchase(product)
                                if success {
                                    await userSettings.checkSubscriptionStatus()
                                    onboardingState.hasSeenOnboarding = true
                                    showLogin = true
                                }
                            } catch {
                                print("DEBUG: Error purchasing subscription: \(error)")
                            }
                        }
                    }
                }) {
                    Text("Get Started for $0.99 per Week")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                
                LegalFooterView()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        } else {
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
            }) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .padding()
            }
        }
    }
}

struct Review: Identifiable {
    let id = UUID()
    let author: String
    let title: String
    let content: String
}

struct RatingPageContent: View {
    let reviews = [
        Review(
            author: "James K.",
            title: "Finally Found That Jacket From Instagram!",
            content: "Game-changer for finding clothes I spot online! Saw this amazing leather jacket in a Reel, took a screenshot, and wha7 found the exact same one plus some cheaper alternatives. The AI consultant suggested ways to style it with different outfits too. Super easy to use and saves hours of searching. No more frantically DMing people asking \"where'd you get that?\""
        ),
        Review(
            author: "Mike R.",
            title: "Perfect for Building My Wardrobe",
            content: "As someone who's not great with fashion, this app is exactly what I needed. I just upload photos of clothes I like or screenshot Instagram posts, and it helps me find similar items at different price points. The AI consultant gives practical advice on how to pair items and build a proper wardrobe. Really helpful for upgrading my style without the awkwardness of asking friends for fashion advice."
        ),
        Review(
            author: "David T.",
            title: "Professional Style Made Easy",
            content: "This app is a lifesaver for keeping my work wardrobe on point. When I see something cool in my Instagram feed, I can instantly find similar options that fit my budget. The fashion consultant feature helps me put together different looks for client meetings and casual Fridays. Finally, an app that understands men's fashion and makes it accessible."
        ),
        Review(
            author: "Alex P.",
            title: "Instagram to Real Life",
            content: "Best feature has to be the Instagram search - saw a great outfit in a Reel, screenshot it, and boom - found exactly where to buy each piece. The similar items feature is fantastic for finding alternatives that fit my budget. Love how I can upload photos of clothes I already own and get suggestions for what to pair them with. Simple, straightforward, no fluff - just what guys need."
        ),
        Review(
            author: "Tom L.",
            title: "Style Upgrade Made Simple",
            content: "This app has seriously upgraded my fashion game. I used to save tons of Instagram posts of outfits I liked but had no idea where to find them. Now I just search with those saved posts and find the exact items or similar ones that fit my budget. The AI consultant gives solid advice on what works together and what doesn't. Perfect for guys who want to dress better but don't want to spend hours shopping."
        )
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Reviews
                VStack(spacing: 24) {
                    ForEach(reviews) { review in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                // Star rating for individual review
                                ForEach(1...5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            
                            Text(review.title)
                                .font(.headline)
                            
                            Text(review.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(review.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if review.id != reviews.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
