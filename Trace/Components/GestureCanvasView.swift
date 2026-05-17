import SwiftUI

struct GestureCanvasView: View {
    @ObservedObject var viewModel: TraceGameViewModel
    @AppStorage("GridAssistEnabled") private var isGridEnabled = false
    let level: TraceLevel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear // Transparent background to catch touches
                
                if isGridEnabled {
                    DotGridView()
                        .transition(.opacity)
                }
                
                // Target path (faint if preview done, fully visible during preview)
                if viewModel.phase == .previewStatic || viewModel.phase == .previewAnimating {
                    GlowingPathView(
                        points: level.pattern.points,
                        isLive: false,
                        color: DesignSystem.ColorToken.accentBlue.opacity(0.3),
                        glowColor: DesignSystem.ColorToken.accentBlue.opacity(0.1),
                        progress: viewModel.phase == .previewAnimating ? viewModel.previewProgress : 0.0
                    )
                }
                
                // User trail
                if viewModel.userPoints.count > 1 && viewModel.phase == .tracing {
                    GlowingPathView(
                        points: viewModel.userPoints.map { NormalizedPoint(x: $0.x, y: $0.y) },
                        isLive: true,
                        color: DesignSystem.ColorToken.accentCyan,
                        glowColor: DesignSystem.ColorToken.accentCyan.opacity(0.6),
                        progress: 1.0
                    )
                }
                
                // Start and End dots
                if let first = level.pattern.points.first {
                    StartEndDotView(
                        position: first,
                        isStart: true,
                        isActive: viewModel.phase == .waitingForStart,
                        visibility: .visible
                    )
                }
                
                if let last = level.pattern.points.last {
                    StartEndDotView(
                        position: last,
                        isStart: false,
                        isActive: false,
                        visibility: viewModel.phase == .tracing ? level.endZoneVisibility : .hidden
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.handleDragChange(value: value, level: level)
                    }
                    .onEnded { value in
                        if viewModel.phase == .tracing {
                            // Let's assume if it ends, user lifted early or finished
                            // We do handleDragEnd first, then check if it was early lift
                            // Actually, handleDragEnd in VM decides if it's fail or not based on End Zone.
                            viewModel.handleDragEnd(value: value, level: level)
                        } else {
                            viewModel.handleEarlyLift()
                        }
                    }
            )
            .onAppear {
                viewModel.setScreenSize(geometry.size)
            }
        }
    }
}
