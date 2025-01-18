//
//  OutfitService.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//
import SwiftUI
import Foundation

enum OutfitServiceError: Error {
    case invalidImage
    case encodingError
    case networkError(Error)
    case serverError(String)
}

class OutfitService {
    static let shared = OutfitService()
    private let baseURL = "https://frames.wha7.com"
    
    func convertImageToBase64(_ image: UIImage, quality: CGFloat = 0.7) throws -> String {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw OutfitServiceError.invalidImage
        }
        return imageData.base64EncodedString()
    }
    func checkProcessedFrames(outfitId: Int) async throws -> (Bool, [item]?) {
        guard let url = URL(string: "\(baseURL)/check_frames/\(outfitId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OutfitServiceError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorResponse["detail"] {
                throw OutfitServiceError.serverError(detail)
            }
            throw OutfitServiceError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        let frameResponse = try JSONDecoder().decode(FrameCheckResponse.self, from: data)
        
        // Convert ProcessedItems to items using the toItem method
        let convertedItems = frameResponse.items?.map { processedItem in
            processedItem.toItem(outfitId: outfitId)
        }
        
        return (frameResponse.has_frames, convertedItems)
    }
    
    func submitFrames(outfitId: Int, frames: [UIImage]) async throws -> [ProcessedFrame] {
        guard let url = URL(string: "\(baseURL)/process_frames/") else {
            throw URLError(.badURL)
        }
        
        // Convert images to base64
        let base64Frames = try frames.map { image -> String in
            try convertImageToBase64(image)
        }
        
        let request = FrameRequest(outfit_id: outfitId, frames: base64Frames)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OutfitServiceError.networkError(URLError(.badServerResponse))
            }
            
            if httpResponse.statusCode != 200 {
                // Try to parse error message from server
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorResponse["detail"] {
                    throw OutfitServiceError.serverError(detail)
                }
                throw OutfitServiceError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            let responseData = try JSONDecoder().decode(ProcessResponse.self, from: data)
            return responseData.processed_frames
        } catch {
            throw OutfitServiceError.networkError(error)
        }
    }
}


struct ItemResponse: Codable {
    let description: String
    let search: String
    
    enum CodingKeys: String, CodingKey {
        case description
        case search
    }
}

// Update FrameRequest to match API expectations
struct FrameRequest: Codable {
    let outfit_id: Int
    let frames: [String]  // Base64 encoded image strings
}
struct FrameCheckResponse: Codable {
    let has_frames: Bool
    let items: [ProcessedItem]?
    
    // Helper method to convert ProcessedItems to app items
    func toItems(outfitId: Int) -> [item]? {
        guard let items = items else { return nil }
        return items.map { $0.toItem(outfitId: outfitId) }
    }
}

