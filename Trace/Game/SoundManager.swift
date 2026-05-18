import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    var isEnabled = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "SoundEnabled")
        }
    }
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "SoundEnabled") as? Bool ?? true
        preloadSounds()
    }
    
    private func preloadSounds() {
        let soundFiles = [
            "soft-tick": "wav",
            "warning": "wav",
            "success": "wav",
            "perfect": "wav",
            "fail": "wav",
            "zen": "wav",
            "phantom": "wav",
            "wormhole": "wav"
        ]
        
        for (name, ext) in soundFiles {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[name] = player
                    print("SoundManager: Successfully preloaded '\(name).\(ext)'")
                } catch {
                    print("SoundManager: Failed to initialize AVAudioPlayer for '\(name)': \(error)")
                }
            } else {
                print("SoundManager: Sound file '\(name).\(ext)' not found in main bundle")
            }
        }
    }
    
    func play(_ name: String) {
        guard isEnabled else { return }
        guard let player = players[name] else {
            print("SoundManager: Player for '\(name)' not found or not loaded")
            return
        }
        
        // Rewind and play immediately to support fast, repetitive triggers (like softTick)
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        
        player.play()
    }
    
    func softTick() {
        play("soft-tick")
    }
    
    func warning() {
        play("warning")
    }
    
    func success() {
        play("success")
    }
    
    func perfect() {
        play("perfect")
    }
    
    func fail() {
        play("fail")
    }
    
    func playZenFreeze() {
        play("zen")
    }
    
    func playPhantomGlimpse() {
        play("phantom")
    }
    
    func playWormhole() {
        play("wormhole")
    }
}
