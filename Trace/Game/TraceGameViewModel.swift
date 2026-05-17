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
    @Published var isAssistModeActive = false
    
    private var startTime: Date?
    private var screenSize: CGSize = .zero
    
    func startLevel(_ level: TraceLevel, isRetry: Bool = false) {
        print("TraceGameViewModel: startLevel \(level.id) (isRetry: \(isRetry))")
        
        // Reset assists and failures if we switch levels or if starting fresh
        if level.id != currentLevel?.id || !isRetry {
            self.consecutiveFailures = 0
            self.isAssistModeActive = false
        }
        
        self.currentLevel = level
        self.userPoints = []
        self.currentScore = nil
        self.previewProgress = 0.0
        
        let previewOnEveryTry = UserDefaults.standard.object(forKey: "PreviewOnEveryTry") as? Bool ?? true
        
        if isRetry && !previewOnEveryTry {
            print("TraceGameViewModel: Skipping preview sequence on retry")
            self.phase = .waitingForStart
        } else {
            self.phase = .preparingLevel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.runPreviewSequence(level)
            }
        }
    }
    
    func setScreenSize(_ size: CGSize) {
        self.screenSize = size
    }
    
    private func runPreviewSequence(_ level: TraceLevel) {
        print("TraceGameViewModel: runPreviewSequence")
        self.phase = .previewStatic
        HapticsManager.shared.softTick()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("TraceGameViewModel: phase previewAnimating")
            self.phase = .previewAnimating
            
            withAnimation(.linear(duration: level.previewDuration)) {
                self.previewProgress = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + level.previewDuration + 0.3) {
                print("TraceGameViewModel: phase waitingForStart")
                HapticsManager.shared.softTick()
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
                print("TraceGameViewModel: User tapped start zone correctly. Moving to tracing phase.")
                phase = .tracing
                startTime = Date()
                userPoints.append(point)
                HapticsManager.shared.softTick()
            } else {
                print("TraceGameViewModel: User missed start zone. Distance: \(d)")
                HapticsManager.shared.warning()
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
        print("TraceGameViewModel: evaluateAttempt, liftedEarly: \(liftedEarly)")
        phase = .evaluating
        let attempt = TraceAttempt(
            levelID: level.id,
            userPoints: userPoints,
            startedAt: startTime ?? Date(),
            endedAt: Date(),
            didLiftEarly: liftedEarly
        )
        
        let score = PathScoringEngine.evaluate(attempt: attempt, level: level, screenSize: screenSize, isAssistActive: isAssistModeActive)
        self.currentScore = score
        
        print("TraceGameViewModel: Evaluation done. didPass: \(score.didPass), total: \(score.total), assisted: \(score.isAssisted)")
        if score.didPass {
            if score.medal == .perfect {
                HapticsManager.shared.perfect()
            } else {
                HapticsManager.shared.success()
            }
            ProgressStore.shared.completeLevel(id: level.id, score: score)
            consecutiveFailures = 0 // Reset failures on successful completion
            phase = .result
        } else {
            HapticsManager.shared.fail()
            ProgressStore.shared.failAttempt(id: level.id, score: score)
            consecutiveFailures += 1 // Increment failures
            print("TraceGameViewModel: Failure incremented. Consecutive Failures: \(consecutiveFailures)")
            phase = .failed
        }
    }
    
    func retry() {
        if let level = currentLevel {
            startLevel(level, isRetry: true)
        }
    }
}
