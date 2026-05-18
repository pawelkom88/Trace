import SwiftUI

struct LifelineExplainerModal: View {
    let lifeline: LifelineType
    let gems: Int
    let onUse: () -> Void
    let onCancel: () -> Void
    let onBuyGems: () -> Void
    
    @State private var animateCard = false
    
    var body: some View {
        ZStack {
            // Darkened backing blur to isolate the modal
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Explainer Card
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header (Close X Button)
                HStack {
                    Spacer()
                    Button(action: { dismissModal() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Icon and Title
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(lifelineColor.opacity(0.15))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: lifeline.iconSystemName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(lifelineColor)
                            .shadow(color: lifelineColor.opacity(0.5), radius: 8)
                    }
                    
                    Text(lifeline.name.uppercased())
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.ColorToken.gemPrimary)
                        Text("\(lifeline.gemCost) Gems")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.ColorToken.accentCyan)
                    }
                }
                
                // Live Interactive Animation Preview Area
                VStack {
                    Spacer()
                    animationPreview
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color.black.opacity(0.35))
                .cornerRadius(DesignSystem.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Description Text
                Text(descriptionText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, 4)
                
                // Action CTA Button
                if gems >= lifeline.gemCost {
                    Button(action: {
                        dismissModal {
                            onUse()
                        }
                    }) {
                        Text("ACTIVATE NOW")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [lifelineColor, lifelineColor.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: lifelineColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                } else {
                    Button(action: {
                        dismissModal {
                            onBuyGems()
                        }
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("GET GEMS (NEED \(lifeline.gemCost - gems) MORE)")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(DesignSystem.ColorToken.gemPrimary)
                                .shadow(color: DesignSystem.ColorToken.gemPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                }
            }
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.ColorToken.backgroundSecondary.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), lifelineColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: lifelineColor.opacity(0.25), radius: 20, x: 0, y: 10)
            .scaleEffect(animateCard ? 1.0 : 0.8)
            .opacity(animateCard ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                animateCard = true
            }
        }
    }
    
    private var lifelineColor: Color {
        switch lifeline {
        case .wormhole: return DesignSystem.ColorToken.lifelineWormhole
        case .zenFreeze: return DesignSystem.ColorToken.lifelineZen
        case .phantomGlimpse: return DesignSystem.ColorToken.lifelinePhantom
        }
    }
    
    private var descriptionText: String {
        switch lifeline {
        case .wormhole:
            return "Bypass space and time to instantly solve the current level with a passing mark. Ideal when you feel completely stuck!"
        case .zenFreeze:
            return "Slows down time dilation by 50%. This effectively doubles your remaining tracing clock, and significantly boosts your speed rating score!"
        case .phantomGlimpse:
            return "Flashes the exact target path path overlay directly on the canvas for 3.0 seconds, allowing you to memorize or trace it perfectly."
        }
    }
    
    private func dismissModal(completion: (() -> Void)? = nil) {
        withAnimation(.easeIn(duration: 0.2)) {
            animateCard = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onCancel()
            completion?()
        }
    }
    
    // MARK: - Previews for Animations
    
    @ViewBuilder
    private var animationPreview: some View {
        switch lifeline {
        case .phantomGlimpse:
            PhantomGlimpsePreview()
        case .zenFreeze:
            ZenFreezePreview()
        case .wormhole:
            WormholePreview()
        }
    }
}

// MARK: - Animated Preview Components

struct PhantomGlimpsePreview: View {
    @State private var pathVisible = false
    
    var body: some View {
        ZStack {
            // Draw a mini grid background
            MiniGrid()
            
            // Draw the target path that fades in/out
            Path { path in
                path.move(to: CGPoint(x: 30, y: 100))
                path.addQuadCurve(to: CGPoint(x: 250, y: 40), control: CGPoint(x: 140, y: 120))
            }
            .stroke(
                DesignSystem.ColorToken.lifelinePhantom,
                style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [4, 4])
            )
            .shadow(color: DesignSystem.ColorToken.lifelinePhantom.opacity(0.8), radius: 4)
            .opacity(pathVisible ? 1.0 : 0.05)
            
            // Pulse indicator
            Text("GLIMPSE")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.ColorToken.lifelinePhantom)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DesignSystem.ColorToken.lifelinePhantom.opacity(0.15))
                .cornerRadius(4)
                .offset(y: -45)
                .opacity(pathVisible ? 1.0 : 0.4)
        }
        .onAppear {
            // Loop fade-in for 1.5 seconds, fade-out for 1.5 seconds
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pathVisible = true
            }
        }
    }
}

