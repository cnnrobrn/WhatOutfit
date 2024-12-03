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
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        }
    }
    
    @Published var instagramUsername: String? {
        didSet {
            UserDefaults.standard.set(instagramUsername, forKey: "instagramUsername")
        }
    }
    
    init() {
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
        self.instagramUsername = UserDefaults.standard.string(forKey: "instagramUsername")
    }
    
    func clearPhoneNumber() {
        phoneNumber = ""
        instagramUsername = nil
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        UserDefaults.standard.removeObject(forKey: "instagramUsername")
    }
}
