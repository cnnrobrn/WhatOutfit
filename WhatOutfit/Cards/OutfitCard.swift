//
//  OutfitCard.swift
//  WhatOutfit
//

import SwiftUI

struct OutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    @State private var imageLoadError = false
    @State private var isLoading = true
    @State private var imageHeight: CGFloat = 400 // Default height
    
    private func decodeImage(from base64String: String) -> UIImage? {
        let cleanedString = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Calculate height based on image aspect ratio and screen width
        let screenWidth = UIScreen.main.bounds.width - 32 // Account for horizontal padding
        let aspectRatio = image.size.height / image.size.width
        imageHeight = screenWidth * aspectRatio
        
        return image
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: imageHeight)
                            .background(Color.gray.opacity(0.1))
                    }
                    
                    if let image = decodeImage(from: outfit.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: imageHeight)
                            .clipped()
                            .onAppear { isLoading = false }
                    } else if imageLoadError {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Failed to load image")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 400) // Fallback height for error state
                        .background(Color.gray.opacity(0.1))
                    }
                }
                .cornerRadius(12)
                .onAppear {
                    if decodeImage(from: outfit.imageData) == nil {
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
    }
}

// Preview provider for testing
struct OutfitCard_Previews: PreviewProvider {
    static var previews: some View {
        OutfitCard(outfit: Outfit(id: 1,
                                imageData: "", // Add test base64 image data here
                                description: "Test outfit",
                                items: nil)) {
            print("Card tapped")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
