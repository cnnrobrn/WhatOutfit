// LazyImageView.swift
import SwiftUI

// Updated PersonalFeedView.swift
struct PersonalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    let phoneNumber: String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.outfits.indices, id: \.self) { index in
                    OutfitCard(outfit: viewModel.outfits[index]) {
                        viewModel.selectedOutfit = viewModel.outfits[index]
                    }
                    .onAppear {
                        if index == viewModel.outfits.count - 2 && !viewModel.isLoading {
                            viewModel.loadPersonalOutfits(phoneNumber: phoneNumber, loadMore: true)
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
            viewModel.loadPersonalOutfits(phoneNumber: phoneNumber)
        }
        .onAppear {
            if viewModel.outfits.isEmpty {
                viewModel.loadPersonalOutfits(phoneNumber: phoneNumber)
            }
        }
    }
}
