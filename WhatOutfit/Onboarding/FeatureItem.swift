//
//  FeatureItem.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/10/25.
//


import SwiftUI

struct FeatureItem: Identifiable {
    let id = UUID()
    let imageName: String
}

struct FeatureCarouselView: View {
    let features = [
        FeatureItem(
            imageName: "Image1"
        ),
        FeatureItem(
            imageName: "Image2"
        ),
        FeatureItem(
            imageName: "Image3"
        ),
        FeatureItem(
            imageName: "Image4"
        ),
        FeatureItem(
            imageName: "Image5"
        ),
        FeatureItem(
            imageName: "Image6"
        ),
        FeatureItem(
            imageName: "Image7"
        ),
        FeatureItem(
            imageName: "Image8"
        ),
        FeatureItem(
            imageName: "Image9"
        )
    ]
    
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(features.enumerated()), id: \.1.id) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.black : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: currentIndex)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % features.count
            }
        }
    }
}

struct FeatureCard: View {
    let feature: FeatureItem
    
    var body: some View {
        VStack(spacing: 16) {
            Image(feature.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 4)
            .padding(.horizontal)
        }
        .padding()
    }
}
