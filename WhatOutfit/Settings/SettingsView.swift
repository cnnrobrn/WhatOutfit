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
                    
                    Section(header: Text("Virtual Try-On")) {
                        NavigationLink("Body Image Settings") {
                            BodyImageSettingsView()
                        }
                    }
                    
                    InstagramLinkingSection()
                    
                    Section {
                        Link(destination: URL(string: "https://www.wha7.com/f/eac6ab97-f56b-447a-8d12-90ce7fe417d2")!) {
                            HStack {
                                Text("Delete Account")
                                    .foregroundColor(.red)
                                Spacer()
                            }
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
