import SwiftUI
import StoreKit

// MARK: - Paywall View

/// Full-screen upgrade view with feature comparison
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    let storeManager = StoreManager.shared
    
    @State private var isPurchasing = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var animateIn = false
    
    /// Optional: The specific feature that triggered this paywall
    var triggeredByFeature: PremiumFeature?
    
    /// Sheets opened from anywhere in the app should match the chosen appearance
    @AppStorage("appearanceMode") private var appearanceRawValue = AppearanceMode.system.rawValue
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    SBSColors.backgroundFallback,
                    SBSColors.backgroundFallback,
                    SBSColors.accentFallback.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: SBSLayout.paddingLarge) {
                    // Header
                    headerSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                    
                    // Feature list
                    featuresSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 30)
                    
                    // Price and purchase
                    purchaseSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 40)
                    
                    // Restore purchases
                    restoreSection
                        .opacity(animateIn ? 1 : 0)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SBSColors.textTertiaryFallback)
                            .padding()
                    }
                    .accessibilityLabel("Close")
                }
                Spacer()
            }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearanceRawValue)?.colorScheme)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            // Launch may have happened offline, so try again for a real price
            if storeManager.premiumProduct == nil {
                await storeManager.loadProducts()
            }
        }
        .onChange(of: storeManager.isPremium) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SBSColors.accentFallback.opacity(0.2),
                                SBSColors.accentFallback.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SBSColors.accentFallback, SBSColors.accentSecondaryFallback],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: SBSLayout.paddingSmall) {
                Text("Unlock Premium")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("Get the most out of your training")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .multilineTextAlignment(.center)
            }
            
            // If triggered by a specific feature, highlight it
            if let feature = triggeredByFeature {
                HStack(spacing: SBSLayout.paddingSmall) {
                    Image(systemName: feature.iconName)
                        .font(.system(size: 14))
                    Text(feature.displayName)
                        .font(SBSFonts.captionBold())
                }
                .foregroundStyle(SBSColors.accentFallback)
                .padding(.horizontal, SBSLayout.paddingMedium)
                .padding(.vertical, SBSLayout.paddingSmall)
                .background(
                    Capsule()
                        .fill(SBSColors.accentFallback.opacity(0.12))
                )
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            Text("What's Included")
                .font(SBSFonts.title3())
                .foregroundStyle(SBSColors.textPrimaryFallback)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: SBSLayout.paddingSmall) {
                ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                    PremiumFeatureRow(feature: feature)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                .fill(SBSColors.surfaceFallback)
        )
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            // Price badge
            VStack(spacing: 4) {
                Text("One-Time Purchase")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                
                Text(storeManager.premiumPriceString)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("Unlock forever • No subscription")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            // Purchase button
            Button {
                Task {
                    await purchasePremium()
                }
            } label: {
                HStack(spacing: SBSLayout.paddingSmall) {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Upgrade Now")
                    }
                }
                .font(SBSFonts.button())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SBSLayout.paddingMedium + 4)
                .background(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusLarge)
                        .fill(
                            LinearGradient(
                                colors: [SBSColors.accentFallback, SBSColors.accentSecondaryFallback],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(isPurchasing)
        }
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.accentFallback)
        }
        .disabled(isPurchasing)
        .padding(.top, SBSLayout.paddingSmall)
    }
    
    // MARK: - Actions
    
    private func purchasePremium() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            switch try await storeManager.purchasePremium() {
            case .purchased:
                dismiss()
            case .pending:
                presentAlert(
                    title: "Purchase Pending",
                    message: "Your purchase is waiting for approval. Premium will unlock automatically once it's approved."
                )
            case .cancelled:
                break
            }
        } catch {
            presentAlert(title: "Purchase Failed", message: error.localizedDescription)
        }
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            try await storeManager.restorePurchases()
            
            if storeManager.isPremium {
                dismiss()
            } else {
                presentAlert(
                    title: "No Purchases Found",
                    message: "We couldn't find a previous Premium purchase for this Apple Account."
                )
            }
        } catch StoreKitError.userCancelled {
            // The user backed out of signing in
        } catch {
            presentAlert(title: "Restore Failed", message: error.localizedDescription)
        }
    }
    
    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Feature Row

private struct PremiumFeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Icon
            ZStack {
                Circle()
                    .fill(SBSColors.accentFallback.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: feature.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SBSColors.accentFallback)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text(feature.featureDescription)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(SBSColors.success)
        }
        .padding(.vertical, SBSLayout.paddingSmall)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}

#Preview("Triggered by Feature") {
    PaywallView(triggeredByFeature: .warmups)
}

