import SwiftUI

@main
struct Top_Set_CalculatorApp: App {
    @State private var settings = AppSettings()
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            CalculatorsView(settings: settings)
                .sbsBackground()
                .preferredColorScheme(settings.appearanceMode.colorScheme)
                .onAppear {
                    // Show onboarding on first launch
                    if !settings.hasSeenOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(settings: settings)
                }
        }
    }
}
