
import SwiftUI

struct ProductLinkView: View {
    let link: ProductLink
    @State private var image: UIImage?
    @State private var showingTryOn = false
    @State private var showingPremiumPrompt = false
    @State private var isProcessingPurchase = false
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image container with try-on button
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(8)
                    
                    // Try-on button overlay
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                if userSettings.isPremium {
                                    showingTryOn = true
                                } else {
                                    showingPremiumPrompt = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.crop.rectangle.fill")
                                    Text("Try On")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(8)
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            .frame(width: 150, height: 150)
            
            // Product details
            VStack(alignment: .leading, spacing: 4) {
                if let merchantName = link.merchantName {
                    Text(merchantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let title = link.title {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                if let rating = link.rating {
                    HStack(alignment: .center, spacing: 4) {
                        StarRatingView(rating: rating)
                        if let reviewCount = link.reviewsCount {
                            Text("(\(reviewCount))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let price = link.price {
                    Text(price)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .bold()
                }
            }
            .frame(width: 150)
        }
        .onAppear {
            loadImage()
        }
        .alert("Premium Feature", isPresented: $showingPremiumPrompt) {
            Button("Upgrade to Premium", role: .none) {
                Task {
                    isProcessingPurchase = true
                    if let product = subscriptionManager.subscriptions.first {
                        do {
                            let success = try await subscriptionManager.purchase(product)
                            if success {
                                await userSettings.checkSubscriptionStatus()
                                if userSettings.isPremium {
                                    showingTryOn = true
                                }
                            }
                        } catch {
                            print("Error purchasing subscription: \(error)")
                        }
                    }
                    isProcessingPurchase = false
                }
            }
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("Virtual Try-On is available exclusively for premium users. Upgrade now to try on clothes virtually!")
        }
        .overlay(Group {
            if isProcessingPurchase {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView("Processing Purchase...")
                            .foregroundColor(.white)
                    )
            }
        })
        .sheet(isPresented: $showingTryOn) {
            if let tryOnImage = image {
                VirtualTryOnView(clothingImage: tryOnImage)
                    .environmentObject(userSettings)
            }
        }
    }
    
    private func loadImage() {
        if let photoUrl = link.photoUrl {
            let cleanedString = photoUrl
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let imageData = Data(base64Encoded: cleanedString) else {
                print("Failed to decode base64 string to Data for item: \(link.title ?? "unknown")")
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                if let uiImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.image = uiImage
                    }
                } else {
                    print("Failed to create UIImage from Data for item: \(link.title ?? "unknown")")
                }
            }
        }
    }
}
