//
//  VideoPlayer.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//
import SwiftUI
import AVKit

// VideoPlayerManager.swift
class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    private var currentPlayer: AVPlayer?
    
    func setCurrentPlayer(_ player: AVPlayer?) {
        // Stop current player if it exists
        currentPlayer?.pause()
        currentPlayer = player
    }
    
    func stopCurrentPlayer() {
        currentPlayer?.pause()
        currentPlayer = nil
    }
}
