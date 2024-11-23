//
//  ContentView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/23/24.
//
import SwiftUI

// Update ContentView to pass phone number
struct ContentView: View {
    @StateObject private var viewModel = OutfitViewModel()
    @State private var phoneNumber: String = ""
    @EnvironmentObject var userSettings: UserSettings
    @State private var isAuthenticated: Bool = false
    @State private var selectedTab = 0
    
    var body: some View {
        if !isAuthenticated {
            LoginView(phoneNumber: $phoneNumber) { success in
                isAuthenticated = success
            }
        } else {
            TabView(selection: $selectedTab) {
                PersonalFeedView(viewModel: viewModel, phoneNumber: phoneNumber)
                    .tabItem {
                        Label("Your Outfits", systemImage: "person.fill")
                    }
                    .tag(0)
                
                GlobalFeedView(viewModel: viewModel)
                    .tabItem {
                        Label("Discover", systemImage: "globe")
                    }
                    .tag(1)
                
                UploadView(phoneNumber: phoneNumber)  // Pass phone number here
                    .tabItem {
                        Label("Upload", systemImage: "plus.circle.fill")
                    }
                    .tag(2)
                
                SettingsView(isAuthenticated: $isAuthenticated)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .sheet(item: $viewModel.selectedOutfit) { outfit in
                OutfitDetailView(outfit: outfit)
            }
        }
    }
}
