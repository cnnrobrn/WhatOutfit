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
    @StateObject private var activationManager = ActivationManager()
    @State private var phoneNumber: String = ""
    @EnvironmentObject var userSettings: UserSettings
    @State private var isAuthenticated: Bool = false
    @State private var selectedTab = 0
    
    var body: some View {
        if !isAuthenticated {
            LoginView(phoneNumber: $phoneNumber) { success in
                if success {
                    activationManager.checkActivation(phoneNumber: phoneNumber)
                }
                isAuthenticated = success
            }
        } else if !activationManager.isActivated {
            ActivationView(phoneNumber: phoneNumber)
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
                
                ConsultantView()
                    .tabItem {
                        Label("Consultant", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(2)
                
                UploadView(phoneNumber: phoneNumber)
                    .tabItem {
                        Label("Upload", systemImage: "plus.circle.fill")
                    }
                    .tag(3)
                
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
}

