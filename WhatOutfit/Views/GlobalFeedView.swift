import SwiftUI

struct GlobalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.globalOutfits.indices, id: \.self) { index in
                        OutfitCard(outfit: viewModel.globalOutfits[index]) {
                            viewModel.selectedOutfit = viewModel.globalOutfits[index]
                        }
                        .onAppear {
                            if index == viewModel.globalOutfits.count - 1 && !viewModel.isLoading {
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
                if viewModel.globalOutfits.isEmpty {
                    viewModel.loadGlobalOutfits()
                }
            }
        }
    }
}
