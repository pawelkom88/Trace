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
        let maxLevelID = LevelRepository.shared.levels.last?.id ?? 1
        let savedID = UserDefaults.standard.integer(forKey: "ResumeLevelID")
        if savedID > 0 {
            return min(savedID, maxLevelID)
        }
        return min(progressStore.progress.highestUnlockedLevel, maxLevelID)
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
                
                GeometryReader { proxy in
                    let size = proxy.size
                    let compactHeight = size.height < 760
                    let sidePadding = min(36, max(20, size.width * 0.08))
                    let titleFontSize = min(compactHeight ? 58 : 72, size.width * 0.17)
                    let titleTracking = min(18, size.width * 0.036)
                    let scoreFontSize = min(48, size.width * 0.115)
                    let heroSpacer = max(compactHeight ? 54 : 120, size.height * (compactHeight ? 0.08 : 0.18))
                    let buttonHeight: CGFloat = compactHeight ? 56 : 62
                    let contentMaxWidth = max(0, size.width - (sidePadding * 2))
                    
                    VStack(spacing: 0) {
                        HStack(alignment: .top) {
                            Spacer()
                            
                            if progressStore.progress.globalPrestigeScore > 0 {
                                VStack(alignment: .trailing, spacing: 6) {
                                    if progressStore.progress.hasAllTimeStar {
                                        HStack(spacing: 6) {
                                            Image(systemName: "star.circle.fill")
                                                .font(.system(size: compactHeight ? 13 : 15, weight: .bold))
                                            Text("ALL-TIME STAR")
                                                .font(.system(size: compactHeight ? 10 : 12, weight: .black))
                                                .tracking(1.4)
                                        }
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.25))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.black.opacity(0.28)))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(red: 1.0, green: 0.84, blue: 0.25).opacity(0.42), lineWidth: 1)
                                        )
                                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.25).opacity(0.22), radius: 12)
                                    }

                                    Text("PRESTIGE SCORE")
                                        .font(.system(size: compactHeight ? 11 : 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.58))
                                        .tracking(compactHeight ? 2.2 : 2.8)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text("\(progressStore.progress.globalPrestigeScore)")
                                        .font(.system(size: scoreFontSize, weight: .light, design: .rounded))
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.62))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.45)
                                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.62).opacity(0.18), radius: 14)
                                }
                                .frame(maxWidth: contentMaxWidth, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, sidePadding)
                        .padding(.top, compactHeight ? 26 : 44)
                        
                        Spacer(minLength: heroSpacer)
                        
                        VStack(spacing: compactHeight ? 12 : 18) {
                            VStack(spacing: compactHeight ? 2 : 6) {
                                Text("PATH")
                                Text("MINDER")
                            }
                            .font(.system(size: titleFontSize, weight: .light, design: .rounded))
                            .tracking(titleTracking)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
                                .font(.system(size: compactHeight ? 18 : 24, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white.opacity(0.72), .white.opacity(0.38)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.bottom, compactHeight ? 18 : 30)
                        
                        VStack(spacing: compactHeight ? 14 : 18) {
                            Button(action: handleStartContinue) {
                                Text(resumeLevelID > 1 ? "Continue Level \(resumeLevelID)" : "Start")
                                    .font(DesignSystem.Typography.subtitle)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: buttonHeight)
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: buttonHeight)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(DesignSystem.Radius.pill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                                        .stroke(Color.white.opacity(0.26), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, compactHeight ? 24 : 34)
                        .padding(.vertical, compactHeight ? 18 : 24)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(red: 0.04, green: 0.04, blue: 0.10).opacity(0.72))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.35), radius: 28, y: 16)
                        )
                        .padding(.horizontal, max(16, sidePadding - 12))
                        
                        HStack {
                            Spacer()
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: compactHeight ? 22 : 26))
                                    .foregroundColor(.white.opacity(0.64))
                                    .frame(width: compactHeight ? 54 : 64, height: compactHeight ? 54 : 64)
                                    .background(Circle().fill(Color.white.opacity(0.08)))
                                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, sidePadding)
                        .padding(.top, compactHeight ? 16 : 28)
                        .padding(.bottom, compactHeight ? 18 : 34)
                    }
                    .frame(width: size.width, height: size.height)
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
