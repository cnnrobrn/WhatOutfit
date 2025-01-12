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
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 40) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                // Phone Input Section
                VStack(spacing: 8) {
                    TextField("Phone Number", text: $phoneNumber)
                        .font(.system(size: 17))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .keyboardType(.phonePad)
                    
//                    Text("We'll send you a verification code")
//                        .font(.caption)
//                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: validateAndLogin) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .alert("Invalid Phone Number", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a valid 10-digit phone number")
        }
        .onAppear {
            if !userSettings.phoneNumber.isEmpty {
                phoneNumber = userSettings.phoneNumber
                onComplete(true)
            }
        }
    }
    
    private func validateAndLogin() {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            userSettings.phoneNumber = phoneNumber
            onComplete(true)
        } else {
            showError = true
        }
    }
}
