import SwiftUI

struct HomeView: View {
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject var purchaseManager = PurchaseManager.shared
    
    @State private var showingPaywall = false
    @State private var showingSettings = false
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
                Image("HomeBackground")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.34)
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.08))
                
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        Spacer()
                        
                        if progressStore.progress.globalPrestigeScore > 0 {
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("PRESTIGE SCORE")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.58))
                                    .tracking(2.8)
                                Text("\(progressStore.progress.globalPrestigeScore)")
                                    .font(.system(size: 48, weight: .light, design: .rounded))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.62))
                                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.62).opacity(0.18), radius: 14)
                            }
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 68)
                    
                    Spacer(minLength: 230)
                    
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Text("PATH")
                            Text("MINDER")
                        }
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .tracking(18)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.78, green: 0.86, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.48), radius: 12)
                        .shadow(color: Color(red: 0.42, green: 0.64, blue: 1.0).opacity(0.34), radius: 26)
                        
                        Text("Watch it. Follow it. Don’t lift.")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.72), .white.opacity(0.38)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .padding(.bottom, 30)
                    
                    VStack(spacing: 18) {
                        Button(action: handleStartContinue) {
                            Text(resumeLevelID > 1 ? "Continue Level \(resumeLevelID)" : "Start")
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 62)
                                .background(DesignSystem.GradientToken.primaryCTA)
                                .cornerRadius(DesignSystem.Radius.pill)
                                .shadow(color: DesignSystem.ColorToken.accentCyan.opacity(0.28), radius: 18, y: 8)
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
                            .frame(height: 62)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(DesignSystem.Radius.pill)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                                    .stroke(Color.white.opacity(0.26), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 34)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color(red: 0.04, green: 0.04, blue: 0.10).opacity(0.72))
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 28, y: 16)
                    )
                    .padding(.horizontal, 24)
                    
                    HStack {
                        Spacer()
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.64))
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 28)
                    .padding(.bottom, 34)
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
