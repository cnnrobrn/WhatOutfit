//
//  ActivationManager.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/27/24.
//
import SwiftUI

// Add the ActivationManager
class ActivationManager: ObservableObject {
    @Published var isActivated: Bool = false
    @Published var errorMessage: String?
    
    func checkActivation(phoneNumber: String) {
        guard let url = URL(string: "https://access.wha7.com/api/user/check_activation") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["phone_number": phoneNumber]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if let data = data,
                   let response = try? JSONDecoder().decode(ActivationResponse.self, from: data) {
                    self?.isActivated = response.isActivated
                } else {
                    self?.errorMessage = "Failed to check activation status"
                }
            }
        }.resume()
    }
}

struct ActivationResponse: Codable {
    let isActivated: Bool
    let needsReferral: Bool
    let message: String?
    let error: String?  // Add this to catch error messages
    
    enum CodingKeys: String, CodingKey {
        case isActivated = "is_activated"
        case needsReferral = "needs_referral"
        case message
        case error
    }
}
extension ActivationResponse: CustomStringConvertible {
    var description: String {
        return """
        ActivationResponse:
        - isActivated: \(isActivated)
        - needsReferral: \(needsReferral)
        - message: \(message ?? "nil")
        - error: \(error ?? "nil")
        """
    }
}
