//
//  MessageModel.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/25/24.
//
import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let image: UIImage?
    let timestamp: Date
    var recommendations: [item]? // Using your existing item model
    
    init(content: String, isUser: Bool, image: UIImage? = nil, recommendations: [item]? = nil) {
        self.content = content
        self.isUser = isUser
        self.image = image
        self.timestamp = Date()
        self.recommendations = recommendations
    }
}
