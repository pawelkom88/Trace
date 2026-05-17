import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = TraceGameViewModel()
    @AppStorage("GridAssistEnabled") private var isGridEnabled = false
    
    @State private var currentLevel: TraceLevel
    @State private var showTierAscension = false
    @State private var previousDifficultyTitle = ""
    var autoAdvance: Bool = false
    var onScoreReported: ((TraceScore) -> Void)?
    var onDismiss: () -> Void
    
    init(level: TraceLevel, autoAdvance: Bool = false, onScoreReported: ((TraceScore) -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self._currentLevel = State(initialValue: level)
        self.autoAdvance = autoAdvance
        self.onScoreReported = onScoreReported
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
            DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        }
                        
                        Button(action: {
                            viewModel.cheatComplete()
                        }) {
                            Text("Cheat")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Level \(currentLevel.id)")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(DesignSystem.ColorToken.textPrimary)
                            .id("level-title-\(currentLevel.id)") // Force refresh for animation if needed
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                Text(String(format: "%.1fs", currentLevel.maxTraceDuration))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "target")
                                Text("\(Int(currentLevel.passThreshold * 100))%")
                            }
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        .padding(.top, 2)
                        
                        if viewModel.isAssistModeActive {
                            Text("Zen Assist Active")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorToken.accentCyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.ColorToken.accentCyan.opacity(0.15))
                                .cornerRadius(4)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Text("Streak: \(ProgressStore.shared.progress.currentStreak)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: DesignSystem.AnimationDuration.quick)) {
                                isGridEnabled.toggle()
                            }
                        }) {
                            Image(systemName: isGridEnabled ? "square.grid.3x3.fill" : "square.grid.3x3")
                                .font(.system(size: 24))
                                .foregroundColor(isGridEnabled ? DesignSystem.ColorToken.accentCyan : DesignSystem.ColorToken.textSecondary)
                        }
                    }
                }
                .padding()
                
                // Instructions
                Text(instructionText)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    .padding(.top, DesignSystem.Spacing.lg)
                
                // Canvas area
                GestureCanvasView(viewModel: viewModel, level: currentLevel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(DesignSystem.Spacing.md)
                    .id("canvas-\(currentLevel.id)") // Clean animation transition
            }
            
            if showTierAscension {
                TierAscensionCard(
                    previousTier: previousDifficultyTitle,
                    currentLevel: currentLevel
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(100)
            }
            
            if viewModel.phase == .result || viewModel.phase == .failed {
                ResultView(
                    score: viewModel.currentScore,
                    viewModel: viewModel,
                    level: currentLevel,
                    onDismiss: {
                        if let score = viewModel.currentScore {
                            onScoreReported?(score)
                        }
                        if viewModel.phase == .result && autoAdvance {
                            advanceToNextLevel()
                        } else {
                            onDismiss()
                        }
                    }
                )
            }
        }
        .onAppear {
            print("GameView: onAppear for level \(currentLevel.id)")
            viewModel.startLevel(currentLevel)
        }
    }
    
    private func advanceToNextLevel() {
        let nextID = currentLevel.id + 1
        
        // Trigger paywall lock if entering premium territory
        if nextID > 15 && !PurchaseManager.shared.isPurchased {
            print("GameView: Next level \(nextID) locked behind paywall. Dismissing to trigger paywall overlay.")
            onDismiss()
            return
        }
        
        if let nextLevel = LevelRepository.shared.level(for: nextID) {
            print("GameView: Advancing smoothly to Level \(nextID)")
            
            let oldDifficulty = self.currentLevel.difficulty
            let newDifficulty = nextLevel.difficulty
            
            if oldDifficulty != newDifficulty {
                self.previousDifficultyTitle = oldDifficulty.rawValue.capitalized
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.showTierAscension = true
                    self.currentLevel = nextLevel
                }
                viewModel.startLevel(nextLevel)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.showTierAscension = false
                    }
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.currentLevel = nextLevel
                }
                viewModel.startLevel(nextLevel)
            }
        } else {
            print("GameView: No more levels left. Dismissing.")
            onDismiss()
        }
    }
    
    private var instructionText: String {
        switch viewModel.phase {
        case .idle, .preparingLevel: return "Get Ready"
        case .tutorial, .previewStatic, .previewAnimating: return "Watch the pattern"
        case .waitingForStart: return "Start here"
        case .tracing: return "Trace without lifting"
        case .evaluating: return "Evaluating..."
        case .result, .failed, .paywall: return ""
        }
    }
}

struct TierAscensionCard: View {
    let previousTier: String
    let currentLevel: TraceLevel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("\(previousTier) Tier Cleared")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    .textCase(.uppercase)
                    .tracking(2)
                
                Text("\(currentLevel.difficulty.rawValue.capitalized) Tier Unlocked")
                    .font(DesignSystem.Typography.heroScore)
                    .foregroundColor(DesignSystem.ColorToken.accentCyan)
                    .multilineTextAlignment(.center)
                    .shadow(color: DesignSystem.ColorToken.accentCyan.opacity(0.5), radius: 10, x: 0, y: 0)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Label("Time Limit:", systemImage: "timer")
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        Spacer()
                        Text("\(String(format: "%.1f", currentLevel.maxTraceDuration))s")
                            .bold()
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Label("Pass Target:", systemImage: "target")
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        Spacer()
                        Text("\(Int(currentLevel.passThreshold * 100))%")
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(DesignSystem.ColorToken.surface)
                .cornerRadius(DesignSystem.Radius.medium)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
    }
}
