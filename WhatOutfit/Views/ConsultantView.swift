//
//  ConsultantView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/25/24.
//
import SwiftUI
import PhotosUI

struct ConsultantView: View {
    @StateObject private var viewModel = ConsultantViewModel()
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader(title: "Consultant")
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedItem,
                               matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    
                    TextField("Ask a question...", text: $viewModel.newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        guard !viewModel.newMessage.isEmpty else { return }
                        viewModel.sendMessage(viewModel.newMessage)
                        viewModel.newMessage = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
        .onChange(of: selectedItem) { _, item in
            if let item = item {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.sendMessage("I'd like advice about this outfit:", image: image)
                    }
                }
            }
        }
    }
}
