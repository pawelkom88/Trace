import Foundation

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    
    @Published var progress: TraceProgress
    
    private let defaults = UserDefaults.standard
    private let key = "TraceProgress"
    private let maxLevel = 50
    
    init() {
        if let data = defaults.data(forKey: key),
           var decoded = try? JSONDecoder().decode(TraceProgress.self, from: data) {
            decoded.hasFullUnlock = true
            if decoded.gems == nil {
                decoded.gems = 100
            }
            if decoded.hasClaimedFinalReward == nil {
                decoded.hasClaimedFinalReward = false
            }
            decoded.highestUnlockedLevel = min(decoded.highestUnlockedLevel, maxLevel)
            self.progress = decoded
        } else {
            self.progress = TraceProgress(
                highestUnlockedLevel: 1,
                completedLevelIDs: [],
                bestScoresByLevel: [:],
                perfectLevelIDs: [],
                currentStreak: 0,
                bestStreak: 0,
                hasCompletedTutorial: false,
                hasFullUnlock: true,
                dailyStreak: 0,
                lastDailyCompletionDate: nil,
                dailyScoresByDate: [:],
                gems: 100,
                hasClaimedFinalReward: false
            )
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(progress) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    private func recordAttempt(id: Int, score: TraceScore) {
        if progress.attemptHistoryByLevel == nil {
            progress.attemptHistoryByLevel = [:]
        }
        var list = progress.attemptHistoryByLevel?[id] ?? []
        let item = TraceAttemptHistoryItem(
            date: Date(),
            accuracy: score.pathAccuracy,
            points: score.calculatedPoints,
            medal: score.medal
        )
        list.append(item)
        if list.count > 10 {
            list.removeFirst()
        }
        progress.attemptHistoryByLevel?[id] = list
    }
    
    func completeLevel(id: Int, score: TraceScore) {
        progress.completedLevelIDs.insert(id)
        
        let previousBest = progress.bestScoresByLevel[id] ?? 0.0
        if score.total > previousBest {
            progress.bestScoresByLevel[id] = score.total
        }
        
        if score.medal == .perfect {
            progress.perfectLevelIDs.insert(id)
        }
        
        if id == progress.highestUnlockedLevel {
            progress.highestUnlockedLevel = min(progress.highestUnlockedLevel + 1, maxLevel)
        }
        
        progress.currentStreak += 1
        if progress.currentStreak > progress.bestStreak {
            progress.bestStreak = progress.currentStreak
        }
        
        recordAttempt(id: id, score: score)
        save()
    }
    
    func failAttempt(id: Int, score: TraceScore) {
        progress.currentStreak = 0
        recordAttempt(id: id, score: score)
        save()
    }
    
    func completeTutorial() {
        progress.hasCompletedTutorial = true
        save()
    }
    
    func unlockFullGame() {
        progress.hasFullUnlock = true
        save()
    }
    
    func resetProgress() {
        progress = TraceProgress(
            highestUnlockedLevel: 1,
            completedLevelIDs: [],
            bestScoresByLevel: [:],
            perfectLevelIDs: [],
            currentStreak: 0,
            bestStreak: 0,
            hasCompletedTutorial: false,
            hasFullUnlock: true,
            dailyStreak: 0,
            lastDailyCompletionDate: nil,
            dailyScoresByDate: [:],
            gems: 100,
            hasClaimedFinalReward: false
        )
        save()
    }
    
    func spendGems(_ amount: Int) -> Bool {
        let current = progress.gems ?? 100
        if current >= amount {
            progress.gems = current - amount
            save()
            return true
        }
        return false
    }
    
    func addGems(_ amount: Int) {
        let current = progress.gems ?? 100
        progress.gems = current + amount
        save()
    }
    
    func claimFinalRewardIfNeeded() -> Bool {
        if progress.hasClaimedFinalReward == true {
            return false
        }
        addGems(200)
        progress.hasClaimedFinalReward = true
        save()
        return true
    }
}
