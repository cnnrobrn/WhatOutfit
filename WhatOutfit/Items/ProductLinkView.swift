import SwiftUI

struct ProductLinkView: View {
    let link: ProductLink
    @State private var image: UIImage?
    @State private var showingTryOn = false
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ImageContainer(
                image: image,
                showingTryOn: $showingTryOn,
                link: link,
                userSettings: userSettings
            )
            
            ProductDetails(link: link)
        }
        .onAppear {
            loadImage()
        }
        .sheet(isPresented: $showingTryOn) {
            if let tryOnImage = image {
                VirtualTryOnView(clothingImage: tryOnImage)
                    .environmentObject(userSettings)
            }
        }
        .alert(item: Binding(
            get: { LikeService.shared.error.map { ErrorWrapper(error: $0) } },
            set: { _ in LikeService.shared.error = nil }
        )) { errorWrapper in
            Alert(
                title: Text("Error"),
                message: Text(errorWrapper.error),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadImage() {
        guard let photoUrl = link.photoUrl else { return }
        
        if let url = URL(string: photoUrl), url.scheme != nil {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error loading image URL for item: \(self.link.title ?? "unknown") - \(error)")
                    return
                }
                
                guard let data = data,
                      let uiImage = UIImage(data: data) else {
                    print("Failed to create UIImage from URL data for item: \(self.link.title ?? "unknown")")
                    return
                }
                
                DispatchQueue.main.async {
                    self.image = uiImage
                }
            }.resume()
        } else {
            let cleanedString = photoUrl
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
                .replacingOccurrences(of: "data:image/webp;base64,", with: "")
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
                    print("Failed to create UIImage from Data for item: \(self.link.title ?? "unknown")")
                }
            }
        }
    }
}

// MARK: - Subviews
private struct ImageContainer: View {
    let image: UIImage?
    @Binding var showingTryOn: Bool
    let link: ProductLink
    let userSettings: UserSettings
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                
                ButtonOverlay(
                    showingTryOn: $showingTryOn,
                    link: link,
                    userSettings: userSettings
                )
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
    }
}

private struct ButtonOverlay: View {
    @Binding var showingTryOn: Bool
    let link: ProductLink
    let userSettings: UserSettings
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                TryOnButton(showingTryOn: $showingTryOn)
                LikeButton(link: link, userSettings: userSettings)
            }
            Spacer()
        }
    }
}

private struct TryOnButton: View {
    @Binding var showingTryOn: Bool
    
    var body: some View {
        Button(action: {
            showingTryOn = true
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
}

private struct LikeButton: View {
    let link: ProductLink
    let userSettings: UserSettings
    @StateObject private var likeService = LikeService.shared
    
    var body: some View {
        Button(action: {
            if LikeService.shared.likedItems.contains(link.id) {
                LikeService.shared.unlikeItem(itemId: link.id, phoneNumber: userSettings.phoneNumber)
            } else {
                LikeService.shared.likeItem(itemId: link.id, phoneNumber: userSettings.phoneNumber)
            }
        }) {
            Image(systemName: LikeService.shared.likedItems.contains(link.id) ? "heart.fill" : "heart")
                .foregroundColor(LikeService.shared.likedItems.contains(link.id) ? .red : .white)
                .padding(8)
                .background(Color.black.opacity(0.75))
                .clipShape(Circle())
        }
        .padding(8)
    }
}

private struct ProductDetails: View {
    let link: ProductLink
    
    var body: some View {
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
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}
