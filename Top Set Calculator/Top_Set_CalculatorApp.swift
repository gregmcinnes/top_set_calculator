import SwiftUI

@main
struct Top_Set_CalculatorApp: App {
    @State private var settings: AppSettings
    @State private var showOnboarding = false
    
    init() {
        #if DEBUG
        // UI tests start from a clean slate, before anything loads saved state
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetState") {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            try? FileManager.default.removeItem(at: LiftStore.defaultFileURL)
        }
        if arguments.contains("-seedSampleLifts") {
            LiftStore.shared.seedSampleHistoryForTesting()
        }
        #endif
        _settings = State(initialValue: AppSettings())
    }
    
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
