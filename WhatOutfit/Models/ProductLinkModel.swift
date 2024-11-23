//
//  ProductLinkModel.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import Foundation
import SwiftUI

struct ProductLink: Identifiable, Codable, Hashable {
    let id: Int
    let photoUrl: String // Actually contains base64 data
    let url: String
    let price: String
    let title: String
    let rating: Double?
    let reviewsCount: Int?
    let merchantName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case photoUrl = "photo_url"
        case url
        case price
        case title
        case rating
        case reviewsCount = "reviews_count"
        case merchantName = "merchant_name"
    }
    
    // Helper function to decode base64 image
    func decodeImage() -> UIImage? {
        // Remove prefix if present
        let cleanedString = photoUrl
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            print("Failed to decode base64 string to Data")
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Failed to create UIImage from Data")
            return nil
        }
        
        return image
    }
}