struct ZenFreezePreview: View {
    @State private var rotateSnowflake = false
    @State private var dotProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            MiniGrid()
            
            // Cyan breathing outline frame (simulates frozen border)
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.8), .blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(6)
                .shadow(color: Color.cyan.opacity(0.4), radius: 4)
            
            // Path for dot
            Path { path in
                path.move(to: CGPoint(x: 50, y: 70))
                path.addLine(to: CGPoint(x: 230, y: 70))
            }
            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            
            // Tracing dot - moving VERY SLOWLY
            GeometryReader { geo in
                Circle()
                    .fill(DesignSystem.ColorToken.accentCyan)
                    .frame(width: 10, height: 10)
                    .shadow(color: .cyan, radius: 4)
                    .offset(x: 50 + (dotProgress * 180) - 5, y: 70 - 5)
            }
            
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .rotationEffect(.degrees(rotateSnowflake ? 360 : 0))
                    Text("50% SLOW MOTION")
                }
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.ColorToken.lifelineZen)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DesignSystem.ColorToken.lifelineZen.opacity(0.15))
                .cornerRadius(4)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotateSnowflake = true
            }
            
            // 4 seconds to trace a short line (slow trace simulation)
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: false)) {
                dotProgress = 1.0
            }
        }
    }
}

struct WormholePreview: View {
    @State private var scaleDot: CGFloat = 1.0
    @State private var positionDot = CGPoint(x: 60, y: 70)
    @State private var showWarpWave = false
    
    var body: some View {
        ZStack {
            MiniGrid()
            
            // Dotted guide line
            Path { path in
                path.move(to: CGPoint(x: 60, y: 70))
                path.addLine(to: CGPoint(x: 220, y: 70))
            }
            .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
            
            // Warp Gates
            Circle()
                .stroke(DesignSystem.ColorToken.lifelineWormhole, lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .position(x: 60, y: 70)
                .shadow(color: DesignSystem.ColorToken.lifelineWormhole, radius: 4)
            
            Circle()
                .stroke(DesignSystem.ColorToken.lifelineWormhole, lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .position(x: 220, y: 70)
                .shadow(color: DesignSystem.ColorToken.lifelineWormhole, radius: 4)
            
            // Particle Warp Wave
            Circle()
                .fill(RadialGradient(
                    colors: [DesignSystem.ColorToken.lifelineWormhole.opacity(0.6), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                ))
                .frame(width: 40, height: 40)
                .position(positionDot)
                .scaleEffect(showWarpWave ? 1.5 : 0.5)
                .opacity(showWarpWave ? 0.0 : 0.8)
            
            // Teleporting Tracing Dot
            Circle()
                .fill(DesignSystem.ColorToken.accentCyan)
                .frame(width: 10, height: 10)
                .position(positionDot)
                .scaleEffect(scaleDot)
                .shadow(color: DesignSystem.ColorToken.accentCyan, radius: 5)
            
            Text("PORTAL WARP")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.ColorToken.lifelineWormhole)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DesignSystem.ColorToken.lifelineWormhole.opacity(0.15))
                .cornerRadius(4)
                .offset(y: -45)
        }
        .onAppear {
            runWormholeLoop()
        }
    }
    
    private func runWormholeLoop() {
        // Repeated sequence
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            // 1. Shrink at start point
            withAnimation(.easeOut(duration: 0.3)) {
                scaleDot = 0.01
                showWarpWave = true
            }
            
            // 2. Change position instantly while shrunk
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                positionDot = (positionDot.x == 60) ? CGPoint(x: 220, y: 70) : CGPoint(x: 60, y: 70)
                showWarpWave = false
                
                // 3. Pop up at end point
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    scaleDot = 1.0
                }
            }
        }
    }
}

// Common grid overlay for previews
struct MiniGrid: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<4) { _ in
                HStack(spacing: 20) {
                    ForEach(0..<8) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }
}
