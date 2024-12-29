//
//  TryOne.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//
import SwiftUI

// MARK: - Network Service
class TryOnService {
    static let shared = TryOnService()
    private let baseURL = "tryon.wha7.com/virtual-tryon"
    
    func performTryOn(clothingImage: Data, userImage: Data) async throws -> Data {
        guard let url = URL(string: "https://\(baseURL)") else {
            throw URLError(.badURL)
        }
        
        // Convert images to base64
        let clothingBase64 = clothingImage.base64EncodedString()
        let userBase64 = userImage.base64EncodedString()
        
        // Prepare request body
        let body: [String: Any] = [
            "clothing_image": clothingBase64,
            "user_image": userBase64
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let tryOnResponse = try JSONDecoder().decode(TryOnResponse.self, from: data)
        guard let resultImageData = Data(base64Encoded: tryOnResponse.resultImage) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return resultImageData
    }
}
