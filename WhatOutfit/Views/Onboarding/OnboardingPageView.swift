//
//  OnboardingPageView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//

import SwiftUI
import StoreKit

import SwiftUI
import StoreKit

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            if page.hasPhotoUpload {
                BodyImageSetupView()
            } else if page.hasInstagramLink {
                InstagramLinkingSection()
            } else {
                GIFImage(name: page.gifName)
                    .frame(height: 200)
            }
            
            Text(page.title)
                .font(.title)
                .bold()
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

