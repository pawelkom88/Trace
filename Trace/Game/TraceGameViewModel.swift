import SwiftUI
import Combine

@MainActor
class TraceGameViewModel: ObservableObject {
    @Published var phase: GamePhase = .idle
    @Published var currentLevel: TraceLevel?
    @Published var userPoints: [TimedPoint] = []
    @Published var currentScore: TraceScore?
    @Published var previewProgress: CGFloat = 0.0
    @Published var consecutiveFailures = 0
    @Published var isAssistModeActive = false {
        didSet {
            if let currentLevel = currentLevel {
                if isAssistModeActive {
                    UserDefaults.standard.set(currentLevel.id, forKey: "ZenModeLevelID")
                } else {
                    if UserDefaults.standard.integer(forKey: "ZenModeLevelID") == currentLevel.id {
                        UserDefaults.standard.removeObject(forKey: "ZenModeLevelID")
                    }
                }
            }
        }
    }
    @Published var showPhantomGlimpse = false
    @Published var timeDilationFactor: Double = 1.0
    @Published var timerBoostPulseToken = UUID()
    @Published var timerBoostDisplayValue: Double = 0.0
    
    private var startTime: Date?
    private var screenSize: CGSize = .zero
    
    func startLevel(_ level: TraceLevel, isRetry: Bool = false) {
        log("startLevel \(level.id) (\(level.title)); isRetry=\(isRetry), previousLevel=\(currentLevel?.id.description ?? "nil"), previousPhase=\(phase), screenSize=\(screenSize)")
        
        UserDefaults.standard.set(level.id, forKey: "ResumeLevelID")
        log("stored ResumeLevelID=\(level.id)")
        
        let isLevelChanged = currentLevel?.id != level.id
        self.currentLevel = level
        
        let zenLevelID = UserDefaults.standard.integer(forKey: "ZenModeLevelID")
        if zenLevelID == level.id {
            self.isAssistModeActive = true
            log("restored ZenMode for level \(level.id)")
        } else {
            // Reset assists and failures if we switch levels or if starting fresh
            if isLevelChanged || !isRetry {
                log("resetting assist/failures; isLevelChanged=\(isLevelChanged), isRetry=\(isRetry)")
                self.consecutiveFailures = 0
                self.isAssistModeActive = false
            }
        }
        self.timeDilationFactor = 1.0
        
        self.userPoints = []
        self.currentScore = nil
        self.previewProgress = 0.0
        self.timerBoostDisplayValue = level.maxTraceDuration * timeDilationFactor
        
        let previewOnEveryTry = UserDefaults.standard.object(forKey: "PreviewOnEveryTry") as? Bool ?? true
        log("startLevel state reset complete; previewOnEveryTry=\(previewOnEveryTry), timerDisplay=\(timerBoostDisplayValue)")
        
        if isRetry && !previewOnEveryTry {
            log("skipping preview sequence on retry; phase waitingForStart")
            self.phase = .waitingForStart
        } else {
            log("phase preparingLevel; scheduling preview sequence in 0.5s")
            self.phase = .preparingLevel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.log("preview delay fired for level \(level.id); currentLevel=\(self.currentLevel?.id.description ?? "nil"), phase=\(self.phase)")
                self.runPreviewSequence(level)
            }
        }
    }
    
    func setScreenSize(_ size: CGSize) {
        if screenSize != size {
            log("screenSize changed \(screenSize) -> \(size)")
        }
        self.screenSize = size
    }
    
    private func runPreviewSequence(_ level: TraceLevel) {
        log("runPreviewSequence requested for level \(level.id); currentLevel=\(currentLevel?.id.description ?? "nil"), phase=\(phase)")
        guard currentLevel?.id == level.id else {
            log("ignored stale preview for level \(level.id); currentLevel=\(currentLevel?.id.description ?? "nil")")
            return
        }
        self.phase = .previewStatic
        HapticsManager.shared.softTick()
        SoundManager.shared.softTick()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.log("previewStatic delay fired for level \(level.id); currentLevel=\(self.currentLevel?.id.description ?? "nil"), phase=\(self.phase)")
            guard self.currentLevel?.id == level.id else {
                self.log("ignored stale preview animation for level \(level.id); currentLevel=\(self.currentLevel?.id.description ?? "nil")")
                return
            }
            self.log("phase previewAnimating")
            self.phase = .previewAnimating
            
            withAnimation(.linear(duration: level.previewDuration)) {
                self.previewProgress = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + level.previewDuration + 0.3) {
                self.log("preview animation complete fired for level \(level.id); currentLevel=\(self.currentLevel?.id.description ?? "nil"), phase=\(self.phase)")
                guard self.currentLevel?.id == level.id else {
                    self.log("ignored stale preview completion for level \(level.id); currentLevel=\(self.currentLevel?.id.description ?? "nil")")
                    return
                }
                self.log("phase waitingForStart")
                HapticsManager.shared.softTick()
                SoundManager.shared.softTick()
                self.phase = .waitingForStart
            }
        }
    }
    
    func handleDragChange(value: DragGesture.Value, level: TraceLevel) {
        guard phase == .waitingForStart || phase == .tracing else { return }
        
        let point = TimedPoint(x: value.location.x / screenSize.width,
                               y: value.location.y / screenSize.height,
                               timestamp: Date().timeIntervalSince1970)
        
        if phase == .waitingForStart {
            // Check if start is valid
            let targetStart = level.pattern.points.first!
            let targetStartPt = CGPoint(x: targetStart.x * screenSize.width, y: targetStart.y * screenSize.height)
            let d = hypot(value.location.x - targetStartPt.x, value.location.y - targetStartPt.y)
            
            if d < 60.0 {
                log("user started trace in zone; distance=\(d), level=\(level.id)")
                phase = .tracing
                startTime = Date()
                userPoints.append(point)
                HapticsManager.shared.softTick()
                SoundManager.shared.softTick()
            } else {
                log("user missed start zone; distance=\(d), level=\(level.id)")
                HapticsManager.shared.warning()
                SoundManager.shared.warning()
                // Do not start
            }
        } else if phase == .tracing {
            userPoints.append(point)
        }
    }
    
    func handleDragEnd(value: DragGesture.Value, level: TraceLevel) {
        guard phase == .tracing else { return }
        
        let point = TimedPoint(x: value.location.x / screenSize.width,
                               y: value.location.y / screenSize.height,
                               timestamp: Date().timeIntervalSince1970)
        userPoints.append(point)
        
        evaluateAttempt(level: level, liftedEarly: false)
    }
    
    func handleEarlyLift() {
        guard phase == .tracing, let level = currentLevel else { return }
        evaluateAttempt(level: level, liftedEarly: true)
    }
    
    private func evaluateAttempt(level: TraceLevel, liftedEarly: Bool) {
        log("evaluateAttempt; level=\(level.id), liftedEarly=\(liftedEarly), points=\(userPoints.count), phase=\(phase)")
        phase = .evaluating
        let attempt = TraceAttempt(
            levelID: level.id,
            userPoints: userPoints,
            startedAt: startTime ?? Date(),
            endedAt: Date(),
            didLiftEarly: liftedEarly
        )
        
        let score = PathScoringEngine.evaluate(attempt: attempt, level: level, screenSize: screenSize, isAssistActive: isAssistModeActive, timeDilationFactor: timeDilationFactor)
        self.currentScore = score
        
        log("evaluation done; didPass=\(score.didPass), total=\(score.total), medal=\(score.medal), assisted=\(score.isAssisted)")
        if score.didPass {
            if score.medal == .perfect {
                HapticsManager.shared.perfect()
                SoundManager.shared.perfect()
            } else {
                HapticsManager.shared.success()
                SoundManager.shared.success()
            }
            ProgressStore.shared.completeLevel(id: level.id, score: score)
            log("completeLevel stored; highestUnlocked=\(ProgressStore.shared.progress.highestUnlockedLevel), resumeLevelID=\(UserDefaults.standard.integer(forKey: "ResumeLevelID"))")
            consecutiveFailures = 0 // Reset failures on successful completion
            self.isAssistModeActive = false
            log("phase result")
            phase = .result
        } else {
            HapticsManager.shared.fail()
            SoundManager.shared.fail()
            ProgressStore.shared.failAttempt(id: level.id, score: score)
            consecutiveFailures += 1 // Increment failures
            log("failure stored; consecutiveFailures=\(consecutiveFailures)")
            log("phase failed")
            phase = .failed
        }
    }
    
    func retry() {
        if let level = currentLevel {
            log("retry requested for level \(level.id)")
            startLevel(level, isRetry: true)
        }
    }
    
    func cheatComplete() {
        guard let level = currentLevel else { return }
        log("cheatComplete activated for level \(level.id)")
        
        let score = TraceScore(
            total: 0.98,
            pathAccuracy: 0.98,
            speed: 1.0,
            smoothness: 1.0,
            didPass: true,
            medal: .perfect,
            failureReason: nil,
            isAssisted: false
        )
        self.currentScore = score
        
        HapticsManager.shared.perfect()
        SoundManager.shared.perfect()
        ProgressStore.shared.completeLevel(id: level.id, score: score)
        consecutiveFailures = 0
        phase = .result
    }
    
    // MARK: - Lifelines
    
    func activateWormhole() {
        guard let level = currentLevel else { return }
        log("lifeline wormhole activated for level \(level.id)")
        
        let score = TraceScore(
            total: level.passThreshold + 0.01,
            pathAccuracy: level.passThreshold + 0.01,
            speed: 0.5,
            smoothness: 0.5,
            didPass: true,
            medal: .pass,
            failureReason: nil,
            isAssisted: true
        )
        self.currentScore = score
        HapticsManager.shared.perfect()
        SoundManager.shared.playWormhole()
        ProgressStore.shared.completeLevel(id: level.id, score: score)
        consecutiveFailures = 0
        phase = .result
    }
    
    func activateZenFreeze() {
        guard let level = currentLevel else { return }
        log("lifeline zen freeze activated for level \(level.id)")
        HapticsManager.shared.softTick()
        SoundManager.shared.playZenFreeze()
        withAnimation {
            timeDilationFactor = 0.5 // Effectively doubles remaining time if implemented in evaluation
        }
        timerBoostDisplayValue = level.maxTraceDuration / timeDilationFactor
        timerBoostPulseToken = UUID()
    }
    
    func activatePhantomGlimpse() {
        log("lifeline phantom glimpse activated")
        HapticsManager.shared.softTick()
        SoundManager.shared.playPhantomGlimpse()
        withAnimation {
            showPhantomGlimpse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                self.showPhantomGlimpse = false
            }
        }
    }
    
    private func log(_ message: String) {
        print("[TraceGameViewModel] \(message)")
    }
}
