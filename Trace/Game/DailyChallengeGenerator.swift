import Foundation

class DailyChallengeGenerator {
    static func generateTodaysLevels() -> [TraceLevel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // Simple hash of date string to use as a seed
        let seed = abs(dateString.hashValue)
        
        // Generate 3 patterns
        var levels: [TraceLevel] = []
        
        for i in 0..<3 {
            let id = 1000 + i
            // Pseudo-random generation based on seed + i
            let r = (seed + i * 100) % 5
            
            let points: [NormalizedPoint]
            if r == 0 {
                points = [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.8, y: 0.8)]
            } else if r == 1 {
                points = [NormalizedPoint(x: 0.2, y: 0.5), NormalizedPoint(x: 0.5, y: 0.2), NormalizedPoint(x: 0.8, y: 0.5)]
            } else if r == 2 {
                points = [NormalizedPoint(x: 0.2, y: 0.8), NormalizedPoint(x: 0.5, y: 0.5), NormalizedPoint(x: 0.8, y: 0.8)]
            } else if r == 3 {
                points = [NormalizedPoint(x: 0.5, y: 0.2), NormalizedPoint(x: 0.5, y: 0.8)]
            } else {
                points = [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.8, y: 0.2), NormalizedPoint(x: 0.2, y: 0.8)]
            }
            
            let level = TraceLevel(
                id: id,
                title: "Daily \(i+1)",
                difficulty: .normal,
                pattern: TracePattern(points: points),
                previewDuration: 1.5,
                maxTraceDuration: 4.0,
                passThreshold: 0.70,
                greatThreshold: 0.88,
                perfectThreshold: 0.96,
                tolerance: 32.0,
                endZoneVisibility: .faint
            )
            levels.append(level)
        }
        
        return levels
    }
}
