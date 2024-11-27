//
//  SettingsView.swift
//  WhatOutfit
//
//  Created by Connor O'Brien on 11/24/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            WhatOutfitHeader()
                .background(Color(.systemBackground))
            NavigationView {
                List {
                    Section(header: Text("Account Information")) {
                        HStack {
                            Text("Phone Number")
                            Spacer()
                            Text(userSettings.phoneNumber)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            userSettings.clearPhoneNumber()
                            isAuthenticated = false
                        }) {
                            HStack {
                                Text("Log Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }
}
