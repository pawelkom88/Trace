import SwiftUI

struct ResultView: View {
    let score: TraceScore?
    let viewModel: TraceGameViewModel
    let level: TraceLevel
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                if let score = score, score.didPass {
                    Text(score.medal.rawValue.capitalized)
                        .font(DesignSystem.Typography.heroScore)
                        .foregroundColor(medalColor(score.medal))
                    
                    if score.isAssisted {
                        Text("Zen Assist Active (0.5x penalty)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorToken.accentCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(DesignSystem.ColorToken.accentCyan.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Score: \(score.calculatedPoints)")
                            .font(DesignSystem.Typography.heroScore)
                            .foregroundColor(.yellow)
                        
                        let bestScore = ProgressStore.shared.progress.bestScoresByLevel[level.id] ?? 0.0
                        if score.total >= bestScore {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("NEW HIGH SCORE")
                            }
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.top, 4)
                    
                    Text("\(Int(score.pathAccuracy * 100))% Accuracy")
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        Text("Streak: \(ProgressStore.shared.progress.currentStreak)")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            
                        Text("Level \(level.id) complete")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                    
                    Spacer().frame(height: DesignSystem.Spacing.xl)
                    
                    Button(action: onDismiss) {
                        Text("Next Level")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.GradientToken.primaryCTA)
                            .cornerRadius(DesignSystem.Radius.pill)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    if score.medal == .pass && !score.isAssisted {
                        Button(action: viewModel.retry) {
                            Text("Try for Great")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.ColorToken.accentCyan)
                        }
                    } else if score.medal == .great && !score.isAssisted {
                        Button(action: viewModel.retry) {
                            Text("Try for Perfect")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.ColorToken.accentCyan)
                        }
                    }
                    
                } else {
                    Text("Almost")
                        .font(DesignSystem.Typography.heroScore)
                        .foregroundColor(DesignSystem.ColorToken.danger)
                    
                    Text(failureMessage)
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if viewModel.consecutiveFailures >= 5 && !viewModel.isAssistModeActive {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Feeling Stuck?")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(DesignSystem.ColorToken.accentCyan)
                            
                            Text("Zen Assist doubles path tolerance so you can glide through. Total score is halved and medal is standard Pass.")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.isAssistModeActive = true
                                    viewModel.retry()
                                }
                            }) {
                                Text("Activate Zen Assist")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(DesignSystem.ColorToken.accentCyan.opacity(0.2))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(DesignSystem.ColorToken.accentCyan, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.ColorToken.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer().frame(height: DesignSystem.Spacing.xl)
                    
                    Button(action: viewModel.retry) {
                        Text("Try Again")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.ColorToken.surfaceBorder)
                            .cornerRadius(DesignSystem.Radius.pill)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    Button(action: onDismiss) {
                        Text("Quit")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                }
            }
        }
    }
    
    private func medalColor(_ medal: TraceMedal) -> Color {
        switch medal {
        case .perfect: return DesignSystem.ColorToken.accentCyan
        case .great: return DesignSystem.ColorToken.accentBlue
        case .pass: return DesignSystem.ColorToken.success
        case .none: return DesignSystem.ColorToken.danger
        }
    }
    
    private var failureMessage: String {
        guard let reason = score?.failureReason else { return "You missed the path." }
        switch reason {
        case .startedOutsideZone: return "Start on the glowing dot."
        case .liftedTooEarly: return "You lifted too soon."
        case .timedOut: return "Too slow."
        case .endedTooFarAway: return "You ended too far away from the target."
        case .outsideToleranceTooLong: return "You went too far off the path."
        }
    }
}
