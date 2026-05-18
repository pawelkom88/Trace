import SwiftUI

struct LifelineBarView: View {
    @ObservedObject var viewModel: TraceGameViewModel
    @ObservedObject var progressStore = ProgressStore.shared
    var onLifelineSelected: (LifelineType) -> Void
    var onInsufficientGems: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(LifelineType.allCases, id: \.self) { lifeline in
                LifelineButton(
                    lifeline: lifeline,
                    viewModel: viewModel,
                    gems: progressStore.progress.gems ?? 100,
                    onLifelineSelected: onLifelineSelected,
                    onInsufficientGems: onInsufficientGems
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                .fill(DesignSystem.ColorToken.backgroundSecondary)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                        .stroke(DesignSystem.ColorToken.surfaceBorder, lineWidth: 1)
                )
        )
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

struct LifelineButton: View {
    let lifeline: LifelineType
    @ObservedObject var viewModel: TraceGameViewModel
    let gems: Int
    var onLifelineSelected: (LifelineType) -> Void
    var onInsufficientGems: () -> Void
    
    var canAfford: Bool {
        return gems >= lifeline.gemCost
    }
    
    var isEnabled: Bool {
        return viewModel.phase == .waitingForStart || viewModel.phase == .tracing
    }
    
    var body: some View {
        Button(action: {
            onLifelineSelected(lifeline)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? lifelineColor.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if isEnabled {
                        Circle()
                            .stroke(lifelineColor.opacity(canAfford ? 0.5 : 0.15), lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .shadow(color: lifelineColor.opacity(canAfford ? 0.6 : 0.0), radius: 5)
                    }
                    
                    Image(systemName: lifeline.iconSystemName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isEnabled ? (canAfford ? lifelineColor : lifelineColor.opacity(0.4)) : .gray)
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 7))
                        .foregroundColor(canAfford ? DesignSystem.ColorToken.gemPrimary : DesignSystem.ColorToken.gemPrimary.opacity(0.4))
                    Text("\(lifeline.gemCost)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isEnabled ? (canAfford ? .white : .white.opacity(0.4)) : .gray)
                }
            }
        }
        .disabled(!isEnabled)
    }
    
    private var lifelineColor: Color {
        switch lifeline {
        case .wormhole: return DesignSystem.ColorToken.lifelineWormhole
        case .zenFreeze: return DesignSystem.ColorToken.lifelineZen
        case .phantomGlimpse: return DesignSystem.ColorToken.lifelinePhantom
        }
    }
}
