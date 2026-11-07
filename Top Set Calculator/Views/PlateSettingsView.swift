import StoreKit
import SwiftUI

// MARK: - Settings View

struct PlateSettingsView: View {
    @Bindable var settings: AppSettings
    @State private var paywallFeature: PremiumFeature?
    @State private var restoreMessage: String?
    @State private var isRestoring = false
    @State private var newPlateWeight = ""
    @State private var collarText = ""
    @State private var showingNewProfile = false
    @State private var newProfileName = ""
    @State private var renamingProfile: GymProfile?
    @State private var renameText = ""
    @State private var showingCustomBarWeight = false
    @State private var customBarWeight: String = ""
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
        // Show all plates (including premium and custom sizes) if user has access
        StandardPlates.configurablePlates(with: settings, useMetric: settings.useMetric)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SBSLayout.space6) {
                    premiumStatusSection
                    
                    // General Settings Section
                    generalSettingsSection
                    
                    gymProfilesSection
                    
                    // My Plates Section
                    myPlatesSection
                    
                    extendedEquipmentSection
                    
                    // Custom Colors Section
                    customColorsSection
                    
                    // More Apps Section
                    moreAppsSection
                    
                    // Version Section
                    versionSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .sbsBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toggleStyle(SBSToggleStyle())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .keyboardDoneToolbar()
            .sheet(item: $paywallFeature) { feature in
                PaywallView(triggeredByFeature: feature)
            }
            .alert("Restore Purchases", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(restoreMessage ?? "")
            }
            .alert("New Gym", isPresented: $showingNewProfile) {
                TextField("Name", text: $newProfileName)
                Button("Add") {
                    let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        settings.addGymProfile(named: name)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Starts as a copy of your current setup.")
            }
            .alert("Rename Gym", isPresented: Binding(
                get: { renamingProfile != nil },
                set: { if !$0 { renamingProfile = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Save") {
                    let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let renamingProfile, !name.isEmpty {
                        settings.renameGymProfile(id: renamingProfile.id, to: name)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }
    
    // MARK: - Premium Status
    
    private var premiumStatusSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            if StoreManager.shared.isPremium {
                HStack(spacing: SBSLayout.space2) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.orangeText)
                    Text("Premium Active")
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                }
            } else {
                Button {
                    paywallFeature = .warmups
                } label: {
                    HStack(spacing: SBSLayout.space2) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.orangeText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Premium")
                                .font(SBSFonts.bodyStrong())
                                .foregroundStyle(Color.ink)
                            Text("One-time purchase, no subscription")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.inkSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.inkTertiary)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    Task { await restorePurchases() }
                } label: {
                    Text(isRestoring ? "Restoring…" : "Restore Purchases")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.orangeText)
                }
                .disabled(isRestoring)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            try await StoreManager.shared.restorePurchases()
            restoreMessage = StoreManager.shared.isPremium
                ? "Premium has been restored."
                : "We couldn't find a previous Premium purchase for this Apple Account."
        } catch StoreKitError.userCancelled {
            // The user backed out of signing in
        } catch {
            restoreMessage = error.localizedDescription
        }
    }
    
    // MARK: - Gym Profiles
    
    private var gymProfilesSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color.ink)
                Text("Gym Profiles")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
                if !StoreManager.shared.canAccess(.gymProfiles) {
                    PremiumBadge()
                }
            }
            
            if StoreManager.shared.canAccess(.gymProfiles) {
                Text("Each gym keeps its own units, bar, plates and collars. Changes below apply to the selected gym.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                ForEach(settings.gymProfiles) { profile in
                    HStack {
                        Button {
                            settings.selectGymProfile(id: profile.id)
                        } label: {
                            HStack {
                                Image(systemName: profile.id == settings.activeGymProfileID ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(profile.id == settings.activeGymProfileID ? Color.orangeText : Color.inkSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(SBSFonts.bodyStrong())
                                        .foregroundStyle(Color.ink)
                                    Text("\(profile.barWeight.weightString()) \(profile.useMetric ? "kg" : "lb") bar")
                                        .font(SBSFonts.numberSmall())
                                        .foregroundStyle(Color.inkSecondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Menu {
                            Button("Rename") {
                                renameText = profile.name
                                renamingProfile = profile
                            }
                            if settings.gymProfiles.count > 1 {
                                Button("Delete", role: .destructive) {
                                    settings.deleteGymProfile(id: profile.id)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.inkSecondary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel("Options for \(profile.name)")
                    }
                }
                
                Button {
                    newProfileName = ""
                    showingNewProfile = true
                } label: {
                    Label("Add Gym", systemImage: "plus")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.orangeText)
                }
            } else {
                lockedFeatureCard(
                    description: "Switch between home, commercial and meet setups",
                    feature: .gymProfiles
                )
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    // MARK: - Extended Equipment
    
    private var extendedEquipmentSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(Color.ink)
                Text("Extended Equipment")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
                if !canAccessExtendedEquipment {
                    PremiumBadge()
                }
            }
            
            if canAccessExtendedEquipment {
                if !settings.useMetric {
                    Toggle(isOn: $settings.use55LbPlates) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use 55 lb Plates")
                                .font(SBSFonts.bodyStrong())
                            Text("Loads 55s first. Most gyms top out at 45s.")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                    .tint(Color.orangeFill)
                    .disabled(settings.useMyPlates)
                    
                    if settings.useMyPlates {
                        Text("My Plates is on, so your 55 lb count decides this.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Divider().overlay(Color.hairline)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Collars")
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                        Text("Weight of one collar, counted on both sides")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Spacer()
                    
                    // Local text so a half-typed "2." isn't rewritten as "2" mid-keystroke
                    TextField("0", text: $collarText)
                    .onAppear(perform: refreshCollarText)
                    .onChange(of: collarText) { _, newValue in
                        settings.collarWeight = WeightInput.parse(newValue, maximum: 100) ?? 0
                    }
                    .onChange(of: settings.activeGymProfileID) { _, _ in refreshCollarText() }
                    .onChange(of: settings.useMetric) { _, _ in refreshCollarText() }
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 70)
                    .padding(8)
                    .field()
                    .accessibilityLabel("Collar weight")
                    
                    Text(settings.unitLabel)
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
                
                Divider().overlay(Color.hairline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Plate Sizes")
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    
                    ForEach(settings.customPlateWeights(useMetric: settings.useMetric).sorted(by: >), id: \.self) { weight in
                        HStack {
                            Text("\(weight.weightString()) \(settings.unitLabel)")
                                .font(SBSFonts.number())
                                .foregroundStyle(Color.ink)
                            Spacer()
                            Button {
                                settings.removeCustomPlate(weight: weight)
                            } label: {
                                Image(systemName: "minus.square.fill")
                                    .foregroundStyle(Color.danger)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityLabel("Remove \(weight.weightString()) \(settings.unitLabel) plate")
                        }
                    }
                    
                    HStack {
                        TextField(settings.useMetric ? "e.g. 0.25" : "e.g. 15", text: $newPlateWeight)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .field()
                            .accessibilityLabel("New plate size")
                        
                        Text(settings.unitLabel)
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                        
                        Button("Add") {
                            if let weight = WeightInput.parse(newPlateWeight, maximum: 200), settings.addCustomPlate(weight: weight) {
                                newPlateWeight = ""
                            }
                        }
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.orangeText)
                        .disabled(WeightInput.parse(newPlateWeight, maximum: 200) == nil)
                    }
                }
            } else {
                lockedFeatureCard(
                    description: "Custom plate sizes, collars, custom bars, and \(settings.useMetric ? "0.5 kg plates" : "55 lb & 1.25 lb plates")",
                    feature: .extendedEquipment
                )
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func refreshCollarText() {
        collarText = settings.collarWeight > 0 ? settings.collarWeight.weightString() : ""
    }
    
    // MARK: - Version Section
    
    private var versionSection: some View {
        VStack(spacing: SBSLayout.space2) {
            Text("Top Set Calculator")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SBSLayout.space6)
    }
    
    // MARK: - General Settings Section
    
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("General")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
            }
            
            // Appearance Mode
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
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
                            .chipBackground(isSelected: settings.appearanceMode == mode)
                            .foregroundStyle(Color.ink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
            
            Divider().overlay(Color.hairline)
            
            // Unit Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Units")
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    Text(settings.useMetric ? "Kilograms (kg)" : "Pounds (lb)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
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
            
            Divider().overlay(Color.hairline)
            
            // Rounding
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Round Weights To")
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                        Text("For suggested training weights")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Picker("Round Weights To", selection: Binding(
                            get: { settings.roundingIncrement },
                            set: { settings.roundingIncrement = $0 }
                        )) {
                            ForEach(WeightRounding.options(useMetric: settings.useMetric), id: \.self) { option in
                                Text(roundingLabel(option)).tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(roundingLabel(settings.roundingIncrement))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.orangeText)
                    }
                }
                
                if let step = settings.smallestLoadStep, settings.roundingIncrement > 0,
                   (settings.roundingIncrement / step).rounded() != settings.roundingIncrement / step {
                    Text("Your plates load in \(step.weightString()) \(settings.unitLabel) steps, so some rounded weights won't be exact on the bar.")
                        .font(SBSFonts.numberSmall())
                        .foregroundStyle(Color.warning)
                }
            }
            .padding(.vertical, 4)
            
            Divider().overlay(Color.hairline)
            
            // Bar Weight
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Bar Weight")
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                        Text("Used in Plate Calculator")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Spacer()
                    
                    if !showingCustomBarWeight {
                        Menu {
                            ForEach(standardBarWeights, id: \.self) { weight in
                                Button {
                                    settings.barWeight = weight
                                } label: {
                                    HStack {
                                        Text("\(weight.weightString()) \(settings.useMetric ? "kg" : "lb")")
                                        if settings.barWeight == weight {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            if canAccessExtendedEquipment {
                                Divider().overlay(Color.hairline)
                                Button {
                                    customBarWeight = settings.barWeight.weightString()
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
                                    Text("Custom: \(settings.barWeight.weightString()) \(settings.useMetric ? "kg" : "lb")")
                                } else {
                                    Text("\(settings.barWeight.weightString()) \(settings.useMetric ? "kg" : "lb")")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Color.orangeText)
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
                            .field()
                            .focused($isBarWeightFocused)
                            .onChange(of: customBarWeight) { _, newValue in
                                if let weight = WeightInput.parse(newValue, maximum: PlateCalculator.maximumTotalWeight) {
                                    settings.barWeight = weight
                                }
                            }
                        
                        Text(settings.useMetric ? "kg" : "lb")
                            .font(SBSFonts.body())
                            .foregroundStyle(Color.inkSecondary)
                        
                        Button {
                            showingCustomBarWeight = false
                            isBarWeightFocused = false
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.orangeText)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func roundingLabel(_ increment: Double) -> String {
        increment > 0 ? "\(increment.weightString()) \(settings.unitLabel)" : "Off"
    }
    
    // MARK: - Custom Colors Section
    
    private var customColorsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(Color.ink)
                Text("Custom Plate Colors")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                
                Spacer()
                
                if !canAccessCustomColors {
                    premiumBadge
                }
            }
            
            if canAccessCustomColors {
                Toggle("Enable Custom Colors", isOn: $settings.useCustomPlateColors)
                    .tint(Color.orangeFill)
                
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
                        settings.resetPlateColors()
                    } label: {
                        Text("Reset to Default Colors")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.orangeText)
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
        .card()
        .padding(.horizontal)
    }
    
    // MARK: - My Plates Section
    
    private var myPlatesSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(Color.ink)
                Text("My Plates")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                
                Spacer()
                
                if !canAccessMyPlates {
                    premiumBadge
                }
            }
            
            Text("Configure which plates you own so the calculator only uses what you have available.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            
            if canAccessMyPlates {
                Toggle("Use My Plate Inventory", isOn: $settings.useMyPlates)
                    .tint(Color.orangeFill)
                
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
                        settings.resetPlateInventory()
                    } label: {
                        Text("Reset to Default Quantities")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.orangeText)
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
        .card()
        .padding(.horizontal)
    }
    
    // MARK: - More Apps Section
    
    private var moreAppsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("More from Top Set")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
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
        .card()
        .padding(.horizontal)
    }
    
    private func appCard(iconName: String, appName: String, description: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: SBSLayout.space4) {
                // App Icon
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(appName)
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    
                    Text(description)
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                        .multilineTextAlignment(.leading)
                    
                    Text("Health & Fitness")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkSecondary)
                }
                
                Spacer()
                
                // External link indicator
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .fill(Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                            .stroke(Color.hairline, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var premiumBadge: some View {
        PremiumBadge()
    }
    
    private func lockedFeatureCard(description: String, feature: PremiumFeature) -> some View {
        VStack(spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text(description)
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Button {
                paywallFeature = feature
            } label: {
                Text("Unlock with Premium")
            }
            .buttonStyle(SBSSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .card()
    }
}

// MARK: - Plate Color Row

struct PlateColorRow: View {
    let plate: Plate
    var settings: AppSettings
    let useMetric: Bool
    
    private var color: Color {
        settings.plateColor(for: plate.weight, defaultColor: plate.color)
    }
    
    private var colorBinding: Binding<Color> {
        Binding(
            get: { color },
            set: { settings.setPlateColor($0, for: plate.weight) }
        )
    }
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            // Plate preview
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 20, height: 32)
            
            // Weight label
            Text(plate.displayWeight(useMetric: useMetric))
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
            Text(useMetric ? "kg" : "lb")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            
            Spacer()
            
            // Color picker
            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plate Inventory Row

struct PlateInventoryRow: View {
    let plate: Plate
    var settings: AppSettings
    let useMetric: Bool
    
    private let maximumCount = 10
    
    private var count: Int {
        settings.plateCount(for: plate.weight)
    }
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            // Plate preview
            RoundedRectangle(cornerRadius: 3)
                .fill(settings.plateColor(for: plate.weight, defaultColor: plate.color))
                .frame(width: 20, height: 32)
            
            // Weight label
            VStack(alignment: .leading, spacing: 2) {
                Text(plate.displayWeight(useMetric: useMetric))
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Text("per side")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Spacer()
            
            // Stepper
            HStack(spacing: 12) {
                Button {
                    settings.setPlateCount(max(0, count - 1), for: plate.weight)
                } label: {
                    Image(systemName: "minus.square.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(count > 0 ? Color.ink : Color.inkTertiary)
                }
                .disabled(count == 0)
                .accessibilityLabel("Remove \(plate.displayWeight) \(useMetric ? "kg" : "lb") plate")
                
                Text("\(count)")
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
                    .frame(minWidth: 30)
                
                Button {
                    settings.setPlateCount(min(maximumCount, count + 1), for: plate.weight)
                } label: {
                    Image(systemName: "plus.square.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(count < maximumCount ? Color.ink : Color.inkTertiary)
                }
                .disabled(count >= maximumCount)
                .accessibilityLabel("Add \(plate.displayWeight) \(useMetric ? "kg" : "lb") plate")
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.selection, trigger: count)
    }
}

// MARK: - Previews

#Preview("Plate Settings") {
    PlateSettingsView(settings: AppSettings())
}

