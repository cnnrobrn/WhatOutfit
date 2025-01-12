//
//  DirectInstagramLinkView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//
import SwiftUI

struct DirectInstagramLinkView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userSettings: UserSettings
    @State private var instagramUsername = ""
    @State private var isLinking = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ENTER INSTAGRAM USERNAME")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                TextField("Username (without @)", text: $instagramUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.asciiCapable)
                    .padding(.horizontal)
                
                HStack {
                    Text("Will appear as:")
                    Text("@\(instagramUsername)")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Text("Enter your Instagram username without the @ symbol")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Link Instagram")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    linkInstagram(username: instagramUsername)
                }
                .disabled(instagramUsername.isEmpty || isLinking)
            )
        }
        .alert("Instagram Integration", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if userSettings.instagramUsername != nil {
                    dismiss()
                    onComplete()
                }
            }
        } message: {
            Text(alertMessage)
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
}
