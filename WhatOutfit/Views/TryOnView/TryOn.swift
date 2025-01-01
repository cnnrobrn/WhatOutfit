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
    
    // MARK: - Subviews
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Creating your virtual try-on... please note that this feature only works for shirts, pants, jackets, dresses, skirts, and tops.")
                .font(.headline)
        }
    }
    
    private func resultView(image: UIImage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                
                Button("Try Another") {
                    resultImage = nil
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
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

// MARK: - Image Picker
