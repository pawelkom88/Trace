import SwiftUI

struct LeaderboardView: View {
    var onDismiss: () -> Void
    
    @ObservedObject private var progressStore = ProgressStore.shared
    @State private var selectedTab: LeaderboardTab = .byLevel
    @Namespace private var tabAnimationNamespace
    @State private var detailsLevel: TraceLevel?
    @State private var activeGameLevel: TraceLevel?
    
    enum LeaderboardTab: String, CaseIterable, Identifiable {
        case byLevel = "By Level"
        case allTime = "All-Time Best"
        
        var id: String { self.rawValue }
    }
    
    struct LeaderboardRowItem: Identifiable {
        var id: Int { levelId }
        let levelId: Int
        let title: String
        let difficulty: TraceDifficulty
        let score: Int
        let accuracy: Double?
    }
    
    struct AllTimeAttemptItem: Identifiable {
        var id: UUID
        let levelId: Int
        let title: String
        let score: Int
        let accuracy: Double
        let date: Date
        let medal: TraceMedal
    }
    
    // Computes top best score per level
    var leaderboardItems: [LeaderboardRowItem] {
        let bestScores = progressStore.progress.bestScoresByLevel
        let history = progressStore.progress.attemptHistoryByLevel ?? [:]
        return bestScores.compactMap { (levelId, bestTotal) -> LeaderboardRowItem? in
            guard let level = LevelRepository.shared.level(for: levelId) else { return nil }
            let score = Int(bestTotal * 10000)
            let bestAttemptAccuracy = history[levelId]?
                .max(by: { $0.points < $1.points })?
                .accuracy
            return LeaderboardRowItem(
                levelId: levelId,
                title: level.title,
                difficulty: level.difficulty,
                score: score,
                accuracy: bestAttemptAccuracy
            )
        }
        .sorted { $0.score > $1.score }
    }
    
    // Computes all recorded attempts flattened and sorted by score descending
    var allTimeAttempts: [AllTimeAttemptItem] {
        let history = progressStore.progress.attemptHistoryByLevel ?? [:]
        var items: [AllTimeAttemptItem] = []
        
        for (levelId, attempts) in history {
            guard let level = LevelRepository.shared.level(for: levelId) else { continue }
            for attempt in attempts {
                items.append(AllTimeAttemptItem(
                    id: attempt.id,
                    levelId: levelId,
                    title: level.title,
                    score: attempt.points,
                    accuracy: attempt.accuracy,
                    date: attempt.date,
                    medal: attempt.medal
                ))
            }
        }
        
        return items.sorted { $0.score > $1.score }
    }
    
    var totalBestScore: Int {
        progressStore.progress.globalPrestigeScore
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
                DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Total Score Header Card
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("TOTAL SCORE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            .tracking(2.0)
                        
                        Text("\(totalBestScore)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(DesignSystem.ColorToken.accentCyan)
                            .shadow(color: DesignSystem.ColorToken.accentCyan.opacity(0.3), radius: 8)
                        
                        Text("Sum of your best score on each completed level")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            .padding(.top, 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.ColorToken.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                    
                    // Custom Sliding Tab Control
                    HStack(spacing: 0) {
                        ForEach(LeaderboardTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(DesignSystem.Typography.subtitle)
                                    .foregroundColor(selectedTab == tab ? .black : DesignSystem.ColorToken.textSecondary)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        ZStack {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(Color.white)
                                                    .matchedGeometryEffect(id: "activeTab", in: tabAnimationNamespace)
                                            }
                                        }
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(DesignSystem.Radius.pill)
                    .padding(.horizontal)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                    
                    // Tab Content
                    if selectedTab == .byLevel {
                        levelScoresView
                    } else {
                        allTimeAttemptsView
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
            .sheet(item: $detailsLevel) { level in
                LevelDetailsView(level: level, onStartLevel: {
                    activeGameLevel = level
                })
            }
            .fullScreenCover(item: $activeGameLevel) { level in
                GameView(
                    level: Binding(
                        get: { activeGameLevel ?? level },
                        set: { activeGameLevel = $0 }
                    ),
                    onDismiss: {
                        activeGameLevel = nil
                    }
                )
            }
        }
    }
    
    // MARK: - By Level Sub-view
    @ViewBuilder
    private var levelScoresView: some View {
        if leaderboardItems.isEmpty {
            emptyStateView(message: "No level scores recorded yet! Play standard levels to set your best performance scores here.")
        } else {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(leaderboardItems.enumerated()), id: \.element.id) { index, item in
                        let rank = index + 1
                        
                        Button(action: {
                            if let level = LevelRepository.shared.level(for: item.levelId) {
                                detailsLevel = level
                            }
                        }) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                MedalBadgeView(rank: rank)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Level \(item.levelId)")
                                        .font(DesignSystem.Typography.caption)
                                        .bold()
                                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                    
                                    Text(item.title)
                                        .font(DesignSystem.Typography.subtitle)
                                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(item.score)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.yellow)
                                    
                                    if let accuracy = item.accuracy {
                                        Text("\(Int(accuracy * 100))% accuracy")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                    }
                                }
                            }
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - All-Time Best Attempts Sub-view
    @ViewBuilder
    private var allTimeAttemptsView: some View {
        if allTimeAttempts.isEmpty {
            emptyStateView(message: "No attempt history recorded yet! Make efforts on any level to build your score list.")
        } else {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(allTimeAttempts.enumerated()), id: \.element.id) { index, item in
                        let rank = index + 1
                        
                        Button(action: {
                            if let level = LevelRepository.shared.level(for: item.levelId) {
                                detailsLevel = level
                            }
                        }) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                MedalBadgeView(rank: rank)
                                
                                Spacer()
                                
                                Text("\(item.score)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                    .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State Component
    @ViewBuilder
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.ColorToken.textSecondary.opacity(0.5))
            
            Text("No efforts recorded yet!")
                .font(DesignSystem.Typography.subtitle)
                .foregroundColor(DesignSystem.ColorToken.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Formatting Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func medalColor(_ medal: TraceMedal) -> Color {
        switch medal {
        case .none: return .gray
        case .pass: return DesignSystem.ColorToken.success
        case .great: return DesignSystem.ColorToken.accentBlue
        case .perfect: return DesignSystem.ColorToken.accentCyan
        }
    }
}

struct MedalBadgeView: View {
    let rank: Int
    
    var body: some View {
        Group {
            switch rank {
            case 1:
                Image(systemName: "medal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // Gold
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 4)
            case 2:
                Image(systemName: "medal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // Silver
                    .shadow(color: Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.4), radius: 4)
            case 3:
                Image(systemName: "medal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(red: 0.80, green: 0.50, blue: 0.20)) // Bronze
                    .shadow(color: Color(red: 0.80, green: 0.50, blue: 0.20).opacity(0.4), radius: 4)
            default:
                Text("\(rank).")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
            }
        }
        .frame(width: 40)
    }
}
