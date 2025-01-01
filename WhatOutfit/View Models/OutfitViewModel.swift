import SwiftUI
import Combine

class OutfitViewModel: ObservableObject {
    @Published var personalOutfits: [Outfit] = []
    @Published var globalOutfits: [Outfit] = []
    @Published var selectedOutfit: Outfit?
    @Published var isLoading = false
    @Published var error: String?
    @Published var instagramUsername: String? {
        didSet {
            UserDefaults.standard.set(instagramUsername, forKey: "instagramUsername")
        }
    }
    // Separate state for each feed
    private var personalCurrentPage = 1
    private var globalCurrentPage = 1
    private var personalHasMore = true
    private var globalHasMore = true
    private let itemsPerPage = 2
    private var cancellables = Set<AnyCancellable>()
    
    private struct OutfitResponse: Codable {
        let outfits: [Outfit]
        let has_more: Bool
    }
    
    func loadGlobalOutfits(loadMore: Bool = false) {
        guard !isLoading else { return }
        
        if loadMore {
            guard globalHasMore else { return }
        } else {
            globalCurrentPage = 1
            globalOutfits = []
        }
        
        isLoading = true
        print("Loading global page \(globalCurrentPage)")
        
        let urlString = "https://access.wha7.com/api/data_all?page=\(globalCurrentPage)&per_page=\(itemsPerPage)"
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
                    self.globalOutfits.append(contentsOf: response.outfits)
                } else {
                    self.globalOutfits = response.outfits
                }
                
                self.globalHasMore = response.has_more
                self.globalCurrentPage += 1
                print("Loaded \(response.outfits.count) global outfits, hasMore: \(response.has_more)")
            }
            .store(in: &cancellables)
    }
    
    func loadPersonalOutfits(phoneNumber: String, instagramUsername: String? = nil, loadMore: Bool = false) {
        guard !isLoading else { return }
        
        if loadMore {
            guard personalHasMore else { return }
        } else {
            personalCurrentPage = 1
            personalOutfits = []
        }
        
        isLoading = true
        print("Loading personal page \(personalCurrentPage)")
        
        guard let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            error = "Invalid phone number encoding"
            isLoading = false
            return
        }
        
        var urlComponents = URLComponents(string: "https://access.wha7.com/api/data")
        var queryItems = [
            URLQueryItem(name: "phone_number", value: encodedPhone),
            URLQueryItem(name: "page", value: String(personalCurrentPage)),
            URLQueryItem(name: "per_page", value: String(itemsPerPage))
        ]
        
        if let username = instagramUsername {
            queryItems.append(URLQueryItem(name: "instagram_username", value: username))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
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
                    self.personalOutfits.append(contentsOf: response.outfits)
                } else {
                    self.personalOutfits = response.outfits
                }
                
                self.personalHasMore = response.has_more
                self.personalCurrentPage += 1
                print("Loaded \(response.outfits.count) personal outfits, hasMore: \(response.has_more)")
            }
            .store(in: &cancellables)
    }
    
    func loadOutfitItems(outfitId: Int) {
        guard let url = URL(string: "https://access.wha7.com/api/items?outfit_id=\(outfitId)") else {
            return
        }
        
        print("Loading items for outfit: \(outfitId)")
        
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
