import Foundation
import SwiftUI

// MARK: - Error Types
enum ImageConversionError: Error {
    case conversionFailed
    case invalidImageData
    case encodingFailed
}

// MARK: - Image Converter
class ImageConverter {
    // This method takes raw image data and converts it to a base64 string
    // We don't need an optional return since we'll use throw for error handling
    static func convertToBase64(imageData: Data) throws -> String {
        // Direct conversion to base64 string - no need for guard since base64EncodedString()
        // is non-optional in Swift
        let base64String = imageData.base64EncodedString()
        
        // Create the complete data URI with proper MIME type prefix
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    // Main processing method that handles both images at once
    static func processImages(humanImage: Data, clothImage: Data) throws -> (human: String, cloth: String) {
        // Process each image independently so we can identify which one failed if needed
        do {
            let humanBase64 = try convertToBase64(imageData: humanImage)
            let clothBase64 = try convertToBase64(imageData: clothImage)
            
            return (humanBase64, clothBase64)
        } catch {
            // Rethrow the error with more context if needed
            throw ImageConversionError.conversionFailed
        }
    }
}

// MARK: - API Models
struct TryOnRequest: Codable {
    // Properties use snake_case to match backend API expectations
    let human_image: String
    let clothing_image: String
    
    // Initializer that handles the conversion process
    init(humanImage: Data, clothImage: Data) throws {
        do {
            // Use our ImageConverter to process both images
            let (humanBase64, clothBase64) = try ImageConverter.processImages(
                humanImage: humanImage,
                clothImage: clothImage
            )
            
            // Set the properties with the converted values
            self.human_image = humanBase64
            self.clothing_image = clothBase64
        } catch {
            // Convert any underlying errors to our domain-specific error
            throw ImageConversionError.conversionFailed
        }
    }
}


struct TryOnResponse: Codable {
    /// Unique identifier for the try-on request
    let id: String
    
    /// Request identifier for tracking the processing status
    let request_id: String
    
    /// Current status of the try-on request (e.g., "processing", "completed")
    let status: String
    
    /// Optional URL for the result (deprecated - kept for backwards compatibility)
    let result_url: String?
    
    /// Base64 encoded image data of the processed try-on result
    let base64_image: String?
    
    /// Converts the base64 image data to a UIImage if processing is complete
    /// - Returns: A UIImage created from the base64 image data
    /// - Throws: TryOnError if conversion fails or processing is incomplete
    func getResultImage() throws -> UIImage {
        // First check if processing is complete
        guard status == "completed" else {
            throw TryOnError.processingIncomplete
        }
        
        // Check for base64 image data
        guard let base64Data = base64_image else {
            // Fallback to result_url if base64_image is not available
            guard let resultURL = result_url,
                  resultURL.hasPrefix("data:image/jpeg;base64,") else {
                throw TryOnError.invalidResponse
            }
            
            let base64String = String(resultURL.dropFirst("data:image/jpeg;base64,".count))
            guard let imageData = Data(base64Encoded: base64String),
                  let image = UIImage(data: imageData) else {
                throw TryOnError.imageConversionFailed
            }
            return image
        }
        
        // Handle base64_image data
        // Check if the string already includes the data URL prefix
        let base64String: String
        if base64Data.hasPrefix("data:image/jpeg;base64,") {
            base64String = String(base64Data.dropFirst("data:image/jpeg;base64,".count))
        } else {
            base64String = base64Data
        }
        
        // Convert base64 string to image data
        guard let imageData = Data(base64Encoded: base64String),
              let image = UIImage(data: imageData) else {
            throw TryOnError.imageConversionFailed
        }
        
        return image
    }
    
    /// Checks if the try-on processing is complete
    var isComplete: Bool {
        return status == "completed" && (base64_image != nil || result_url != nil)
    }
    
    /// Checks if the response needs to be polled again
    var needsPolling: Bool {
        return status == "processing"
    }
}

// MARK: - Usage Example
extension TryOnResponse {
    static func processResponse(_ response: TryOnResponse) async throws -> UIImage {
        // If processing is complete, convert and return the image
        if response.isComplete {
            return try response.getResultImage()
        }
        
        // If still processing, throw an error that can be handled by the caller
        if response.needsPolling {
            throw TryOnError.processingIncomplete
        }
        
        // If neither complete nor processing, something went wrong
        throw TryOnError.invalidResponse
    }
}
