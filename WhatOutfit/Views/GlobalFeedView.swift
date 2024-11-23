import SwiftUI

struct GlobalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.outfits.indices, id: \.self) { index in
                    OutfitCard(outfit: viewModel.outfits[index]) {
                        viewModel.selectedOutfit = viewModel.outfits[index]
                    }
                    .onAppear {
                        if index == viewModel.outfits.count - 2 && !viewModel.isLoading {
                            viewModel.loadGlobalOutfits(loadMore: true)
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            viewModel.loadGlobalOutfits()
        }
        .onAppear {
            if viewModel.outfits.isEmpty {
                viewModel.loadGlobalOutfits()
            }
        }
    }
}
