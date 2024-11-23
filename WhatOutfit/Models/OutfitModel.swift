//
//  OutfitModel.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

// MARK: - Outfit Model
struct Outfit: Identifiable, Codable {
    let id: Int
    let imageData: String
    let description: String?
    var items: [item]?
    
    enum CodingKeys: String, CodingKey {
        case id = "outfit_id"  // Match the API response key
        case imageData = "image_data"  // Match the API response key
        case description
        case items
    }
}
