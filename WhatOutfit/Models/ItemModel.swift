import Foundation

struct item: Identifiable, Codable, Hashable {
    var id: Int { itemId } // Computed property for Identifiable conformance
    var itemId: Int  // Changed from 'let' to 'var'
    let outfitId: Int
    let description: String
    var links: [ProductLink]?
    let timestamp: Date?
    let searchQuery: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
    }
    
    static func == (lhs: item, rhs: item) -> Bool {
        lhs.itemId == rhs.itemId
    }
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case outfitId = "outfit_id"
        case description
        case links
        case timestamp
        case searchQuery = "search_query"
    }
}
