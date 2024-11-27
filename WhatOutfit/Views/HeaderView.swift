//
//  HeaderView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/25/24.
//
import SwiftUI

// Custom Header Component
struct WhatOutfitHeader: View {
    var title: String = "What Outfit"
    
    var body: some View {
        HStack {
            // Option 1: Image logo
            Image("Logo")  // Add your logo image to assets
                .resizable()
                .scaledToFit()
                .frame(height: 30)
            
            // Option 2: Custom styled text
            // Text(title)
            //     .font(.custom("YourCustomFont", size: 24))  // Use your brand font
            //     .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
