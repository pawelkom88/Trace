import SwiftUI

struct ResultView: View {
    let score: TraceScore?
    let viewModel: TraceGameViewModel
    let level: TraceLevel
    var onDismiss: () -> Void
    var onNext: () -> Void
    
    var body: some View {
        ZStack {
            if let score = score, score.didPass {
                Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // HUD Row
                    ZStack {
                        HStack {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                Text("\(ProgressStore.shared.progress.currentStreak) streak")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Text("Level \(level.id)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Result Header
                    VStack(spacing: 12) {
                        let resultText = score.medal == .perfect ? "Perfect" : (score.medal == .great ? "Great" : "Pass")
                        Text(resultText)
                            .font(.system(size: 52, weight: .black))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        
                        Text("Level \(level.id) complete")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Score Block
                    VStack(spacing: 4) {
                        Text("SCORE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                        
                        let formatter: NumberFormatter = {
                            let f = NumberFormatter()
                            f.numberStyle = .decimal
                            return f
                        }()
                        let formattedScore = formatter.string(from: NSNumber(value: score.calculatedPoints)) ?? "\(score.calculatedPoints)"
                        
                        Text(formattedScore)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        let bestScore = ProgressStore.shared.progress.bestScoresByLevel[level.id] ?? 0.0
                        if score.total >= bestScore {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("NEW HIGH SCORE")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(0.5)
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 1.0, green: 0.8, blue: 0.2), lineWidth: 1.5)
                            )
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Stat Chips
                    HStack(spacing: 16) {
                        // Accuracy Chip
                        VStack(spacing: 4) {
                            Text(String(format: "%.0f%%", score.pathAccuracy * 100))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.9, blue: 1.0)) // Cyan
                            Text("ACCURACY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        
                        // Time Chip
                        let userPoints = viewModel.userPoints
                        let duration: Double = {
                            guard let first = userPoints.first, let last = userPoints.last else { return 0.0 }
                            return max(0.0, last.timestamp - first.timestamp)
                        }()
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.1fs", duration))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("TIME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: onNext) {
                            Text("Next Level")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.2, green: 0.9, blue: 1.0)) // Cyan
                                .cornerRadius(30)
                        }
                        
                        if !score.isAssisted && score.medal != .perfect {
                            Button(action: viewModel.retry) {
                                let nextMedalText = score.medal == .pass ? "Great" : "Perfect"
                                Text("Try for \(nextMedalText) →")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.vertical, 8)
                            }
                        } else {
                            Button(action: viewModel.retry) {
                                Text("Try Again →")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            } else {
                Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // HUD Row
                    ZStack {
                        HStack {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                Text("\(ProgressStore.shared.progress.currentStreak) streak")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Text("Level \(level.id)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Result Header
                    VStack(spacing: 12) {
                        Text("Almost")
                            .font(.system(size: 52, weight: .black))
                            .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.35))
                        
                        Text(failureMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Stat Chips
                    HStack(spacing: 16) {
                        let userPoints = viewModel.userPoints
                        let duration: Double = {
                            guard let first = userPoints.first, let last = userPoints.last else { return 0.0 }
                            return max(0.0, last.timestamp - first.timestamp)
                        }()
                        
                        // Time Chip
                        VStack(spacing: 4) {
                            Text(String(format: "%.1fs", duration))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("TIME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        
                        // Accuracy Chip
                        VStack(spacing: 4) {
                            Text(String(format: "%.0f%%", (score?.pathAccuracy ?? 0) * 100))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("ACCURACY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    
                    if viewModel.consecutiveFailures >= 5 {
                        Spacer()
                            .frame(height: 24)
                        
                        // Zen Assist Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feeling stuck?")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Zen Assist doubles path tolerance so you can glide through. Score is halved and medal caps at Pass.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(3)
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.isAssistModeActive.toggle()
                                    viewModel.retry()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.isAssistModeActive ? "leaf.fill" : "leaf")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(viewModel.isAssistModeActive ? "Zen Assist Active" : "Activate Zen Assist")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(viewModel.isAssistModeActive ? DesignSystem.ColorToken.accentCyan : Color.black.opacity(0.3))
                                .foregroundColor(viewModel.isAssistModeActive ? .black : DesignSystem.ColorToken.accentCyan)
                                .clipShape(Capsule())
                                .overlay(
                                    Group {
                                        if !viewModel.isAssistModeActive {
                                            Capsule()
                                                .stroke(DesignSystem.ColorToken.accentCyan, lineWidth: 1.5)
                                        }
                                    }
                                )
                                .shadow(color: viewModel.isAssistModeActive ? DesignSystem.ColorToken.accentCyan.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 0)
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: viewModel.retry) {
                            Text("Try Again")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(30)
                        }
                        
                        Button(action: onDismiss) {
                            Text("Quit")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
