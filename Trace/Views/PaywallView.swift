import SwiftUI

struct PaywallView: View {
    @ObservedObject var purchaseManager = PurchaseManager.shared
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
            DesignSystem.GradientToken.backgroundGlow.ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Spacer()
                
                Text("You’re getting good.")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("You’ve completed the first 15 levels. Unlock the full game to continue with harder patterns and sharper challenges.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    FeatureRow(text: "35 more levels")
                    FeatureRow(text: "Harder patterns")
                    FeatureRow(text: "Daily Challenge")
                    FeatureRow(text: "Local stats")
                }
                .padding(.vertical, DesignSystem.Spacing.xl)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await purchaseManager.purchase()
                        if purchaseManager.isPurchased {
                            onDismiss()
                        }
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if purchaseManager.isPerformingPurchase {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            let btnText = purchaseManager.unlockProduct != nil ? "Unlock Full Game — \(purchaseManager.unlockProduct!.displayPrice)" : "Unlock Full Game"
                            Text(btnText)
                                .font(DesignSystem.Typography.subtitle)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(purchaseManager.isPerformingPurchase ? AnyView(DesignSystem.ColorToken.surfaceBorder) : AnyView(DesignSystem.GradientToken.primaryCTA))
                    .cornerRadius(DesignSystem.Radius.pill)
                }
                .disabled(purchaseManager.isPerformingPurchase)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Button(action: onDismiss) {
                    Text("Continue with free practice")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                }
                .disabled(purchaseManager.isPerformingPurchase)
                
                Button(action: {
                    Task {
                        await purchaseManager.restorePurchases()
                        if purchaseManager.isPurchased {
                            onDismiss()
                        }
                    }
                }) {
                    Text("Restore Purchases")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorToken.accentCyan)
                }
                .disabled(purchaseManager.isPerformingPurchase)
                
                Text("One-time purchase. No subscription.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.ColorToken.textSecondary.opacity(0.5))
                    .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .alert("Purchase Error", isPresented: Binding(
                get: { purchaseManager.lastErrorMessage != nil },
                set: { if !$0 { purchaseManager.lastErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = purchaseManager.lastErrorMessage {
                    Text(message)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.ColorToken.accentCyan)
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.ColorToken.textPrimary)
        }
    }
}
