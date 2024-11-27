import SwiftUI
import PhotosUI

// Define the response structure to match your JSON format
struct ConsultantResponse: Codable {
    let response: String
    let recommendations: [Recommendation]
}

struct Recommendation: Codable {
    let Item: String
    let Amazon_Search: String
    let Recommendation_ID: String
}

class ConsultantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage: String = ""
    @Published var isLoading = false
    @Published var selectedImage: UIImage?
    
    private let apiUrl = "https://app.wha7.com/ios/consultant"
    
    init() {
        messages.append(Message(
            content: "Hello! I'm your fashion consultant. You can ask me questions about outfits or upload images for style advice.",
            isUser: false
        ))
    }
    
    func sendMessage(_ content: String, image: UIImage? = nil) {
        let userMessage = Message(content: content, isUser: true, image: image)
        messages.append(userMessage)
        isLoading = true
        
        // Convert image to base64 if present
        var imageContent: String? = nil
        if let image = image {
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                imageContent = imageData.base64EncodedString()
            }
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "image_content": imageContent ?? "",
            "text": content,
            "from_number": UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
        ]
        
        // Create URL request
        guard let url = URL(string: apiUrl) else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            handleError("Failed to serialize request body")
            return
        }
        
        // Make API call
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.handleError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                do {
                    // Decode the response using the ConsultantResponse struct
                    let decoder = JSONDecoder()
                    let consultantResponse = try decoder.decode(ConsultantResponse.self, from: data)
                    
                    // Convert recommendations to items
                    let items = consultantResponse.recommendations.map { recommendation -> item in
                        return item(
                            itemId: Int(recommendation.Recommendation_ID) ?? 0,
                            outfitId: 0, // This will be set by the backend
                            description: recommendation.Item,
                            links: nil, // Links will be loaded separately
                            timestamp: Date()
                        )
                    }
                    
                    // Add the response message with recommendations
                    self?.messages.append(Message(
                        content: consultantResponse.response,
                        isUser: false,
                        recommendations: items
                    ))
                    
                } catch {
                    self?.handleError("Failed to parse response: \(error.localizedDescription)")
                    print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                }
            }
        }
        
        task.resume()
    }
    
    private func handleError(_ message: String) {
        print("Error: \(message)")
        messages.append(Message(
            content: "Sorry, there was an error processing your request. Please try again.",
            isUser: false
        ))
        isLoading = false
    }
}
