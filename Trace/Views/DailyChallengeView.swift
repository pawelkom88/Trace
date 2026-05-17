import SwiftUI

struct DailyChallengeView: View {
    var onDismiss: () -> Void
    @State private var levels = DailyChallengeGenerator.generateTodaysLevels()
    @State private var currentLevelIndex = 0
    @State private var showingResult = false
    @State private var scores: [TraceScore] = []
    
    @State private var showingGame = false
    
    var body: some View {
        ZStack {
            DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
            
            if showingResult {
                DailyResultView(scores: scores, onDismiss: onDismiss)
            } else {
                VStack {
                    Text("Daily Challenge")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    
                    Text("Pattern \(currentLevelIndex + 1) of 3")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    
                    Spacer()
                    
                    Button("Start Pattern") {
                        showingGame = true
                    }
                    .font(DesignSystem.Typography.subtitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(DesignSystem.GradientToken.primaryCTA)
                    .cornerRadius(DesignSystem.Radius.pill)
                    
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameView(level: levels[currentLevelIndex], onScoreReported: { score in
                scores.append(score)
            }, onDismiss: {
                showingGame = false
                if currentLevelIndex < 2 {
                    currentLevelIndex += 1
                } else {
                    showingResult = true
                }
            })
        }
    }
}

struct DailyResultView: View {
    let scores: [TraceScore]
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text("Daily Challenge Complete")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.ColorToken.textPrimary)
            
            let avgAccuracy = scores.isEmpty ? 0.0 : scores.reduce(0) { $0 + $1.pathAccuracy } / Double(scores.count)
            
            Text("\(Int(avgAccuracy * 100))% Accuracy")
                .font(DesignSystem.Typography.heroScore)
                .foregroundColor(DesignSystem.ColorToken.accentCyan)
            
            Text("\(ProgressStore.shared.progress.dailyStreak)-day streak")
                .font(DesignSystem.Typography.subtitle)
                .foregroundColor(DesignSystem.ColorToken.textSecondary)
            
            Spacer()
            
            Button(action: shareResult) {
                Text("Share Result")
                    .font(DesignSystem.Typography.subtitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.GradientToken.primaryCTA)
                    .cornerRadius(DesignSystem.Radius.pill)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    private func shareResult() {
        let avgAccuracy = scores.isEmpty ? 0.0 : scores.reduce(0) { $0 + $1.pathAccuracy } / Double(scores.count)
        let text = "Trace - Daily Challenge\n\(Int(avgAccuracy * 100))% Accuracy\nWatch it. Trace it. Don’t lift."
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
