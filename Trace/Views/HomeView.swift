import SwiftUI

struct HomeView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var showingDaily = false
    @State private var showingPractice = false
    @State private var showingLeaderboard = false
    @State private var showingGame = false
    @State private var activeGameLevel = LevelRepository.shared.level(for: 1)!
    @State private var refreshID = UUID()
    
    private var resumeLevelID: Int {
        let savedID = UserDefaults.standard.integer(forKey: "ResumeLevelID")
        if savedID > 0 {
            return savedID
        }
        return progressStore.progress.highestUnlockedLevel
    }
    
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
                        Text("PATHMINDER")
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
                        
                        Text("Watch it. Follow it. Don’t lift.")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: handleStartContinue) {
                            Text(resumeLevelID > 1 ? "Continue Level \(resumeLevelID)" : "Start")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.GradientToken.primaryCTA)
                                .cornerRadius(DesignSystem.Radius.pill)
                        }
                        
                        Button(action: { showingLeaderboard = true }) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                                Text("Leaderboard")
                                    .font(DesignSystem.Typography.subtitle)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.pill)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                                    .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                            )
                        }
                        
                        Button(action: {
                            if purchaseManager.isPurchased {
                                showingDaily = true
                            } else {
                                showingPaywall = true
                            }
                        }) {
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
            .fullScreenCover(isPresented: $showingGame, onDismiss: handleGameDismiss) {
                GameView(
                    level: $activeGameLevel,
                    autoAdvance: true,
                    onDismiss: dismissGame
                )
                .onAppear {
                    log("game cover content appeared for level \(activeGameLevel.id)")
                }
                .onDisappear {
                    log("game cover content disappeared; showingGame=\(showingGame), activeLevel=\(activeGameLevel.id)")
                }
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
            .fullScreenCover(isPresented: $showingLeaderboard) {
                LeaderboardView(onDismiss: { showingLeaderboard = false })
            }
            .onAppear {
                log("onAppear; refreshing view state; resumeLevelID=\(resumeLevelID), highestUnlocked=\(progressStore.progress.highestUnlockedLevel), activeLevel=\(activeGameLevel.id), showingGame=\(showingGame)")
                refreshID = UUID()
            }
            .onChange(of: showingGame) { oldValue, newValue in
                log("showingGame changed \(oldValue) -> \(newValue); activeLevel=\(activeGameLevel.id), resumeLevelID=\(resumeLevelID)")
            }
            .onChange(of: activeGameLevel.id) { oldValue, newValue in
                log("activeGameLevel changed \(oldValue) -> \(newValue); showingGame=\(showingGame)")
            }
            .onChange(of: showingPaywall) { oldValue, newValue in
                log("showingPaywall changed \(oldValue) -> \(newValue); highestUnlocked=\(progressStore.progress.highestUnlockedLevel)")
            }
            .task {
                log("purchaseManager initialize task started")
                purchaseManager.initialize()
            }
        }
    }
    
    private func handleStartContinue() {
        let currentLevelID = resumeLevelID
        log("handleStartContinue tapped; resumeLevelID=\(currentLevelID), highestUnlocked=\(progressStore.progress.highestUnlockedLevel), showingGame=\(showingGame), activeLevel=\(activeGameLevel.id)")
        
        if currentLevelID > 15 && !purchaseManager.isPurchased {
            log("start blocked by paywall for level \(currentLevelID)")
            showingPaywall = true
            return
        }
        
        if let level = LevelRepository.shared.level(for: currentLevelID) {
            log("found level \(level.id) (\(level.title)); setting activeGameLevel then presenting cover")
            activeGameLevel = level
            showingGame = true
        } else {
            log("missing level for id \(currentLevelID); cannot present game")
        }
    }
    
    private func dismissGame() {
        log("dismissGame called; hiding game cover from activeLevel=\(activeGameLevel.id)")
        showingGame = false
    }
    
    private func handleGameDismiss() {
        log("handleGameDismiss; activeLevel=\(activeGameLevel.id), highestUnlocked=\(progressStore.progress.highestUnlockedLevel), resumeLevelID=\(resumeLevelID)")
        showingGame = false
        checkPaywall()
    }
    
    private func checkPaywall() {
        let currentLevelID = progressStore.progress.highestUnlockedLevel
        log("checkPaywall; highestUnlocked=\(currentLevelID), purchased=\(purchaseManager.isPurchased)")
        if currentLevelID > 15 && !purchaseManager.isPurchased {
            log("showing paywall after game dismiss for level \(currentLevelID)")
            showingPaywall = true
        }
    }
    
    private func log(_ message: String) {
        print("[HomeView] \(message)")
    }
}
