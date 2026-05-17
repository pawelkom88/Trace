import SwiftUI

struct PracticeView: View {
    var onDismiss: () -> Void
    @State private var detailsLevel: TraceLevel?
    @State private var activeGameLevel: TraceLevel?
    
    let categories = [
        ("Straight Lines", 1...3),
        ("Curves", 4...4),
        ("Turns", 5...10),
        ("Zig-zags", 7...7),
        ("Mixed", 11...15)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        ForEach(categories, id: \.0) { category in
                            VStack(alignment: .leading) {
                                Text(category.0)
                                    .font(DesignSystem.Typography.subtitle)
                                    .foregroundColor(DesignSystem.ColorToken.textPrimary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DesignSystem.Spacing.md) {
                                        ForEach(category.1, id: \.self) { id in
                                            if let level = LevelRepository.shared.level(for: id) {
                                                Button(action: {
                                                    detailsLevel = level
                                                }) {
                                                    VStack {
                                                        Text("Level \(id)")
                                                            .font(DesignSystem.Typography.body)
                                                            .foregroundColor(DesignSystem.ColorToken.textPrimary)
                                                    }
                                                    .frame(width: 100, height: 100)
                                                    .background(DesignSystem.ColorToken.surface)
                                                    .cornerRadius(DesignSystem.Radius.medium)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Practice")
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
                GameView(level: level, onDismiss: {
                    activeGameLevel = nil
                })
            }
        }
    }
}
struct SparklineView: View {
    let data: [Double] // Accuracy values between 0.0 and 1.0
    
    var body: some View {
        GeometryReader { geo in
            if data.count < 2 {
                VStack {
                    Spacer()
                    Text("Need at least 2 attempts to plot progression")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            } else {
                Path { path in
                    let stepX = geo.size.width / CGFloat(data.count - 1)
                    
                    for (index, val) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height * CGFloat(1.0 - val) // 1.0 is top, 0.0 is bottom
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [DesignSystem.ColorToken.accentCyan, DesignSystem.ColorToken.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .background(
                    Path { path in
                        let stepX = geo.size.width / CGFloat(data.count - 1)
                        for (index, val) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height * CGFloat(1.0 - val)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        DesignSystem.ColorToken.accentCyan.opacity(0.3),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                    )
                )
            }
        }
    }
}

struct LevelDetailsView: View {
    let level: TraceLevel
    @Environment(\.dismiss) var dismiss
    var onStartLevel: () -> Void
    
    @ObservedObject private var progressStore = ProgressStore.shared
    
    init(level: TraceLevel, onStartLevel: @escaping () -> Void) {
        self.level = level
        self.onStartLevel = onStartLevel
    }
    
    var body: some View {
        ZStack {
            DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
            DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                    Spacer()
                    Text("Level \(level.id) Stats")
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .opacity(0)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Title Card
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text(level.title)
                                .font(DesignSystem.Typography.title)
                                .foregroundColor(DesignSystem.ColorToken.textPrimary)
                            
                            Text(level.difficulty.rawValue.uppercased())
                                .font(DesignSystem.Typography.caption)
                                .bold()
                                .foregroundColor(difficultyColor(level.difficulty))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(difficultyColor(level.difficulty).opacity(0.15))
                                .cornerRadius(DesignSystem.Radius.small)
                        }
                        .padding(.top)
                        
                        // Personal Best Summary
                        if let bestScorePercent = progressStore.progress.bestScoresByLevel[level.id] {
                            let bestPoints = Int(bestScorePercent * 10000)
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("PERSONAL BEST")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                    .tracking(1.5)
                                
                                Text("\(bestPoints) PTS")
                                    .font(DesignSystem.Typography.heroScore)
                                    .foregroundColor(.yellow)
                                
                                Text("Best Accuracy: \(Int(bestScorePercent * 100))%")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.ColorToken.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Text("No attempts yet")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                Text("Complete this level to establish a score!")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .padding(.horizontal)
                        }
                        
                        // Sparkline Chart (last 10 attempts)
                        if let attempts = progressStore.progress.attemptHistoryByLevel?[level.id], !attempts.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Progression Curve")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                    .tracking(1.0)
                                
                                SparklineView(data: attempts.map { $0.accuracy })
                                    .frame(height: 100)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .padding(.horizontal)
                        }
                        
                        // Attempts Leaderboard / List
                        if let attempts = progressStore.progress.attemptHistoryByLevel?[level.id], !attempts.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Recent Attempts")
                                    .font(DesignSystem.Typography.subtitle)
                                    .foregroundColor(DesignSystem.ColorToken.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(attempts.reversed().prefix(10)) { attempt in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(formatDate(attempt.date))
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(DesignSystem.ColorToken.textSecondary)
                                            Text("\(Int(attempt.accuracy * 100))% Accuracy")
                                                .font(DesignSystem.Typography.body)
                                                .foregroundColor(DesignSystem.ColorToken.textPrimary)
                                        }
                                        Spacer()
                                        
                                        if attempt.medal != .none {
                                            Text(attempt.medal.rawValue.capitalized)
                                                .font(DesignSystem.Typography.caption)
                                                .bold()
                                                .foregroundColor(medalColor(attempt.medal))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(medalColor(attempt.medal).opacity(0.15))
                                                .cornerRadius(4)
                                        }
                                        
                                        Text("\(attempt.points) PTS")
                                            .font(DesignSystem.Typography.subtitle)
                                            .foregroundColor(.yellow)
                                    }
                                    .padding(.horizontal)
                                    Divider().background(DesignSystem.ColorToken.surfaceBorder)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                
                // CTA Action Button
                Button(action: {
                    dismiss()
                    onStartLevel()
                }) {
                    Text(progressStore.progress.bestScoresByLevel[level.id] != nil ? "Replay Level" : "Start Level")
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.GradientToken.primaryCTA)
                        .cornerRadius(DesignSystem.Radius.pill)
                }
                .padding(.horizontal)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
        }
    }
    
    private func difficultyColor(_ diff: TraceDifficulty) -> Color {
        switch diff {
        case .easy: return .green
        case .normal: return .blue
        case .hard: return .orange
        case .expert: return .red
        }
    }
    
    private func medalColor(_ medal: TraceMedal) -> Color {
        switch medal {
        case .none: return .gray
        case .pass: return .blue
        case .great: return .purple
        case .perfect: return .yellow
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
