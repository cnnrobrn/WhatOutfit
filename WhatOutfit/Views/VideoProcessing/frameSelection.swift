//
//  frameSelection.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//
import SwiftUI
import AVKit


struct VideoFrameSelectionView: View {
    let player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFrames: [UIImage] = []
    @State private var showingReview = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap the video to determine which frames have outfits.")
                .font(.headline)
                .padding()
            
            ZStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: 400)
                        .cornerRadius(12)
                    
                    // Add a transparent button over the video for tap detection
                    Button(action: {
                        captureCurrentFrame(from: player)
                    }) {
                        Color.clear
                    }
                    .frame(height: 400)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedFrames.indices, id: \.self) { index in
                        FrameThumbnail(image: selectedFrames[index]) {
                            selectedFrames.remove(at: index)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
            
            Spacer()
            
            Button(action: {
                showingReview = true
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .disabled(selectedFrames.isEmpty)
        }
        .navigationBarItems(leading: Button("Cancel") { dismiss() })
        .fullScreenCover(isPresented: $showingReview) {
            VideoFrameReviewView(frames: selectedFrames)
        }
    }
    
    private func captureCurrentFrame(from player: AVPlayer) {
        guard let asset = player.currentItem?.asset else { return }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: player.currentTime().seconds,
                         preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            selectedFrames.append(image)
        } catch {
            print("Error capturing frame: \(error)")
        }
    }
}
