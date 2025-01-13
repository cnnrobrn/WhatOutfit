import SwiftUI

struct PersonalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    @EnvironmentObject var userSettings: UserSettings
    let phoneNumber: String
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.personalOutfits.indices, id: \.self) { index in
                        OutfitCard(outfit: viewModel.personalOutfits[index]) {
                            viewModel.selectedOutfit = viewModel.personalOutfits[index]
                        }
                        .onAppear {
                            // Load more when we're 2 items away from the end
                            if index == viewModel.personalOutfits.count - 2 && !viewModel.isLoading {
                                viewModel.loadPersonalOutfits(
                                    phoneNumber: phoneNumber,
                                    instagramUsername: userSettings.instagramUsername,
                                    loadMore: true
                                )
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
                // Reset and reload from start on pull-to-refresh
                viewModel.loadPersonalOutfits(
                    phoneNumber: phoneNumber,
                    instagramUsername: userSettings.instagramUsername
                )
            }
            .onAppear {
                if viewModel.personalOutfits.isEmpty {
                    viewModel.loadPersonalOutfits(
                        phoneNumber: phoneNumber,
                        instagramUsername: userSettings.instagramUsername
                    )
                }
            }
        }
    }
}
