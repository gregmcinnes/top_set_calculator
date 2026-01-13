import SwiftUI

// MARK: - Settings View

struct PlateSettingsView: View {
    @Bindable var settings: AppSettings
    @State private var showingPaywall = false
    @State private var showingCustomBarWeight = false
    @State private var customBarWeight: String = ""
    @State private var reviewModeTapCount = 0
    @State private var showReviewModeLogin = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isBarWeightFocused: Bool
    
    private var canAccessCustomColors: Bool {
        StoreManager.shared.canAccess(.customPlateColors)
    }
    
    private var canAccessMyPlates: Bool {
        StoreManager.shared.canAccess(.myPlates)
    }
    
    private var canAccessExtendedEquipment: Bool {
        StoreManager.shared.canAccess(.extendedEquipment)
    }
    
    private var standardBarWeights: [Double] {
        if settings.useMetric {
            return canAccessExtendedEquipment ? [25, 20, 15, 12, 10] : [20, 15, 10]
        } else {
            return canAccessExtendedEquipment ? [55, 45, 35, 30, 25, 15] : [45, 35, 25, 15]
        }
    }
    
    private var isCustomBarWeight: Bool {
        !standardBarWeights.contains(settings.barWeight)
    }
    
    private var plates: [Plate] {
        // Show all plates (including premium) if user has access
        if canAccessExtendedEquipment {
            return settings.useMetric ? StandardPlates.allMetricPlates : StandardPlates.allImperialPlates
        }
        return settings.useMetric ? StandardPlates.metricPlates : StandardPlates.plates
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SBSLayout.sectionSpacing) {
                    // General Settings Section
                    generalSettingsSection
                    
                    // Custom Colors Section
                    customColorsSection
                    
                    // My Plates Section
                    myPlatesSection
                    
                    // More Apps Section
                    moreAppsSection
                    
                    // Version Section (with hidden review mode unlock)
                    versionSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .sbsBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .preferredColorScheme(settings.appearanceMode.colorScheme)
            }
            .sheet(isPresented: $showReviewModeLogin) {
                ReviewModeLoginView()
                    .preferredColorScheme(settings.appearanceMode.colorScheme)
            }
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }
    
    // MARK: - Version Section
    
    private var versionSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            // Version info with hidden unlock gesture
            Text("Top Set Calculator")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .onTapGesture {
                    // Hidden gesture for App Store reviewers - tap version 7 times
                    reviewModeTapCount += 1
                    if reviewModeTapCount >= 7 {
                        showReviewModeLogin = true
                        reviewModeTapCount = 0
                    }
                    
                    // Reset count after 3 seconds of no taps
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if reviewModeTapCount < 7 {
                            reviewModeTapCount = 0
                        }
                    }
                }
            
            // Show review mode status if enabled
            if StoreManager.shared.isReviewModeEnabled {
                Text("Review Mode Active")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.success)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SBSLayout.paddingLarge)
    }
    
    // MARK: - General Settings Section
    
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                Text("General")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
            }
            
            // Appearance Mode
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                HStack(spacing: 8) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                settings.appearanceMode = mode
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20))
                                Text(mode.displayName)
                                    .font(SBSFonts.caption())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                                    .fill(settings.appearanceMode == mode ? 
                                          SBSColors.accentFallback.opacity(0.15) : 
                                          SBSColors.surfaceFallback)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                                    .stroke(settings.appearanceMode == mode ? 
                                            SBSColors.accentFallback : 
                                            SBSColors.textTertiaryFallback.opacity(0.3), 
                                            lineWidth: settings.appearanceMode == mode ? 2 : 1)
                            )
                            .foregroundStyle(settings.appearanceMode == mode ? 
                                             SBSColors.accentFallback : 
                                             SBSColors.textSecondaryFallback)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
            
            Divider()
                .background(SBSColors.textTertiaryFallback.opacity(0.2))
            
            // Unit Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Units")
                        .font(SBSFonts.bodyBold())
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                    Text(settings.useMetric ? "Kilograms (kg)" : "Pounds (lb)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                }
                
                Spacer()
                
                Picker("Units", selection: $settings.useMetric) {
                    Text("lb").tag(false)
                    Text("kg").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding(.vertical, 4)
            
            Divider()
                .background(SBSColors.textTertiaryFallback.opacity(0.2))
            
            // Bar Weight
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Bar Weight")
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                        Text("Used in Plate Calculator")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                    }
                    
                    Spacer()
                    
                    if !showingCustomBarWeight {
                        Menu {
                            ForEach(standardBarWeights, id: \.self) { weight in
                                Button {
                                    settings.barWeight = weight
                                } label: {
                                    HStack {
                                        Text("\(Int(weight)) \(settings.useMetric ? "kg" : "lb")")
                                        if settings.barWeight == weight {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            if canAccessExtendedEquipment {
                                Divider()
                                Button {
                                    customBarWeight = String(format: "%.0f", settings.barWeight)
                                    showingCustomBarWeight = true
                                    isBarWeightFocused = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Custom...")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if isCustomBarWeight {
                                    Text("Custom: \(Int(settings.barWeight)) \(settings.useMetric ? "kg" : "lb")")
                                } else {
                                    Text("\(Int(settings.barWeight)) \(settings.useMetric ? "kg" : "lb")")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(SBSColors.accentFallback)
                        }
                    }
                }
                
                // Custom bar weight input
                if showingCustomBarWeight && canAccessExtendedEquipment {
                    HStack(spacing: 8) {
                        TextField("Weight", text: $customBarWeight)
                            .font(SBSFonts.body())
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(SBSColors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                            .focused($isBarWeightFocused)
                            .onChange(of: customBarWeight) { _, newValue in
                                if let weight = Double(newValue), weight > 0 {
                                    settings.barWeight = weight
                                }
                            }
                        
                        Text(settings.useMetric ? "kg" : "lb")
                            .font(SBSFonts.body())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        Button {
                            showingCustomBarWeight = false
                            isBarWeightFocused = false
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(SBSColors.accentFallback)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    // MARK: - Custom Colors Section
    
    private var customColorsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(SBSColors.accentFallback)
                Text("Custom Plate Colors")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Spacer()
                
                if !canAccessCustomColors {
                    premiumBadge
                }
            }
            
            if canAccessCustomColors {
                Toggle("Enable Custom Colors", isOn: $settings.useCustomPlateColors)
                    .tint(SBSColors.accentFallback)
                
                if settings.useCustomPlateColors {
                    VStack(spacing: 12) {
                        ForEach(plates) { plate in
                            PlateColorRow(
                                plate: plate,
                                settings: settings,
                                useMetric: settings.useMetric
                            )
                        }
                    }
                    .padding(.top, 8)
                    
                    Button {
                        settings.customPlateColors = [:]
                    } label: {
                        Text("Reset to Default Colors")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.accentFallback)
                    }
                    .padding(.top, 8)
                }
            } else {
                lockedFeatureCard(
                    description: "Personalize your barbell with custom plate colors",
                    feature: .customPlateColors
                )
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    // MARK: - My Plates Section
    
    private var myPlatesSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(SBSColors.accentFallback)
                Text("My Plates")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Spacer()
                
                if !canAccessMyPlates {
                    premiumBadge
                }
            }
            
            Text("Configure which plates you own so the calculator only uses what you have available.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            if canAccessMyPlates {
                Toggle("Use My Plate Inventory", isOn: $settings.useMyPlates)
                    .tint(SBSColors.accentFallback)
                
                if settings.useMyPlates {
                    VStack(spacing: 12) {
                        ForEach(plates) { plate in
                            PlateInventoryRow(
                                plate: plate,
                                settings: settings,
                                useMetric: settings.useMetric
                            )
                        }
                    }
                    .padding(.top, 8)
                    
                    Button {
                        // Reset to default quantities (including premium plates if accessible)
                        if settings.useMetric {
                            if canAccessExtendedEquipment {
                                settings.myPlates = [25: 4, 20: 4, 15: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 2, 0.5: 2]
                            } else {
                                settings.myPlates = [25: 4, 20: 4, 15: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 2]
                            }
                        } else {
                            if canAccessExtendedEquipment {
                                settings.myPlates = [55: 2, 45: 4, 35: 2, 25: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 2]
                            } else {
                                settings.myPlates = [45: 4, 35: 2, 25: 2, 10: 2, 5: 2, 2.5: 2]
                            }
                        }
                    } label: {
                        Text("Reset to Default Quantities")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.accentFallback)
                    }
                    .padding(.top, 8)
                }
            } else {
                lockedFeatureCard(
                    description: "Tell the calculator which plates you have so it only uses what's available",
                    feature: .myPlates
                )
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    // MARK: - More Apps Section
    
    private var moreAppsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                Text("More from Top Set")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
            }
            
            // Top Set Training App Card
            appCard(
                iconName: "TopSetTrainingIcon",
                appName: "Top Set Training",
                description: "Run proven strength programs",
                url: "https://apps.apple.com/us/app/top-set-training/id6757244828"
            )
            
            // Top Set Timer App Card
            appCard(
                iconName: "TopSetTimerIcon",
                appName: "Top Set Timer",
                description: "Rest timer for weight lifting",
                url: "https://apps.apple.com/us/app/top-set-timer/id6756226855"
            )
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func appCard(iconName: String, appName: String, description: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: SBSLayout.paddingMedium) {
                // App Icon
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(appName)
                        .font(SBSFonts.bodyBold())
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                    
                    Text(description)
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                        .multilineTextAlignment(.leading)
                    
                    Text("Health & Fitness")
                        .font(.system(size: 10))
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
                
                Spacer()
                
                // External link indicator
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.surfaceFallback)
                    .overlay(
                        RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                            .stroke(SBSColors.textTertiaryFallback.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var premiumBadge: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SBSColors.accentFallback, SBSColors.accentSecondaryFallback],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
    
    private func lockedFeatureCard(description: String, feature: PremiumFeature) -> some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                Text(description)
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Button {
                showingPaywall = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Unlock with Premium")
                        .font(SBSFonts.captionBold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [SBSColors.accentFallback, SBSColors.accentSecondaryFallback],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                .fill(SBSColors.surfaceFallback)
                .overlay(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                        .strokeBorder(SBSColors.textTertiaryFallback.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Plate Color Row

struct PlateColorRow: View {
    let plate: Plate
    var settings: AppSettings
    let useMetric: Bool
    
    @State private var selectedColor: Color
    
    init(plate: Plate, settings: AppSettings, useMetric: Bool) {
        self.plate = plate
        self.settings = settings
        self.useMetric = useMetric
        
        // Initialize with current color (plate.color already has the correct default)
        _selectedColor = State(initialValue: settings.plateColor(for: plate.weight, defaultColor: plate.color))
    }
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Plate preview
            RoundedRectangle(cornerRadius: 3)
                .fill(selectedColor)
                .frame(width: 20, height: 32)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            // Weight label
            Text(plate.displayWeight(useMetric: useMetric))
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            Text(useMetric ? "kg" : "lb")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            Spacer()
            
            // Color picker
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .onChange(of: selectedColor) { _, newColor in
                    settings.setPlateColor(newColor, for: plate.weight)
                }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plate Inventory Row

struct PlateInventoryRow: View {
    let plate: Plate
    var settings: AppSettings
    let useMetric: Bool
    
    private var count: Int {
        settings.myPlates[plate.weight] ?? 0
    }
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Plate preview
            RoundedRectangle(cornerRadius: 3)
                .fill(plate.color)
                .frame(width: 20, height: 32)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            // Weight label
            VStack(alignment: .leading, spacing: 2) {
                Text(plate.displayWeight(useMetric: useMetric))
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("per side")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            
            Spacer()
            
            // Stepper
            HStack(spacing: 12) {
                Button {
                    let newCount = max(0, count - 1)
                    settings.myPlates[plate.weight] = newCount
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(count > 0 ? SBSColors.accentFallback : SBSColors.textTertiaryFallback)
                }
                .disabled(count == 0)
                
                Text("\(count)")
                    .font(SBSFonts.number())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                    .frame(minWidth: 30)
                
                Button {
                    let newCount = min(10, count + 1)
                    settings.myPlates[plate.weight] = newCount
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SBSColors.accentFallback)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Review Mode Login View

struct ReviewModeLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var isAuthenticating = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    // Review credentials - share these with Apple in App Store Connect
    // You can change these to whatever you prefer
    private static let reviewUsername = "app_review"
    private static let reviewPassword = "TopSet2026!"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: SBSLayout.sectionSpacing) {
                Spacer()
                
                // Lock icon
                ZStack {
                    Circle()
                        .fill(SBSColors.accentFallback.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(SBSColors.accentFallback)
                }
                
                Text("Authorized Access Only")
                    .font(SBSFonts.title2())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("Enter your credentials to continue")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                // Login form
                VStack(spacing: SBSLayout.paddingMedium) {
                    // Username field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                            .padding()
                            .background(SBSColors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(SBSColors.surfaceFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                    
                    // Error message
                    if showError {
                        Text("Invalid credentials")
                            .font(SBSFonts.caption())
                            .foregroundStyle(.red)
                    }
                    
                    // Login button
                    Button {
                        authenticate()
                    } label: {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                            }
                        }
                        .font(SBSFonts.button())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SBSLayout.paddingMedium)
                        .background(SBSColors.accentFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
                    }
                    .disabled(username.isEmpty || password.isEmpty || isAuthenticating)
                    .opacity(username.isEmpty || password.isEmpty ? 0.6 : 1)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                        .fill(SBSColors.surfaceFallback.opacity(0.5))
                )
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .sbsBackground()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .username
            }
        }
    }
    
    private func authenticate() {
        showError = false
        isAuthenticating = true
        
        // Small delay to feel more like a real auth check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAuthenticating = false
            
            if username.lowercased() == Self.reviewUsername.lowercased() && 
               password == Self.reviewPassword {
                // Success - enable review mode
                Task { @MainActor in
                    StoreManager.shared.enableReviewMode()
                }
                dismiss()
            } else {
                showError = true
                password = ""
            }
        }
    }
}

// MARK: - Previews

#Preview("Plate Settings") {
    PlateSettingsView(settings: AppSettings())
}

#Preview("Review Mode Login") {
    ReviewModeLoginView()
}

