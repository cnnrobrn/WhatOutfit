//
//  BodyImageView.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//

import SwiftUI

struct BodyImageSetupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Take or Select a Full Body Photo")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("Please wear form-fitting clothing for best results")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let imageData = userSettings.userBodyImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }
            
            Button(action: {
                sourceType = .camera
                showImagePicker = true
            }) {
                Label("Take Photo", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                sourceType = .photoLibrary
                showImagePicker = true
            }) {
                Label("Choose from Library", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    userSettings.userBodyImage = imageData
                }
            }
        }
    }
}
