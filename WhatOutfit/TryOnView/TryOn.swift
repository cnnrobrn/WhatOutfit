//
//  TryOn.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//

import SwiftUI

struct VirtualTryOnView: View {
    // MARK: - Properties
    let clothingImage: UIImage
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userSettings: UserSettings
    @State private var resultImage: UIImage?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var showBodyImageSetup = false
    // Add these properties at the top of VirtualTryOnView alongside other @State variables
    @State private var characterPosition = CGPoint(x: 100, y: 0)
    @State private var isJumping = false
    @State private var obstaclePosition = CGPoint(x: UIScreen.main.bounds.width, y: 0)
    @State private var gameScore = 0
    @State private var gameTimer: Timer?
    @State private var isGameOver = false

    // Add these constants
    private let groundHeight: CGFloat = 250
    private let jumpHeight: CGFloat = 120
    private let obstacleSize = CGSize(width: 30, height: 50)
    
    // MARK: - Body
    var body: some View {  // This is the required property for View protocol conformance
        ZStack {
            // Main content
            VStack {
                if isLoading {
                    loadingView
                } else if let result = resultImage {
                    resultView(image: result)
                } else {
                    startView
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBodyImageSetup) {
            BodyImageSetupView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "An unknown error occurred")
        }
        .onAppear {
            if userSettings.userBodyImage == nil {
                showBodyImageSetup = true
            }
        }
    }
    
    private var loadingView: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Creating your virtual try-on...enjoy this game while you wait.")
                        .font(.headline)
                    
                    // Game Area
                    ZStack {
                        // Character
                        Image("Logo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .position(CGPoint(x: characterPosition.x,
                                            y: groundHeight - (isJumping ? jumpHeight : 0)))
                        
                        // Obstacle
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: obstacleSize.width, height: obstacleSize.height)
                            .position(x: obstaclePosition.x, y: groundHeight)
                        
                        // Score overlay
                        VStack {
                            Text("Score: \(gameScore)")
                                .font(.headline)
                                .padding()
                            Spacer()
                        }
                        
                        if isGameOver {
                            VStack {
                                Text("Game Over!")
                                    .font(.title)
                                Text("Score: \(gameScore)")
                                    .font(.headline)
                                Button("Restart") {
                                    startGame()
                                }
                                .padding()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        }
                    }
                    .frame(height: 300) // Fixed height for game area
                    .clipped() // This ensures the game stays within bounds
                    
                    // Ground
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 2)
                    
                    Text("Tap to jump!")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                Spacer()
            }
            .onAppear {
                startGame()
            }
            .onDisappear {
                cleanup()
            }
            .onTapGesture {
                jump()
            }
        }
    }

    // Update startGame function to use the new groundHeight
    private func startGame() {
        characterPosition = CGPoint(x: 100, y: groundHeight)
        obstaclePosition = CGPoint(x: UIScreen.main.bounds.width, y: groundHeight)
        isGameOver = false
        gameScore = 0
        
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateGame()
        }
    }

    // Update collision detection in updateGame
    private func updateGame() {
        // Update obstacle position
        obstaclePosition.x -= 5
        
        // Reset obstacle when it goes off screen
        if obstaclePosition.x < -obstacleSize.width {
            obstaclePosition.x = UIScreen.main.bounds.width
            gameScore += 1
        }
        
        // Handle jumping
        if isJumping {
            characterPosition.y += 5
            if characterPosition.y >= groundHeight {
                characterPosition.y = groundHeight
                isJumping = false
            }
        }
        
        // Check for collision
        let characterFrame = CGRect(x: characterPosition.x - 25,
                                  y: characterPosition.y - (isJumping ? jumpHeight : 0) - 25,
                                  width: 50,
                                  height: 50)
        
        let obstacleFrame = CGRect(x: obstaclePosition.x - obstacleSize.width/2,
                                  y: obstaclePosition.y - obstacleSize.height/2,
                                  width: obstacleSize.width,
                                  height: obstacleSize.height)
        
        if characterFrame.intersects(obstacleFrame) {
            gameOver()
        }
    }
    
    private func jump() {
        if !isJumping {
            isJumping = true
            withAnimation(.easeOut(duration: 0.5)) {
                characterPosition.y -= jumpHeight
            }
        }
    }

    private func gameOver() {
        gameTimer?.invalidate()
        gameTimer = nil
        isGameOver = true
    }

    // Add clean up when the view disappears
    private func cleanup() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    private func resultView(image: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(25)
                
                VStack(spacing: 12) {
                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(
                            "I tried this outfit on in the wha7 app. Try on outfits for yourself at redirect.wha7.com/",
                            image: Image(uiImage: image)
                        )
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    Button("Done") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var startView: some View {
        VStack(spacing: 20) {
            if let userBodyImageData = userSettings.userBodyImage,
               let userBodyImage = UIImage(data: userBodyImageData) {
                Image(uiImage: userBodyImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            }
            
            Button(action: performTryOn) {
                Text("Start Try-On")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(userSettings.userBodyImage == nil)
            
            if userSettings.userBodyImage == nil {
                Text("Please set up your body image first")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    private func performTryOn() {
        guard let userImageData = userSettings.userBodyImage,
              let userImage = UIImage(data: userImageData) else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let result = try await TryOnService.shared.performTryOn(
                    clothingImage: clothingImage,
                    userImage: userImage
                )
                
                await MainActor.run {
                    resultImage = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                    isLoading = false
                }
            }
        }
    }
}
