import SwiftUI

// MARK: - Main Calculators View

struct CalculatorsView: View {
    var settings: AppSettings
    @State private var showingSettings = false
    @State private var paywallFeature: PremiumFeature?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SBSLayout.sectionSpacing) {
                    VStack(spacing: SBSLayout.cardSpacing) {
                        calculatorCard(.oneRepMax, icon: "trophy.fill", color: .orange, title: "One-Rep Max", description: "Estimate your 1RM from submaximal lifts")
                        calculatorCard(.rpe(), icon: "gauge.with.needle.fill", color: .purple, title: "RPE Calculator", description: "Find weights for target RPE levels")
                        calculatorCard(.plate(), icon: "circle.grid.2x1.fill", color: .blue, title: "Plate Calculator", description: "Visualize which plates to load")
                        calculatorCard(.trainingMax(), icon: "percent", color: .green, title: "Training Max", description: "Calculate TM and percentage charts")
                        calculatorCard(.scores, icon: "scalemass.fill", color: .mint, title: "Strength Scores", description: "Wilks, DOTS & IPF GL Points")
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: SBSLayout.cardSpacing) {
                        Text("Plan & Track")
                            .font(SBSFonts.title3())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                        
                        premiumCard(.warmups, route: .warmups(), color: .red)
                        premiumCard(.myLifts, route: .myLifts, color: .indigo)
                        premiumCard(.backoffSets, route: .backoff(), color: .teal)
                        premiumCard(.meetPlanner, route: .meetPlanner, color: .pink)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .sbsBackground()
            .navigationTitle("Top Set Calculator")
            .navigationBarTitleDisplayMode(.large)
            .calculatorDestinations(settings: settings)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                PlateSettingsView(settings: settings)
            }
            .sheet(item: $paywallFeature) { feature in
                PaywallView(triggeredByFeature: feature)
            }
        }
    }
    
    private func calculatorCard(_ route: CalculatorRoute, icon: String, color: Color, title: String, description: String) -> some View {
        NavigationLink(value: route) {
            CalculatorCard(icon: icon, iconColor: color, title: title, description: description)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func premiumCard(_ feature: PremiumFeature, route: CalculatorRoute, color: Color) -> some View {
        if StoreManager.shared.canAccess(feature) {
            calculatorCard(route, icon: feature.iconName, color: color, title: feature.displayName, description: feature.featureDescription)
        } else {
            Button {
                paywallFeature = feature
            } label: {
                PremiumCalculatorCard(icon: feature.iconName, iconColor: color, title: feature.displayName, description: feature.featureDescription)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Calculator Card

struct CalculatorCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding()
        .sbsCard()
    }
}

// MARK: - Premium Calculator Card (Locked State)

struct PremiumCalculatorCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Icon with lock overlay
            ZStack {
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor.opacity(0.5))
                
                // Lock badge
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Circle().fill(SBSColors.accentFallback))
                    .offset(x: 16, y: 16)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SBSFonts.bodyBold())
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                    
                    PremiumBadge()
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Spacer()
            
            // Unlock button indicator
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(SBSColors.accentFallback)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                .fill(SBSColors.surfaceFallback)
                .overlay(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                        .stroke(
                            LinearGradient(
                                colors: [SBSColors.accentFallback.opacity(0.3), SBSColors.accentSecondaryFallback.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: SBSLayout.shadowRadius, x: 0, y: SBSLayout.shadowY)
    }
}

// MARK: - One-Rep Max Calculator

struct OneRepMaxCalculatorView: View {
    var settings: AppSettings
    
    @AppStorage private var weight: String
    @AppStorage private var reps: String
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    init(settings: AppSettings) {
        self.settings = settings
        _weight = AppStorage(wrappedValue: "", "oneRepMax.weight.\(settings.unitLabel)")
        _reps = AppStorage(wrappedValue: "", "oneRepMax.reps")
    }
    
    private var weightValue: Double? {
        WeightInput.parse(weight)
    }
    
    private var repsValue: Int? {
        Int(reps)
    }
    
    // Different formulas for calculating 1RM
    private var results: [OneRepMax.Estimate] {
        guard let w = weightValue, let r = repsValue else { return [] }
        return OneRepMax.estimates(weight: w, reps: r)
    }
    
    private var estimatedMax: Double? {
        guard let w = weightValue, let r = repsValue else { return nil }
        return OneRepMax.median(weight: w, reps: r)
    }
    
    private var unit: String {
        settings.unitLabel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Input section
                inputSection
                
                // Results section
                if estimatedMax != nil {
                    resultsSection
                }
                
                // Info section
                infoSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("One-Rep Max")
        .navigationBarTitleDisplayMode(.inline)
        .recordsCalculation(key: estimatedMax.map { "\($0)" })
    }
    
    private var inputSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            HStack {
                Text("Enter Your Lift")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                Spacer()
            }
            
            HStack(spacing: SBSLayout.paddingMedium) {
                // Weight input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight (\(unit))")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    TextField("0", text: $weight)
                        .font(SBSFonts.weightLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .weight)
                        .padding()
                        .background(SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
                
                Text("×")
                    .font(SBSFonts.title())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                
                // Reps input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reps")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    TextField("0", text: $reps)
                        .font(SBSFonts.weightLarge())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .reps)
                        .padding()
                        .background(SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
            
            if let r = repsValue, r > OneRepMax.maximumReps {
                Text("Estimates only work up to \(OneRepMax.maximumReps) reps")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.warning)
            } else if let r = repsValue, r > 12 {
                Text("Estimates get less reliable above 12 reps")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.warning)
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var resultsSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            // Median estimate (highlighted)
            if let estimate = estimatedMax {
                VStack(spacing: 8) {
                    Text("Estimated 1RM")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    Text(formatWeight(estimate))
                        .heroNumberFont()
                        .foregroundStyle(SBSColors.accentFallback)
                    
                    Text("Median of all formulas")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SBSLayout.paddingLarge)
                .background(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                        .fill(SBSColors.accentFallback.opacity(0.1))
                )
                
                ResultActions {
                    ResultLink(title: "Use in RPE", icon: "gauge.with.needle.fill", route: .rpe(e1RM: oneDecimal(estimate)))
                    ResultLink(title: "Use in Training Max", icon: "percent", route: .trainingMax(max: oneDecimal(estimate)))
                    if let w = weightValue, let r = repsValue {
                        SaveSetButton(weight: w, reps: r, useMetric: settings.useMetric)
                    }
                    ShareResultButton(
                        title: "Estimated 1RM",
                        value: formatWeight(estimate),
                        detail: "\(weight) \(unit) × \(reps)"
                    )
                }
            }
            
            // Individual formula results
            VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
                Text("By Formula")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                ForEach(results, id: \.name) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(SBSFonts.bodyBold())
                                .foregroundStyle(SBSColors.textPrimaryFallback)
                            
                            Text(result.description)
                                .font(SBSFonts.caption())
                                .foregroundStyle(SBSColors.textTertiaryFallback)
                        }
                        
                        Spacer()
                        
                        Text(formatWeight(result.value))
                            .font(SBSFonts.number())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                    }
                    .padding(.vertical, 8)
                    
                    if result.name != results.last?.name {
                        Divider()
                    }
                }
            }
            .padding()
            .background(SBSColors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            
            if let estimate = estimatedMax {
                trainingPercentagesSection(e1rm: estimate)
                repMaxSection(e1rm: estimate)
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private func trainingPercentagesSection(e1rm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Training Percentages")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: SBSLayout.paddingSmall) {
                ForEach([95, 90, 85, 80, 75, 70, 65, 60], id: \.self) { percentage in
                    let target = e1rm * Double(percentage) / 100.0
                    loadTile(label: "\(percentage)%", weight: target)
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
    }
    
    private func repMaxSection(e1rm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Estimated Rep Maxes")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: SBSLayout.paddingSmall) {
                ForEach([2, 3, 4, 5, 6, 8, 10, 12], id: \.self) { reps in
                    loadTile(label: "\(reps)RM", weight: RPETable.weight(e1RM: e1rm, reps: reps, rpe: 10))
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
    }
    
    /// A rounded weight that opens in the Plate Calculator when tapped
    private func loadTile(label: String, weight: Double) -> some View {
        NavigationLink(value: CalculatorRoute.plate(weight: settings.rounded(weight))) {
            VStack(spacing: 4) {
                Text(label)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Text(settings.loadString(weight))
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(SBSColors.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
    }
    
    private func oneDecimal(_ weight: Double) -> Double {
        (weight * 10).rounded() / 10
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(SBSColors.accentSecondaryFallback)
                Text("How It Works")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Text("Enter a weight and the number of reps you completed. The calculator takes the median of six formulas to estimate your one-rep max. Results are most accurate for 1-10 reps; higher rep ranges become less reliable. Tap any weight to see how to load it.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        "\(weight.weightString(maxFractionDigits: 1)) \(unit)"
    }
}

// MARK: - RPE Calculator

struct RPECalculatorView: View {
    var settings: AppSettings
    private let initialE1RM: Double?
    
    private enum Mode: String, CaseIterable, Identifiable {
        case findWeight = "Find Weight"
        case findMax = "Find e1RM"
        var id: String { rawValue }
    }
    
    @AppStorage private var e1rm: String
    @AppStorage private var setWeight: String
    @AppStorage("rpe.mode") private var modeRaw = Mode.findWeight.rawValue
    @AppStorage("rpe.reps") private var targetReps = 5
    @AppStorage("rpe.rpe") private var selectedRPE = 8.0
    @State private var didApplyInitial = false
    @FocusState private var isE1RMFocused: Bool
    
    init(settings: AppSettings, initialE1RM: Double? = nil) {
        self.settings = settings
        self.initialE1RM = initialE1RM
        _e1rm = AppStorage(wrappedValue: "", "rpe.e1rm.\(settings.unitLabel)")
        _setWeight = AppStorage(wrappedValue: "", "rpe.setWeight.\(settings.unitLabel)")
    }
    
    private var mode: Mode {
        Mode(rawValue: modeRaw) ?? .findWeight
    }
    
    private var e1rmValue: Double? {
        WeightInput.parse(e1rm)
    }
    
    private var setWeightValue: Double? {
        WeightInput.parse(setWeight)
    }
    
    private var unit: String {
        settings.unitLabel
    }
    
    private let rpeValues = RPETable.rpeValues
    
    private func percentageFor(reps: Int, rpe: Double) -> Double {
        RPETable.percentage(reps: reps, rpe: rpe)
    }
    
    private var calculatedWeight: Double? {
        guard let e1rm = e1rmValue else { return nil }
        return RPETable.weight(e1RM: e1rm, reps: targetReps, rpe: selectedRPE)
    }
    
    private var calculatedMax: Double? {
        guard let weight = setWeightValue else { return nil }
        return RPETable.e1RM(weight: weight, reps: targetReps, rpe: selectedRPE)
    }
    
    /// The max the reference grid is built from, in either mode
    private var activeMax: Double? {
        mode == .findWeight ? e1rmValue : calculatedMax
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                Picker("Mode", selection: $modeRaw) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if mode == .findWeight {
                    e1rmInputSection
                } else {
                    setWeightInputSection
                }
                
                // Reps selector
                repsSection
                
                // RPE selector
                rpeSection
                
                // Result
                if mode == .findWeight, let weight = calculatedWeight {
                    resultSection(weight: weight)
                } else if mode == .findMax, let max = calculatedMax {
                    maxResultSection(max: max)
                }
                
                if let activeMax {
                    rpeGridSection(e1rm: activeMax)
                }
                
                // RPE table
                rpeTableSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("RPE Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: targetReps)
        .sensoryFeedback(.selection, trigger: selectedRPE)
        .recordsCalculation(key: activeMax.map { "\($0)-\(targetReps)-\(selectedRPE)-\(modeRaw)" })
        .onAppear {
            if let initialE1RM, !didApplyInitial {
                e1rm = initialE1RM.weightString(maxFractionDigits: 1)
                modeRaw = Mode.findWeight.rawValue
            }
            didApplyInitial = true
        }
    }
    
    private var setWeightInputSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("The Set You Completed")
                .font(SBSFonts.title3())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            WeightField(label: "Weight", text: $setWeight, unit: unit)
            
            Text("Pick the reps you did and how hard it felt below.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func maxResultSection(max: Double) -> some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            VStack(spacing: 8) {
                Text("Estimated 1RM")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Text("\(max.weightString(maxFractionDigits: 1)) \(unit)")
                    .heroNumberFont()
                    .foregroundStyle(SBSColors.accentFallback)
                
                Text("\(setWeight) \(unit) × \(targetReps) @ RPE \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.paddingLarge)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.accentFallback.opacity(0.1))
            )
            
            ResultActions {
                ResultLink(title: "Use in Training Max", icon: "percent", route: .trainingMax(max: (max * 10).rounded() / 10))
                if let setWeightValue {
                    PremiumResultLink(title: "Back-off Sets", icon: "arrow.down.right", feature: .backoffSets, route: .backoff(topSet: setWeightValue))
                    SaveSetButton(weight: setWeightValue, reps: targetReps, rpe: selectedRPE, useMetric: settings.useMetric)
                }
                ShareResultButton(
                    title: "Estimated 1RM",
                    value: "\(max.weightString(maxFractionDigits: 1)) \(unit)",
                    detail: "\(setWeight) \(unit) × \(targetReps) @ RPE \(String(format: "%.1f", selectedRPE))"
                )
            }
        }
        .padding(.horizontal)
    }
    
    /// Weights for every reps and RPE combination, with the current choice highlighted
    private func rpeGridSection(e1rm: Double) -> some View {
        let columns = rpeValues.filter { $0 >= 7 }.reversed().map { $0 }
        
        return VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Weights by Reps and RPE (\(unit))")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    GridRow {
                        Text("Reps")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textTertiaryFallback)
                        ForEach(columns, id: \.self) { rpe in
                            Text(String(format: "%.1f", rpe))
                                .font(SBSFonts.captionBold())
                                .foregroundStyle(SBSColors.textSecondaryFallback)
                        }
                    }
                    
                    ForEach(Array(RPETable.repRange), id: \.self) { reps in
                        GridRow {
                            Text("\(reps)")
                                .font(SBSFonts.captionBold())
                                .foregroundStyle(SBSColors.textSecondaryFallback)
                            
                            ForEach(columns, id: \.self) { rpe in
                                let isSelected = reps == targetReps && rpe == selectedRPE
                                Button {
                                    targetReps = reps
                                    selectedRPE = rpe
                                } label: {
                                    Text(settings.rounded(RPETable.weight(e1RM: e1rm, reps: reps, rpe: rpe)).weightString(maxFractionDigits: settings.roundingIncrement > 0 ? 2 : 1))
                                        .font(SBSFonts.caption())
                                        .monospacedDigit()
                                        .foregroundStyle(isSelected ? .white : SBSColors.textPrimaryFallback)
                                        .frame(minWidth: 36, minHeight: 32)
                                        .background(isSelected ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .accessibilityLabel("\(reps) reps at RPE \(String(format: "%.1f", rpe))")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private var e1rmInputSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            HStack {
                Text("Your Estimated 1RM")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                Spacer()
            }
            
            HStack {
                TextField("Enter E1RM", text: $e1rm)
                    .font(SBSFonts.weightLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isE1RMFocused)
                
                Text(unit)
                    .font(SBSFonts.title2())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            .padding()
            .background(SBSColors.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            
            LiftFillChips(useMetric: settings.useMetric) { e1rm = $0.weightString(maxFractionDigits: 1) }
            
            Text("Don't know it? Switch to Find e1RM above, or use the One-Rep Max calculator.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var repsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Target Reps: \(targetReps)")
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(RPETable.repRange), id: \.self) { rep in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                targetReps = rep
                            }
                        } label: {
                            Text("\(rep)")
                                .font(SBSFonts.bodyBold())
                                .foregroundStyle(targetReps == rep ? .white : SBSColors.textPrimaryFallback)
                                .frame(width: 44, height: 44)
                                .background(
                                    targetReps == rep ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback
                                )
                                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        }
                    }
                }
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            HStack {
                Text("Target RPE: \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Spacer()
                
                Text(rpeDescription(selectedRPE))
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            HStack(spacing: 8) {
                ForEach(rpeValues, id: \.self) { rpe in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRPE = rpe
                        }
                    } label: {
                        Text(String(format: "%.1f", rpe))
                            .font(SBSFonts.caption())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(selectedRPE == rpe ? .white : SBSColors.textPrimaryFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedRPE == rpe ? rpeColor(rpe) : SBSColors.surfaceElevatedFallback
                            )
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                }
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func resultSection(weight: Double) -> some View {
        let load = settings.rounded(weight)
        
        return VStack(spacing: SBSLayout.paddingMedium) {
            VStack(spacing: 8) {
                Text("Target Weight")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Text(settings.loadString(weight))
                    .heroNumberFont()
                    .foregroundStyle(SBSColors.accentFallback)
                
                let percentage = percentageFor(reps: targetReps, rpe: selectedRPE)
                Text("\(Int((percentage * 100).rounded()))% of E1RM for \(targetReps) reps @ RPE \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.paddingLarge)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.accentFallback.opacity(0.1))
            )
            
            ResultActions {
                ResultLink(title: "Load this weight", icon: "circle.grid.2x1.fill", route: .plate(weight: load))
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: load))
                PremiumResultLink(title: "Back-off Sets", icon: "arrow.down.right", feature: .backoffSets, route: .backoff(topSet: load))
            }
        }
        .padding(.horizontal)
    }
    
    private var rpeTableSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("RPE Reference")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            VStack(spacing: 8) {
                ForEach([10.0, 9.5, 9.0, 8.5, 8.0, 7.5, 7.0, 6.5], id: \.self) { rpe in
                    HStack {
                        Text(String(format: "%.1f", rpe))
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(rpeColor(rpe))
                            .frame(width: 40)
                        
                        Text(rpeFullDescription(rpe))
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func rpeColor(_ rpe: Double) -> Color {
        switch rpe {
        case 10: return .red
        case 9.5: return .orange
        case 9: return .orange
        case 8.5: return .yellow
        case 8: return .green
        case 7.5: return .green
        case 7: return .blue
        default: return .blue
        }
    }
    
    private func rpeDescription(_ rpe: Double) -> String {
        switch rpe {
        case 10: return "Max effort"
        case 9.5: return "Maybe 1 more"
        case 9: return "1 rep left"
        case 8.5: return "1-2 reps left"
        case 8: return "2 reps left"
        case 7.5: return "2-3 reps left"
        case 7: return "3 reps left"
        default: return "3+ reps left"
        }
    }
    
    private func rpeFullDescription(_ rpe: Double) -> String {
        switch rpe {
        case 10: return "Maximum effort, no reps left in the tank"
        case 9.5: return "Could maybe get 1 more rep"
        case 9: return "Could definitely get 1 more rep"
        case 8.5: return "Could get 1-2 more reps"
        case 8: return "Could get 2 more reps"
        case 7.5: return "Could get 2-3 more reps"
        case 7: return "Could get 3 more reps"
        default: return "Could get 3-4+ more reps"
        }
    }
    
}

// MARK: - Standalone Plate Calculator

struct StandalonePlateCalculatorView: View {
    var settings: AppSettings
    private let initialWeight: Double?
    
    @AppStorage("plate.target") private var targetWeight: String = ""
    @AppStorage("plate.recent.lb") private var recentImperial: String = ""
    @AppStorage("plate.recent.kg") private var recentMetric: String = ""
    @State private var barWeight: Double
    @State private var didApplyInitial = false
    @State private var steppedCount = 0
    @State private var showingSettings = false
    @State private var paywallFeature: PremiumFeature?
    @State private var showingCustomBarWeight = false
    @State private var customBarWeight: String = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isBarWeightFocused: Bool
    
    init(settings: AppSettings, initialWeight: Double? = nil) {
        self.settings = settings
        self.initialWeight = initialWeight
        _barWeight = State(initialValue: settings.barWeight)
    }
    
    private var useMetric: Bool {
        settings.useMetric
    }
    
    private var targetWeightValue: Double {
        WeightInput.parse(targetWeight, maximum: PlateCalculator.maximumTotalWeight) ?? 0
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
    }
    
    /// How far the plus and minus buttons move the weight
    private var stepSize: Double {
        settings.roundingIncrement > 0
            ? settings.roundingIncrement
            : WeightRounding.defaultIncrement(useMetric: useMetric)
    }
    
    private var recentWeights: [Double] {
        RecentWeights.decode(useMetric ? recentMetric : recentImperial)
    }
    
    private var commonBarWeights: [Double] {
        let hasPremiumEquipment = StoreManager.shared.canAccess(.extendedEquipment)
        if useMetric {
            return hasPremiumEquipment ? [25, 20, 15, 12, 10] : [20, 15, 10]
        } else {
            return hasPremiumEquipment ? [55, 45, 35, 30, 25, 15] : [45, 35, 25, 15]
        }
    }
    
    private var hasCustomizations: Bool {
        (settings.useCustomPlateColors && StoreManager.shared.canAccess(.customPlateColors)) ||
        (settings.useMyPlates && StoreManager.shared.canAccess(.myPlates))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Weight input
                weightInputSection
                
                // Bar weight selector
                barWeightSection
                
                // Gym switcher
                if StoreManager.shared.canAccess(.gymProfiles) && settings.gymProfiles.count > 1 {
                    gymSwitcher
                }
                
                // Barbell visualization
                if targetWeightValue > 0 {
                    barbellSection
                }
                
                // Plate legend
                PlateLegendView(useMetric: useMetric, settings: settings)
                    .padding(.horizontal)
                
                // Quick weights
                quickWeightsSection
                
                // Premium upgrade nudge (show if not premium)
                if !StoreManager.shared.isPremium {
                    premiumNudgeSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("Plate Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: hasCustomizations ? "gearshape.fill" : "gearshape")
                        .foregroundStyle(hasCustomizations ? SBSColors.accentFallback : SBSColors.textSecondaryFallback)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
            PlateSettingsView(settings: settings)
        }
        .sheet(item: $paywallFeature) { feature in
            PaywallView(triggeredByFeature: feature)
        }
        .onChange(of: settings.barWeight) { _, newValue in
            barWeight = newValue
        }
        .onChange(of: settings.useMetric) { _, _ in
            // The typed number means something different in the new unit
            targetWeight = ""
            showingCustomBarWeight = false
        }
        .sensoryFeedback(.selection, trigger: steppedCount)
        .recordsCalculation(key: targetWeightValue > 0 ? "\(targetWeightValue)-\(barWeight)" : nil)
        .task(id: targetWeightValue) {
            // Long enough that half-typed numbers don't end up in the list
            guard targetWeightValue > 0 else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            rememberCurrentWeight()
        }
        .onAppear {
            if let initialWeight, !didApplyInitial {
                targetWeight = initialWeight.weightString()
            }
            didApplyInitial = true
        }
    }
    
    private func rememberCurrentWeight() {
        let updated = RecentWeights.encode(RecentWeights.adding(targetWeightValue, to: recentWeights))
        if useMetric {
            recentMetric = updated
        } else {
            recentImperial = updated
        }
    }
    
    private var gymSwitcher: some View {
        Menu {
            ForEach(settings.gymProfiles) { profile in
                Button {
                    settings.selectGymProfile(id: profile.id)
                } label: {
                    if profile.id == settings.activeGymProfileID {
                        Label(profile.name, systemImage: "checkmark")
                    } else {
                        Text(profile.name)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "building.2.fill")
                Text(settings.activeGymProfile?.name ?? "Gym")
                    .font(SBSFonts.bodyBold())
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(SBSColors.accentFallback)
            .padding()
            .sbsCard()
        }
        .padding(.horizontal)
    }
    
    /// Sets the field to a nearby weight, as when stepping or picking a suggestion
    private func setTarget(_ weight: Double) {
        targetWeight = weight.weightString()
        isWeightFocused = false
        steppedCount += 1
    }
    
    private var premiumNudgeSection: some View {
        Button {
            paywallFeature = .myPlates
        } label: {
            HStack(spacing: SBSLayout.paddingMedium) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SBSColors.accentFallback.opacity(0.2), SBSColors.accentSecondaryFallback.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(SBSColors.accentFallback)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Configure Your Plates")
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                        
                        PremiumBadge()
                    }
                    
                    Text("Set which plates you own for accurate calculations")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.surfaceFallback)
                    .overlay(
                        RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                            .stroke(
                                LinearGradient(
                                    colors: [SBSColors.accentFallback.opacity(0.3), SBSColors.accentSecondaryFallback.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private var weightInputSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            HStack {
                Text("Total Weight")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                Spacer()
            }
            
            HStack(spacing: SBSLayout.paddingSmall) {
                stepButton(icon: "minus", label: "Decrease weight") {
                    setTarget(max(0, targetWeightValue - stepSize))
                }
                
                HStack {
                    TextField("0", text: $targetWeight)
                        .font(SBSFonts.weightLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($isWeightFocused)
                        .accessibilityLabel("Total Weight")
                    
                    Text(unit)
                        .font(SBSFonts.title2())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                }
                .padding()
                .background(SBSColors.surfaceElevatedFallback)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
                
                stepButton(icon: "plus", label: "Increase weight") {
                    setTarget(min(PlateCalculator.maximumTotalWeight, targetWeightValue + stepSize))
                }
            }
            
            if targetWeightValue > 0 {
                Text("≈ \(Units.convert(targetWeightValue, fromMetric: useMetric, toMetric: !useMetric).weightString(maxFractionDigits: 1)) \(useMetric ? "lb" : "kg")")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            
            if WeightInput.parse(targetWeight) != nil && targetWeightValue == 0 {
                Text("Enter a weight up to \(formatWeight(PlateCalculator.maximumTotalWeight))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.warning)
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func stepButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(SBSColors.accentFallback)
                .frame(width: 44, height: 44)
                .background(SBSColors.accentFallback.opacity(0.1))
                .clipShape(Circle())
        }
        .accessibilityLabel("\(label) by \(stepSize.weightString()) \(unit)")
    }
    
    private var isCustomBarWeight: Bool {
        !commonBarWeights.contains(barWeight)
    }
    
    private var barWeightSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Bar Weight: \(formatWeight(barWeight))")
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonBarWeights, id: \.self) { weight in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                barWeight = weight
                                showingCustomBarWeight = false
                            }
                        } label: {
                            Text(formatWeightShort(weight))
                                .font(SBSFonts.caption())
                                .fixedSize()
                                .foregroundStyle(barWeight == weight && !showingCustomBarWeight ? .white : SBSColors.textPrimaryFallback)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    barWeight == weight && !showingCustomBarWeight ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback
                                )
                                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        }
                    }
                    
                    // Custom bar weight button (premium only)
                    if !StoreManager.shared.canAccess(.extendedEquipment) {
                        Button {
                            paywallFeature = .extendedEquipment
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text("Custom")
                                    .font(SBSFonts.caption())
                                    .fixedSize()
                            }
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(SBSColors.surfaceElevatedFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        }
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingCustomBarWeight = true
                                customBarWeight = barWeight.weightString()
                            }
                            isBarWeightFocused = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 10))
                                Text("Custom")
                                    .font(SBSFonts.caption())
                                    .fixedSize()
                            }
                            .foregroundStyle(showingCustomBarWeight || isCustomBarWeight ? .white : SBSColors.textPrimaryFallback)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                showingCustomBarWeight || isCustomBarWeight ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback
                            )
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        }
                    }
                }
            }
            
            // Custom bar weight input field
            if showingCustomBarWeight && StoreManager.shared.canAccess(.extendedEquipment) {
                HStack(spacing: 8) {
                    TextField("Bar weight", text: $customBarWeight)
                        .font(SBSFonts.body())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        .focused($isBarWeightFocused)
                        .onChange(of: customBarWeight) { _, newValue in
                            if let weight = WeightInput.parse(newValue, maximum: PlateCalculator.maximumTotalWeight) {
                                barWeight = weight
                            }
                        }
                    
                    Text(unit)
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
                .padding(.top, 4)
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var barbellSection: some View {
        let calculator = PlateCalculator(barWeight: barWeight, settings: settings)
        let result = calculator.calculate(totalWeight: targetWeightValue)
        
        // Show what's actually on the bar when the exact weight can't be made
        let displayWeight = result.achievableWeight
        
        return VStack(spacing: SBSLayout.paddingMedium) {
            // Warning banner at top if weight can't be achieved
            if !result.isExact && result.remainder > 0 {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Can't make \(formatWeight(targetWeightValue))")
                                .font(SBSFonts.bodyBold())
                            Text("Showing closest: \(formatWeight(result.achievableWeight)) (missing \(formatWeight(result.remainder * 2)))")
                                .font(SBSFonts.caption())
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    
                    HStack(spacing: 8) {
                        closestLoadButton(label: "Below", weight: result.achievableWeight)
                        if let above = calculator.closestLoad(atOrAbove: targetWeightValue) {
                            closestLoadButton(label: "Above", weight: above)
                        }
                    }
                    
                    if settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) {
                        Text("Add more plates in Settings to reach this weight.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(.white.opacity(0.8))
                    } else if !StoreManager.shared.canAccess(.extendedEquipment) {
                        Button {
                            paywallFeature = .extendedEquipment
                        } label: {
                            HStack(spacing: 4) {
                                Text("Upgrade to Premium for \(useMetric ? "0.5 kg" : "1.25 lb") change plates")
                                Image(systemName: "chevron.right")
                            }
                            .font(SBSFonts.captionBold())
                            .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                        .fill(SBSColors.warning)
                )
            }
            
            BarbellView(
                weight: displayWeight,
                useMetric: useMetric,
                barWeight: barWeight,
                showLabels: true,
                compact: false,
                settings: settings
            )
            
            // Plate breakdown
            if !result.platesPerSide.isEmpty {
                PlateBreakdownView(result: result, useMetric: useMetric)
            } else if targetWeightValue <= calculator.emptyLoad {
                Text(targetWeightValue < calculator.emptyLoad
                     ? "\(formatWeight(targetWeightValue)) is lighter than the bar"
                     : "Bar only - no plates needed")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            ResultActions {
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: displayWeight))
                PremiumResultLink(title: "Back-off Sets", icon: "arrow.down.right", feature: .backoffSets, route: .backoff(topSet: displayWeight))
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func closestLoadButton(label: String, weight: Double) -> some View {
        Button {
            setTarget(weight)
        } label: {
            Text("\(label): \(formatWeight(weight))")
                .font(SBSFonts.captionBold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
        }
    }
    
    private var quickWeightsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            if !recentWeights.isEmpty {
                Text("Recent")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentWeights, id: \.self) { weight in
                            Button {
                                setTarget(weight)
                            } label: {
                                Text(formatWeightShort(weight))
                                    .font(SBSFonts.caption())
                                    .foregroundStyle(SBSColors.textPrimaryFallback)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(SBSColors.surfaceElevatedFallback)
                                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            
            Text("Quick Select")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            let quickWeights: [Double] = useMetric
                ? [60, 80, 100, 120, 140, 160, 180, 200]
                : [135, 185, 225, 275, 315, 365, 405, 455]
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(quickWeights, id: \.self) { weight in
                    Button {
                        setTarget(weight)
                    } label: {
                        Text(formatWeightShort(weight))
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(SBSColors.surfaceElevatedFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        "\(weight.weightString()) \(unit)"
    }
    
    private func formatWeightShort(_ weight: Double) -> String {
        weight.weightString()
    }
}

// MARK: - Plate Breakdown View

struct PlateBreakdownView: View {
    let result: PlateCalculatorResult
    let useMetric: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Load per side:")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            // Group plates by weight
            let grouped = Dictionary(grouping: result.platesPerSide) { $0.weight }
            let sortedWeights = grouped.keys.sorted(by: >)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(sortedWeights, id: \.self) { weight in
                    if let plates = grouped[weight], let plate = plates.first {
                        HStack(spacing: 4) {
                            if plates.count > 1 {
                                Text("\(plates.count)×")
                                    .font(SBSFonts.caption())
                                    .foregroundStyle(SBSColors.textSecondaryFallback)
                            }
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(plate.color)
                                .frame(width: 12, height: 20)
                            
                            Text(plate.displayWeight(useMetric: useMetric))
                                .font(SBSFonts.captionBold())
                                .foregroundStyle(SBSColors.textPrimaryFallback)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Training Max Calculator

struct TrainingMaxCalculatorView: View {
    var settings: AppSettings
    private let initialMax: Double?
    
    @AppStorage private var actualMax: String
    @AppStorage("trainingMax.percentage") private var tmPercentage: Double = 90
    @State private var didApplyInitial = false
    @FocusState private var isMaxFocused: Bool
    
    init(settings: AppSettings, initialMax: Double? = nil) {
        self.settings = settings
        self.initialMax = initialMax
        _actualMax = AppStorage(wrappedValue: "", "trainingMax.max.\(settings.unitLabel)")
    }
    
    private var actualMaxValue: Double? {
        WeightInput.parse(actualMax)
    }
    
    private var trainingMax: Double? {
        guard let max = actualMaxValue else { return nil }
        return max * (tmPercentage / 100.0)
    }
    
    private var unit: String {
        settings.unitLabel
    }
    
    // Common TM percentages used in different programs
    private let tmPercentages: [(value: Double, program: String)] = [
        (85, "Conservative / 5/3/1 BBB"),
        (90, "Standard / 5/3/1"),
        (92.5, "Moderate"),
        (95, "Aggressive")
    ]
    
    // Percentages to show in the chart
    private let chartPercentages = [100, 95, 90, 85, 80, 75, 70, 65, 60, 55, 50]
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Actual max input
                actualMaxSection
                
                // TM percentage selector
                tmPercentageSection
                
                // Training max result
                if let tm = trainingMax {
                    trainingMaxResultSection(tm: tm)
                }
                
                // Percentage chart
                if let tm = trainingMax {
                    percentageChartSection(tm: tm)
                }
                
                // Info section
                infoSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("Training Max")
        .navigationBarTitleDisplayMode(.inline)
        .recordsCalculation(key: trainingMax.map { "\($0)" })
        .onAppear {
            if let initialMax, !didApplyInitial {
                actualMax = initialMax.weightString(maxFractionDigits: 1)
            }
            didApplyInitial = true
        }
    }
    
    private var actualMaxSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            HStack {
                Text("Your Actual 1RM")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                Spacer()
            }
            
            HStack {
                TextField("Enter 1RM", text: $actualMax)
                    .font(SBSFonts.weightLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isMaxFocused)
                
                Text(unit)
                    .font(SBSFonts.title2())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            .padding()
            .background(SBSColors.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            
            LiftFillChips(useMetric: settings.useMetric) { actualMax = $0.weightString(maxFractionDigits: 1) }
            
            Text("Your tested or estimated one-rep max")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var tmPercentageSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            HStack {
                Text("TM Percentage: \(tmPercentage.weightString(maxFractionDigits: 1))%")
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Spacer()
            }
            
            // Slider
            Slider(value: $tmPercentage, in: 80...100, step: 2.5)
                .tint(SBSColors.accentFallback)
            
            // Quick select buttons
            HStack(spacing: 8) {
                ForEach(tmPercentages, id: \.value) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tmPercentage = preset.value
                        }
                    } label: {
                        Text("\(preset.value.weightString(maxFractionDigits: 1))%")
                            .font(SBSFonts.caption())
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(tmPercentage == preset.value ? .white : SBSColors.textPrimaryFallback)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                tmPercentage == preset.value ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback
                            )
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                }
            }
            
            // Show which program uses this percentage
            if let matchingPreset = tmPercentages.first(where: { $0.value == tmPercentage }) {
                Text(matchingPreset.program)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .padding(.top, 4)
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func trainingMaxResultSection(tm: Double) -> some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            VStack(spacing: 8) {
                Text("Training Max")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Text(formatWeight(tm))
                    .heroNumberFont()
                    .foregroundStyle(SBSColors.accentFallback)
                
                if let max = actualMaxValue {
                    Text("\(tmPercentage.weightString(maxFractionDigits: 1))% of \(max.weightString(maxFractionDigits: 1)) \(unit)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.paddingLarge)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(SBSColors.accentFallback.opacity(0.1))
            )
            
            ResultActions {
                ResultLink(title: "Load this weight", icon: "circle.grid.2x1.fill", route: .plate(weight: settings.rounded(tm)))
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: settings.rounded(tm)))
            }
        }
        .padding(.horizontal)
    }
    
    private func percentageChartSection(tm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Percentage Chart (of TM)")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            // Two-column layout
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(chartPercentages, id: \.self) { percentage in
                    let weight = tm * Double(percentage) / 100.0
                    
                    HStack {
                        Text("\(percentage)%")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                            .fixedSize()
                        
                        Spacer(minLength: 4)
                        
                        Text(formatWeight(weight))
                            .font(SBSFonts.bodyBold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(percentage == 100 ? SBSColors.accentFallback : SBSColors.textPrimaryFallback)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        percentage == 100 
                            ? SBSColors.accentFallback.opacity(0.1) 
                            : SBSColors.surfaceElevatedFallback
                    )
                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
            
            // 5/3/1 cycle
            VStack(alignment: .leading, spacing: 8) {
                Text("5/3/1 Cycle")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .padding(.top, 8)
                
                programmingWeek(name: "Week 1 (5s)", sets: [(65, "5"), (75, "5"), (85, "5+")], tm: tm)
                programmingWeek(name: "Week 2 (3s)", sets: [(70, "3"), (80, "3"), (90, "3+")], tm: tm)
                programmingWeek(name: "Week 3 (5/3/1)", sets: [(75, "5"), (85, "3"), (95, "1+")], tm: tm)
                programmingWeek(name: "Week 4 (Deload)", sets: [(40, "5"), (50, "5"), (60, "5")], tm: tm)
                
                Text("\"+\" means as many good reps as you can. Joker sets are optional heavier sets after the top set, usually in 5-10% jumps.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func programmingWeek(name: String, sets: [(percentage: Int, reps: String)], tm: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            ForEach(sets, id: \.percentage) { set in
                HStack {
                    Text("\(set.percentage)% × \(set.reps)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    Spacer()
                    
                    Text(formatWeight(tm * Double(set.percentage) / 100.0))
                        .font(SBSFonts.captionBold())
                        .foregroundStyle(SBSColors.textPrimaryFallback)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(SBSColors.accentSecondaryFallback)
                Text("What is a Training Max?")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Text("A Training Max (TM) is a percentage of your true 1RM used for programming. Using a TM (typically 85-90%) instead of your actual max allows for better bar speed, reduced injury risk, and room to progress over time. Most percentage-based programs calculate weights from your TM, not your true max.")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        settings.loadString(weight)
    }
}

// MARK: - Strength Scores View

struct StrengthScoresView: View {
    var settings: AppSettings
    
    @AppStorage private var bodyWeight: String
    @AppStorage private var total: String
    @AppStorage private var squat: String
    @AppStorage private var bench: String
    @AppStorage private var deadlift: String
    @AppStorage("scores.useIndividualLifts") private var useIndividualLifts: Bool = false
    @AppStorage("scores.isMale") private var isMale: Bool = true
    @State private var selectedFormula: StrengthFormula = .wilks
    @FocusState private var focusedField: StrengthField?
    
    init(settings: AppSettings) {
        self.settings = settings
        let unit = settings.unitLabel
        _bodyWeight = AppStorage(wrappedValue: "", "scores.bodyWeight.\(unit)")
        _total = AppStorage(wrappedValue: "", "scores.total.\(unit)")
        _squat = AppStorage(wrappedValue: "", "scores.squat.\(unit)")
        _bench = AppStorage(wrappedValue: "", "scores.bench.\(unit)")
        _deadlift = AppStorage(wrappedValue: "", "scores.deadlift.\(unit)")
    }
    
    private var useMetric: Bool {
        settings.useMetric
    }
    
    enum StrengthField {
        case bodyWeight, total, squat, bench, deadlift
    }
    
    enum StrengthFormula: String, CaseIterable {
        case wilks = "Wilks"
        case dots = "DOTS"
        case ipfGL = "IPF GL"
    }
    
    private var bodyWeightValue: Double? {
        WeightInput.parse(bodyWeight)
    }
    
    private var squatValue: Double {
        WeightInput.parse(squat) ?? 0
    }
    
    private var benchValue: Double {
        WeightInput.parse(bench) ?? 0
    }
    
    private var deadliftValue: Double {
        WeightInput.parse(deadlift) ?? 0
    }
    
    private var calculatedTotal: Double {
        squatValue + benchValue + deadliftValue
    }
    
    private var totalValue: Double? {
        if useIndividualLifts {
            let sum = calculatedTotal
            return sum > 0 ? sum : nil
        } else {
            return WeightInput.parse(total)
        }
    }
    
    private var canCalculate: Bool {
        guard let bw = bodyWeightValue, let t = totalValue else { return false }
        return bw > 0 && t > 0
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
    }
    
    // Convert lbs to kg for calculation
    private var bodyWeightKg: Double? {
        guard let bw = bodyWeightValue else { return nil }
        return useMetric ? bw : bw * 0.453592
    }
    
    private var totalKg: Double? {
        guard let t = totalValue else { return nil }
        return useMetric ? t : t * 0.453592
    }
    
    // Classification based on score (thresholds vary by formula)
    private func classification(for score: Double, formula: StrengthFormula) -> (name: String, color: Color) {
        let thresholds = classificationThresholds(for: formula)
        
        switch score {
        case 0..<thresholds.novice: return ("Beginner", .gray)
        case thresholds.novice..<thresholds.intermediate: return ("Novice", .blue)
        case thresholds.intermediate..<thresholds.advanced: return ("Intermediate", .green)
        case thresholds.advanced..<thresholds.elite: return ("Advanced", .orange)
        case thresholds.elite..<thresholds.worldClass: return ("Elite", .red)
        case thresholds.worldClass...: return ("World Class", .purple)
        default: return ("", .clear)
        }
    }
    
    private struct ClassificationThresholds {
        let novice: Double
        let intermediate: Double
        let advanced: Double
        let elite: Double
        let worldClass: Double
    }
    
    private func classificationThresholds(for formula: StrengthFormula) -> ClassificationThresholds {
        switch formula {
        case .wilks, .dots:
            // Wilks and DOTS use similar 0-500+ scale
            return ClassificationThresholds(
                novice: 200,
                intermediate: 300,
                advanced: 400,
                elite: 450,
                worldClass: 500
            )
        case .ipfGL:
            // IPF GL uses 0-100+ scale (100 = world record level)
            return ClassificationThresholds(
                novice: 35,
                intermediate: 50,
                advanced: 65,
                elite: 80,
                worldClass: 100
            )
        }
    }
    
    /// The next level up, or nil once at the top
    private func nextLevel(after score: Double, formula: StrengthFormula) -> (name: String, score: Double)? {
        let thresholds = classificationThresholds(for: formula)
        let levels: [(String, Double)] = [
            ("Novice", thresholds.novice),
            ("Intermediate", thresholds.intermediate),
            ("Advanced", thresholds.advanced),
            ("Elite", thresholds.elite),
            ("World Class", thresholds.worldClass)
        ]
        return levels.first { score < $0.1 }.map { (name: $0.0, score: $0.1) }
    }
    
    private func scoreFor(_ formula: StrengthFormula) -> Double? {
        guard let bwKg = bodyWeightKg, let tKg = totalKg else { return nil }
        
        switch formula {
        case .wilks: return StrengthScoring.wilks(totalKg: tKg, bodyweightKg: bwKg, isMale: isMale)
        case .dots: return StrengthScoring.dots(totalKg: tKg, bodyweightKg: bwKg, isMale: isMale)
        case .ipfGL: return StrengthScoring.ipfGL(totalKg: tKg, bodyweightKg: bwKg, isMale: isMale)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Sex selection
                sexSelectionSection
                
                // Input section
                inputSection
                
                // Results section
                if canCalculate {
                    resultsSection
                }
                
                // Classification guide
                classificationGuideSection
                
                // Info section
                infoSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("Strength Scores")
        .navigationBarTitleDisplayMode(.inline)
        .recordsCalculation(key: canCalculate ? "\(bodyWeightValue ?? 0)-\(totalValue ?? 0)-\(isMale)" : nil)
    }
    
    private var sexSelectionSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Sex")
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMale = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "figure.stand")
                        Text("Male")
                    }
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(isMale ? .white : SBSColors.textPrimaryFallback)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isMale ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback)
                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMale = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "figure.stand.dress")
                        Text("Female")
                    }
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(!isMale ? .white : SBSColors.textPrimaryFallback)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(!isMale ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback)
                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var inputSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            HStack {
                Text("Enter Your Data")
                    .font(SBSFonts.title3())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                Spacer()
            }
            
            // Body weight input
            VStack(alignment: .leading, spacing: 6) {
                Text("Body Weight (\(unit))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                TextField("0", text: $bodyWeight)
                    .font(SBSFonts.weightLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .bodyWeight)
                    .padding()
                    .background(SBSColors.surfaceElevatedFallback)
                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
            }
            
            // Input mode toggle
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useIndividualLifts = false
                    }
                } label: {
                    Text("Enter Total")
                        .font(SBSFonts.captionBold())
                        .foregroundStyle(!useIndividualLifts ? .white : SBSColors.textPrimaryFallback)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!useIndividualLifts ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useIndividualLifts = true
                    }
                } label: {
                    Text("Enter Lifts")
                        .font(SBSFonts.captionBold())
                        .foregroundStyle(useIndividualLifts ? .white : SBSColors.textPrimaryFallback)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(useIndividualLifts ? SBSColors.accentFallback : SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
            
            if useIndividualLifts {
                // Individual lift inputs
                VStack(spacing: 12) {
                    liftInputField(label: "Squat", value: $squat, field: .squat)
                    liftInputField(label: "Bench", value: $bench, field: .bench)
                    liftInputField(label: "Deadlift", value: $deadlift, field: .deadlift)
                    
                    // Show calculated total
                    if calculatedTotal > 0 {
                        HStack {
                            Text("Total")
                                .font(SBSFonts.bodyBold())
                                .foregroundStyle(SBSColors.textSecondaryFallback)
                            Spacer()
                            Text(formatWeight(calculatedTotal))
                                .font(SBSFonts.bodyBold())
                                .foregroundStyle(SBSColors.accentFallback)
                        }
                        .padding()
                        .background(SBSColors.accentFallback.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    }
                }
            } else {
                // Total input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Powerlifting Total (\(unit))")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    TextField("0", text: $total)
                        .font(SBSFonts.weightLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .total)
                        .padding()
                        .background(SBSColors.surfaceElevatedFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                    
                    Text("Squat + Bench + Deadlift")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func liftInputField(label: String, value: Binding<String>, field: StrengthField) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
                .frame(minWidth: 70, alignment: .leading)
            
            TextField("0", text: value)
                .font(SBSFonts.number())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: field)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(SBSColors.surfaceElevatedFallback)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
            
            Text(unit)
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
                .fixedSize()
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        "\(weight.weightString(maxFractionDigits: 1)) \(unit)"
    }
    
    private var resultsSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            // All three scores displayed as cards
            HStack(spacing: 12) {
                ForEach(StrengthFormula.allCases, id: \.self) { formula in
                    if let score = scoreFor(formula) {
                        scoreCard(formula: formula, score: score)
                    }
                }
            }
            
            // Detailed breakdown for selected formula
            if let score = scoreFor(selectedFormula) {
                VStack(spacing: 12) {
                    // Formula selector
                    HStack(spacing: 8) {
                        ForEach(StrengthFormula.allCases, id: \.self) { formula in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFormula = formula
                                }
                            } label: {
                                Text(formula.rawValue)
                                    .font(SBSFonts.captionBold())
                                    .foregroundStyle(selectedFormula == formula ? .white : SBSColors.textPrimaryFallback)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedFormula == formula ? formulaColor(formula) : SBSColors.surfaceFallback)
                                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                            }
                        }
                    }
                    
                    // Selected score large display
                    VStack(spacing: 8) {
                        Text("\(selectedFormula.rawValue) Score")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        Text(String(format: "%.2f", score))
                            .heroNumberFont(size: 56)
                            .foregroundStyle(formulaColor(selectedFormula))
                        
                        let classInfo = classification(for: score, formula: selectedFormula)
                        Text(classInfo.name)
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(classInfo.color)
                            .clipShape(Capsule())
                        
                        if let next = nextLevel(after: score, formula: selectedFormula),
                           let currentTotal = totalValue,
                           let needed = StrengthScoring.total(forScore: next.score, currentScore: score, currentTotal: currentTotal) {
                            Text("+\(formatWeight(needed - currentTotal)) on your total to reach \(next.name)")
                                .font(SBSFonts.caption())
                                .foregroundStyle(SBSColors.textSecondaryFallback)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SBSLayout.paddingLarge)
                    .background(
                        RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                            .fill(formulaColor(selectedFormula).opacity(0.1))
                    )
                }
            }
            
            if let score = scoreFor(selectedFormula) {
                ShareResultButton(
                    title: "\(selectedFormula.rawValue) Score",
                    value: String(format: "%.1f", score),
                    detail: classification(for: score, formula: selectedFormula).name
                )
            }
            
            // Calculation details
            if let bwKg = bodyWeightKg, let tKg = totalKg {
                VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
                    Text("Calculation Details")
                        .font(SBSFonts.captionBold())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    HStack {
                        Text("Body Weight")
                            .font(SBSFonts.body())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        Spacer()
                        Text(detailWeight(entered: bodyWeightValue, kilograms: bwKg))
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(SBSFonts.body())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        Spacer()
                        Text(detailWeight(entered: totalValue, kilograms: tKg))
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                    }
                }
                .padding()
                .background(SBSColors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    /// Scores are computed in kilograms, so pounds users see both
    private func detailWeight(entered: Double?, kilograms: Double) -> String {
        let metric = String(format: "%.1f kg", kilograms)
        guard !useMetric, let entered else { return metric }
        return "\(entered.weightString(maxFractionDigits: 1)) lb (\(metric))"
    }
    
    private func scoreCard(formula: StrengthFormula, score: Double) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFormula = formula
            }
        } label: {
            VStack(spacing: 6) {
                Text(formula.rawValue)
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(selectedFormula == formula ? .white : SBSColors.textSecondaryFallback)
                
                Text(String(format: "%.1f", score))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedFormula == formula ? .white : formulaColor(formula))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(selectedFormula == formula ? formulaColor(formula) : SBSColors.surfaceFallback)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .stroke(selectedFormula == formula ? Color.clear : formulaColor(formula).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formulaColor(_ formula: StrengthFormula) -> Color {
        switch formula {
        case .wilks: return .mint
        case .dots: return .orange
        case .ipfGL: return .purple
        }
    }
    
    private var classificationGuideSection: some View {
        let thresholds = classificationThresholds(for: selectedFormula)
        
        return VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
            Text("Classification Guide (\(selectedFormula.rawValue))")
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            Text(selectedFormula == .ipfGL 
                 ? "Approximate ranges. On the IPF GL scale, 100+ is roughly world class"
                 : "Approximate ranges for \(selectedFormula.rawValue)")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                classificationRow(name: "Beginner", range: "< \(Int(thresholds.novice))", color: .gray)
                classificationRow(name: "Novice", range: "\(Int(thresholds.novice)) - \(Int(thresholds.intermediate))", color: .blue)
                classificationRow(name: "Intermediate", range: "\(Int(thresholds.intermediate)) - \(Int(thresholds.advanced))", color: .green)
                classificationRow(name: "Advanced", range: "\(Int(thresholds.advanced)) - \(Int(thresholds.elite))", color: .orange)
                classificationRow(name: "Elite", range: "\(Int(thresholds.elite)) - \(Int(thresholds.worldClass))", color: .red)
                classificationRow(name: "World Class", range: "\(Int(thresholds.worldClass))+", color: .purple)
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func classificationRow(name: String, range: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(SBSFonts.bodyBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
            
            Spacer()
            
            Text(range)
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
        }
        .padding(.vertical, 4)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(SBSColors.accentSecondaryFallback)
                Text("About These Formulas")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                formulaInfoRow(
                    name: "Wilks",
                    color: .mint,
                    description: "The classic formula used since 1994. Well-established but may favor middle weight classes."
                )
                
                Divider()
                
                formulaInfoRow(
                    name: "DOTS",
                    color: .orange,
                    description: "Created in 2019 to be more accurate for very light and very heavy lifters."
                )
                
                Divider()
                
                formulaInfoRow(
                    name: "IPF GL",
                    color: .purple,
                    description: "The IPF's official formula, adopted in 2020 to replace its earlier IPF Points."
                )
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func formulaInfoRow(name: String, color: Color, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
        }
    }
}

// MARK: - Previews

#Preview("Calculators") {
    CalculatorsView(settings: AppSettings())
}

#Preview("1RM Calculator") {
    NavigationStack {
        OneRepMaxCalculatorView(settings: AppSettings())
    }
}

#Preview("RPE Calculator") {
    NavigationStack {
        RPECalculatorView(settings: AppSettings())
    }
}

#Preview("Plate Calculator") {
    NavigationStack {
        StandalonePlateCalculatorView(settings: AppSettings())
    }
}

#Preview("Training Max Calculator") {
    NavigationStack {
        TrainingMaxCalculatorView(settings: AppSettings())
    }
}

#Preview("Strength Scores") {
    NavigationStack {
        StrengthScoresView(settings: AppSettings())
    }
}
