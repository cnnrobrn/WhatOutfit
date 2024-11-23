//
//  ProductLinkView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI

// Updated ProductLinkView
struct ProductLinkView: View {
    let link: ProductLink
    @State private var image: UIImage?
    
    var body: some View {
        Link(destination: URL(string: link.url) ?? URL(string: "https://www.google.com")!) {
            VStack(alignment: .leading, spacing: 8) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    ProgressView()
                        .frame(width: 150, height: 150)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.merchantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(link.title)
                        .font(.caption)
                        .lineLimit(2)
                    
                    Text(link.price)
                        .font(.caption)
                        .bold()
                }
                .frame(width: 150)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Decode image on appear
            if image == nil {
                DispatchQueue.global(qos: .background).async {
                    let decodedImage = link.decodeImage()
                    DispatchQueue.main.async {
                        self.image = decodedImage
                    }
                }
            }
        }
    }
}
