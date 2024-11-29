//
//  StarRating.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/27/24.
//
import SwiftUI

struct StarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    
    func starType(for position: Int) -> String {
        if Double(position) <= rating {
            return "star.fill"
        } else if Double(position) - rating < 1 && Double(position) - rating > 0 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .foregroundColor(.yellow)
                    .font(.caption2)
            }
        }
    }
}
