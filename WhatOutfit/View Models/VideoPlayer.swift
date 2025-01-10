//
//  VideoPlayer.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//
import AVKit

class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    @Published private(set) var currentPlayer: AVPlayer?
    private var activePlayerID: UUID?
    
    private init() {}
    
    func setCurrentPlayer(_ player: AVPlayer?, withID id: UUID) {
        // Only switch if it's a different player or ID
        if currentPlayer !== player || activePlayerID != id {
            stopCurrentPlayer()
            
            currentPlayer = player
            activePlayerID = id
            
            // Configure the new player
            if let player = player {
                // Prevent performance issues with audio
                player.isMuted = true
                
                // Set video gravity to aspect fit to reduce memory usage
                if let playerLayer = player.currentItem?.asset as? AVURLAsset {
                    player.currentItem?.videoComposition = nil
                }
                
                // Reduce memory usage by limiting playback quality
                player.currentItem?.preferredPeakBitRate = 2000000 // 2Mbps
                
                // Set preferred video qualities
                player.currentItem?.preferredMaximumResolution = CGSize(width: 1280, height: 720)
            }
        }
    }
    
    func stopCurrentPlayer() {
        currentPlayer?.pause()
        currentPlayer?.currentItem?.preferredPeakBitRate = 0
        currentPlayer?.currentItem?.videoComposition = nil
        currentPlayer = nil
        activePlayerID = nil
    }
    
    func isCurrentPlayer(_ player: AVPlayer?, withID id: UUID) -> Bool {
        return player === currentPlayer && id == activePlayerID
    }
}
