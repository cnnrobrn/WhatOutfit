//
//  TryOnError.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/30/24.
//
import SwiftUI

enum TryOnError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case processingFailed
    case networkError(Error)
    case processingTimeout
    case processingIncomplete
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert images to required format"
        case .invalidResponse:
            return "Received invalid response from server"
        case .processingFailed:
            return "Failed to process the try-on request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .processingTimeout:
            return "The try-on process took too long. Please try again"
        case .processingIncomplete:
            return "The image processing is not yet complete"
        }
    }
}
