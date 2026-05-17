import UIKit
import CoreHaptics

class HapticsManager {
    static let shared = HapticsManager()
    
    var isEnabled = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "HapticsEnabled")
        }
    }
    
    init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "HapticsEnabled") as? Bool ?? true
    }
    
    func softTick() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func fail() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func perfect() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let extra = UIImpactFeedbackGenerator(style: .rigid)
            extra.impactOccurred()
        }
    }
}
