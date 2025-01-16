//
//  ItemCard.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//
import SwiftUI

struct ItemCard: View {
    let item: item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.description)
                .font(.headline)
                .foregroundColor(.primary)  // Explicitly set to primary color
                .padding(.horizontal)
            
            if let links = item.links, !links.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(links) { link in
                            Link(destination: link.cleanURL()) {
                                ProductLinkView(link: link)
                                    .frame(height: 220)
                            }
                            .buttonStyle(PlainButtonStyle())  // Remove default link styling
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Loading products...")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

