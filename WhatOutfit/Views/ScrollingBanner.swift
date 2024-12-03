//
//  ScrollingBanner.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 12/2/24.
//

import SwiftUI

struct ScrollingBanner: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            
            HStack(spacing: 50) {
                ForEach(0..<3) { _ in
                    Text(text)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .offset(x: offset)
            .background(
                GeometryReader { textGeometry in
                    Color.clear.onAppear {
                        textWidth = (textGeometry.size.width - 100) / 3 // Account for spacing
                        // Start the offset at 0
                        offset = 0
                        // Start the animation
                        animate()
                    }
                }
            )
            .frame(maxHeight: .infinity)
        }
        .frame(height: 40)
        .background(Color.red)
        .clipped()
    }
    
    private func animate() {
        withAnimation(.linear(duration: Double(textWidth) / 75).repeatForever(autoreverses: false)) {
            // Move by one text width
            offset = -textWidth
        }
    }
}

// Preview provider for testing
struct ScrollingBanner_Previews: PreviewProvider {
    static var previews: some View {
        ScrollingBanner(text: "🎉 New Feature: AI Outfit Consultant now available! Try it out in the Consultant tab. More exciting updates coming soon!")
    }
}
