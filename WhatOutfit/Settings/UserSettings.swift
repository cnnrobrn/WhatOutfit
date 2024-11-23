//
//  UserSettings.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI

class UserSettings: ObservableObject {
    @Published var phoneNumber: String {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")
        }
    }
    
    init() {
        // Load saved phone number on init, or empty string if none exists
        self.phoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
    }
    
    func clearPhoneNumber() {
        phoneNumber = ""
        UserDefaults.standard.removeObject(forKey: "userPhoneNumber")
    }
    
    func isAuthenticated() -> Bool {
        return !phoneNumber.isEmpty
    }
}
