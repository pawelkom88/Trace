import SwiftUI

struct GlowingPathView: View {
    let points: [NormalizedPoint]
    let isLive: Bool
    let color: Color
    let glowColor: Color
    var progress: CGFloat = 1.0 // For drawing animation
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let scaledPoints = points.map { CGPoint(x: $0.x * width, y: $0.y * height) }
            
            if scaledPoints.count > 1 {
                ZStack {
                    // Glow
                    Path { path in
                        path.move(to: scaledPoints[0])
                        for point in scaledPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .trim(from: 0, to: progress)
                    .stroke(
                        glowColor.opacity(0.4),
                        style: StrokeStyle(
                            lineWidth: DesignSystem.Stroke.glowPathWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .blur(radius: 8)
                    
                    // Core line
                    Path { path in
                        path.move(to: scaledPoints[0])
                        for point in scaledPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: isLive ? DesignSystem.Stroke.livePathWidth : DesignSystem.Stroke.targetPathWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
    }
}
