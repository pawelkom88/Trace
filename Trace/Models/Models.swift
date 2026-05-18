import Foundation

enum TraceDifficulty: String, Codable, CaseIterable {
    case easy
    case normal
    case hard
    case expert
}

struct NormalizedPoint: Codable, Equatable {
    let x: Double
    let y: Double
}

struct TracePattern: Codable, Equatable {
    let points: [NormalizedPoint]
}

enum EndZoneVisibility: Codable, Equatable {
    case visible
    case faint
    case hidden
}

struct TraceLevel: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let difficulty: TraceDifficulty
    let pattern: TracePattern
    let previewDuration: TimeInterval
    let maxTraceDuration: TimeInterval
    let passThreshold: Double
    let greatThreshold: Double
    let perfectThreshold: Double
    let tolerance: Double
    let endZoneVisibility: EndZoneVisibility
}

struct TimedPoint: Codable, Equatable {
    let x: Double
    let y: Double
    let timestamp: TimeInterval
}

struct TraceAttempt {
    let levelID: Int
    let userPoints: [TimedPoint]
    let startedAt: Date
    let endedAt: Date?
    let didLiftEarly: Bool
}

enum TraceMedal: String, Codable {
    case none
    case pass
    case great
    case perfect
}

enum TraceFailureReason: String, Codable {
    case startedOutsideZone
    case liftedTooEarly
    case timedOut
    case endedTooFarAway
    case outsideToleranceTooLong
}

enum LifelineType: String, Codable, CaseIterable {
    case wormhole
    case zenFreeze
    case phantomGlimpse
    
    var name: String {
        switch self {
        case .wormhole: return "Wormhole"
        case .zenFreeze: return "Zen Freeze"
        case .phantomGlimpse: return "Phantom"
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .wormhole: return "aqi.medium"
        case .zenFreeze: return "snowflake"
        case .phantomGlimpse: return "eye"
        }
    }
    
    var gemCost: Int {
        switch self {
        case .wormhole: return 20
        case .zenFreeze: return 8
        case .phantomGlimpse: return 14
        }
    }
}

struct TraceScore {
    let total: Double
    let pathAccuracy: Double
    let speed: Double
    let smoothness: Double
    let didPass: Bool
    let medal: TraceMedal
    let failureReason: TraceFailureReason?
    var isAssisted: Bool = false
    
    var calculatedPoints: Int {
        return Int(total * 10000)
    }
}

struct TraceAttemptHistoryItem: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let accuracy: Double
    let points: Int
    let medal: TraceMedal
}

struct TraceProgress: Codable {
    var highestUnlockedLevel: Int
    var completedLevelIDs: Set<Int>
    var bestScoresByLevel: [Int: Double]
    var perfectLevelIDs: Set<Int>
    var currentStreak: Int
    var bestStreak: Int
    var hasCompletedTutorial: Bool
    var hasFullUnlock: Bool
    var dailyStreak: Int
    var lastDailyCompletionDate: String?
    var dailyScoresByDate: [String: Double]
    var attemptHistoryByLevel: [Int: [TraceAttemptHistoryItem]]?
    var gems: Int?
    var hasClaimedFinalReward: Bool?
    
    var globalPrestigeScore: Int {
        let sum = bestScoresByLevel.values.reduce(0, +)
        return Int(sum * 10000)
    }
}

enum GamePhase: Equatable {
    case idle
    case tutorial
    case preparingLevel
    case previewStatic
    case previewAnimating
    case waitingForStart
    case tracing
    case evaluating
    case result
    case failed
    case paywall
}
