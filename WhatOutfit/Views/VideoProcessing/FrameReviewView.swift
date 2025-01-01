//
//  FrameReviewView.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 1/1/25.
//

import SwiftUI
import AVKit

struct VideoFrameReviewView: View {
    let frames: [UIImage]
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss
    @State private var showingSubmitAlert = false
    
    var body: some View {
        VStack {
            Text("Review Photos")
                .font(.headline)
                .padding()
            
            Image(uiImage: frames[currentIndex])
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: .infinity)
                .padding()
            
            HStack {
                Button(action: previousFrame) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                .disabled(currentIndex == 0)
                
                Spacer()
                
                Text("\(currentIndex + 1) of \(frames.count)")
                    .font(.subheadline)
                
                Spacer()
                
                Button(action: nextFrame) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .disabled(currentIndex == frames.count - 1)
            }
            .padding()
            
            if currentIndex == frames.count - 1 {
                Button(action: { showingSubmitAlert = true }) {
                    Text("Submit for Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .alert("Submit Outfits", isPresented: $showingSubmitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Submit") {
                // Handle submission
                dismiss()
            }
        } message: {
            Text("Would you like to submit these outfits for analysis?")
        }
    }
    
    private func nextFrame() {
        withAnimation {
            currentIndex = min(currentIndex + 1, frames.count - 1)
        }
    }
    
    private func previousFrame() {
        withAnimation {
            currentIndex = max(currentIndex - 1, 0)
        }
    }
}
