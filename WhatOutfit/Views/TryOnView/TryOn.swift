//
//  TryOn.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//

import SwiftUI




// MARK: - Views


// MARK: - Virtual Try-On View
struct VirtualTryOnView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var resultImage: UIImage?
    @State private var isLoading = false
    @State private var showBodyImageSetup = false
    let clothingImage: UIImage
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Processing...")
            } else if let result = resultImage {
                Image(uiImage: result)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Ready for virtual try-on")
            }
            
            Button(action: performTryOn) {
                Text("Try On")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(userSettings.userBodyImage == nil || isLoading)
        }
        .padding()
        .sheet(isPresented: $showBodyImageSetup) {
            BodyImageSetupView()
        }
        .onAppear {
            if userSettings.userBodyImage == nil {
                showBodyImageSetup = true
            }
        }
    }
    
    private func performTryOn() {
        guard let userImageData = userSettings.userBodyImage,
              let clothingImageData = clothingImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let resultData = try await TryOnService.shared.performTryOn(
                    clothingImage: clothingImageData,
                    userImage: userImageData
                )
                
                if let result = UIImage(data: resultData) {
                    await MainActor.run {
                        resultImage = result
                        isLoading = false
                    }
                }
            } catch {
                print("Try-on error: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}


// MARK: - Image Picker
