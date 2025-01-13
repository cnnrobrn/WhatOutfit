import SwiftUI
import AVKit

struct OutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    @State private var imageLoadError = false
    @State private var isLoading = true
    @State private var mediaHeight: CGFloat = 400
    @State private var playerId = UUID()
    @State private var player: AVPlayer?
    @State private var isVideoContent = false
    @State private var showingFrameSelection = false
    @State private var showingImageDetail = false
    @State private var hasProcessedFrames = false
    @State private var processedItems: [item]?
    @State private var mediaImage: UIImage?
    @State private var isViewVisible = false
    
    @StateObject private var playerManager = VideoPlayerManager.shared
    
    private func setupMedia() {
        let cleanedString = outfit.imageData
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:video/mp4;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            imageLoadError = true
            isLoading = false
            return
        }
        
        // Try to decode as image first
        if let image = UIImage(data: data) {
            mediaImage = image
            mediaHeight = calculateImageHeight(from: image)
            isVideoContent = false
            isLoading = false
            return
        }
        
        // Handle as video
        isVideoContent = true
        player = playerManager.preparePlayer(from: data, id: playerId)
        updateVideoHeight()
        isLoading = false
    }
    
    private func calculateImageHeight(from image: UIImage) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        let aspectRatio = image.size.height / image.size.width
        return screenWidth * aspectRatio
    }
    
    private func updateVideoHeight() {
        guard let asset = player?.currentItem?.asset else { return }
        
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }
                let videoSize = try await track.load(.naturalSize)
                let screenWidth = UIScreen.main.bounds.width - 32
                let aspectRatio = videoSize.height / videoSize.width
                await MainActor.run {
                    mediaHeight = screenWidth * aspectRatio
                }
            } catch {
                print("Error calculating video height: \(error)")
                await MainActor.run {
                    mediaHeight = 400
                }
            }
        }
    }
    
    private func handleCardTap() {
        Task {
            if isVideoContent {
                do {
                    let (hasFrames, items) = try await OutfitService.shared.checkProcessedFrames(outfitId: outfit.id)
                    await MainActor.run {
                        if hasFrames {
                            hasProcessedFrames = true
                            processedItems = items
                            showingImageDetail = true
                        } else {
                            showingFrameSelection = true
                        }
                    }
                } catch {
                    print("Error checking frames: \(error)")
                    await MainActor.run {
                        showingFrameSelection = true
                    }
                }
            } else {
                showingImageDetail = true
            }
        }
    }
    
    var body: some View {
        Button(action: handleCardTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .background(Color.gray.opacity(0.1))
                    } else if isVideoContent, let videoPlayer = player {
                        VideoPlayer(player: videoPlayer)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .preference(key: ViewVisibilityKey.self, value: true)
                            .onPreferenceChange(ViewVisibilityKey.self) { isVisible in
                                if isVisible != isViewVisible {
                                    isViewVisible = isVisible
                                    if isVisible {
                                        playerManager.playVideo(id: playerId)
                                    } else {
                                        playerManager.pauseVideo(id: playerId)
                                    }
                                }
                            }
                    } else if !isVideoContent, let image = mediaImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .clipped()
                    } else if imageLoadError {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Failed to load media")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .background(Color.gray.opacity(0.1))
                    }
                }
            }
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            setupMedia()
        }
        .onDisappear {
            if isVideoContent {
                playerManager.cleanupPlayer(id: playerId)
            }
        }
        .fullScreenCover(isPresented: $showingFrameSelection) {
            VideoFrameSelectionView(player: player, outfit: outfit)
        }
        .sheet(isPresented: $showingImageDetail) {
            if isVideoContent && hasProcessedFrames {
                OutfitDetailView(outfit: Outfit(
                    id: outfit.id,
                    imageData: outfit.imageData,
                    description: outfit.description,
                    items: processedItems
                ))
            } else {
                OutfitDetailView(outfit: outfit)
            }
        }
    }
}

// Preference key for tracking view visibility
struct ViewVisibilityKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
