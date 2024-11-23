//
//  OutfitCard.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

// Updated OutfitCard.swift
import SwiftUI

struct OutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    private func decodeImage(from base64String: String) -> UIImage? {
        // Remove prefix if present
        let cleanedString = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                if let image = decodeImage(from: outfit.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fills the frame while maintaining aspect ratio
                        .frame(width: UIScreen.main.bounds.width - 32, height: 400) // Fixed height and width
                        .clipped() // Clips any overflow
                        .cornerRadius(12) // Rounded corners
                } else {
                    Color.gray
                        .frame(width: UIScreen.main.bounds.width - 32, height: 400)
                        .cornerRadius(12)
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
