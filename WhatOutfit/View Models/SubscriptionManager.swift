//
//  SubscriptionManager.swift
//  WhatOutfit
//
//  Created by Dan O'Brien on 12/23/24.
//

import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    private var productIds: [String] = [
        // Add your subscription product IDs from App Store Connect here
        "Wha7PremiumOne"
    ]
    
    private init() {
        // Start listening for transactions when the manager is initialized
        Task {
            await observeTransactions()
        }
    }
    
    func loadProducts() async throws {
        subscriptions = try await Product.products(for: productIds)
        
        // Sort products by price if needed
        subscriptions.sort { $0.price < $1.price }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        // Start a purchase
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            // Handle successful purchase
            switch verificationResult {
            case .verified(let transaction):
                // Update purchased subscriptions
                await updatePurchasedSubscriptions()
                // Finish the transaction
                await transaction.finish()
                return true
                
            case .unverified:
                // Handle unverified transaction
                print("Transaction verification failed")
                return false
            }
            
        case .userCancelled:
            return false
            
        case .pending:
            print("Transaction pending user action")
            return false
            
        @unknown default:
            return false
        }
    }
    
    func checkSubscriptionStatus(for groupID: String) async throws -> Bool {
        // Get subscription status
        let statuses = try await Product.SubscriptionInfo.status(for: groupID)
        
        // Check if any status is active
        for status in statuses {
            if status.state == .subscribed {
                return true
            }
        }
        
        return false
    }
    
    private func updatePurchasedSubscriptions() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Find the product for this transaction
                if let product = subscriptions.first(where: { $0.id == transaction.productID }) {
                    purchasedSubscriptions.append(product)
                }
            case .unverified:
                continue
            }
        }
    }
    
    private func observeTransactions() async {
        // Listen for transactions from App Store
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                // Handle transaction state
                if transaction.revocationDate == nil {
                    // Transaction is valid
                    await updatePurchasedSubscriptions()
                } else {
                    // Transaction was refunded or revoked
                    purchasedSubscriptions.removeAll { $0.id == transaction.productID }
                }
                
                // Always finish the transaction
                await transaction.finish()
                
            case .unverified:
                // Handle unverified transaction
                print("Received unverified transaction")
            }
        }
    }
    
    // Helper method to check if user is eligible for introductory offer
    func checkIntroEligibility(groupID: String) async -> Bool {
        return await Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupID)
    }
}
