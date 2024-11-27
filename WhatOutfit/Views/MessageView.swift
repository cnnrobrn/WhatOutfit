//
//  MessageView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/25/24.
//
import SwiftUI
// Message Bubble View
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
            
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if let recommendations = message.recommendations {
                VStack(spacing: 12) {
                    ForEach(recommendations) { item in
                        ItemCard(item: item)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}
