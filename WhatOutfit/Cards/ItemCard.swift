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
                .padding(.horizontal)
            
            if let links = item.links {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(links) { link in
                            ProductLinkView(link: link)
                                .frame(height: 220) // Fixed height for consistency
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
