import SwiftUI

struct StartEndDotView: View {
    let position: NormalizedPoint
    let isStart: Bool
    let isActive: Bool
    let visibility: EndZoneVisibility
    
    var body: some View {
        GeometryReader { geometry in
            let x = position.x * geometry.size.width
            let y = position.y * geometry.size.height
            let size = isStart ? DesignSystem.Stroke.startDotSize : DesignSystem.Stroke.endDotSize
            
            if visibility != .hidden || isStart {
                ZStack {
                    Circle()
                        .fill(isStart ? DesignSystem.ColorToken.accentCyan : DesignSystem.ColorToken.accentBlue)
                        .frame(width: size, height: size)
                        .shadow(
                            color: (isStart ? DesignSystem.ColorToken.accentCyan : DesignSystem.ColorToken.accentBlue).opacity(isActive ? 0.8 : 0.4),
                            radius: isActive ? 12 : 6
                        )
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .opacity(visibility == .faint && !isStart ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: DesignSystem.AnimationDuration.normal).repeatForever(autoreverses: true), value: isActive)
                }
                .position(x: x, y: y)
            }
        }
    }
}
