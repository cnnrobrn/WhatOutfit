//
//  UploadView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

// UploadView.swift
import SwiftUI
import PhotosUI

struct UploadView: View {
    let phoneNumber: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false  // New state for success alert
    
    
    private func uploadImage(_ item: PhotosPickerItem) {
        isUploading = true
        print("Starting upload process...")
        
        Task {
            do {
                // Load image data
                print("Loading image data...")
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    print("Failed to load image data")
                    throw URLError(.badServerResponse)
                }
                print("Image data loaded successfully, size: \(data.count) bytes")
                
                // Create request
                let urlString = "https://app.wha7.com/ios"
                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Create base64 string with prefix
                let base64String = data.base64EncodedString()
                
                // Create request body
                let bodyData: [String: String] = [
                    "image_content": base64String,
                    "from_number": phoneNumber
                ]
                
                // Convert to JSON data
                let jsonData = try JSONSerialization.data(withJSONObject: bodyData)
                request.httpBody = jsonData
                
                print("Sending request to: \(urlString)")
                print("With phone number: \(phoneNumber)")
                
                let (responseData, response) = try await URLSession.shared.data(for: request)
                
                // Debug response
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("Upload successful")
                    await MainActor.run {
                        isUploading = false
                        selectedItem = nil
                        showingSuccess = true  // Show success alert
                    }
                } else {
                    print("Server returned error status: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
            } catch {
                print("Upload failed with error: \(error)")
                print("Error description: \(error.localizedDescription)")
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            NavigationView {
                VStack {
                    if isUploading {
                        ProgressView("Analyzing image...")
                    } else {
                        PhotosPicker(selection: $selectedItem,
                                     matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 64, height: 64)
                                    .foregroundColor(.blue)
                                
                                Text("Upload Photo")
                                    .font(.headline)
                                
                                Text("Share an outfit you'd like analyzed")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding()
                        }
                    }
                }
                .navigationTitle("Upload Outfit")
                .onChange(of: selectedItem) { _, item in
                    if let item = item {
                        uploadImage(item)
                    }
                }
                .alert("Upload Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .alert("Upload Successful", isPresented: $showingSuccess) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your item has been uploaded successfully. Please navigate to the \"Your Outfits\" tab and refresh.")
                }
            }
        }
    }
}
