import SwiftUI

struct PersonalFeedView: View {
    @ObservedObject var viewModel: OutfitViewModel
    @EnvironmentObject var userSettings: UserSettings
    let phoneNumber: String
    
    // Add state for viewport calculation
    @State private var viewportRect: CGRect = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            
            //ScrollingBanner(text: "🎉 Connect your Instagram to send posts directly to the Wha7_Outfit Instagram. Responses are displayed in app! 🎉")
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(viewModel.personalOutfits.enumerated()), id: \.element.id) { index, outfit in
                        OutfitCard(outfit: outfit) {
                            viewModel.selectedOutfit = outfit
                        }
                        .id(outfit.id)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: FramePreferenceKey.self,
                                    value: proxy.frame(in: .named("scrollView"))
                                )
                            }
                        )
                        .onAppear {
                            // Load more content if needed
                            if index == viewModel.personalOutfits.count - 1 && !viewModel.isLoading {
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
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(FramePreferenceKey.self) { frame in
                viewportRect = frame
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
