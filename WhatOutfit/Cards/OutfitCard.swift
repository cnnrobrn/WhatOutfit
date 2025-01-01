//
//  OutfitCard.swift
//  WhatOutfit
//

import SwiftUI
import AVKit


import SwiftUI
import AVKit

struct OutfitCard: View {
   let outfit: Outfit
   let onTap: () -> Void
   @State private var imageLoadError = false
   @State private var isLoading = true
   @State private var mediaHeight: CGFloat = 400 // Default height
   @State private var player: AVPlayer?
   @State private var isVisible = false
   @State private var showingFrameSelection = false
   @State private var showingImageDetail = false
   
   private let videoPlayerManager = VideoPlayerManager.shared
   
   private func handleCardTap() {
       if player != nil {
           showingFrameSelection = true
       } else {
           showingImageDetail = true
       }
   }
   
   private func calculateImageHeight(from image: UIImage) -> CGFloat {
       let screenWidth = UIScreen.main.bounds.width - 32
       let aspectRatio = image.size.height / image.size.width
       return screenWidth * aspectRatio
   }
   
   private func calculateVideoHeight(from asset: AVAsset) async -> CGFloat {
       let screenWidth = UIScreen.main.bounds.width - 32
       do {
           let tracks = try await asset.loadTracks(withMediaType: .video)
           guard let track = tracks.first else { return 400 }
           let videoSize = try await track.load(.naturalSize)
           let aspectRatio = videoSize.height / videoSize.width
           return screenWidth * aspectRatio
       } catch {
           print("Error calculating video height: \(error)")
           return 400 // Default fallback height
       }
   }
   
   private func updateVideoHeight(for videoPlayer: AVPlayer) {
       guard let asset = videoPlayer.currentItem?.asset else { return }
       
       Task {
           let height = await calculateVideoHeight(from: asset)
           await MainActor.run {
               mediaHeight = height
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
           return (image, nil)
       }
       
       // If not an image, try to decode as video
       let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
       do {
           try data.write(to: tmpURL)
           let player = AVPlayer(url: tmpURL)
           return (nil, player)
       } catch {
           print("Error creating video player: \(error)")
           return (nil, nil)
       }
   }
   
   private func handleVideoAppearance() {
       guard let videoPlayer = player else { return }
       videoPlayerManager.setCurrentPlayer(videoPlayer)
       videoPlayer.actionAtItemEnd = .none
       NotificationCenter.default.addObserver(
           forName: .AVPlayerItemDidPlayToEndTime,
           object: videoPlayer.currentItem,
           queue: .main) { _ in
           videoPlayer.seek(to: .zero)
           videoPlayer.play()
       }
       videoPlayer.play()
   }
   
   private func handleVideoDisappearance() {
       guard let videoPlayer = player else { return }
       videoPlayer.pause()
       NotificationCenter.default.removeObserver(self)
       if isVisible {
           videoPlayerManager.stopCurrentPlayer()
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
                   }
                   
                   let mediaResult = decodeMedia(from: outfit.imageData)
                   if let image = mediaResult.0 {
                       // Display image
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
                       // Display video
                       VideoPlayer(player: videoPlayer)
                           .frame(maxWidth: .infinity)
                           .frame(height: mediaHeight)
                           .onAppear {
                               player = videoPlayer
                               updateVideoHeight(for: videoPlayer)
                               isLoading = false
                               isVisible = true
                               handleVideoAppearance()
                           }
                           .onDisappear {
                               isVisible = false
                               handleVideoDisappearance()
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
                       .frame(height: 400) // Fallback height for error state
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
       .fullScreenCover(isPresented: $showingFrameSelection) {
           VideoFrameSelectionView(player: player)
       }
       .sheet(isPresented: $showingImageDetail) {
           // Your existing image detail view
           Text("Image Detail View")
       }
   }
}
