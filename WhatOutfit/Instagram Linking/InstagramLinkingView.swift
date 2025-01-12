//
//  InstagramLinkingView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 12/1/24.
//
import SwiftUI

struct InstagramLinkingSection: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var isLinking = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showUsernameInput = false
    @State private var instagramUsername = ""
    
    var body: some View {
        Section(header: Text("Social Accounts")) {
            // Show current username if exists
            if let username = userSettings.instagramUsername {
                HStack {
                    Text("Instagram")
                    Spacer()
                    Text("@\(username)")
                        .foregroundColor(.gray)
                }
                
                // Add edit button
                Button(action: {
                    instagramUsername = username
                    showUsernameInput = true
                }) {
                    HStack {
                        Text("Edit Instagram Username")
                        Spacer()
                        Image(systemName: "pencil")
                    }
                }
                
                Button(action: unlinkInstagram) {
                    HStack {
                        Text("Unlink Instagram")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            } else {
                Button(action: { showUsernameInput = true }) {
                    HStack {
                        Text("Link Instagram Account")
                        Spacer()
                        Image(systemName: "link")
                    }
                }
            }
        }
        .alert("Instagram Integration", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showUsernameInput) {
            NavigationView {
                Form {
                    Section(header: Text("Enter Instagram Username")) {
                        TextField("Username (without @)", text: $instagramUsername)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                    }
                    
                    Section(footer: Text("Enter your Instagram username without the @ symbol")) {
                        // Preview how it will look
                        HStack {
                            Text("Will appear as:")
                            Spacer()
                            Text("@\(instagramUsername)")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("Link Instagram")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showUsernameInput = false
                        instagramUsername = ""
                    },
                    trailing: Button("Save") {
                        linkInstagram(username: instagramUsername)
                        showUsernameInput = false
                    }
                    .disabled(instagramUsername.isEmpty || isLinking)
                )
            }
        }
    }    
    private func linkInstagram(username: String) {
        isLinking = true
        guard let url = URL(string: "https://access.wha7.com/api/instagram/link") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "phone_number": userSettings.phoneNumber,
            "instagram_username": username
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLinking = false
                
                if let error = error {
                    alertMessage = "Failed to link Instagram: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    userSettings.instagramUsername = username
                    alertMessage = "Successfully linked to @\(username)"
                } else {
                    alertMessage = "Failed to link Instagram account"
                }
                showAlert = true
                instagramUsername = ""
            }
        }.resume()
    }
    
    private func unlinkInstagram() {
        guard let url = URL(string: "https://access.wha7.com/api/instagram/unlink") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": userSettings.phoneNumber]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if error == nil {
                    userSettings.instagramUsername = nil
                    alertMessage = "Instagram account unlinked"
                } else {
                    alertMessage = "Failed to unlink Instagram account"
                }
                showAlert = true
            }
        }.resume()
    }
}

struct InstagramLinkResponse: Codable {
    let username: String
}
