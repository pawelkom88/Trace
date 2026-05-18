import Foundation

struct LevelRepository {
    static let shared = LevelRepository()
    let levels: [TraceLevel]
    
    init() {
        self.levels = LevelRepository.generateLevels()
    }
    
    func level(for id: Int) -> TraceLevel? {
        return levels.first { $0.id == id }
    }
    
    static func generateLevels() -> [TraceLevel] {
        var generatedLevels: [TraceLevel] = []
        
        // Helper to create a level
        func createLevel(id: Int, title: String, diff: TraceDifficulty, points: [NormalizedPoint]) {
            let maxTrace: TimeInterval
            let tolerance: Double
            let endZone: EndZoneVisibility
            
            maxTrace = 3.5
            switch diff {
            case .easy:
                tolerance = 44.0
                endZone = .visible
            case .normal:
                tolerance = 32.0
                endZone = .faint
            case .hard:
                tolerance = 22.0
                endZone = .hidden
            case .expert:
                tolerance = 14.0
                endZone = .hidden
            }
            
            let pass: Double
            let great: Double
            let perfect: Double
            
            switch diff {
            case .easy: pass = 0.65; great = 0.85; perfect = 0.95
            case .normal: pass = 0.70; great = 0.88; perfect = 0.96
            case .hard: pass = 0.80; great = 0.90; perfect = 0.97
            case .expert: pass = 0.88; great = 0.94; perfect = 0.98
            }
            
            let level = TraceLevel(
                id: id,
                title: title,
                difficulty: diff,
                pattern: TracePattern(points: points),
                previewDuration: 1.5,
                maxTraceDuration: maxTrace,
                passThreshold: pass,
                greatThreshold: great,
                perfectThreshold: perfect,
                tolerance: tolerance,
                endZoneVisibility: endZone
            )
            generatedLevels.append(level)
        }
        
        // Reusable Pattern Generators
        func straight(x1: Double, y1: Double, x2: Double, y2: Double) -> [NormalizedPoint] {
            return [NormalizedPoint(x: x1, y: y1), NormalizedPoint(x: x2, y: y2)]
        }
        
        func curve(x1: Double, y1: Double, cx: Double, cy: Double, x2: Double, y2: Double, segments: Int = 20) -> [NormalizedPoint] {
            var pts: [NormalizedPoint] = []
            for i in 0...segments {
                let t = Double(i) / Double(segments)
                let invT = 1.0 - t
                let px = invT * invT * x1 + 2 * invT * t * cx + t * t * x2
                let py = invT * invT * y1 + 2 * invT * t * cy + t * t * y2
                pts.append(NormalizedPoint(x: px, y: py))
            }
            return pts
        }
        
        func lShape() -> [NormalizedPoint] {
            return [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.2, y: 0.8), NormalizedPoint(x: 0.8, y: 0.8)]
        }
        
