//
//  MainView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//
import SwiftUI


struct MainTabView: View {
    @ObservedObject var viewModel: OutfitViewModel
    let phoneNumber: String
    @Binding var selectedTab: Int
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LikedItemsView(phoneNumber: phoneNumber)
                .tabItem {
                    Label("Liked Items", systemImage: "heart.fill")
                }
                .tag(0)
            PersonalFeedView(viewModel: viewModel, phoneNumber: phoneNumber)
                .tabItem {
                    Label("Your Outfits", systemImage: "person.fill")
                }
                .tag(1)
            
            GlobalFeedView(viewModel: viewModel)
                .tabItem {
                    Label("Discover", systemImage: "globe")
                }
                .tag(2)
            
            ConsultantView()
                .tabItem {
                    Label("Consultant", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
            
//            UploadView(phoneNumber: phoneNumber)
//                .tabItem {
//                    Label("Upload", systemImage: "plus.circle.fill")
//                }
//                .tag(3)
            
            SettingsView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .sheet(item: $viewModel.selectedOutfit) { outfit in
            OutfitDetailView(outfit: outfit)
        }
    }
}
