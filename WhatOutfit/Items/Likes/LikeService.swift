// LikeService.swift
import Foundation
import Combine

struct LikeRequest: Codable {
    let id: Int
    let phoneNumber: String
    enum CodingKeys: String, CodingKey {
        case id = "link_id"  // Keep the API expect link_id
        case phoneNumber = "phone_number"
    }
}

class LikeService: ObservableObject {
    static let shared = LikeService()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var likedItems: Set<Int> = []
    @Published var error: String?
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        return !phoneNumber.isEmpty
    }
    
    func likeItem(itemId: Int, phoneNumber: String) {
        guard isValidPhoneNumber(phoneNumber) else {
            error = "Please log in to like items"
            print("Invalid phone number") // Add logging
            return
        }
        
        guard let url = URL(string: "https://like.wha7.com/api/likes") else {
            print("Invalid URL") // Add logging
            return
        }
        
        let request = LikeRequest(id: itemId, phoneNumber: phoneNumber)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encodedData = try JSONEncoder().encode(request)
            urlRequest.httpBody = encodedData
            print("Request body: \(String(data: encodedData, encoding: .utf8) ?? "")") // Add logging
        } catch {
            self.error = "Failed to encode request: \(error.localizedDescription)"
            print("Encoding error: \(error)") // Add logging
            return
        }
        
        print("Sending request to: \(url.absoluteString)") // Add logging
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in // Add weak self
                    switch completion {
                    case .finished:
                        print("Request completed successfully") // Add logging
                        self?.likedItems.insert(itemId)
                    case .failure(let error):
                        print("Network error: \(error)") // Add logging
                        self?.error = "Failed to like item: \(error.localizedDescription)"
                    }
                },
                receiveValue: { data in
                    // Add response logging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func unlikeItem(itemId: Int, phoneNumber: String) {
        print("Starting unlikeItem operation for itemId: \(itemId)")
        
        guard isValidPhoneNumber(phoneNumber) else {
            let errorMessage = "Please log in to unlike items"
            print("Authentication error: Invalid phone number format")
            error = errorMessage
            return
        }
        
        // Encode the phone number for URL safety
        guard let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://like.wha7.com/api/likes/\(itemId)?phone_number=\(encodedPhone)") else {
            let errorMessage = "Failed to construct URL for unlike operation"
            print("URL Construction Error: \(errorMessage)")
            error = errorMessage
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        print("Initiating network request to unlike itemId: \(itemId)")
        URLSession.shared.dataTaskPublisher(for: urlRequest)
        
        print("Initiating network request to unlike itemId: \(itemId)")
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Successfully unliked itemId: \(itemId)")
                        self.likedItems.remove(itemId)
                        
                    case .failure(let error):
                        let errorMessage = "Failed to unlike item: \(error.localizedDescription)"
                        print("Network Error: \(errorMessage)")
                        print("Detailed network error: \(error)")
                        
                        self.error = errorMessage
                    }
                },
                receiveValue: { data in
                    // Log response data length for debugging
                    print("Received response data of length: \(data.count) bytes")
                }
            )
            .store(in: &cancellables)
    }
}
