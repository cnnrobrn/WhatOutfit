//
//  LoginView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI


struct LoginView: View {
    @Binding var phoneNumber: String
    let onComplete: (Bool) -> Void
    @State private var showError = false
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What Outfit")
                .font(.largeTitle)
                .fontWeight(.light)
            
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
                .padding()
            
            Button("Continue") {
                validateAndLogin()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .alert("Invalid Phone Number", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            // Check if we have a stored phone number
            if userSettings.isAuthenticated() {
                phoneNumber = userSettings.phoneNumber
                onComplete(true)
            }
        }
    }
    
    private func validateAndLogin() {
        // Basic validation
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            userSettings.phoneNumber = phoneNumber
            onComplete(true)
        } else {
            showError = true
        }
    }
}
