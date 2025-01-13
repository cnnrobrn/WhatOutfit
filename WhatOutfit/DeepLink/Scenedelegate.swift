//
//  Scenedelegate.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/11/25.
//


// In your SceneDelegate.swift
import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // Handle Universal Links
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }
        handleIncomingURL(incomingURL)
    }
    
    // Handle Custom URL Schemes (needed for Instagram fallback)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        handleIncomingURL(url)
    }
    
    // Common handling for both Universal Links and URL Schemes
    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path else {
            return
        }

        print("Received URL: \(url)")
        print("Path: \(path)")
        
        // Extract any query parameters
        let queryItems = components.queryItems ?? []
        
        switch path {
        case "/profile":
            let userId = queryItems.first(where: { $0.name == "id" })?.value
            navigateToProfile(userId: userId)
        case "/settings":
            navigateToSettings()
        default:
            navigateToHome()
        }
    }
    
    // Navigation methods - implement these based on your app's structure
    private func navigateToProfile(userId: String?) {
        // Implementation depends on your app's navigation structure
        print("Navigate to profile: \(userId ?? "unknown")")
    }
    
    private func navigateToSettings() {
        print("Navigate to settings")
    }
    
    private func navigateToHome() {
        print("Navigate to home")
    }
}
