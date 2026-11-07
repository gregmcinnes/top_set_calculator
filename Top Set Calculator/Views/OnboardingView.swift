import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            // Background
            SBSColors.backgroundFallback
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    CalculatorsPage()
                        .tag(1)
                    
                    FeaturesPage()
                        .tag(2)
                    
                    MoreAppsPage(onGetStarted: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: SBSLayout.paddingLarge) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? SBSColors.accentFallback : SBSColors.textTertiaryFallback.opacity(0.5))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: SBSLayout.paddingMedium) {
                        if currentPage > 0 {
                            Button {
                                withAnimation {
                                    currentPage -= 1
                                }
                            } label: {
                                Text("Back")
                                    .font(SBSFonts.button())
                                    .foregroundStyle(SBSColors.textSecondaryFallback)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, SBSLayout.paddingMedium)
                            }
                        }
                        
                        Button {
                            if currentPage < totalPages - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                                .font(SBSFonts.button())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SBSLayout.paddingMedium)
                                .background(SBSColors.accentFallback)
                                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
                        }
                    }
                    .padding(.horizontal, SBSLayout.paddingLarge)
                }
                .padding(.bottom, SBSLayout.paddingXLarge)
            }
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
    
    private func completeOnboarding() {
        settings.hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: SBSLayout.sectionSpacing) {
            Spacer()
            
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SBSColors.accentFallback, SBSColors.accentSecondaryFallback],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: SBSColors.accentFallback.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, SBSLayout.paddingMedium)
            
            VStack(spacing: SBSLayout.paddingSmall) {
                Text("Welcome to")
                    .font(SBSFonts.title2())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Text("Top Set Calculator")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textPrimaryFallback)
            }
            
            Text("Your complete toolkit for\nstrength training calculations")
                .font(SBSFonts.body())
                .foregroundStyle(SBSColors.textSecondaryFallback)
                .multilineTextAlignment(.center)
                .padding(.top, SBSLayout.paddingSmall)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
    }
}

// MARK: - Calculators Page

private struct CalculatorsPage: View {
    var body: some View {
        VStack(spacing: SBSLayout.sectionSpacing) {
            Spacer()
            
            VStack(spacing: SBSLayout.paddingSmall) {
                Text("Powerful Calculators")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("Everything you need to optimize your training")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.paddingMedium) {
                CalculatorFeatureRow(
                    icon: "trophy.fill",
                    iconColor: .orange,
                    title: "One-Rep Max",
                    description: "Estimate your 1RM using 6 proven formulas"
                )
                
                CalculatorFeatureRow(
                    icon: "gauge.with.needle.fill",
                    iconColor: .purple,
                    title: "RPE Calculator",
                    description: "Find target weights for any RPE level"
                )
                
                CalculatorFeatureRow(
                    icon: "circle.grid.2x1.fill",
                    iconColor: .blue,
                    title: "Plate Calculator",
                    description: "Visualize exactly which plates to load"
                )
                
                CalculatorFeatureRow(
                    icon: "percent",
                    iconColor: .green,
                    title: "Training Max",
                    description: "Calculate TM for percentage-based programs"
                )
                
                CalculatorFeatureRow(
                    icon: "scalemass.fill",
                    iconColor: .mint,
                    title: "Strength Scores",
                    description: "Wilks, DOTS & IPF GL points"
                )
            }
            .padding(.horizontal, SBSLayout.paddingMedium)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
    }
}

private struct CalculatorFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            ZStack {
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Spacer()
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
    }
}

// MARK: - Features Page

private struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: SBSLayout.sectionSpacing) {
            Spacer()
            
            VStack(spacing: SBSLayout.paddingSmall) {
                Text("Customize Your Setup")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("Tailor the app to match your equipment")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.paddingLarge) {
                FeatureCard(
                    icon: "slider.horizontal.3",
                    title: "Units & Bar Weight",
                    description: "Switch between pounds and kilograms. Set your default barbell weight.",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "paintpalette.fill",
                    title: "Custom Plate Colors",
                    description: "Personalize the barbell visualization to match your gym's plates.",
                    color: .pink,
                    isPremium: true
                )
                
                FeatureCard(
                    icon: "tray.full.fill",
                    title: "My Plates",
                    description: "Tell the calculator which plates you own for accurate load-outs.",
                    color: .orange,
                    isPremium: true
                )
            }
            .padding(.horizontal, SBSLayout.paddingMedium)
            
            HStack(spacing: 6) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                Text("Access settings from the gear icon")
                    .font(SBSFonts.caption())
            }
            .foregroundStyle(SBSColors.textTertiaryFallback)
            .padding(.top, SBSLayout.paddingSmall)
            
            Text("PRO features, including warm-ups and My Lifts, are part of a one-time Premium unlock.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .multilineTextAlignment(.center)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var isPremium = false
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SBSFonts.bodyBold())
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                    
                    if isPremium {
                        PremiumBadge()
                    }
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
    }
}

// MARK: - More Apps Page

private struct MoreAppsPage: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: SBSLayout.sectionSpacing) {
            Spacer()
            
            VStack(spacing: SBSLayout.paddingSmall) {
                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SBSColors.accentFallback)
                    
                    Text("The Top Set Suite")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                }
                
                Text("Level up your training with our other apps")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.paddingMedium) {
                // Top Set Training
                OnboardingAppCard(
                    iconName: "TopSetTrainingIcon",
                    appName: "Top Set Training",
                    description: "A weight lifting tracker for proven lifting programs.",
                    url: "https://apps.apple.com/us/app/top-set-training/id6757244828"
                )
                
                // Top Set Timer
                OnboardingAppCard(
                    iconName: "TopSetTimerIcon",
                    appName: "Top Set Timer",
                    description: "A no-frills rest timer for weight lifting.",
                    url: "https://apps.apple.com/us/app/top-set-timer/id6756226855"
                )
            }
            .padding(.horizontal, SBSLayout.paddingMedium)
            
            Text("You're all set!")
                .font(SBSFonts.title3())
                .foregroundStyle(SBSColors.textPrimaryFallback)
                .padding(.top, SBSLayout.paddingLarge)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
    }
}

private struct OnboardingAppCard: View {
    let iconName: String
    let appName: String
    let description: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
                HStack(spacing: SBSLayout.paddingMedium) {
                    // App Icon
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // App Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appName)
                            .font(SBSFonts.title3())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                        
                        Text("Health & Fitness")
                            .font(.system(size: 12))
                            .foregroundStyle(SBSColors.textTertiaryFallback)
                    }
                    
                    Spacer()
                    
                    // External link indicator
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.surfaceFallback)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .stroke(SBSColors.textTertiaryFallback.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Previews

#Preview("Onboarding") {
    OnboardingView(settings: AppSettings())
}

#Preview("Welcome Page") {
    WelcomePage()
        .sbsBackground()
}

#Preview("Calculators Page") {
    CalculatorsPage()
        .sbsBackground()
}

#Preview("Features Page") {
    FeaturesPage()
        .sbsBackground()
}

#Preview("More Apps Page") {
    MoreAppsPage(onGetStarted: {})
        .sbsBackground()
}

