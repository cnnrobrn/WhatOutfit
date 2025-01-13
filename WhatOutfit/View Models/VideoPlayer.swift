import SwiftUI
import AVKit
import Combine

class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    private var players: [UUID: (player: AVPlayer, url: URL, lastUsed: Date)] = [:]
    private var observers: [UUID: NSKeyValueObservation] = [:]
    private var loopObservers: [UUID: NSObjectProtocol] = [:]
    private var visiblePlayers = Set<UUID>()
    
    private let maxConcurrentPlayers = 2
    private let maxPausedDuration: TimeInterval = 30 // Maximum time a paused player stays in memory
    private var cleanupTimer: Timer?
    
    private init() {
        setupAudioSession()
        setupMemoryMonitoring()
        startCleanupTimer()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupMemoryMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // Aggressively cleanup on memory warning
        let playersToRemove = players.filter { !visiblePlayers.contains($0.key) }
        playersToRemove.keys.forEach { cleanupPlayer(id: $0) }
    }
    
    func preparePlayer(from data: Data, id: UUID) -> AVPlayer? {
        // Return existing player if available and update last used time
        if let existingPlayer = players[id] {
            players[id] = (existingPlayer.player, existingPlayer.url, Date())
            return existingPlayer.player
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
            
            // Cleanup oldest players if we exceed the limit
            cleanupExcessPlayers()
            
            // Store player with timestamp
            players[id] = (player, tmpURL, Date())
            
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
            cleanupPlayer(id: id)
            return nil
        }
    }
    
    func playVideo(id: UUID) {
        visiblePlayers.insert(id)
        if let playerInfo = players[id] {
            players[id] = (playerInfo.player, playerInfo.url, Date())
            playerInfo.player.seek(to: .zero)
            playerInfo.player.play()
        }
    }
    
    func pauseVideo(id: UUID) {
        visiblePlayers.remove(id)
        if let playerInfo = players[id] {
            playerInfo.player.pause()
        }
    }
    
    private func cleanupExcessPlayers() {
        guard players.count >= maxConcurrentPlayers else { return }
        
        // Sort players by last used time, oldest first
        let sortedPlayers = players.sorted { $0.value.lastUsed < $1.value.lastUsed }
        
        // Remove oldest non-visible players until we're under the limit
        for (id, _) in sortedPlayers {
            if !visiblePlayers.contains(id) {
                cleanupPlayer(id: id)
                if players.count < maxConcurrentPlayers {
                    break
                }
            }
        }
    }
    
    func cleanupPlayer(id: UUID) {
        visiblePlayers.remove(id)
        
        observers[id]?.invalidate()
        observers.removeValue(forKey: id)
        
        if let loopObserver = loopObservers[id] {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObservers.removeValue(forKey: id)
        
        if let playerInfo = players[id] {
            playerInfo.player.pause()
            playerInfo.player.replaceCurrentItem(with: nil)
            try? FileManager.default.removeItem(at: playerInfo.url)
        }
        
        players.removeValue(forKey: id)
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.cleanupOldPlayers()
        }
    }
    
    private func cleanupOldPlayers() {
        let now = Date()
        let oldPlayers = players.filter { !visiblePlayers.contains($0.key) &&
            now.timeIntervalSince($0.value.lastUsed) > maxPausedDuration }
        
        oldPlayers.keys.forEach { cleanupPlayer(id: $0) }
    }
    
    deinit {
        cleanupTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        players.keys.forEach(cleanupPlayer)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
