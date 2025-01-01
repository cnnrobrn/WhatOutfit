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
    private let baseURL = "https://tryon.wha7.com/virtual-tryon"
    
    // Configuration constants
    private enum Config {
        static let maxPollingAttempts = 10
        static let pollingInterval: UInt64 = 2_000_000_000  // 2 seconds in nanoseconds
        static let imageCompressionQuality: CGFloat = 0.8
    }
    
    private init() {}
    
    /// Performs a virtual try-on with the provided clothing and user images
    /// - Parameters:
    ///   - clothingImage: The clothing image to try on
    ///   - userImage: The user's body image
    /// - Returns: A UIImage containing the processed try-on result
    /// - Throws: Various errors that might occur during the process
    func performTryOn(clothingImage: UIImage, userImage: UIImage) async throws -> UIImage {
        // Step 1: Convert images to base64
        guard let clothingBase64 = clothingImage.jpegData(compressionQuality: Config.imageCompressionQuality),
              let userBase64 = userImage.jpegData(compressionQuality: Config.imageCompressionQuality) else {
            throw TryOnError.imageConversionFailed
        }
        
        // Step 2: Prepare the request body
        let tryOnRequest = try TryOnRequest(
            humanImage: userBase64,
            clothImage: clothingBase64
        )
        
        // Step 3: Create and configure the URL request
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the request body
        request.httpBody = try JSONEncoder().encode(tryOnRequest)
        
        // Step 4: Make the initial request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Verify we got a valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Step 5: Decode the initial response
        var tryOnResponse = try JSONDecoder().decode(TryOnResponse.self, from: data)
        
        // Step 6: Poll for results if necessary
        var attempts = 0
        
        while tryOnResponse.needsPolling && attempts < Config.maxPollingAttempts {
            // Wait for the polling interval
            try await Task.sleep(nanoseconds: Config.pollingInterval)
            
            // Increment attempt counter
            attempts += 1
            
            // Create status check URL
            let statusURL = URL(string: "\(baseURL)/\(tryOnResponse.id)")!
            
            // Make status check request
            let (statusData, statusResponse) = try await URLSession.shared.data(from: statusURL)
            
            // Verify status response
            guard let httpStatusResponse = statusResponse as? HTTPURLResponse,
                  (200...299).contains(httpStatusResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Update response with latest status
            tryOnResponse = try JSONDecoder().decode(TryOnResponse.self, from: statusData)
            
            // If processing is complete, break the polling loop
            if tryOnResponse.isComplete {
                break
            }
        }
        
        // Step 7: Check if we exceeded polling attempts
        guard attempts < Config.maxPollingAttempts else {
            throw TryOnError.processingIncomplete
        }
        
        // Step 8: Get the final image result
        return try tryOnResponse.getResultImage()
    }
}


extension UIImage {
    /// Converts the image to base64 with an optional compression quality
    /// - Parameter compressionQuality: Quality of the JPEG compression (0.0 to 1.0)
    /// - Returns: Optional base64 encoded string
    func toBase64(compressionQuality: CGFloat = 0.8) -> String? {
        return jpegData(compressionQuality: compressionQuality)?.base64EncodedString()
    }
}
