//
//  UserSettings.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI
import StoreKit

class UserSettings: ObservableObject {
    @Published var phoneNumber: String {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        }
    }
    
    @Published var instagramUsername: String? {
        didSet {
            UserDefaults.standard.set(instagramUsername, forKey: "instagramUsername")
        }
    }
    
    @Published var isPremium: Bool = false {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
    }
    @Published var userBodyImage: Data? {
        didSet {
            UserDefaults.standard.set(userBodyImage, forKey: "userBodyImage")
        }
    }
    
    init() {
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
        self.instagramUsername = UserDefaults.standard.string(forKey: "instagramUsername")
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.userBodyImage = UserDefaults.standard.data(forKey: "userBodyImage")

        
        // Check subscription status on init
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    func clearPhoneNumber() {
        phoneNumber = ""
        instagramUsername = nil
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        UserDefaults.standard.removeObject(forKey: "instagramUsername")
    }
    func clearBodyImage() {
        userBodyImage = nil
        UserDefaults.standard.removeObject(forKey: "userBodyImage")
    }
    
    @MainActor
    func checkSubscriptionStatus() async {
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: "Wha7PremiumOne")
            // Check if any status is active
            let isSubscribed = statuses.contains { status in
                status.state == .subscribed
            }
            self.isPremium = isSubscribed
        } catch {
            print("Error checking subscription status: \(error)")
        }
    }
}
