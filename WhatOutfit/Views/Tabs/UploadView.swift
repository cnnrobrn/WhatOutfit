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
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @StateObject private var uploadManager = UploadManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            //ScrollingBanner(text: "🎉 Connect your Instagram to send posts directly to the Wha7_Outfit Instagram. Responses are displayed in app! 🎉")
            NavigationView {
                VStack {
                    PhotosPicker(selection: $selectedItems,
                               matching: .images,
                               photoLibrary: .shared()) {
                        VStack(spacing: 16) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 72, height: 72)
                                .foregroundColor(.blue)
                            
                            Text("Upload Photos")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Select multiple outfits to analyze\nUploads will continue in the background")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                                .background(Color(.systemBackground))
                        )
                        .padding()
                    }
                    
                    if !uploadManager.uploadStatuses.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(uploadManager.uploadStatuses.sorted(by: { $0.orderNumber < $1.orderNumber })) { status in
                                HStack {
                                    if status.isComplete {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        ProgressView()
                                            .frame(width: 16, height: 16)
                                    }
                                    Text("Image \(status.orderNumber)")
                                        .foregroundColor(status.isComplete ? .secondary : .primary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .navigationTitle("Upload Outfits")
                .onChange(of: selectedItems) { _, items in
                    Task {
                        // Clear previous uploads if any
                        uploadManager.uploadStatuses.removeAll()
                        uploadManager.successCount = 0
                        
                        // Create new upload statuses with order numbers
                        for (index, item) in items.enumerated() {
                            let status = UploadStatus(
                                id: UUID(),
                                item: item,
                                orderNumber: index + 1
                            )
                            await MainActor.run {
                                uploadManager.uploadStatuses.append(status)
                            }
                            await uploadManager.uploadImage(status: status, phoneNumber: phoneNumber)
                        }
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
                    Text("Your outfits have been uploaded successfully. Please navigate to the \"Your Outfits\" tab and refresh.")
                }
            }
        }
    }
}
