import SwiftUI
import AVKit
import Combine

class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    @Published private(set) var currentPlayer: AVPlayer?
    private var activePlayerID: UUID?
    private var playerCache: [UUID: AVPlayer] = [:] // Cache for player instances
    private var tempURLs: Set<URL> = []
    private let maxSimultaneousPlayers = 2
    private var cleanupTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupMemoryMonitoring()
        startCleanupTimer()
    }
    
    private func setupMemoryMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.performPeriodicCleanup()
        }
    }
    
    func setCurrentPlayer(_ player: AVPlayer?, withID id: UUID) {
        // Pause current player if switching to a different one
        if currentPlayer !== player {
            stopCurrentPlayer()
        }
        
        // Cache management
        if let player = player {
            cleanupCache()
            playerCache[id] = player
            
            // Configure the player
            player.isMuted = true
            
            if let playerItem = player.currentItem {
                playerItem.preferredPeakBitRate = 200000 // .2Mbps
                playerItem.preferredMaximumResolution = CGSize(width: 640, height: 360)
            }
        }
        
        currentPlayer = player
        activePlayerID = id
    }
    
    func addTempURL(_ url: URL) {
        tempURLs.insert(url)
    }
    
    private func cleanupCache() {
        while playerCache.count >= maxSimultaneousPlayers {
            guard let oldestID = playerCache.keys.first else { break }
            removePlayer(withID: oldestID)
        }
    }
    
    private func cleanupTempFiles() {
        for url in tempURLs {
            try? FileManager.default.removeItem(at: url)
        }
        tempURLs.removeAll()
    }
    
    func removePlayer(withID id: UUID) {
        if let player = playerCache[id] {
            player.pause()
            player.replaceCurrentItem(with: nil)
            playerCache.removeValue(forKey: id)
        }
    }
    
    private func performPeriodicCleanup() {
        cleanupCache()
        cleanupTempFiles()
    }
    
    @objc private func handleMemoryWarning() {
        // Clear entire cache on memory warning
        playerCache.forEach { id, player in
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        playerCache.removeAll()
        cleanupTempFiles()
        currentPlayer = nil
        activePlayerID = nil
    }
    
    func stopCurrentPlayer() {
        currentPlayer?.pause()
        currentPlayer = nil
        activePlayerID = nil
    }
    
    func isCurrentPlayer(_ player: AVPlayer?, withID id: UUID) -> Bool {
        return player === currentPlayer && id == activePlayerID
    }
    
    deinit {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        cancellables.removeAll()
        cleanupTempFiles()
        handleMemoryWarning()
    }
}
