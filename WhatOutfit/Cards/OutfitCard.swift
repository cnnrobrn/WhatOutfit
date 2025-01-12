import SwiftUI
import AVKit


struct OutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    @State private var imageLoadError = false
    @State private var isLoading = true
    @State private var mediaHeight: CGFloat = 400
    @State private var player: AVPlayer?
    @State private var isVisible = false
    @State private var showingFrameSelection = false
    @State private var showingImageDetail = false
    @State private var hasProcessedFrames = false
    @State private var processedItems: [item]?
    @State private var playerID = UUID()
    @State private var videoURL: URL?
    @State private var isVideoReady = false
    
    // Add observation of VideoPlayerManager
    @StateObject private var videoPlayerManager = VideoPlayerManager.shared
    
    private func handleCardTap() {
        Task {
            if player != nil {
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
    
    private func decodeMedia(from base64String: String) -> (UIImage?, AVPlayer?) {
        let cleanedString = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:video/mp4;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            return (nil, nil)
        }
        
        // Try to decode as image first
        if let image = UIImage(data: data) {
            // Resize image to a reasonable size for display
            let maxDimension: CGFloat = 1080 // Maximum dimension for images
            let size = image.size
            
            if size.width > maxDimension || size.height > maxDimension {
                let ratio = size.width / size.height
                let newSize: CGSize
                if size.width > size.height {
                    newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
                } else {
                    newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return (resizedImage, nil)
            }
            
            return (image, nil)
        }
        
        // If not an image, handle as video
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try data.write(to: tmpURL)
            
            // Create asset with options for better performance
            let assetOptions = [
                AVURLAssetPreferPreciseDurationAndTimingKey: false
            ]
            let asset = AVURLAsset(url: tmpURL, options: assetOptions)
            let playerItem = AVPlayerItem(asset: asset)
            
            // Aggressively optimize playback settings
            playerItem.preferredPeakBitRate = 800_000 // 800Kbps - much lower but still decent quality
            playerItem.preferredMaximumResolution = CGSize(width: 480, height: 854) // 480p
            
            // Configure AVPlayer
            let player = AVPlayer(playerItem: playerItem)
            player.automaticallyWaitsToMinimizeStalling = true
            player.isMuted = true
            
            // Set playback rate for potentially smoother playback
            player.rate = 1.0
            
            // Configure additional AVPlayerItem settings
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = false
            
            return (nil, player)
        } catch {
            print("Error creating video player: \(error)")
            // Clean up temp file if creation failed
            try? FileManager.default.removeItem(at: tmpURL)
            return (nil, nil)
        }
    }
    
    private func handleVideoAppearance() {
        guard let videoPlayer = player, isVisible else { return }
        
        // Only manage playback if we're the current player
        videoPlayerManager.setCurrentPlayer(videoPlayer, withID: playerID)
        
        if videoPlayerManager.isCurrentPlayer(videoPlayer, withID: playerID) {
            videoPlayer.actionAtItemEnd = .none
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: videoPlayer.currentItem,
                queue: .main) { [weak videoPlayer] _ in
                    guard let player = videoPlayer else { return }
                    player.seek(to: .zero)
                    if videoPlayerManager.isCurrentPlayer(player, withID: playerID) {
                        player.play()
                    }
                }
            
            videoPlayer.play()
        }
    }
    
    private func handleVideoDisappearance() {
        guard let videoPlayer = player else { return }
        
        // Only stop if we're the current player
        if videoPlayerManager.isCurrentPlayer(videoPlayer, withID: playerID) {
            videoPlayerManager.stopCurrentPlayer()
        }
        
        NotificationCenter.default.removeObserver(self)
        videoPlayer.pause()
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
                    }
                    
                    let mediaResult = decodeMedia(from: outfit.imageData)
                    if let image = mediaResult.0 {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .clipped()
                            .onAppear {
                                mediaHeight = calculateImageHeight(from: image)
                                isLoading = false
                            }
                    } else if let videoPlayer = mediaResult.1 {
                        VideoPlayer(player: videoPlayer)
                            .frame(maxWidth: .infinity)
                            .frame(height: mediaHeight)
                            .onAppear {
                                player = videoPlayer
                                updateVideoHeight(for: videoPlayer)
                                isLoading = false
                            }
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
                .cornerRadius(12)
                .onAppear {
                    let mediaResult = decodeMedia(from: outfit.imageData)
                    if mediaResult.0 == nil && mediaResult.1 == nil {
                        imageLoadError = true
                        isLoading = false
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isVisible = true
            if player != nil {
                handleVideoAppearance()
            }
        }
        .onDisappear {
            isVisible = false
            if player != nil {
                handleVideoDisappearance()
            }
        }
        // Track ScrollView visibility
        .onChange(of: isVisible) { newValue in
            if newValue {
                if player != nil {
                    handleVideoAppearance()
                }
            } else {
                if player != nil {
                    handleVideoDisappearance()
                }
            }
        }
        // Clean up when view is destroyed
        .onDisappear {
            if let videoPlayer = player {
                videoPlayer.pause()
                NotificationCenter.default.removeObserver(self)
                if videoPlayerManager.isCurrentPlayer(videoPlayer, withID: playerID) {
                    videoPlayerManager.stopCurrentPlayer()
                }
            }
        }
        .fullScreenCover(isPresented: $showingFrameSelection) {
            VideoFrameSelectionView(player: player, outfit: outfit)
        }
        .sheet(isPresented: $showingImageDetail) {
            if player != nil && hasProcessedFrames {
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
    private func setupVideo(url: URL) {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Configure player item
        playerItem.preferredPeakBitRate = 800_000
        playerItem.preferredMaximumResolution = CGSize(width: 480, height: 854)
        
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        newPlayer.isMuted = true
        
        // Preload video
        Task {
            do {
                try await playerItem.asset.load(.isPlayable)
                await MainActor.run {
                    player = newPlayer
                    isVideoReady = true
                    if isVisible {
                        handleVideoAppearance()
                    }
                }
            } catch {
                print("Error loading video: \(error)")
            }
        }
    }
    private func calculateImageHeight(from image: UIImage) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32
        let aspectRatio = image.size.height / image.size.width
        return screenWidth * aspectRatio
    }
    
    private func updateVideoHeight(for videoPlayer: AVPlayer) {
        guard let asset = videoPlayer.currentItem?.asset else { return }
        
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
}
