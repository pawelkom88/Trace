import Foundation

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    
    @Published var progress: TraceProgress
    
    private let defaults = UserDefaults.standard
    private let key = "TraceProgress"
    
    init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(TraceProgress.self, from: data) {
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
                hasFullUnlock: false,
                dailyStreak: 0,
                lastDailyCompletionDate: nil,
                dailyScoresByDate: [:]
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
            progress.highestUnlockedLevel += 1
        }
        LevelVariantStore.shared.clearLockedVariant(for: id)
        
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
        let hasUnlock = progress.hasFullUnlock
        progress = TraceProgress(
            highestUnlockedLevel: 1,
            completedLevelIDs: [],
            bestScoresByLevel: [:],
            perfectLevelIDs: [],
            currentStreak: 0,
            bestStreak: 0,
            hasCompletedTutorial: false,
            hasFullUnlock: hasUnlock,
            dailyStreak: 0,
            lastDailyCompletionDate: nil,
            dailyScoresByDate: [:]
        )
        LevelVariantStore.shared.clearAllLockedVariants()
        save()
    }

    @discardableResult
    func spendGems(_ amount: Int) -> Bool {
        let current = progress.gems ?? 100
        guard amount > 0, current >= amount else { return false }
        progress.gems = current - amount
        save()
        return true
    }

    func addGems(_ amount: Int) {
        guard amount > 0 else { return }
        let current = progress.gems ?? 100
        progress.gems = current + amount
        save()
    }

    @discardableResult
    func claimFinalRewardIfNeeded() -> Bool {
        let rewardKey = "TraceFinalRewardClaimed"
        guard !defaults.bool(forKey: rewardKey) else { return false }
        addGems(100)
        defaults.set(true, forKey: rewardKey)
        return true
    }
}
