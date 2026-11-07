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
            Color.bg
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: SBSLayout.space6) {
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
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.ink)
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
        VStack(spacing: SBSLayout.space4) {
            Image("TopSetMark")
                .resizable()
                .scaledToFit()
                .frame(width: 72)
                .accessibilityHidden(true)
            
            VStack(spacing: SBSLayout.space2) {
                Text("Unlock Premium")
                    .titleLargeStyle()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink)
                
                Text("Get the most out of your training")
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // If triggered by a specific feature, highlight it
            if let feature = triggeredByFeature {
                HStack(spacing: SBSLayout.space2) {
                    Image(systemName: feature.iconName)
                        .font(.system(size: 14))
                    Text(feature.displayName)
                        .font(SBSFonts.caption())
                }
                .foregroundStyle(Color.ink)
                .padding(.horizontal, SBSLayout.space4)
                .padding(.vertical, SBSLayout.space2)
                .background(Color.orangeSoft)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: SBSLayout.space4) {
            Text("What's Included")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: SBSLayout.space2) {
                ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                    PremiumFeatureRow(feature: feature)
                }
            }
        }
        .padding()
        .card()
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: SBSLayout.space4) {
            // Price badge
            VStack(spacing: 4) {
                Text("One-Time Purchase")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                Text(storeManager.premiumPriceString)
                    .font(SBSFonts.numberLarge())
                    .foregroundStyle(Color.ink)
                
                Text("Unlock forever · No subscription")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            // Purchase button
            Button {
                Task {
                    await purchasePremium()
                }
            } label: {
                HStack(spacing: SBSLayout.space2) {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color.orangeInk)
                    } else {
                        Text("Upgrade Now")
                    }
                }
                
            }
            .buttonStyle(SBSPrimaryButtonStyle())
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
                .foregroundStyle(Color.orangeText)
        }
        .disabled(isPurchasing)
        .padding(.top, SBSLayout.space2)
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
        HStack(spacing: SBSLayout.space4) {
            // Icon
            Image(systemName: feature.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 36, height: 36)
                .field()
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Text(feature.featureDescription)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.success)
        }
        .padding(.vertical, SBSLayout.space2)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}

#Preview("Triggered by Feature") {
    PaywallView(triggeredByFeature: .warmups)
}

