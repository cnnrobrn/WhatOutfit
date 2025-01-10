//
//  Onboarding.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//

import SwiftUI

class OnboardingState: ObservableObject {
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
}
