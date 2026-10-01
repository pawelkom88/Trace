import Foundation

final class LevelVariantStore {
    static let shared = LevelVariantStore()

    private let defaults = UserDefaults.standard
    private let lockedVariantsKey = "LockedLevelVariants"
    private let variantCount = 3

    private init() {}

    func variantIndex(for levelID: Int) -> Int {
        if let lockedIndex = lockedVariants()[levelID] {
            return lockedIndex
        }
        return dailyVariantIndex(for: levelID)
    }

    func lockVariant(_ variantIndex: Int, for levelID: Int) {
        var variants = lockedVariants()
        variants[levelID] = variantIndex
        saveLockedVariants(variants)
    }

    func clearLockedVariant(for levelID: Int) {
        var variants = lockedVariants()
        variants.removeValue(forKey: levelID)
        saveLockedVariants(variants)
    }

    func clearAllLockedVariants() {
        defaults.removeObject(forKey: lockedVariantsKey)
    }

    private func dailyVariantIndex(for levelID: Int) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let dayNumber = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: startOfDay).day ?? 0
        return abs(dayNumber + levelID) % variantCount
    }

    private func lockedVariants() -> [Int: Int] {
        guard let data = defaults.data(forKey: lockedVariantsKey),
              let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveLockedVariants(_ variants: [Int: Int]) {
        if let data = try? JSONEncoder().encode(variants) {
            defaults.set(data, forKey: lockedVariantsKey)
        }
    }
}

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

        func createLevel(id: Int, title: String, diff: TraceDifficulty, points: [NormalizedPoint]) {
            let maxTrace: TimeInterval = 3.5
            let tolerance: Double
            let endZone: EndZoneVisibility

            switch diff {
            case .easy:
                tolerance = 44.0
                endZone = .visible
            case .normal:
                tolerance = 32.0
                endZone = .faint
            case .hard:
                tolerance = 20.0
                endZone = .hidden
            case .expert:
                tolerance = 13.0
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

            let variantIndex = LevelVariantStore.shared.variantIndex(for: id)
            let level = TraceLevel(
                id: id,
                variantIndex: variantIndex,
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

        func variant(_ base: [NormalizedPoint], index: Int) -> [NormalizedPoint] {
            switch index {
            case 1:
                return base.map { NormalizedPoint(x: 1.0 - $0.x, y: $0.y) }
            case 2:
                return base.map { NormalizedPoint(x: $0.y, y: $0.x) }
            default:
                return base
            }
        }

        func selectedFreePattern(id: Int, base: [NormalizedPoint]) -> [NormalizedPoint] {
            if id <= 4 {
                return base
            }

            let variantIndex = LevelVariantStore.shared.variantIndex(for: id)
            return variant(base, index: variantIndex)
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

        func gridPoint(_ column: Int, _ row: Int) -> NormalizedPoint {
            let columns = 6.0
            let rows = 6.0
            return NormalizedPoint(
                x: 0.10 + (Double(column) / columns) * 0.80,
                y: 0.10 + (Double(row) / rows) * 0.80
            )
        }

        func bonusPattern(id: Int) -> [NormalizedPoint] {
            switch id {
            case 51:
                return [gridPoint(0, 0), gridPoint(6, 0), gridPoint(6, 6), gridPoint(0, 6), gridPoint(0, 2), gridPoint(4, 2), gridPoint(4, 4), gridPoint(2, 4)]
            case 52:
                return [gridPoint(0, 1), gridPoint(2, 1), gridPoint(2, 0), gridPoint(4, 0), gridPoint(4, 2), gridPoint(6, 2), gridPoint(6, 4), gridPoint(3, 4), gridPoint(3, 6), gridPoint(0, 6)]
            case 53:
                return [gridPoint(1, 0), gridPoint(1, 6), gridPoint(2, 6), gridPoint(2, 1), gridPoint(3, 1), gridPoint(3, 6), gridPoint(4, 6), gridPoint(4, 0), gridPoint(5, 0), gridPoint(5, 6)]
            case 54:
                return [gridPoint(0, 3), gridPoint(3, 0), gridPoint(6, 3), gridPoint(3, 6), gridPoint(1, 4), gridPoint(5, 4), gridPoint(5, 2), gridPoint(1, 2), gridPoint(3, 0)]
            case 55:
                return [gridPoint(0, 0), gridPoint(6, 0), gridPoint(6, 1), gridPoint(1, 1), gridPoint(1, 5), gridPoint(5, 5), gridPoint(5, 2), gridPoint(2, 2), gridPoint(2, 6), gridPoint(6, 6)]
            case 56:
                return [gridPoint(0, 6), gridPoint(0, 0), gridPoint(6, 0), gridPoint(6, 6), gridPoint(5, 6), gridPoint(5, 1), gridPoint(1, 1), gridPoint(1, 5), gridPoint(4, 5), gridPoint(4, 2), gridPoint(2, 2)]
            case 57:
                return [gridPoint(0, 2), gridPoint(6, 2), gridPoint(6, 0), gridPoint(4, 0), gridPoint(4, 6), gridPoint(2, 6), gridPoint(2, 0), gridPoint(0, 0), gridPoint(0, 4), gridPoint(6, 4)]
            case 58:
                return [gridPoint(3, 0), gridPoint(6, 0), gridPoint(6, 3), gridPoint(3, 3), gridPoint(3, 6), gridPoint(0, 6), gridPoint(0, 3), gridPoint(2, 3), gridPoint(2, 1), gridPoint(5, 1)]
            case 59:
                return [gridPoint(0, 0), gridPoint(6, 6), gridPoint(6, 4), gridPoint(2, 4), gridPoint(2, 2), gridPoint(6, 2), gridPoint(6, 0), gridPoint(0, 6)]
            case 60:
                return [gridPoint(0, 5), gridPoint(1, 5), gridPoint(1, 1), gridPoint(2, 1), gridPoint(2, 5), gridPoint(3, 5), gridPoint(3, 1), gridPoint(4, 1), gridPoint(4, 5), gridPoint(5, 5), gridPoint(5, 1), gridPoint(6, 1)]
            case 61:
                return [gridPoint(0, 3), gridPoint(2, 3), gridPoint(2, 0), gridPoint(4, 0), gridPoint(4, 3), gridPoint(6, 3), gridPoint(6, 6), gridPoint(3, 6), gridPoint(3, 2), gridPoint(1, 2), gridPoint(1, 5)]
            case 62:
                return [gridPoint(0, 0), gridPoint(3, 0), gridPoint(3, 2), gridPoint(6, 2), gridPoint(6, 6), gridPoint(4, 6), gridPoint(4, 4), gridPoint(1, 4), gridPoint(1, 1), gridPoint(5, 1), gridPoint(5, 5)]
            case 63:
                return [gridPoint(0, 6), gridPoint(6, 0), gridPoint(4, 0), gridPoint(4, 4), gridPoint(6, 4), gridPoint(6, 6), gridPoint(2, 6), gridPoint(2, 2), gridPoint(0, 2), gridPoint(0, 0), gridPoint(3, 0)]
            case 64:
                return [gridPoint(0, 1), gridPoint(6, 1), gridPoint(6, 5), gridPoint(0, 5), gridPoint(0, 3), gridPoint(4, 3), gridPoint(4, 0), gridPoint(2, 0), gridPoint(2, 6), gridPoint(5, 6), gridPoint(5, 2)]
            default:
                return [gridPoint(0, 0), gridPoint(6, 0), gridPoint(6, 6), gridPoint(0, 6), gridPoint(0, 1), gridPoint(5, 1), gridPoint(5, 5), gridPoint(1, 5), gridPoint(1, 2), gridPoint(4, 2), gridPoint(4, 4), gridPoint(2, 4), gridPoint(2, 3), gridPoint(3, 3)]
            }
        }

        func curatedProgressionPattern(id: Int) -> [NormalizedPoint]? {
            switch id {
            case 16:
                return [gridPoint(1, 1), gridPoint(5, 1), gridPoint(5, 4), gridPoint(2, 4)]
            case 18:
                return [gridPoint(1, 5), gridPoint(1, 2), gridPoint(4, 2), gridPoint(4, 4), gridPoint(6, 4)]
            case 26:
                return [gridPoint(0, 3), gridPoint(3, 3), gridPoint(3, 1), gridPoint(6, 1), gridPoint(6, 5)]
            case 31:
                return [gridPoint(1, 1), gridPoint(5, 1), gridPoint(5, 5), gridPoint(2, 5), gridPoint(2, 3)]
            case 32:
                return [gridPoint(0, 2), gridPoint(2, 2), gridPoint(2, 5), gridPoint(5, 5), gridPoint(5, 1)]
            case 34:
                return [gridPoint(1, 0), gridPoint(1, 4), gridPoint(4, 4), gridPoint(4, 2), gridPoint(6, 2)]
            case 36:
                return [gridPoint(0, 5), gridPoint(3, 5), gridPoint(3, 2), gridPoint(6, 2), gridPoint(6, 0)]
            case 37:
                return [gridPoint(1, 1), gridPoint(5, 1), gridPoint(5, 3), gridPoint(2, 3), gridPoint(2, 6), gridPoint(6, 6)]
            case 40:
                return [gridPoint(0, 5), gridPoint(2, 3), gridPoint(0, 1), gridPoint(3, 1), gridPoint(6, 4), gridPoint(4, 6), gridPoint(1, 3)]
            case 47:
                return [gridPoint(0, 0), gridPoint(3, 3), gridPoint(6, 0), gridPoint(6, 2), gridPoint(2, 6), gridPoint(0, 4), gridPoint(4, 0)]
            case 50:
                return [gridPoint(0, 6), gridPoint(2, 4), gridPoint(0, 2), gridPoint(2, 0), gridPoint(6, 4), gridPoint(4, 6), gridPoint(1, 3), gridPoint(5, 1)]
            default:
                return nil
            }
        }

        func seededPattern(id: Int, diff: TraceDifficulty, variantIndex: Int) -> [NormalizedPoint] {
            struct SeededGenerator {
                var state: UInt64

                init(seed: Int) {
                    self.state = UInt64(seed)
                }

                mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
                    state = state &* 6364136223846793005 &+ 1442695040888963407
                    let fraction = Double(state >> 11) * (1.0 / 9007199254740991.0)
                    return range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                }
            }

            let seed = id * 1000 + variantIndex * 97
            var rng = SeededGenerator(seed: seed)

            let basePointCount: Int
            switch diff {
            case .easy:
                basePointCount = 2
            case .normal:
                basePointCount = 3 + (id - 16) / 10
            case .hard:
                basePointCount = 5 + (id - 30) / 6
            case .expert:
                basePointCount = 7 + (id - 42) / 4
            }

            let pointCount = max(2, min(basePointCount + Int(rng.nextDouble(in: 0...2)), 9))
            let isSmooth = rng.nextDouble(in: 0...1) > 0.5
            var generatedPoints: [NormalizedPoint] = []

            if isSmooth {
                var currentX = rng.nextDouble(in: 0.2...0.8)
                var currentY = rng.nextDouble(in: 0.2...0.8)

                for _ in 0..<pointCount {
                    let nextX = rng.nextDouble(in: 0.1...0.9)
                    let nextY = rng.nextDouble(in: 0.1...0.9)
                    let cx = rng.nextDouble(in: 0.1...0.9)
                    let cy = rng.nextDouble(in: 0.1...0.9)
                    let segment = curve(x1: currentX, y1: currentY, cx: cx, cy: cy, x2: nextX, y2: nextY)

                    if generatedPoints.isEmpty {
                        generatedPoints.append(contentsOf: segment)
                    } else {
                        generatedPoints.append(contentsOf: segment.dropFirst())
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

            return generatedPoints
        }

        createLevel(id: 1, title: "The Line", diff: .easy, points: selectedFreePattern(id: 1, base: straight(x1: 0.5, y1: 0.2, x2: 0.5, y2: 0.8)))
        createLevel(id: 2, title: "Across", diff: .easy, points: selectedFreePattern(id: 2, base: straight(x1: 0.2, y1: 0.5, x2: 0.8, y2: 0.5)))
        createLevel(id: 3, title: "Diagonal", diff: .easy, points: selectedFreePattern(id: 3, base: straight(x1: 0.2, y1: 0.2, x2: 0.8, y2: 0.8)))
        createLevel(id: 4, title: "Slide", diff: .easy, points: selectedFreePattern(id: 4, base: straight(x1: 0.8, y1: 0.2, x2: 0.2, y2: 0.8)))
        createLevel(id: 5, title: "Gentle Arc", diff: .easy, points: selectedFreePattern(id: 5, base: curve(x1: 0.2, y1: 0.5, cx: 0.5, cy: 0.2, x2: 0.8, y2: 0.5)))
        createLevel(id: 6, title: "L-Shape", diff: .normal, points: selectedFreePattern(id: 6, base: lShape()))
        createLevel(id: 7, title: "V-Shape", diff: .normal, points: selectedFreePattern(id: 7, base: vShape()))
        createLevel(id: 8, title: "Z-Shape", diff: .normal, points: selectedFreePattern(id: 8, base: zShape()))
        createLevel(id: 9, title: "S-Curve", diff: .normal, points: selectedFreePattern(id: 9, base: sCurve()))
        createLevel(id: 10, title: "U-Turn", diff: .normal, points: selectedFreePattern(id: 10, base: curve(x1: 0.3, y1: 0.3, cx: 0.5, cy: 0.9, x2: 0.7, y2: 0.3)))
        createLevel(id: 11, title: "Wobble", diff: .normal, points: selectedFreePattern(id: 11, base: [
            NormalizedPoint(x: 0.2, y: 0.5),
            NormalizedPoint(x: 0.4, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.8),
            NormalizedPoint(x: 0.8, y: 0.5)
        ]))
        createLevel(id: 12, title: "Staircase", diff: .normal, points: selectedFreePattern(id: 12, base: [
            NormalizedPoint(x: 0.2, y: 0.2),
            NormalizedPoint(x: 0.4, y: 0.2),
            NormalizedPoint(x: 0.4, y: 0.5),
            NormalizedPoint(x: 0.6, y: 0.5),
            NormalizedPoint(x: 0.6, y: 0.8),
            NormalizedPoint(x: 0.8, y: 0.8)
        ]))
        createLevel(id: 13, title: "Square Spiral", diff: .normal, points: selectedFreePattern(id: 13, base: [
            NormalizedPoint(x: 0.8, y: 0.8),
            NormalizedPoint(x: 0.2, y: 0.8),
            NormalizedPoint(x: 0.2, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.2),
            NormalizedPoint(x: 0.6, y: 0.6),
            NormalizedPoint(x: 0.4, y: 0.6)
        ]))
        createLevel(id: 14, title: "Hook", diff: .normal, points: selectedFreePattern(id: 14, base: [NormalizedPoint(x: 0.5, y: 0.2), NormalizedPoint(x: 0.5, y: 0.7)] + curve(x1: 0.5, y1: 0.7, cx: 0.5, cy: 0.9, x2: 0.3, y2: 0.8)))
        createLevel(id: 15, title: "Loop", diff: .normal, points: selectedFreePattern(id: 15, base: curve(x1: 0.3, y1: 0.5, cx: 0.1, cy: 0.1, x2: 0.5, y2: 0.2) + curve(x1: 0.5, y1: 0.2, cx: 0.9, cy: 0.3, x2: 0.7, y2: 0.6)))

        for id in 16...50 {
            let diff: TraceDifficulty
            if id < 30 {
                diff = .normal
            } else if id < 42 {
                diff = .hard
            } else {
                diff = .expert
            }

            let variantIndex = LevelVariantStore.shared.variantIndex(for: id)
            let points = if let curatedPattern = curatedProgressionPattern(id: id) {
                variant(curatedPattern, index: variantIndex)
            } else {
                seededPattern(id: id, diff: diff, variantIndex: variantIndex)
            }

            createLevel(
                id: id,
                title: "Pattern \(id)",
                diff: diff,
                points: points
            )
        }

        for id in 51...65 {
            let variantIndex = LevelVariantStore.shared.variantIndex(for: id)
            createLevel(
                id: id,
                title: "Speed Path \(id)",
                diff: .expert,
                points: variant(bonusPattern(id: id), index: variantIndex)
            )
        }

        return generatedLevels
    }
}
