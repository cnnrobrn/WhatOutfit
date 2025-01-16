//
//  BodyImage.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/28/24.
//

import SwiftUI

struct BodyImageSettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section(header: Text("Body Image")) {
                if let imageData = userSettings.userBodyImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                NavigationLink("Update Body Image") {
                    BodyImageSetupView()
                }
                
                Button("Reset Body Image", role: .destructive) {
                    userSettings.clearBodyImage()
                }
            }
        }
    }
}
