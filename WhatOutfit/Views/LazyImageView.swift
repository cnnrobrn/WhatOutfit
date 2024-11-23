import SwiftUI

struct LazyImageView: View {
    let base64String: String
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView() // Shows a loading spinner
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .background(Color.gray.opacity(0.1))
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard !isLoading else { return }
        isLoading = true
        
        // Move image decoding to background thread
        DispatchQueue.global(qos: .background).async {
            // Clean the base64 string
            let cleanedString = base64String
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("Base64 string length: \(cleanedString.count)")
            print("Base64 string start: \(cleanedString.prefix(50))")
            
            if let imageData = Data(base64Encoded: cleanedString, options: .ignoreUnknownCharacters),
               let decodedImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.image = decodedImage
                    self.isLoading = false
                }
            } else {
                print("Failed to decode image")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
