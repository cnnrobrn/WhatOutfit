import SwiftUI
import AVKit

struct VideoFrameSelectionView: View {
    let player: AVPlayer?
    let outfit: Outfit
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFrames: [UIImage] = []
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var progressMessage = "Processing frames..."
    @State private var showingDetailView = false
    @State private var updatedOutfit: Outfit?
    @State private var isCapturing = false
    @State private var imageGenerator: AVAssetImageGenerator?
    
    private func setupImageGenerator() {
        guard imageGenerator == nil,
              let asset = player?.currentItem?.asset else { return }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 1280)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        imageGenerator = generator
    }
    
    private func captureCurrentFrame() {
        guard !isCapturing,
              let player = player,
              let generator = imageGenerator else { return }
        
        // Prevent multiple simultaneous captures
        isCapturing = true
        
        // Pause player during capture
        player.pause()
        
        let time = CMTime(seconds: player.currentTime().seconds, preferredTimescale: 600)
        
        Task {
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                
                await MainActor.run {
                    if selectedFrames.count < 10 {
                        let resizedImage = resizeImage(image, maxDimension: 720)
                        selectedFrames.append(resizedImage)
                    } else {
                        showError(message: "Maximum 10 frames allowed")
                    }
                    isCapturing = false
                    player.play()
                }
            } catch {
                await MainActor.run {
                    showError(message: "Error capturing frame: \(error.localizedDescription)")
                    isCapturing = false
                    player.play()
                }
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let ratio = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func submitFrames() {
        guard !selectedFrames.isEmpty else {
            showError(message: "Please select at least one frame")
            return
        }
        
        guard selectedFrames.count <= 10 else {
            showError(message: "Maximum 10 frames allowed")
            return
        }
        
        isProcessing = true
        progressMessage = "Processing frames..."
        
        // Pause video during processing
        player?.pause()
        
        Task {
            do {
                let processedFrames = try await OutfitService.shared.submitFrames(
                    outfitId: outfit.id,
                    frames: selectedFrames
                )
                
                await MainActor.run {
                    isProcessing = false
                    if let lastFrame = processedFrames.last {
                        let convertedItems = lastFrame.items.map { processedItem in
                            processedItem.toItem(outfitId: outfit.id)
                        }
                        
                        updatedOutfit = Outfit(
                            id: outfit.id,
                            imageData: outfit.imageData,
                            description: outfit.description,
                            items: convertedItems
                        )
                        showingDetailView = true
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    showError(message: "Error submitting frames: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isProcessing {
                    VStack {
                        ProgressView(progressMessage)
                        Text("This may take a few moments...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                } else {
                    Text("Tap the video to capture outfit frames")
                        .font(.headline)
                        .padding()
                    
                    ZStack {
                        if let player = player {
                            VideoPlayer(player: player)
                                .frame(height: 400)
                                .cornerRadius(12)
                                .overlay(
                                    Button(action: {
                                        if !isCapturing {
                                            captureCurrentFrame()
                                        }
                                    }) {
                                        Color.clear
                                    }
                                )
                        }
                    }
                    
                    if !selectedFrames.isEmpty {
                        Text("\(selectedFrames.count)/10 frames selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(selectedFrames.indices, id: \.self) { index in
                                FrameThumbnail(image: selectedFrames[index]) {
                                    selectedFrames.remove(at: index)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                    
                    Button(action: submitFrames) {
                        Text("Submit for Analysis")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedFrames.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(selectedFrames.isEmpty)
                    .padding(.horizontal)
                }
            }
            .navigationBarItems(leading: Button("Cancel") {
                player?.pause()
                dismiss()
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showingDetailView) {
                if let updatedOutfit = updatedOutfit {
                    OutfitDetailView(outfit: updatedOutfit)
                }
            }
            .onAppear {
                setupImageGenerator()
                player?.play()
            }
            .onDisappear {
                player?.pause()
                imageGenerator = nil
            }
        }
    }
}
