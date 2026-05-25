import SwiftUI
import StoreKit

struct GemShopView: View {
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @ObservedObject var progressStore = ProgressStore.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
            DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Huge jewel visual
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.ColorToken.gemPrimary.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .blur(radius: 10)
                        
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(DesignSystem.GradientToken.gemGradient)
                            .shadow(color: DesignSystem.ColorToken.gemPrimary.opacity(0.5), radius: 10)
                    }
                    
                    Text("GEMS SHOP")
                        .font(DesignSystem.Typography.heroScore)
                        .tracking(3)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text("Current Balance:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        Text("\(progressStore.progress.gems ?? 100)")
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(DesignSystem.ColorToken.accentCyan)
                    }
                }
                
                if purchaseManager.isLoadingProducts {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.ColorToken.accentCyan))
                        Text("Loading Shop...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorToken.textSecondary)
                            .padding(.top)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            if purchaseManager.gemProducts.isEmpty {
                                // Fallback/Demo items if StoreKit isn't fully set up yet
                                ForEach(fallbackPacks) { pack in
                                    GemPackRow(pack: pack, action: {
                                        // Simulate purchase locally for developers/players
                                        ProgressStore.shared.addGems(pack.gemCount)
                                        HapticsManager.shared.perfect()
                                        SoundManager.shared.perfect()
                                    })
                                }
                            } else {
                                ForEach(purchaseManager.gemProducts, id: \.id) { product in
                                    let pack = packFor(productID: product.id, product: product)
                                    GemPackRow(pack: pack, action: {
                                        Task {
                                            await purchaseManager.purchase(product)
                                        }
                                    })
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                    }
                }
            }
            
            if purchaseManager.isPerformingPurchase {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Contacting App Store...")
                            .foregroundColor(.white)
                            .font(DesignSystem.Typography.subtitle)
                    }
                }
            }
        }
        .onAppear {
            purchaseManager.initialize()
        }
    }
    
    private func packFor(productID: String, product: Product) -> GemPack {
        switch productID {
        case "trace.gems.50":
            return GemPack(id: productID, name: "Shard of Gems", gemCount: 50, priceString: product.displayPrice, description: "50 Gems for tracing lifelines", bonusText: nil, color: DesignSystem.ColorToken.lifelinePhantom, iconName: "eye", imageName: "Gems50")
        case "trace.gems.180":
            return GemPack(id: productID, name: "Cluster of Gems", gemCount: 180, priceString: product.displayPrice, description: "180 Gems - Slight power boost", bonusText: "+20% Bonus", color: DesignSystem.ColorToken.lifelineZen, iconName: "snowflake", imageName: "Gems180")
        case "trace.gems.350":
            return GemPack(id: productID, name: "Geode of Gems", gemCount: 350, priceString: product.displayPrice, description: "350 Gems - Keep the streak alive", bonusText: "+40% Bonus", color: DesignSystem.ColorToken.accentBlue, iconName: "diamond.fill", imageName: "Gems350")
        case "trace.gems.800":
            return GemPack(id: productID, name: "Supernova Vault", gemCount: 800, priceString: product.displayPrice, description: "800 Gems - Ultimate value vault", bonusText: "+60% Bonus", color: DesignSystem.ColorToken.lifelineWormhole, iconName: "aqi.medium", imageName: "Gems800")
        default:
            return GemPack(id: productID, name: product.displayName, gemCount: 50, priceString: product.displayPrice, description: product.description, bonusText: nil, color: DesignSystem.ColorToken.gemPrimary, iconName: "diamond", imageName: "Gems50")
        }
    }
    
    private var fallbackPacks: [GemPack] {
        [
            GemPack(id: "trace.gems.50", name: "Shard of Gems", gemCount: 50, priceString: "$0.99", description: "50 Gems for tracing lifelines", bonusText: nil, color: DesignSystem.ColorToken.lifelinePhantom, iconName: "eye", imageName: "Gems50"),
            GemPack(id: "trace.gems.180", name: "Cluster of Gems", gemCount: 180, priceString: "$2.99", description: "180 Gems - Slight power boost", bonusText: "+20% Bonus", color: DesignSystem.ColorToken.lifelineZen, iconName: "snowflake", imageName: "Gems180"),
            GemPack(id: "trace.gems.350", name: "Geode of Gems", gemCount: 350, priceString: "$4.99", description: "350 Gems - Keep the streak alive", bonusText: "+40% Bonus", color: DesignSystem.ColorToken.accentBlue, iconName: "diamond.fill", imageName: "Gems350"),
            GemPack(id: "trace.gems.800", name: "Supernova Vault", gemCount: 800, priceString: "$9.99", description: "800 Gems - Ultimate value vault", bonusText: "+60% Bonus", color: DesignSystem.ColorToken.lifelineWormhole, iconName: "aqi.medium", imageName: "Gems800")
        ]
    }
}

struct GemPack: Identifiable {
    let id: String
    let name: String
    let gemCount: Int
    let priceString: String
    let description: String
    let bonusText: String?
    let color: Color
    let iconName: String
    let imageName: String
}

struct GemPackRow: View {
    let pack: GemPack
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Glow Jewel icon
                ZStack {
                    Circle()
                        .fill(pack.color.opacity(0.12))
                        .frame(width: 50, height: 50)
                    
                    Image(pack.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .shadow(color: pack.color.opacity(0.4), radius: 6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let bonus = pack.bonusText {
                        Text(bonus)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(pack.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(pack.color.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(pack.color.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 2)
                    }
                    
                    Text(pack.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Text(pack.description)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 8)
                
                // Purchase button
                Text(pack.priceString)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [pack.color.opacity(0.85), pack.color.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                Capsule()
                                    .stroke(pack.color, lineWidth: 1)
                            )
                    )
                    .shadow(color: pack.color.opacity(0.3), radius: 4)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(DesignSystem.ColorToken.backgroundSecondary.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                LinearGradient(
                                    colors: [DesignSystem.ColorToken.surfaceBorder, pack.color.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
