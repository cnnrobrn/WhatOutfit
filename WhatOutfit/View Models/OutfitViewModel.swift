// Import required frameworks
import SwiftUI     // Framework for building user interfaces in Swift
import Combine     // Framework for handling asynchronous events and data streams (similar to Python's asyncio)

// Main view model class for managing outfit data
// ObservableObject is similar to a Python class that can notify observers of changes
class OutfitViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var selectedOutfit: Outfit?
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasMoreContent = true
    
    private var currentPage = 1
    private let itemsPerPage = 10
    private var cancellables = Set<AnyCancellable>()
    
    // Structure to match API response
    private struct OutfitResponse: Codable {
        let outfits: [Outfit]
        let has_more: Bool
    }
    
    func loadGlobalOutfits(loadMore: Bool = false) {
        guard !isLoading else { return }
        
        if loadMore {
            guard hasMoreContent else { return }
        } else {
            currentPage = 1
            outfits = []
        }
        
        isLoading = true
        print("Loading global page \(currentPage)")
        
        // Make sure to use the correct endpoint
        let urlString = "https://access.wha7.com/api/data_all?page=\(currentPage)&per_page=\(itemsPerPage)"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: OutfitResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error loading global outfits: \(error)")
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if loadMore {
                    self.outfits.append(contentsOf: response.outfits)
                } else {
                    self.outfits = response.outfits
                }
                
                self.hasMoreContent = response.has_more
                self.currentPage += 1
                print("Loaded \(response.outfits.count) global outfits, hasMore: \(response.has_more)")
            }
            .store(in: &cancellables)
    }
    
    func loadPersonalOutfits(phoneNumber: String, loadMore: Bool = false) {
        guard !isLoading else { return }
        
        if loadMore {
            guard hasMoreContent else { return }
        } else {
            currentPage = 1
            outfits = []
        }
        
        isLoading = true
        print("Loading personal page \(currentPage)")
        
        guard let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            error = "Invalid phone number encoding"
            isLoading = false
            return
        }
        
        let urlString = "https://access.wha7.com/api/data?phone_number=\(encodedPhone)&page=\(currentPage)&per_page=\(itemsPerPage)"
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: OutfitResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error loading personal outfits: \(error)")
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if loadMore {
                    self.outfits.append(contentsOf: response.outfits)
                } else {
                    self.outfits = response.outfits
                }
                
                self.hasMoreContent = response.has_more
                self.currentPage += 1
                print("Loaded \(response.outfits.count) personal outfits, hasMore: \(response.has_more)")
            }
            .store(in: &cancellables)
    }


    
    // Function to load items for a specific outfit
    func loadOutfitItems(outfitId: Int) {
        guard let url = URL(string: "https://access.wha7.com/api/items?outfit_id=\(outfitId)") else {
            return
        }
        
        print("Loading items for outfit: \(outfitId)")
        
        // Similar pattern to other load functions but updates selectedOutfit
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [item].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error loading items: \(error)")
                }
            } receiveValue: { [weak self] items in
                print("Received items: \(items.count)")
                // Update selected outfit with loaded items
                if let currentOutfit = self?.selectedOutfit {
                    self?.selectedOutfit = Outfit(
                        id: currentOutfit.id,
                        imageData: currentOutfit.imageData,
                        description: currentOutfit.description,
                        items: items
                    )
                }
            }
            .store(in: &cancellables)
    }

}
