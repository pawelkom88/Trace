import SwiftUI

struct VictoryView: View {
    var onDismiss: () -> Void
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("GAME COMPLETE")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(pop ? 1.0 : 0.88)

                Text("All 50 levels cleared")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text("+200 GEMS")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.ColorToken.gemPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(DesignSystem.ColorToken.gemPrimary.opacity(0.15))
                    .cornerRadius(14)

                Text("Reward added to your account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.ColorToken.accentCyan)

                Button(action: onDismiss) {
                    Text("Back Home")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.ColorToken.accentCyan)
                        .cornerRadius(28)
                }
                .padding(.top, 8)
            }
            .padding(28)
            .background(DesignSystem.ColorToken.backgroundSecondary)
            .cornerRadius(24)
            .padding(.horizontal, 24)

            ConfettiOverlayView()
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
                pop = true
            }
        }
    }
}

private struct ConfettiOverlayView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<40, id: \.self) { i in
                Capsule()
                    .fill(i % 2 == 0 ? DesignSystem.ColorToken.accentCyan : DesignSystem.ColorToken.gemPrimary)
                    .frame(width: 6, height: 12)
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: animate ? geo.size.height + 40 : -20
                    )
                    .animation(
                        .linear(duration: Double.random(in: 1.4...2.4))
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.04),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
