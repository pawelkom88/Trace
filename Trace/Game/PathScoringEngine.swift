import Foundation
import CoreGraphics

struct PathScoringEngine {
    
    static func evaluate(attempt: TraceAttempt, level: TraceLevel, screenSize: CGSize, isAssistActive: Bool = false) -> TraceScore {
        let userPoints = attempt.userPoints
        let targetPoints = level.pattern.points
        
        // Timeout check
        let duration = (attempt.endedAt ?? Date()).timeIntervalSince(attempt.startedAt)
        if duration > level.maxTraceDuration {
            return failScore(reason: .timedOut, level: level)
        }
        
        // Early lift check
        if attempt.didLiftEarly {
            return failScore(reason: .liftedTooEarly, level: level)
        }
        
        // Need enough points
        if userPoints.count < 3 {
            return failScore(reason: .endedTooFarAway, level: level)
        }
        
        // Start check
        guard let firstTarget = targetPoints.first, let firstUser = userPoints.first else {
            return failScore(reason: .startedOutsideZone, level: level)
        }
        let startDist = distance(
            p1: CGPoint(x: firstUser.x * screenSize.width, y: firstUser.y * screenSize.height),
            p2: CGPoint(x: firstTarget.x * screenSize.width, y: firstTarget.y * screenSize.height)
        )
        // If they started way off the zone. Start zone is ~24pt wide. Give some padding.
        let allowedStartDist = isAssistActive ? 120.0 : 60.0
        if startDist > allowedStartDist {
            return failScore(reason: .startedOutsideZone, level: level)
        }
        
        // End check
        let lastTarget = targetPoints.last!
        let lastUser = userPoints.last!
        let endDist = distance(
            p1: CGPoint(x: lastUser.x * screenSize.width, y: lastUser.y * screenSize.height),
            p2: CGPoint(x: lastTarget.x * screenSize.width, y: lastTarget.y * screenSize.height)
        )
        
        let endTolerance: Double
        switch level.difficulty {
        case .easy: endTolerance = 120.0
        case .normal: endTolerance = 80.0
        case .hard: endTolerance = 50.0
        case .expert: endTolerance = 30.0
        }
        
        let allowedEndTolerance = isAssistActive ? endTolerance * 2.0 : endTolerance
        if endDist > allowedEndTolerance {
            return failScore(reason: .endedTooFarAway, level: level)
        }
        
        // Resample
        let resampledTarget = resample(points: targetPoints.map { CGPoint(x: $0.x, y: $0.y) }, n: 100)
        let resampledUser = resample(points: userPoints.map { CGPoint(x: $0.x, y: $0.y) }, n: 100)
        
        // Point by point distance
        var totalDist: Double = 0
        var maxDist: Double = 0
        
        for i in 0..<100 {
            let u = resampledUser[i]
            let t = resampledTarget[i]
            
            // convert normalized resampled to screen
            let pu = CGPoint(x: u.x * screenSize.width, y: u.y * screenSize.height)
            let pt = CGPoint(x: t.x * screenSize.width, y: t.y * screenSize.height)
            
            let d = distance(p1: pu, p2: pt)
            totalDist += d
            if d > maxDist { maxDist = d }
        }
        
        let avgDist = totalDist / 100.0
        
        // Path Accuracy: Max score 1.0. Drops as avgDist approaches tolerance.
        let activeTolerance = isAssistActive ? level.tolerance * 2.0 : level.tolerance
        let pathAccuracy = max(0.0, 1.0 - (avgDist / activeTolerance))
        
        // Speed: 1.0 if perfectly halfway through max time.
        let speedScore = max(0.0, 1.0 - (duration / level.maxTraceDuration))
        
        // Smoothness
        let smoothnessScore = 0.95
        
        // Weighted Total
        var total = (pathAccuracy * 0.7) + (speedScore * 0.2) + (smoothnessScore * 0.1)
        
        let didPass = total >= level.passThreshold
        var medal: TraceMedal
        
        if isAssistActive {
            // Apply 0.5x score penalty and lock medal to a standard pass
            total = total * 0.5
            medal = didPass ? .pass : .none
        } else {
            if total >= level.perfectThreshold {
                medal = .perfect
            } else if total >= level.greatThreshold {
                medal = .great
            } else if total >= level.passThreshold {
                medal = .pass
            } else {
                medal = .none
            }
        }
        
        // Strict failure conditions
        if !didPass && avgDist > activeTolerance * 2.0 {
            return failScore(reason: .outsideToleranceTooLong, level: level)
        }
        
        return TraceScore(
            total: total,
            pathAccuracy: pathAccuracy,
            speed: speedScore,
            smoothness: smoothnessScore,
            didPass: didPass,
            medal: medal,
            failureReason: didPass ? nil : .outsideToleranceTooLong,
            isAssisted: isAssistActive
        )
    }
    
    private static func failScore(reason: TraceFailureReason, level: TraceLevel) -> TraceScore {
        return TraceScore(
            total: 0,
            pathAccuracy: 0,
            speed: 0,
            smoothness: 0,
            didPass: false,
            medal: .none,
            failureReason: reason,
            isAssisted: false
        )
    }
    
    // Resample function to get n evenly spaced points
    private static func resample(points: [CGPoint], n: Int) -> [CGPoint] {
        guard points.count > 1 else { return points }
        let I = pathLength(points: points) / Double(n - 1)
        var D: Double = 0
        var srcPts = points
        var newPts = [srcPts.first!]
        var i = 1
        
        while i < srcPts.count {
            let pt1 = srcPts[i - 1]
            let pt2 = srcPts[i]
            let d = distance(p1: pt1, p2: pt2)
            
            if D + d >= I {
                let qx = pt1.x + CGFloat((I - D) / d) * (pt2.x - pt1.x)
                let qy = pt1.y + CGFloat((I - D) / d) * (pt2.y - pt1.y)
                let q = CGPoint(x: qx, y: qy)
                newPts.append(q)
                srcPts.insert(q, at: i)
                D = 0
            } else {
                D += d
            }
            i += 1
        }
        
        if newPts.count < n {
            newPts.append(points.last!)
        }
        
        return newPts
    }
    
    private static func pathLength(points: [CGPoint]) -> Double {
        var d: Double = 0
        for i in 1..<points.count {
            d += distance(p1: points[i - 1], p2: points[i])
        }
        return d
    }
    
    private static func distance(p1: CGPoint, p2: CGPoint) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return Double(sqrt(dx*dx + dy*dy))
    }
}
