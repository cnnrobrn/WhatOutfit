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
    @Published var isSubscriptionActive: Bool = false
    
    private var productIds: [String] = [
        "Wha7PremiumOne"
    ]
    
    private init() {
        Task {
            await observeTransactions()
            await checkCurrentSubscriptionStatus()
        }
    }
    
    func loadProducts() async throws {
        subscriptions = try await Product.products(for: productIds)
        subscriptions.sort { $0.price < $1.price }
        await checkCurrentSubscriptionStatus()
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                // Immediately update subscription status
                isSubscriptionActive = true
                await updatePurchasedSubscriptions()
                await transaction.finish()
                // Notify UserSettings
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                return true
                
            case .unverified:
                print("Transaction verification failed")
                return false
            }
            
        case .userCancelled, .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    private func checkCurrentSubscriptionStatus() async {
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: "Wha7PremiumOne")
            let isActive = statuses.contains { status in
                status.state == .subscribed || status.state == .inGracePeriod
            }
            
            DispatchQueue.main.async {
                self.isSubscriptionActive = isActive
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
            }
        } catch {
            print("Error checking subscription status: \(error)")
        }
    }
    
    private func updatePurchasedSubscriptions() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let product = subscriptions.first(where: { $0.id == transaction.productID }) {
                    DispatchQueue.main.async {
                        self.purchasedSubscriptions.append(product)
                    }
                }
            }
        }
    }
    
    private func observeTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    await updatePurchasedSubscriptions()
                    isSubscriptionActive = true
                } else {
                    purchasedSubscriptions.removeAll { $0.id == transaction.productID }
                    isSubscriptionActive = false
                }
                
                await transaction.finish()
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
