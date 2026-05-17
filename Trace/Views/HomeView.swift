import SwiftUI

struct HomeView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var showingGame = false
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var showingDaily = false
    @State private var showingPractice = false
    @State private var targetLevel: TraceLevel?
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
                DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if progressStore.progress.globalPrestigeScore > 0 {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PRESTIGE SCORE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                    .tracking(1.5)
                                Text("\(progressStore.progress.globalPrestigeScore)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.top, 50)
                    } else {
                        Spacer()
                            .frame(height: 50)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("TRACE")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .tracking(8)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                        
                        Text("Watch it. Trace it. Don’t lift.")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: handleStartContinue) {
                            Text(progressStore.progress.highestUnlockedLevel > 1 ? "Continue Level \(progressStore.progress.highestUnlockedLevel)" : "Start")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.GradientToken.primaryCTA)
                                .cornerRadius(DesignSystem.Radius.pill)
                        }
                        
                        /*
                        Button(action: { showingDaily = true }) {
                            Text("Daily Challenge")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.ColorToken.surface)
                                .cornerRadius(DesignSystem.Radius.pill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                                        .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                                )
                        }
                        
                        Button(action: { showingPractice = true }) {
                            Text("Practice")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.ColorToken.surface)
                                .cornerRadius(DesignSystem.Radius.pill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                                        .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                                )
                        }
                        */
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    HStack {
                        Spacer()
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.md)
                }
            }
            .id(refreshID)
            .fullScreenCover(item: $targetLevel) { level in
                GameView(level: level, autoAdvance: true, onDismiss: {
                    targetLevel = nil
                    checkPaywall()
                })
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView(onDismiss: { showingPaywall = false })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingDaily) {
                DailyChallengeView(onDismiss: { showingDaily = false })
            }
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeView(onDismiss: { showingPractice = false })
            }
            .onAppear {
                print("HomeView: onAppear, refreshing view state")
                refreshID = UUID()
            }
            .task {
                purchaseManager.initialize()
            }
        }
    }
    
    private func handleStartContinue() {
        let currentLevelID = progressStore.progress.highestUnlockedLevel
        print("HomeView: handleStartContinue clicked. currentLevelID: \(currentLevelID)")
        
        if currentLevelID > 15 && !purchaseManager.isPurchased {
            print("HomeView: showing paywall")
            showingPaywall = true
            return
        }
        
        if let level = LevelRepository.shared.level(for: currentLevelID) {
            print("HomeView: Found level \(level.id), presenting GameView")
            targetLevel = level
        } else {
            print("HomeView: Could not find level for id \(currentLevelID)")
        }
    }
    
    private func checkPaywall() {
        let currentLevelID = progressStore.progress.highestUnlockedLevel
        if currentLevelID > 15 && !purchaseManager.isPurchased {
            showingPaywall = true
        }
    }
}
