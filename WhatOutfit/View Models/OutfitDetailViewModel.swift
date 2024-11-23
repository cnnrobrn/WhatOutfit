//
//  OutfitDetailViewModel.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//
import SwiftUI

class OutfitDetailViewModel: ObservableObject {
    @Published var items: [item] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadItems(for outfitId: Int) {
        isLoading = true
        
        guard let url = URL(string: "https://access.wha7.com/api/items?outfit_id=\(outfitId)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        print("Loading items for outfit: \(outfitId)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Error loading items: \(error)")
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                // Print response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                
                do {
                    let decodedItems = try JSONDecoder().decode([item].self, from: data)
                    self?.items = decodedItems
                    print("Successfully loaded \(decodedItems.count) items")
                } catch {
                    self?.error = "Failed to decode items: \(error)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