        func vShape() -> [NormalizedPoint] {
            return [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.5, y: 0.8), NormalizedPoint(x: 0.8, y: 0.2)]
        }
        
        func zShape() -> [NormalizedPoint] {
            return [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.8, y: 0.2), NormalizedPoint(x: 0.2, y: 0.8), NormalizedPoint(x: 0.8, y: 0.8)]
        }
        
        func sCurve() -> [NormalizedPoint] {
            var pts: [NormalizedPoint] = []
            pts.append(contentsOf: curve(x1: 0.8, y1: 0.2, cx: 0.2, cy: 0.2, x2: 0.5, y2: 0.5))
            pts.append(contentsOf: curve(x1: 0.5, y1: 0.5, cx: 0.8, cy: 0.8, x2: 0.2, y2: 0.8))
            return pts
        }
        
        // Levels 1-15: Free (Easy to Normal)
        createLevel(id: 1, title: "The Line", diff: .easy, points: straight(x1: 0.5, y1: 0.2, x2: 0.5, y2: 0.8))
        createLevel(id: 2, title: "Across", diff: .easy, points: straight(x1: 0.2, y1: 0.5, x2: 0.8, y2: 0.5))
        createLevel(id: 3, title: "Diagonal", diff: .easy, points: straight(x1: 0.2, y1: 0.2, x2: 0.8, y2: 0.8))
        createLevel(id: 4, title: "Slide", diff: .easy, points: straight(x1: 0.8, y1: 0.2, x2: 0.2, y2: 0.8))
        createLevel(id: 5, title: "Gentle Arc", diff: .easy, points: curve(x1: 0.2, y1: 0.5, cx: 0.5, cy: 0.2, x2: 0.8, y2: 0.5))
        createLevel(id: 6, title: "L-Shape", diff: .normal, points: lShape())
        createLevel(id: 7, title: "V-Shape", diff: .normal, points: vShape())
        createLevel(id: 8, title: "Z-Shape", diff: .normal, points: zShape())
        createLevel(id: 9, title: "S-Curve", diff: .normal, points: sCurve())
        createLevel(id: 10, title: "U-Turn", diff: .normal, points: curve(x1: 0.3, y1: 0.3, cx: 0.5, cy: 0.9, x2: 0.7, y2: 0.3))
        
        // Level 11: Completely unique "Wobble" pattern
        createLevel(id: 11, title: "Wobble", diff: .normal, points: [
            NormalizedPoint(x: 0.2, y: 0.5),
            NormalizedPoint(x: 0.4, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.8),
            NormalizedPoint(x: 0.8, y: 0.5)
        ])
        
        createLevel(id: 12, title: "Staircase", diff: .normal, points: [NormalizedPoint(x: 0.2, y: 0.2), NormalizedPoint(x: 0.4, y: 0.2), NormalizedPoint(x: 0.4, y: 0.5), NormalizedPoint(x: 0.6, y: 0.5), NormalizedPoint(x: 0.6, y: 0.8), NormalizedPoint(x: 0.8, y: 0.8)])
        
        // Level 13: Completely unique "Square Spiral"
        createLevel(id: 13, title: "Square Spiral", diff: .normal, points: [
            NormalizedPoint(x: 0.8, y: 0.8),
            NormalizedPoint(x: 0.2, y: 0.8),
            NormalizedPoint(x: 0.2, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.6),
            NormalizedPoint(x: 0.4, y: 0.6)
        ])
        
        createLevel(id: 14, title: "Hook", diff: .normal, points: [NormalizedPoint(x: 0.5, y: 0.2), NormalizedPoint(x: 0.5, y: 0.7)] + curve(x1: 0.5, y1: 0.7, cx: 0.5, cy: 0.9, x2: 0.3, y2: 0.8))
        createLevel(id: 15, title: "Loop", diff: .normal, points: curve(x1: 0.3, y1: 0.5, cx: 0.1, cy: 0.1, x2: 0.5, y2: 0.2) + curve(x1: 0.5, y1: 0.2, cx: 0.9, cy: 0.3, x2: 0.7, y2: 0.6))
        
        // Levels 16-50: Premium (Normal, Hard, Expert) with Weekly Rotation
        // Seed based on current week and year
        let calendar = Calendar.current
        let date = Date()
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        
        // Simple Linear Congruential Generator for reproducible random patterns per week
        struct SeededGenerator {
            var state: UInt64
            init(seed: Int) { self.state = UInt64(seed) }
            mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                let fraction = Double(state >> 11) * (1.0 / 9007199254740991.0)
                return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
            }
        }
        
        for id in 16...50 {
            // Difficulty ramps up
            let diff: TraceDifficulty
            if id < 30 { diff = .normal }
            else if id < 42 { diff = .hard }
            else { diff = .expert }
            
            // Unique seed for each level that changes weekly
            let levelSeed = year * 1000 + week * 100 + id
            var rng = SeededGenerator(seed: levelSeed)
            
            // Complexity increases with level ID
            let minPoints = 3 + (id - 16) / 8 // Ramps up point count
            let maxPoints = minPoints + 2
            let pointCount = Int(rng.nextDouble(in: Double(minPoints)...Double(maxPoints)))
            
            var generatedPoints: [NormalizedPoint] = []
            
            // Determine if this is a sharp zigzag shape or a smooth curve sequence
            let isSmooth = rng.nextDouble(in: 0...1) > 0.5
            
            if isSmooth {
                var currentX = rng.nextDouble(in: 0.2...0.8)
                var currentY = rng.nextDouble(in: 0.2...0.8)
                
                for _ in 0..<pointCount {
                    let nextX = rng.nextDouble(in: 0.1...0.9)
                    let nextY = rng.nextDouble(in: 0.1...0.9)
                    let cx = rng.nextDouble(in: 0.1...0.9)
                    let cy = rng.nextDouble(in: 0.1...0.9)
                    
                    let newSegment = curve(x1: currentX, y1: currentY, cx: cx, cy: cy, x2: nextX, y2: nextY)
                    if generatedPoints.isEmpty {
                        generatedPoints.append(contentsOf: newSegment)
                    } else {
                        // avoid duplicating the connecting point
                        generatedPoints.append(contentsOf: newSegment.dropFirst())
                    }
                    
                    currentX = nextX
                    currentY = nextY
                }
            } else {
                for _ in 0...pointCount {
                    generatedPoints.append(NormalizedPoint(
                        x: rng.nextDouble(in: 0.15...0.85),
                        y: rng.nextDouble(in: 0.15...0.85)
                    ))
                }
            }
            
            createLevel(id: id, title: "Week \(week) - \(id)", diff: diff, points: generatedPoints)
        }
        
        return generatedLevels
    }
}
