//
//  GIFImage.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 1/9/25.
//


import SwiftUI
import WebKit

struct GIFImage: UIViewRepresentable {
    let name: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let gifURL = Bundle.main.url(forResource: name, withExtension: "gif") {
            let request = URLRequest(url: gifURL)
            webView.load(request)
        }
    }
}