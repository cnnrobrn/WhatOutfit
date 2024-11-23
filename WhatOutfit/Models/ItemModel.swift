//
//  ItemModel.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import Foundation



struct item: Identifiable, Codable, Hashable {
    var id: Int { itemId } // Computed property for Identifiable conformance
    let itemId: Int
    let outfitId: Int
    let description: String
    var links: [ProductLink]?
    let timestamp: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
    }
    
    static func == (lhs: item, rhs: item) -> Bool {
        lhs.itemId == rhs.itemId
    }
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case outfitId = "outfit_id"
        case description
        case links
        case timestamp
    }
}
