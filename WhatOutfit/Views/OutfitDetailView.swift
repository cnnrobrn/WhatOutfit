//
//  OutfitDetailView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/23/24.
//

import SwiftUI

struct OutfitDetailView: View {
    let outfit: Outfit
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OutfitDetailViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Display the outfit image at the top
                    if let image = decodeImage(from: outfit.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.error != nil {
                        Text("Failed to load items")
                            .foregroundColor(.red)
                    } else if viewModel.items.isEmpty {
                        Text("No items found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.items) { item in
                            ItemCard(item: item)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shop This Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadItems(for: outfit.id)
        }
    }
    
    private func decodeImage(from base64String: String) -> UIImage? {
        // Remove prefix if present
        let cleanedString = base64String.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
}
