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
                
                // Target path (faint if preview done, fully visible during preview, or visible via Phantom Glimpse)
                if viewModel.phase == .previewStatic || viewModel.phase == .previewAnimating || viewModel.showPhantomGlimpse {
                    GlowingPathView(
                        points: level.pattern.points,
                        isLive: false,
                        color: viewModel.showPhantomGlimpse ? DesignSystem.ColorToken.lifelinePhantom.opacity(0.4) : DesignSystem.ColorToken.accentBlue.opacity(0.3),
                        glowColor: viewModel.showPhantomGlimpse ? DesignSystem.ColorToken.lifelinePhantom.opacity(0.2) : DesignSystem.ColorToken.accentBlue.opacity(0.1),
                        progress: viewModel.phase == .previewAnimating ? viewModel.previewProgress : 1.0
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
                
                // Frosted Ice border overlay when Zen Freeze is active!
                if viewModel.timeDilationFactor < 1.0 {
                    ZenFreezeOverlay()
                        .transition(.opacity)
                }
                
                // Pulsing dashed cyan border overlay when Zen Mode (Assist) is active!
                if viewModel.isAssistModeActive {
                    ZenAssistOverlay()
                        .transition(.opacity)
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
            .onChange(of: geometry.size) { oldValue, newValue in
                viewModel.setScreenSize(newValue)
            }
        }
    }
}

struct ZenFreezeOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
            .stroke(
                LinearGradient(
                    colors: [.cyan, .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .shadow(color: .cyan.opacity(isAnimating ? 0.8 : 0.3), radius: isAnimating ? 15 : 6)
            .opacity(isAnimating ? 0.9 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

struct ZenAssistOverlay: View {
    @State private var pulseIntensity = 0.4
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
            .strokeBorder(
                DesignSystem.ColorToken.accentCyan,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [8, 6])
            )
            .shadow(color: DesignSystem.ColorToken.accentCyan.opacity(pulseIntensity), radius: pulseIntensity * 10, x: 0, y: 0)
            .opacity(pulseIntensity + 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseIntensity = 0.8
                }
            }
    }
}
