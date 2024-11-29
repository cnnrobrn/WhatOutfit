//
//  ActivationView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/27/24.
//
import SwiftUI

// Add the Activation View
struct ActivationView: View {
    let phoneNumber: String
    @State private var referralCode: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @StateObject private var activationManager = ActivationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to WhatOutfit!")
                .font(.title)
                .padding()
            
            Text("Please enter a referral code to activate your account.")
                .multilineTextAlignment(.center)
                .padding()
            
            TextField("Enter Referral Code", text: $referralCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.allCharacters)
                .textInputAutocapitalization(.characters)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: validateReferral) {
                if isProcessing {
                    ProgressView()
                } else {
                    Text("Activate Account")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(referralCode.isEmpty || isProcessing)
            
            Spacer()
        }
        .padding()
    }
    private func formatPhoneNumber(_ phone: String) -> String {
        var formatted = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if !formatted.starts(with: "+1") {
            formatted = "+1" + formatted
        }
        return formatted
    }

    private func validateReferral() {
        isProcessing = true
        errorMessage = nil
        
        let formattedPhone = formatPhoneNumber(phoneNumber)
        print("Starting referral validation for code: \(referralCode)")
        print("Phone number (formatted): \(formattedPhone)")
        
        guard let url = URL(string: "https://access.wha7.com/api/referral/validate") else {
            print("Error: Invalid URL for referral validation")
            errorMessage = "Invalid URL configuration"
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "code": referralCode.uppercased(),
            "phone_number": formattedPhone
        ]
        
        print("Sending validation request with body: \(body)")
                
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing request body: \(error)")
            errorMessage = "Failed to prepare request"
            isProcessing = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
            }
            
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    print("Network error: \(error)")
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    print("No data received from server")
                    errorMessage = "No response from server"
                    return
                }
                
                // Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(ActivationResponse.self, from: data)
                    print("Decoded response: \(response)")
                    
                    if response.isActivated {
                        print("Activation successful")
                        activationManager.isActivated = true
                    } else {
                        print("Activation failed: \(response.message ?? "No error message provided")")
                        errorMessage = response.message ?? "Invalid referral code"
                    }
                } catch {
                    print("Decoding error: \(error)")
                    print("Decoding error details: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            print("Missing key: \(key)")
                        case .valueNotFound(let type, _):
                            print("Missing value for type: \(type)")
                        case .typeMismatch(let type, _):
                            print("Type mismatch for type: \(type)")
                        default:
                            print("Other decoding error: \(decodingError)")
                        }
                    }
                    errorMessage = "Failed to process server response"
                }
            }
        }.resume()
    }
}



