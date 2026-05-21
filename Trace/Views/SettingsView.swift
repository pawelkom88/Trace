import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("HapticsEnabled") private var hapticsEnabled = true
    @AppStorage("SoundEnabled") private var soundEnabled = true
    @AppStorage("PreviewOnEveryTry") private var previewOnEveryTry = true
    @ObservedObject var purchaseManager = PurchaseManager.shared
    @State private var showResetConfirm = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.ColorToken.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .padding()
                        .background(DesignSystem.ColorToken.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    
                    Toggle("Sound", isOn: $soundEnabled)
                        .padding()
                        .background(DesignSystem.ColorToken.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    
                    Toggle("Watch Pattern on Every Try", isOn: $previewOnEveryTry)
                        .padding()
                        .background(DesignSystem.ColorToken.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    
                    Button(action: {
                        Task {
                            await purchaseManager.restorePurchases()
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            if purchaseManager.isPerformingPurchase {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.ColorToken.textPrimary))
                            } else {
                                Text("Restore Purchases")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.ColorToken.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .foregroundColor(DesignSystem.ColorToken.textPrimary)
                    }
                    .disabled(purchaseManager.isPerformingPurchase)
                    
                    Button(action: {
                        showResetConfirm = true
                    }) {
                        Text("Reset Progress")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.ColorToken.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                            .foregroundColor(DesignSystem.ColorToken.danger)
                    }
                    .confirmationDialog("Are you sure?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                        Button("Reset Progress", role: .destructive) {
                            ProgressStore.shared.resetProgress()
                            UserDefaults.standard.removeObject(forKey: "ResumeLevelID")
                            UserDefaults.standard.removeObject(forKey: "ZenModeLevelID")
                            dismiss() // Wipes progress and redirects immediately back to Home screen
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will erase all your scores and streaks. Purchase unlocks will be preserved.")
                    }
                    
                    Spacer()
                    
                    Text("PathMinder works offline. No account. No backend.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorToken.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: hapticsEnabled) { oldValue, newValue in
                HapticsManager.shared.isEnabled = newValue
            }
            .onChange(of: soundEnabled) { oldValue, newValue in
                SoundManager.shared.isEnabled = newValue
            }
            .alert("StoreKit Status", isPresented: Binding(
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
