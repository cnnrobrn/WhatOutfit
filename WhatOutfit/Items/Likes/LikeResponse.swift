import SwiftUI
import Combine
import Foundation

public struct LikedItemsView: View {
    @StateObject private var viewModel = LikedItemsViewModel()
    @EnvironmentObject var userSettings: UserSettings
    let phoneNumber: String
    
    public init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 4), // Minimal space between columns
        GridItem(.flexible(), spacing: 4)
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) { // Minimal space between rows
                    ForEach(Array(viewModel.likedItems.enumerated()), id: \.1.id) { index, item in
                        if let link = item.link {
                            VStack {
                                ProductLinkView(link: link)
                                    .offset(y: CGFloat(index.isMultiple(of: 2) ? 0 : 20)) // Reduced offset for stagger
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1) // Reduced shadow
                            .padding(.horizontal, 2) // Minimal padding around cards
                        }
                    }
                }
                .padding(.vertical, 4) // Minimal vertical padding
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .refreshable {
                await viewModel.refreshItems(phoneNumber: phoneNumber)
            }
            .overlay(
                Group {
                    if !viewModel.isLoading && viewModel.likedItems.isEmpty {
                        VStack(spacing: 12) {
                            Text("Welcome to your liked items")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Like items for them to show up here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                    }
                }
            )
        }
        .onAppear {
            if viewModel.likedItems.isEmpty {
                viewModel.fetchLikedItems(phoneNumber: phoneNumber)
            }
        }
    }
}

// Update the ViewModel to handle task cancellation gracefully
extension LikedItemsViewModel {
    @MainActor
    func refreshItems(phoneNumber: String) async {
        guard !isLoading else { return } // Prevent multiple concurrent refreshes
        
        isLoading = true
        error = nil
        
        do {
            guard let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://like.wha7.com/api/likes/user/\(encodedPhone)") else {
                error = "Invalid URL"
                isLoading = false
                return
            }
            
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Check if task was cancelled
            try Task.checkCancellation()
            
            let likes = try JSONDecoder().decode([LikeResponse].self, from: data)
            self.likedItems = likes
            LikeService.shared.likedItems = Set(likes.map { $0.linkId })
            
        } catch is CancellationError {
            // Ignore cancellation errors silently
            print("Refresh task was cancelled")
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                self.error = "Error: \(error.localizedDescription)"
                print("Error refreshing liked items: \(error)")
            }
        }
        
        isLoading = false
    }
}

// Update the response models to match the API
struct LikeResponse: Codable, Identifiable {
    let id: Int
    let linkId: Int
    let phoneNumber: String
    let createdAt: String
    let link: ProductLink?  // Make this optional
    
    enum CodingKeys: String, CodingKey {
        case id
        case linkId = "link_id"
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
        case link
    }
}

class LikedItemsViewModel: ObservableObject {
    @Published var likedItems: [LikeResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchLikedItems(phoneNumber: String) {
        isLoading = true
        error = nil
        
        guard let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://like.wha7.com/api/likes/user/\(encodedPhone)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { (data: Data, response: URLResponse) -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                // Log response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw API Response: \(jsonString)")
                }
                
                return data
            }
            .decode(type: [LikeResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = "Error: \(error.localizedDescription)"
                        print("Error fetching liked items: \(error)")
                    }
                },
                receiveValue: { [weak self] likes in
                    self?.likedItems = likes
                    // Update LikeService with the liked item IDs
                    LikeService.shared.likedItems = Set(likes.map { $0.linkId })
                }
            )
            .store(in: &cancellables)
    }
}
