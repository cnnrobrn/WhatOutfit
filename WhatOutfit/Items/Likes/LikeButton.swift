import SwiftUI

struct LikeButton: View {
    let link: ProductLink
    let userSettings: UserSettings
    @StateObject private var likeService = LikeService.shared
    
    var body: some View {
        Button(action: {
            if LikeService.shared.likedItems.contains(link.id) {
                LikeService.shared.unlikeItem(itemId: link.id, phoneNumber: userSettings.phoneNumber)
            } else {
                LikeService.shared.likeItem(itemId: link.id, phoneNumber: userSettings.phoneNumber)
            }
        }) {
            Image(systemName: LikeService.shared.likedItems.contains(link.id) ? "heart.fill" : "heart")
                .foregroundColor(LikeService.shared.likedItems.contains(link.id) ? .red : .white)
                .padding(8)
                .background(Color.black.opacity(0.75))
                .clipShape(Circle())
        }
        .padding(8)
    }
}