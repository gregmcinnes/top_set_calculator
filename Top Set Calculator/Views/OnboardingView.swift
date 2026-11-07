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
            Color.bg
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
                VStack(spacing: SBSLayout.space6) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Rectangle()
                                .fill(index == currentPage ? Color.orangeFill : Color.hairline)
                                .frame(width: 10, height: 10)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: SBSLayout.space4) {
                        if currentPage > 0 {
                            Button {
                                withAnimation {
                                    currentPage -= 1
                                }
                            } label: {
                                Text("Back")
                            }
                            .buttonStyle(SBSSecondaryButtonStyle())
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
                        }
                        .buttonStyle(SBSPrimaryButtonStyle())
                    }
                    .padding(.horizontal, SBSLayout.space6)
                }
                .padding(.bottom, SBSLayout.space8)
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
        VStack(spacing: SBSLayout.space6) {
            Spacer()
            
            // The mark
            Image("TopSetMark")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .accessibilityHidden(true)
                .padding(.bottom, SBSLayout.space4)
            
            VStack(spacing: SBSLayout.space2) {
                Text("Welcome to")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.inkSecondary)
                
                Text("Top Set Calculator")
                    .titleLargeStyle()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.ink)
            }
            
            Text("Your complete toolkit for\nstrength training calculations")
                .font(SBSFonts.body())
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, SBSLayout.space2)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.space6)
    }
}

// MARK: - Calculators Page

private struct CalculatorsPage: View {
    var body: some View {
        VStack(spacing: SBSLayout.space6) {
            Spacer()
            
            VStack(spacing: SBSLayout.space2) {
                Text("Powerful Calculators")
                    .font(SBSFonts.title())
                    .foregroundStyle(Color.ink)
                
                Text("Everything you need to optimize your training")
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.space4) {
                CalculatorFeatureRow(
                    icon: "trophy.fill",
                    title: "One-Rep Max",
                    description: "Estimate your 1RM using 6 proven formulas"
                )
                
                CalculatorFeatureRow(
                    icon: "gauge.with.needle.fill",
                    title: "RPE Calculator",
                    description: "Find target weights for any RPE level"
                )
                
                CalculatorFeatureRow(
                    icon: "circle.grid.2x1.fill",
                    title: "Plate Calculator",
                    description: "Visualize exactly which plates to load"
                )
                
                CalculatorFeatureRow(
                    icon: "percent",
                    title: "Training Max",
                    description: "Calculate TM for percentage-based programs"
                )
                
                CalculatorFeatureRow(
                    icon: "scalemass.fill",
                    title: "Strength Scores",
                    description: "Wilks, DOTS & IPF GL points"
                )
            }
            .padding(.horizontal, SBSLayout.space4)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.space6)
    }
}

private struct CalculatorFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .field()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Spacer()
        }
        .padding()
        .card()
    }
}

// MARK: - Features Page

private struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: SBSLayout.space6) {
            Spacer()
            
            VStack(spacing: SBSLayout.space2) {
                Text("Customize Your Setup")
                    .font(SBSFonts.title())
                    .foregroundStyle(Color.ink)
                
                Text("Tailor the app to match your equipment")
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.space6) {
                FeatureCard(
                    icon: "slider.horizontal.3",
                    title: "Units & Bar Weight",
                    description: "Switch between pounds and kilograms. Set your default barbell weight."
                )
                
                FeatureCard(
                    icon: "paintpalette.fill",
                    title: "Custom Plate Colors",
                    description: "Personalize the barbell visualization to match your gym's plates.",
                    isPremium: true
                )
                
                FeatureCard(
                    icon: "tray.full.fill",
                    title: "My Plates",
                    description: "Tell the calculator which plates you own for accurate load-outs.",
                    isPremium: true
                )
            }
            .padding(.horizontal, SBSLayout.space4)
            
            HStack(spacing: 6) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                Text("Access settings from the gear icon")
                    .font(SBSFonts.caption())
            }
            .foregroundStyle(Color.inkSecondary)
            .padding(.top, SBSLayout.space2)
            
            Text("PRO features, including warm-ups and My Lifts, are part of a one-time Premium unlock.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.space6)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    var isPremium = false
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .field()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    
                    if isPremium {
                        PremiumBadge()
                    }
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .card()
    }
}

// MARK: - More Apps Page

private struct MoreAppsPage: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: SBSLayout.space6) {
            Spacer()
            
            VStack(spacing: SBSLayout.space2) {
                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.ink)

                    Text("The Top Set Suite")
                        .font(SBSFonts.title())
                        .foregroundStyle(Color.ink)
                }
                
                Text("Level up your training with our other apps")
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: SBSLayout.space4) {
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
            .padding(.horizontal, SBSLayout.space4)
            
            Text("You're all set!")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
                .padding(.top, SBSLayout.space6)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, SBSLayout.space6)
    }
}

private struct OnboardingAppCard: View {
    let iconName: String
    let appName: String
    let description: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: SBSLayout.space4) {
                HStack(spacing: SBSLayout.space4) {
                    // App Icon
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // App Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appName)
                            .font(SBSFonts.heading())
                            .foregroundStyle(Color.ink)
                        
                        Text("Health & Fitness")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Spacer()
                    
                    // External link indicator
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkSecondary)
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
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

