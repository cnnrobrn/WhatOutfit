import SwiftUI
import AVKit
import Combine

class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    private var players: [UUID: (player: AVPlayer, url: URL)] = [:]
    private var loopObservers: [UUID: NSObjectProtocol] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func preparePlayer(from data: Data, id: UUID) -> AVPlayer? {
        // Return existing player if available
        if let existingPlayer = players[id]?.player {
            return existingPlayer
        }
        
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try data.write(to: tmpURL)
            
            let asset = AVURLAsset(url: tmpURL)
            let playerItem = AVPlayerItem(asset: asset)
            
            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = true
            player.actionAtItemEnd = .none
            
            players[id] = (player, tmpURL)
            
            // Setup loop observer
            let loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main) { [weak player] _ in
                    player?.seek(to: .zero)
                    player?.play()
                }
            loopObservers[id] = loopObserver
            
            return player
        } catch {
            print("Error preparing video player: \(error)")
            return nil
        }
    }
    
    func playVideo(id: UUID) {
        if let (player, _) = players[id] {
            player.seek(to: .zero)
            player.play()
        }
    }
    
    func pauseVideo(id: UUID) {
        players[id]?.player.pause()
    }
    
    func cleanupPlayer(id: UUID) {
        if let loopObserver = loopObservers[id] {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObservers.removeValue(forKey: id)
        
        if let (player, url) = players[id] {
            player.pause()
            player.replaceCurrentItem(with: nil)
            try? FileManager.default.removeItem(at: url)
        }
        
        players.removeValue(forKey: id)
    }
    
    deinit {
        players.keys.forEach(cleanupPlayer)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
