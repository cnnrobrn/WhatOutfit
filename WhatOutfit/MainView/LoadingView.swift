//
//  LoadingView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/11/25.
//
import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("Logo") // Make sure this asset exists in your project
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            ProgressView()
                .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
