import SwiftUI
import PhotosUI
import Foundation

struct ConsultantResponse: Codable {
    let response: String
    let recommendations: [Recommendation]
}

struct Recommendation: Codable {
    let Item: String
    let Amazon_Search: String
    let Recommendation_ID: Int
    
    enum CodingKeys: String, CodingKey {
        case Item
        case Amazon_Search
        case Recommendation_ID
    }
}

private struct RAGResponse: Codable {
    let item_id: Int
}

class ConsultantViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage: String = ""
    @Published var isLoading = false
    @Published var selectedImage: UIImage?
    @Published var isActivated: Bool = false
    @Published var showingActivationAlert: Bool = false

    private let apiUrl = "https://app.wha7.com/ios/consultant"
    
    init() {
        messages.append(Message(
            content: "Hello! I'm your fashion consultant. You can ask me questions about outfits or upload images for style advice.",
            isUser: false
        ))
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            print("Error: \(message)")
            self?.isLoading = false
            self?.messages.append(Message(
                content: "Sorry, there was an error processing your request. Please try again.",
                isUser: false
            ))
        }
    }
    
    func checkActivation(phoneNumber: String) {
        // Call your backend to check activation status
        guard let url = URL(string: "https://access.wha7.com/api/user/status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": phoneNumber]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode([String: Bool].self, from: data) {
                    self?.isActivated = response["is_activated"] ?? false
                    if !self!.isActivated {
                        self?.showingActivationAlert = true
                    }
                }
            }
        }.resume()
    }
    
    private func processRecommendations(_ recommendations: [Recommendation], query: String) -> [item] {
        print("Processing recommendations for query: \(query)")
        
        let items = recommendations.enumerated().map { index, recommendation -> item in
            print("Processing recommendation: \(recommendation.Item)")
            
            return item(
                itemId: recommendation.Recommendation_ID,
                outfitId: index + 1,
                description: recommendation.Item,
                links: nil,
                timestamp: Date(),
                searchQuery: recommendation.Amazon_Search
            )
        }
        print("Processed \(items.count) recommendations")
        return items
    }
    
    private func fetchLinksForItem(_ item: item, completion: @escaping (item?) -> Void) {
        // First use RAG search to get the proper item ID
        let ragBody: [String: Any] = [
            "item_description": item.searchQuery ?? item.description
        ]
        
        guard let ragUrl = URL(string: "https://access.wha7.com/rag_search") else {
            handleError("Invalid RAG URL")
            completion(nil)
            return
        }
        
        var ragRequest = URLRequest(url: ragUrl)
        ragRequest.httpMethod = "POST"
        ragRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            ragRequest.httpBody = try JSONSerialization.data(withJSONObject: ragBody)
        } catch {
            handleError("Failed to serialize RAG request: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: ragRequest) { [weak self] data, response, error in
            if let error = error {
                self?.handleError("RAG search error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                self?.handleError("No data received from RAG search")
                completion(nil)
                return
            }
            
            do {
                let ragResponse = try JSONDecoder().decode(RAGResponse.self, from: data)
                
                guard let linksUrl = URL(string: "https://access.wha7.com/api/links?item_id=\(ragResponse.item_id)") else {
                    self?.handleError("Invalid links URL")
                    completion(nil)
                    return
                }
                
                print("Fetching links for item \(ragResponse.item_id)")
                
                URLSession.shared.dataTask(with: linksUrl) { linkData, linkResponse, linkError in
                    if let linkError = linkError {
                        self?.handleError("Link fetch error: \(linkError.localizedDescription)")
                        completion(nil)
                        return
                    }
                    
                    guard let linkData = linkData else {
                        self?.handleError("No link data received")
                        completion(nil)
                        return
                    }
                    
                    do {
                        let links = try JSONDecoder().decode([ProductLink].self, from: linkData)
                        print("Successfully decoded \(links.count) links")
                        var updatedItem = item
                        updatedItem.links = links
                        completion(updatedItem)
                    } catch {
                        self?.handleError("Link decode error: \(error.localizedDescription)")
                        completion(nil)
                    }
                }.resume()
                
            } catch {
                self?.handleError("RAG response decode error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
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
            handleError("Failed to serialize request body: \(error.localizedDescription)")
            return
        }
        
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
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw API Response:")
                    print(responseString)
                }
                
                do {
                    let decoder = JSONDecoder()
                    let consultantResponse = try decoder.decode(ConsultantResponse.self, from: data)
                    
                    // Process recommendations
                    let items = self?.processRecommendations(consultantResponse.recommendations, query: content) ?? []
                    
                    // Create initial message
                    let responseMessage = Message(
                        content: consultantResponse.response,
                        isUser: false,
                        recommendations: items
                    )
                    self?.messages.append(responseMessage)
                    
                    // Fetch links for each item
                    let linkGroup = DispatchGroup()
                    var updatedItems = items
                    
                    for index in items.indices {
                        linkGroup.enter()
                        self?.fetchLinksForItem(items[index]) { updatedItem in
                            if let updatedItem = updatedItem {
                                DispatchQueue.main.async {
                                    updatedItems[index] = updatedItem
                                }
                            }
                            linkGroup.leave()
                        }
                    }
                    
                    linkGroup.notify(queue: .main) {
                        if let lastIndex = self?.messages.count.advanced(by: -1) {
                            let updatedMessage = Message(
                                content: consultantResponse.response,
                                isUser: false,
                                recommendations: updatedItems
                            )
                            self?.messages[lastIndex] = updatedMessage
                            
                            print("=== Final Message Update ===")
                            updatedItems.forEach { item in
                                print("Item: \(item.description)")
                                print("Links count: \(item.links?.count ?? 0)")
                            }
                            print("==========================")
                        }
                    }
                } catch {
                    self?.handleError("Failed to parse response: \(error.localizedDescription)")
                    print("Parsing error: \(error)")
                }
            }
        }
        
        task.resume()
    }
}
