import SwiftUI
import SafariServices

struct LegalFooterView: View {
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    
    private let privacyPolicyURL = "https://www.wha7.com/privacy"
    private let termsOfUseURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    
    var body: some View {
        let baseFont = Font.system(size: 10)
        
        HStack(spacing: 0) {
            Group {
                Text("By using this app, you agree to our ")
                    .foregroundColor(.gray)
                
                Text("Terms of Use")
                    .foregroundColor(.gray)
                    .underline()
                    .onTapGesture {
                        handleTermsTap()
                    }
                
                Text(" and ")
                    .foregroundColor(.gray)
                
                Text("Privacy Policy")
                    .foregroundColor(.gray)
                    .underline()
                    .onTapGesture {
                        handlePrivacyPolicyTap()
                    }
            }
            .font(baseFont)
        }
        .multilineTextAlignment(.center)
    }
    
    private func handleTermsTap() {
        if let url = URL(string: termsOfUseURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func handlePrivacyPolicyTap() {
        if let url = URL(string: privacyPolicyURL) {
            UIApplication.shared.open(url)
        }
    }
}
