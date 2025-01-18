//
//  BodyImageView.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//

import SwiftUI
import AVFoundation

struct BodyImageSetupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            activateCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        activateCamera()
                    }
                } else {
                    showCameraPermissionAlert()
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            showCameraPermissionAlert()
        }
    }
    
    private func activateCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sourceType = .camera
            showImagePicker = true
        } else {
            alertMessage = "Camera is not available on this device."
            showCameraAlert = true
        }
    }
    
    private func showCameraPermissionAlert() {
        alertMessage = "Please enable camera access in Settings to take photos."
        showCameraAlert = true
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 12) {
                    Text("Take or Select a Full Body Photo")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    Text("Wear form fitting clothing against a plain background for the fastest results during try-ons")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
                Spacer()
                
                // Image Preview
                if let imageData = userSettings.userBodyImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.1))
                                .blur(radius: 8)
                                .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 4)
                        .padding()
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: openCamera) {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        Label("Choose from Library", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType) { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    userSettings.userBodyImage = imageData
                }
            }
        }
        .alert(isPresented: $showCameraAlert) {
            Alert(
                title: Text("Camera Access"),
                message: Text(alertMessage),
                primaryButton: .default(Text("Settings")) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
