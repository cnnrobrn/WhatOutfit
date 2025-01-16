//
//  FrameThumbnail.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//
import SwiftUI
import AVKit


struct FrameThumbnail: View {
    let image: UIImage
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .padding(4)
        }
    }
}


