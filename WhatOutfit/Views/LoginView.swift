import SwiftUI

// Add an enum to track the phone number type
enum PhoneNumberType {
    case us
    case uk
    case unknown
    
    var flag: String {
        switch self {
        case .us: return "🇺🇸"
        case .uk: return "🇬🇧"
        case .unknown: return ""
        }
    }
}

struct LoginView: View {
    @Binding var phoneNumber: String
    let onComplete: (Bool) -> Void
    @State private var showError = false
    @State private var phoneNumberType: PhoneNumberType = .unknown
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 40) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                // Phone Input Section
                VStack(spacing: 8) {
                    HStack {
                        TextField("Phone Number", text: $phoneNumber)
                            .font(.system(size: 17))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .onChange(of: phoneNumber) { _ in
                                phoneNumberType = detectPhoneNumberType(phoneNumber)
                            }
                        
                        if phoneNumberType != .unknown {
                            Text(phoneNumberType.flag)
                                .font(.title2)
                                .padding(.trailing, 8)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: validateAndLogin) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .alert("Invalid Phone Number", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(getErrorMessage())
        }
        .onAppear {
            if !userSettings.phoneNumber.isEmpty {
                phoneNumber = userSettings.phoneNumber
                onComplete(true)
            }
        }
        VStack(spacing: 16) {
            
            // Legal Footer
            VStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.system(size: 10))
                    
                    Text("and")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.wha7.com/privacy")!)
                        .font(.system(size: 10))
                }
            }
        }
    }
    
    
    
    private func detectPhoneNumberType(_ number: String) -> PhoneNumberType {
        let cleaned = number.filter { $0.isNumber }
        
        // Check for UK numbers with country code
        if cleaned.hasPrefix("44") && (cleaned.count >= 11 && cleaned.count <= 13) {
            return .uk
        }
        
        // Check for UK numbers without country code (common UK area code prefixes)
        let ukPrefixes = ["01", "02", "03", "07", "08"]
        if cleaned.count == 10 && ukPrefixes.contains(String(cleaned.prefix(2))) {
            return .uk
        }
        
        // US numbers are 10 digits or 11 digits with '1' prefix
        if (cleaned.count == 10 && !ukPrefixes.contains(String(cleaned.prefix(2)))) ||
           (cleaned.hasPrefix("1") && cleaned.count == 11) {
            return .us
        }
        
        return .unknown
    }
    
    private func validateAndLogin() {
        let cleaned = phoneNumber.filter { $0.isNumber }
        
        switch phoneNumberType {
        case .us:
            // Preserve existing US phone number handling
            let digits: String
            if cleaned.hasPrefix("1") && cleaned.count == 11 {
                digits = String(cleaned.dropFirst())
            } else {
                digits = cleaned
            }
            
            if digits.count == 10 {
                userSettings.phoneNumber = digits
                onComplete(true)
            } else {
                showError = true
            }
            
        case .uk:
            // Handle UK numbers
            let digits: String
            if cleaned.hasPrefix("44") {
                digits = String(cleaned.dropFirst(2))
            } else {
                digits = cleaned
            }
            
            // Accept both 10 and 11 digit UK numbers
            if digits.count >= 10 && digits.count <= 11 {
                // Store with +44 prefix for UK numbers
                userSettings.phoneNumber = "44" + digits
                onComplete(true)
            } else {
                showError = true
            }
            
        case .unknown:
            showError = true
        }
    }
    
    private func getErrorMessage() -> String {
        switch phoneNumberType {
        case .us:
            return "Please enter a valid 10-digit US phone number"
        case .uk:
            return "Please enter a valid 11-digit UK phone number"
        case .unknown:
            return "Please enter a valid US or UK phone number"
        }
    }
}
