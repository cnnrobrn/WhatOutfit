import SwiftUI
import StoreKit

class UserSettings: ObservableObject {
    
    @Published var phoneNumber: String {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        }
    }
    
    @Published var instagramUsername: String? {
        didSet {
            UserDefaults.standard.set(instagramUsername, forKey: "instagramUsername")
        }
    }
    
    @Published var isPremium: Bool = false {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
    }
    
    @Published var userBodyImage: Data? {
        didSet {
            UserDefaults.standard.set(userBodyImage, forKey: "userBodyImage")
        }
    }
    
    init() {
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
        self.instagramUsername = UserDefaults.standard.string(forKey: "instagramUsername")
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.userBodyImage = UserDefaults.standard.data(forKey: "userBodyImage")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionChange),
            name: .subscriptionStatusChanged,
            object: nil
        )
        
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    @objc private func handleSubscriptionChange() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    @MainActor
    func checkSubscriptionStatus() async {
        isPremium = SubscriptionManager.shared.isSubscriptionActive
    }
    
    func clearPhoneNumber() {
        phoneNumber = ""
        instagramUsername = nil
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        UserDefaults.standard.removeObject(forKey: "instagramUsername")
    }
    
    func clearBodyImage() {
        userBodyImage = nil
        UserDefaults.standard.removeObject(forKey: "userBodyImage")
    }
}
