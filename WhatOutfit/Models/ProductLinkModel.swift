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
    let photoUrl: String?
    let url: String
    let price: String?
    let title: String?
    let rating: Double?
    let reviewsCount: Int?
    let merchantName: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProductLink, rhs: ProductLink) -> Bool {
        lhs.id == rhs.id
    }
    
    func cleanURL() -> URL {
        var cleanedURL = url
        
        // Remove Google redirect prefix if present
        if cleanedURL.starts(with: "/url?q=") {
            cleanedURL = String(cleanedURL.dropFirst(7))
        }
        
        // URL decode the string
        if let decodedURL = cleanedURL.removingPercentEncoding {
            cleanedURL = decodedURL
        }
        
        // Remove any parameters after source or ref
        if let range = cleanedURL.range(of: "?source=") ??
                      cleanedURL.range(of: "&source=") ??
                      cleanedURL.range(of: "?ref=") ??
                      cleanedURL.range(of: "&ref=") {
            cleanedURL = String(cleanedURL[..<range.lowerBound])
        }
        
        // Ensure URL starts with https://
        if !cleanedURL.starts(with: "http://") && !cleanedURL.starts(with: "https://") {
            cleanedURL = "https://" + cleanedURL
        }
        
        return URL(string: cleanedURL) ?? URL(string: "https://www.google.com")!
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
        guard let photoUrlString = photoUrl else {
            print("No photo URL available")
            return nil
        }
        
        // Remove prefix if present
        let cleanedString = photoUrlString
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedString.isEmpty else {
            print("Empty image data string")
            return nil
        }
        
        guard let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters) else {
            print("Failed to decode base64 string to Data for item: \(title ?? "unknown")")
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Failed to create UIImage from Data for item: \(title ?? "unknown")")
            return nil
        }
        
        return image
    }
}
