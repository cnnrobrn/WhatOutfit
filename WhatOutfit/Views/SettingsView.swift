//
//  SettingsView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            NavigationView {
                List {
                    Section(header: Text("Account Information")) {
                        HStack {
                            Text("Phone Number")
                            Spacer()
                            Text(userSettings.phoneNumber)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            userSettings.clearPhoneNumber()
                            isAuthenticated = false
                        }) {
                            HStack {
                                Text("Log Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }
}
// In SettingsView.swift
struct ReferFriendView: View {
    @State private var referralCode: String?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    let phoneNumber: String
    
    var body: some View {
        VStack(spacing: 20) {
            if let code = referralCode {
                Text("Your Referral Code")
                    .font(.headline)
                
                Text(code)
                    .font(.system(.title, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button("Share Code") {
                    showShareSheet = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: generateCode) {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate Referral Code")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
        }
        .padding()
        .sheet(isPresented: $showShareSheet) {
            if let code = referralCode {
                ShareSheet(items: ["Join me on WhatOutfit! Use my referral code: \(code)"])
            }
        }
        .task {
            // Check if user already has a code
            await checkExistingCode()
        }
    }
    
    private func generateCode() {
        isGenerating = true
        
        guard let url = URL(string: "https://access.wha7.com/api/referral/generate") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": phoneNumber]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isGenerating = false
                
                if let data = data,
                   let response = try? JSONDecoder().decode(ReferralResponse.self, from: data) {
                    referralCode = response.code
                }
            }
        }.resume()
    }
    
    private func checkExistingCode() async {
        // Add endpoint to check for existing code
        guard let url = URL(string: "https://access.wha7.com/api/referral/check") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": phoneNumber]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(ReferralResponse.self, from: data) {
                referralCode = response.code
            }
        } catch {
            print("Error checking existing code: \(error)")
        }
    }
}

struct ReferralResponse: Codable {
    let code: String
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
