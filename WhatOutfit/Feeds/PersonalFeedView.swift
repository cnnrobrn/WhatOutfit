import SwiftUI

struct PersonalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    @EnvironmentObject var userSettings: UserSettings
    let phoneNumber: String
    
    // Track scroll position
    @State private var isNearBottom = false
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.personalOutfits.enumerated()), id: \.element.id) { index, outfit in
                        OutfitCard(outfit: outfit) {
                            viewModel.selectedOutfit = outfit
                        }
                        .id(outfit.id)
                        .onAppear {
                            // Check if we're within the last item
                            if index <= viewModel.personalOutfits.count - 2 {
                                // Trigger load more when last item appears
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

// Preference key for tracking frame positions
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Add extension to help with scroll position tracking
extension View {
    func readSize(onChange: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.frame(in: .named("scroll")))
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}
