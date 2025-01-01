//
//  ReelModels.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/2/25.
//

import SwiftUI
// Response models for frame processing
struct ProcessResponse: Codable {
    let processed_frames: [ProcessedFrame]
}

struct ProcessedFrame: Codable {
    let frame_id: Int
    let items: [ProcessedItem]  // Changed from [item] to [ProcessedItem]
}

struct ProcessedItem: Codable {
    let description: String
    let search: String
    
    // Convert ProcessedItem to your app's item model
    func toItem(outfitId: Int) -> item {
        return item(
            itemId: 0,  // You might want to generate a temporary ID
            outfitId: outfitId,
            description: description,
            links: nil,  // Links will be populated later if needed
            timestamp: nil,
            searchQuery: search
        )
    }
}
