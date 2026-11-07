import SwiftUI

// MARK: - Main Calculators View

struct CalculatorsView: View {
    var settings: AppSettings
    @State private var showingSettings = false
    @State private var paywallFeature: PremiumFeature?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SBSLayout.space6) {
                    HomeHeader()

                    VStack(alignment: .leading, spacing: SBSLayout.space3) {
                        KnurlSectionHeader(title: "Calculators")
                        
                        calculatorCard(.oneRepMax, icon: "trophy.fill", title: "One-Rep Max", description: "Estimate your 1RM from submaximal lifts")
                        calculatorCard(.rpe(), icon: "gauge.with.needle.fill", title: "RPE Calculator", description: "Find weights for target RPE levels")
                        calculatorCard(.plate(), icon: "circle.grid.2x1.fill", title: "Plate Calculator", description: "Visualize which plates to load")
                        calculatorCard(.trainingMax(), icon: "percent", title: "Training Max", description: "Calculate TM and percentage charts")
                        calculatorCard(.scores, icon: "scalemass.fill", title: "Strength Scores", description: "Wilks, DOTS & IPF GL Points")
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: SBSLayout.space3) {
                        KnurlSectionHeader(title: "Plan & Track")
                        
                        premiumCard(.warmups, route: .warmups())
                        premiumCard(.myLifts, route: .myLifts)
                        premiumCard(.backoffSets, route: .backoff())
                        premiumCard(.meetPlanner, route: .meetPlanner)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .sbsBackground()
            .screenNavigation("Top Set Calculator")
            .calculatorDestinations(settings: settings)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.inkSecondary)
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
    
    private func calculatorCard(_ route: CalculatorRoute, icon: String, title: String, description: String) -> some View {
        NavigationLink(value: route) {
            CalculatorCard(icon: icon, title: title, description: description)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func premiumCard(_ feature: PremiumFeature, route: CalculatorRoute) -> some View {
        if StoreManager.shared.canAccess(feature) {
            calculatorCard(route, icon: feature.iconName, title: feature.displayName, description: feature.featureDescription)
        } else {
            Button {
                paywallFeature = feature
            } label: {
                PremiumCalculatorCard(icon: feature.iconName, title: feature.displayName, description: feature.featureDescription)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Home Header

private struct HomeHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: SBSLayout.space3) {
            Image("TopSetMark")
                .resizable()
                .scaledToFit()
                .frame(width: 56)
                .accessibilityHidden(true)

            ScreenTitle("Top Set Calculator")
                .padding(.horizontal, -SBSLayout.space4)
        }
        .padding(.horizontal, SBSLayout.space4)
    }
}

// MARK: - Calculator Card

struct CalculatorCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .field()
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkTertiary)
        }
        .padding()
        .card()
    }
}

// MARK: - Premium Calculator Card (Locked State)

struct PremiumCalculatorCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: SBSLayout.space4) {
            // Icon with lock overlay
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
                .frame(width: 44, height: 44)
                .field()
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    
                    PremiumBadge()
                }
                
                Text(description)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
                .accessibilityLabel("Locked")
        }
        .padding()
        .card()
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
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("One-Rep Max")
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
        .screenNavigation("One-Rep Max")
        .recordsCalculation(key: estimatedMax.map { "\($0)" })
    }
    
    private var inputSection: some View {
        VStack(spacing: SBSLayout.space4) {
            HStack {
                Text("Enter Your Lift")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            HStack(spacing: SBSLayout.space4) {
                // Weight input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight (\(unit))")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    
                    TextField("0", text: $weight)
                        .font(SBSFonts.numberLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .weight)
                        .padding()
                        .field()
                }
                
                Text("×")
                    .font(SBSFonts.title())
                    .foregroundStyle(Color.inkSecondary)
                
                // Reps input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reps")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    
                    TextField("0", text: $reps)
                        .font(SBSFonts.numberLarge())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .reps)
                        .padding()
                        .field()
                }
            }
            
            if let r = repsValue, r > OneRepMax.maximumReps {
                Text("Estimates only work up to \(OneRepMax.maximumReps) reps")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.warning)
            } else if let r = repsValue, r > 12 {
                Text("Estimates get less reliable above 12 reps")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.warning)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var resultsSection: some View {
        VStack(spacing: SBSLayout.space4) {
            // Median estimate (highlighted)
            if let estimate = estimatedMax {
                VStack(spacing: 8) {
                    Text("Estimated 1RM")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    
                    HeroNumber(value: formatWeight(estimate))
                    
                    Text("Median of all formulas")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SBSLayout.space6)
                .signatureCard()
                
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
            VStack(alignment: .leading, spacing: SBSLayout.space2) {
                Text("By Formula")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
                
                ForEach(results, id: \.name) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(SBSFonts.bodyStrong())
                                .foregroundStyle(Color.ink)
                            
                            Text(result.description)
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.inkSecondary)
                        }
                        
                        Spacer()
                        
                        Text(formatWeight(result.value))
                            .font(SBSFonts.number())
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.vertical, 8)
                    
                    if result.name != results.last?.name {
                        Divider().overlay(Color.hairline)
                    }
                }
            }
            .padding()
            .card()
            
            if let estimate = estimatedMax {
                trainingPercentagesSection(e1rm: estimate)
                repMaxSection(e1rm: estimate)
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private func trainingPercentagesSection(e1rm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Training Percentages")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: SBSLayout.space2) {
                ForEach([95, 90, 85, 80, 75, 70, 65, 60], id: \.self) { percentage in
                    let target = e1rm * Double(percentage) / 100.0
                    loadTile(label: "\(percentage)%", weight: target)
                }
            }
        }
        .padding()
        .card()
    }
    
    private func repMaxSection(e1rm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Estimated Rep Maxes")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: SBSLayout.space2) {
                ForEach([2, 3, 4, 5, 6, 8, 10, 12], id: \.self) { reps in
                    loadTile(label: "\(reps)RM", weight: RPETable.weight(e1RM: e1rm, reps: reps, rpe: 10))
                }
            }
        }
        .padding()
        .card()
    }
    
    /// A rounded weight that opens in the Plate Calculator when tapped
    private func loadTile(label: String, weight: Double) -> some View {
        NavigationLink(value: CalculatorRoute.plate(weight: settings.rounded(weight))) {
            VStack(spacing: 4) {
                Text(label)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                Text(settings.loadString(weight))
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .field()
        }
        .buttonStyle(.plain)
    }
    
    private func oneDecimal(_ weight: Double) -> Double {
        (weight * 10).rounded() / 10
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("How It Works")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Text("Enter a weight and the number of reps you completed. The calculator takes the median of six formulas to estimate your one-rep max. Results are most accurate for 1-10 reps; higher rep ranges become less reliable. Tap any weight to see how to load it.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .card()
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
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("RPE Calculator")
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
        .screenNavigation("RPE Calculator")
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
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("The Set You Completed")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
            
            WeightField(label: "Weight", text: $setWeight, unit: unit)
            
            Text("Pick the reps you did and how hard it felt below.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func maxResultSection(max: Double) -> some View {
        VStack(spacing: SBSLayout.space4) {
            VStack(spacing: 8) {
                Text("Estimated 1RM")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                HeroNumber(value: "\(max.weightString(maxFractionDigits: 1)) \(unit)")
                
                Text("\(setWeight) \(unit) × \(targetReps) @ RPE \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.numberSmall())
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.space6)
            .signatureCard()
            
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
        
        return VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Weights by Reps and RPE (\(unit))")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    GridRow {
                        Text("Reps")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                        ForEach(columns, id: \.self) { rpe in
                            Text(String(format: "%.1f", rpe))
                                .eyebrowStyle()
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                    
                    ForEach(Array(RPETable.repRange), id: \.self) { reps in
                        GridRow {
                            Text("\(reps)")
                                .eyebrowStyle()
                                .foregroundStyle(Color.inkSecondary)
                            
                            ForEach(columns, id: \.self) { rpe in
                                let isSelected = reps == targetReps && rpe == selectedRPE
                                Button {
                                    targetReps = reps
                                    selectedRPE = rpe
                                } label: {
                                    Text(settings.rounded(RPETable.weight(e1RM: e1rm, reps: reps, rpe: rpe)).weightString(maxFractionDigits: settings.roundingIncrement > 0 ? 2 : 1))
                                        .font(SBSFonts.caption())
                                        .monospacedDigit()
                                        .foregroundStyle(Color.ink)
                                        .frame(minWidth: 36, minHeight: 32)
                                        .chipBackground(isSelected: isSelected)
                                }
                                .accessibilityLabel("\(reps) reps at RPE \(String(format: "%.1f", rpe))")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var e1rmInputSection: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Your Estimated 1RM")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            HStack {
                TextField("Enter E1RM", text: $e1rm)
                    .font(SBSFonts.numberLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isE1RMFocused)
                
                Text(unit)
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding()
            .field()
            
            LiftFillChips(useMetric: settings.useMetric) { e1rm = $0.weightString(maxFractionDigits: 1) }
            
            Text("Don't know it? Switch to Find e1RM above, or use the One-Rep Max calculator.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var repsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Target Reps: \(targetReps)")
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(RPETable.repRange), id: \.self) { rep in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                targetReps = rep
                            }
                        } label: {
                            Text("\(rep)")
                                .font(SBSFonts.number())
                                .foregroundStyle(Color.ink)
                                .frame(width: 44, height: 44)
                                .chipBackground(isSelected: targetReps == rep)
                        }
                    }
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            HStack {
                Text("Target RPE: \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
                
                Spacer()
                
                Text(rpeDescription(selectedRPE))
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            HStack(spacing: 8) {
                ForEach(rpeValues, id: \.self) { rpe in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRPE = rpe
                        }
                    } label: {
                        Text(String(format: "%.1f", rpe))
                            .font(SBSFonts.numberSmall())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .chipBackground(isSelected: selectedRPE == rpe)
                    }
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func resultSection(weight: Double) -> some View {
        let load = settings.rounded(weight)
        
        return VStack(spacing: SBSLayout.space4) {
            VStack(spacing: 8) {
                Text("Target Weight")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                HeroNumber(value: settings.loadString(weight), style: .workingWeight)
                
                let percentage = percentageFor(reps: targetReps, rpe: selectedRPE)
                Text("\(Int((percentage * 100).rounded()))% of E1RM for \(targetReps) reps @ RPE \(String(format: "%.1f", selectedRPE))")
                    .font(SBSFonts.numberSmall())
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.space6)
            .signatureCard()
            
            ResultActions {
                ResultLink(title: "Load this weight", icon: "circle.grid.2x1.fill", route: .plate(weight: load))
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: load))
                PremiumResultLink(title: "Back-off Sets", icon: "arrow.down.right", feature: .backoffSets, route: .backoff(topSet: load))
            }
        }
        .padding(.horizontal)
    }
    
    private var rpeTableSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("RPE Reference")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            VStack(spacing: 8) {
                ForEach([10.0, 9.5, 9.0, 8.5, 8.0, 7.5, 7.0, 6.5], id: \.self) { rpe in
                    HStack {
                        Text(String(format: "%.1f", rpe))
                            .font(SBSFonts.number())
                            .foregroundStyle(Color.ink)
                            .fixedSize()
                            .frame(minWidth: 56, alignment: .leading)
                        
                        Text(rpeFullDescription(rpe))
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
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
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Plate Calculator")
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
        .screenNavigation("Plate Calculator")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: hasCustomizations ? "gearshape.fill" : "gearshape")
                        .foregroundStyle(hasCustomizations ? Color.orangeText : Color.inkSecondary)
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
                    .font(SBSFonts.bodyStrong())
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(Color.orangeText)
            .padding()
            .card()
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
            HStack(spacing: SBSLayout.space4) {
                Image(systemName: "tray.full.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .field()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Configure Your Plates")
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                        
                        PremiumBadge()
                    }
                    
                    Text("Set which plates you own for accurate calculations")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
            }
            .padding()
        .card()
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private var weightInputSection: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Total Weight")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            HStack(spacing: SBSLayout.space2) {
                stepButton(icon: "minus", label: "Decrease weight") {
                    setTarget(max(0, targetWeightValue - stepSize))
                }
                
                HStack {
                    TextField("0", text: $targetWeight)
                        .font(SBSFonts.numberLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($isWeightFocused)
                        .accessibilityLabel("Total Weight")
                    
                    Text(unit)
                        .font(SBSFonts.heading())
                        .foregroundStyle(Color.inkSecondary)
                }
                .padding()
                .field()
                
                stepButton(icon: "plus", label: "Increase weight") {
                    setTarget(min(PlateCalculator.maximumTotalWeight, targetWeightValue + stepSize))
                }
            }
            
            if targetWeightValue > 0 {
                Text("≈ \(Units.convert(targetWeightValue, fromMetric: useMetric, toMetric: !useMetric).weightString(maxFractionDigits: 1)) \(useMetric ? "lb" : "kg")")
                    .font(SBSFonts.numberSmall())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            if WeightInput.parse(targetWeight) != nil && targetWeightValue == 0 {
                Text("Enter a weight up to \(formatWeight(PlateCalculator.maximumTotalWeight))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.warning)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func stepButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .field()
        }
        .accessibilityLabel("\(label) by \(stepSize.weightString()) \(unit)")
    }
    
    private var isCustomBarWeight: Bool {
        !commonBarWeights.contains(barWeight)
    }
    
    private var barWeightSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Bar Weight: \(formatWeight(barWeight))")
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
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
                                .font(SBSFonts.numberSmall())
                                .fixedSize()
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .chipBackground(isSelected: barWeight == weight && !showingCustomBarWeight)
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
                            .foregroundStyle(Color.inkSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .field()
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
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .chipBackground(isSelected: showingCustomBarWeight || isCustomBarWeight)
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
                        .field()
                        .focused($isBarWeightFocused)
                        .onChange(of: customBarWeight) { _, newValue in
                            if let weight = WeightInput.parse(newValue, maximum: PlateCalculator.maximumTotalWeight) {
                                barWeight = weight
                            }
                        }
                    
                    Text(unit)
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
                .padding(.top, 4)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var barbellSection: some View {
        let calculator = PlateCalculator(barWeight: barWeight, settings: settings)
        let result = calculator.calculate(totalWeight: targetWeightValue)
        
        // Show what's actually on the bar when the exact weight can't be made
        let displayWeight = result.achievableWeight
        
        return VStack(spacing: SBSLayout.space4) {
            // Warning banner at top if weight can't be achieved
            if !result.isExact && result.remainder > 0 {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Can't make \(formatWeight(targetWeightValue))")
                                .font(SBSFonts.bodyStrong())
                            Text("Showing closest: \(formatWeight(result.achievableWeight)) (missing \(formatWeight(result.remainder * 2)))")
                                .font(SBSFonts.caption())
                        }
                        Spacer()
                    }
                    .foregroundStyle(Color.warning)
                    
                    HStack(spacing: 8) {
                        closestLoadButton(label: "Below", weight: result.achievableWeight)
                        if let above = calculator.closestLoad(atOrAbove: targetWeightValue) {
                            closestLoadButton(label: "Above", weight: above)
                        }
                    }
                    
                    if settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) {
                        Text("Add more plates in Settings to reach this weight.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    } else if !StoreManager.shared.canAccess(.extendedEquipment) {
                        Button {
                            paywallFeature = .extendedEquipment
                        } label: {
                            HStack(spacing: 4) {
                                Text("Upgrade to Premium for \(useMetric ? "0.5 kg" : "1.25 lb") change plates")
                                Image(systemName: "chevron.right")
                            }
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.orangeText)
                        }
                    }
                }
                .padding()
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                        .strokeBorder(Color.warning, lineWidth: SBSLayout.strokeHairline)
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
                    .foregroundStyle(Color.inkSecondary)
            }
            
            ResultActions {
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: displayWeight))
                PremiumResultLink(title: "Back-off Sets", icon: "arrow.down.right", feature: .backoffSets, route: .backoff(topSet: displayWeight))
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func closestLoadButton(label: String, weight: Double) -> some View {
        Button {
            setTarget(weight)
        } label: {
            Text("\(label): \(formatWeight(weight))")
                .font(SBSFonts.numberSmall())
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .card()
        }
    }
    
    private var quickWeightsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            if !recentWeights.isEmpty {
                Text("Recent")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentWeights, id: \.self) { weight in
                            Button {
                                setTarget(weight)
                            } label: {
                                Text(formatWeightShort(weight))
                                    .font(SBSFonts.numberSmall())
                                    .foregroundStyle(Color.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .field()
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            
            Text("Quick Select")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
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
                            .font(SBSFonts.numberSmall())
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .field()
                    }
                }
            }
        }
        .padding()
        .card()
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
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
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
                                    .foregroundStyle(Color.inkSecondary)
                            }
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(plate.color)
                                .frame(width: 12, height: 20)
                            
                            Text(plate.displayWeight(useMetric: useMetric))
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.ink)
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
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Training Max")
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
        .screenNavigation("Training Max")
        .recordsCalculation(key: trainingMax.map { "\($0)" })
        .onAppear {
            if let initialMax, !didApplyInitial {
                actualMax = initialMax.weightString(maxFractionDigits: 1)
            }
            didApplyInitial = true
        }
    }
    
    private var actualMaxSection: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Your Actual 1RM")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            HStack {
                TextField("Enter 1RM", text: $actualMax)
                    .font(SBSFonts.numberLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isMaxFocused)
                
                Text(unit)
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding()
            .field()
            
            LiftFillChips(useMetric: settings.useMetric) { actualMax = $0.weightString(maxFractionDigits: 1) }
            
            Text("Your tested or estimated one-rep max")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var tmPercentageSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            HStack {
                Text("TM Percentage: \(tmPercentage.weightString(maxFractionDigits: 1))%")
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
                
                Spacer()
            }
            
            // Slider
            Slider(value: $tmPercentage, in: 80...100, step: 2.5)
                .tint(Color.orangeFill)
            
            // Quick select buttons
            HStack(spacing: 8) {
                ForEach(tmPercentages, id: \.value) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tmPercentage = preset.value
                        }
                    } label: {
                        Text("\(preset.value.weightString(maxFractionDigits: 1))%")
                            .font(SBSFonts.numberSmall())
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .chipBackground(isSelected: tmPercentage == preset.value)
                    }
                }
            }
            
            // Show which program uses this percentage
            if let matchingPreset = tmPercentages.first(where: { $0.value == tmPercentage }) {
                Text(matchingPreset.program)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func trainingMaxResultSection(tm: Double) -> some View {
        VStack(spacing: SBSLayout.space4) {
            VStack(spacing: 8) {
                Text("Training Max")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                HeroNumber(value: formatWeight(tm))
                
                if let max = actualMaxValue {
                    Text("\(tmPercentage.weightString(maxFractionDigits: 1))% of \(max.weightString(maxFractionDigits: 1)) \(unit)")
                        .font(SBSFonts.numberSmall())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.space6)
            .signatureCard()
            
            ResultActions {
                ResultLink(title: "Load this weight", icon: "circle.grid.2x1.fill", route: .plate(weight: settings.rounded(tm)))
                PremiumResultLink(title: "Warm up to it", icon: "flame.fill", feature: .warmups, route: .warmups(topSet: settings.rounded(tm)))
            }
        }
        .padding(.horizontal)
    }
    
    private func percentageChartSection(tm: Double) -> some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Percentage Chart (of TM)")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            // Two-column layout
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(chartPercentages, id: \.self) { percentage in
                    let weight = tm * Double(percentage) / 100.0
                    
                    HStack {
                        Text("\(percentage)%")
                            .font(SBSFonts.numberSmall())
                            .foregroundStyle(Color.inkSecondary)
                            .fixedSize()
                        
                        Spacer(minLength: 4)
                        
                        Text(formatWeight(weight))
                            .font(SBSFonts.number())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(Color.ink)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .chipBackground(isSelected: percentage == 100)
                }
            }
            
            // 5/3/1 cycle
            VStack(alignment: .leading, spacing: 8) {
                Text("5/3/1 Cycle")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 8)
                
                programmingWeek(name: "Week 1 (5s)", sets: [(65, "5"), (75, "5"), (85, "5+")], tm: tm)
                programmingWeek(name: "Week 2 (3s)", sets: [(70, "3"), (80, "3"), (90, "3+")], tm: tm)
                programmingWeek(name: "Week 3 (5/3/1)", sets: [(75, "5"), (85, "3"), (95, "1+")], tm: tm)
                programmingWeek(name: "Week 4 (Deload)", sets: [(40, "5"), (50, "5"), (60, "5")], tm: tm)
                
                Text("\"+\" means as many good reps as you can. Joker sets are optional heavier sets after the top set, usually in 5-10% jumps.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func programmingWeek(name: String, sets: [(percentage: Int, reps: String)], tm: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.ink)
            
            ForEach(sets, id: \.percentage) { set in
                HStack {
                    Text("\(set.percentage)% × \(set.reps)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    
                    Spacer()
                    
                    Text(formatWeight(tm * Double(set.percentage) / 100.0))
                        .font(SBSFonts.numberSmall())
                        .foregroundStyle(Color.ink)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("What is a Training Max?")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Text("A Training Max (TM) is a percentage of your true 1RM used for programming. Using a TM (typically 85-90%) instead of your actual max allows for better bar speed, reduced injury risk, and room to progress over time. Most percentage-based programs calculate weights from your TM, not your true max.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .card()
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
        case 0..<thresholds.novice: return ("Beginner", Color.inkSecondary)
        case thresholds.novice..<thresholds.intermediate: return ("Novice", Color.inkSecondary)
        case thresholds.intermediate..<thresholds.advanced: return ("Intermediate", Color.ink)
        case thresholds.advanced..<thresholds.elite: return ("Advanced", Color.ink)
        case thresholds.elite..<thresholds.worldClass: return ("Elite", Color.success)
        case thresholds.worldClass...: return ("World Class", Color.orangeText)
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
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Strength Scores")
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
        .screenNavigation("Strength Scores")
        .recordsCalculation(key: canCalculate ? "\(bodyWeightValue ?? 0)-\(totalValue ?? 0)-\(isMale)" : nil)
    }
    
    private var sexSelectionSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Sex")
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
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
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .chipBackground(isSelected: isMale)
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
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .chipBackground(isSelected: !isMale)
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var inputSection: some View {
        VStack(spacing: SBSLayout.space4) {
            HStack {
                Text("Enter Your Data")
                    .font(SBSFonts.heading())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            // Body weight input
            VStack(alignment: .leading, spacing: 6) {
                Text("Body Weight (\(unit))")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                TextField("0", text: $bodyWeight)
                    .font(SBSFonts.numberLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .bodyWeight)
                    .padding()
                    .field()
            }
            
            // Input mode toggle
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useIndividualLifts = false
                    }
                } label: {
                    Text("Enter Total")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .chipBackground(isSelected: !useIndividualLifts)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useIndividualLifts = true
                    }
                } label: {
                    Text("Enter Lifts")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .chipBackground(isSelected: useIndividualLifts)
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
                                .font(SBSFonts.bodyStrong())
                                .foregroundStyle(Color.inkSecondary)
                            Spacer()
                            Text(formatWeight(calculatedTotal))
                                .font(SBSFonts.number())
                                .foregroundStyle(Color.ink)
                        }
                        .padding()
                        .field()
                    }
                }
            } else {
                // Total input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Powerlifting Total (\(unit))")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    
                    TextField("0", text: $total)
                        .font(SBSFonts.numberLarge())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .total)
                        .padding()
                        .field()
                    
                    Text("Squat + Bench + Deadlift")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func liftInputField(label: String, value: Binding<String>, field: StrengthField) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
                .frame(minWidth: 70, alignment: .leading)
            
            TextField("0", text: value)
                .font(SBSFonts.number())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: field)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .field()
            
            Text(unit)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .fixedSize()
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        "\(weight.weightString(maxFractionDigits: 1)) \(unit)"
    }
    
    private var resultsSection: some View {
        VStack(spacing: SBSLayout.space4) {
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
                                    .font(SBSFonts.caption())
                                    .foregroundStyle(Color.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedFormula == formula ? Color.orangeSoft : Color.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
                            }
                        }
                    }
                    
                    // Selected score large display
                    VStack(spacing: 8) {
                        Text("\(selectedFormula.rawValue) Score")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                        
                        HeroNumber(value: String(format: "%.2f", score))
                        
                        let classInfo = classification(for: score, formula: selectedFormula)
                        StatusBadge(text: classInfo.name, color: classInfo.color)
                        
                        if let next = nextLevel(after: score, formula: selectedFormula),
                           let currentTotal = totalValue,
                           let needed = StrengthScoring.total(forScore: next.score, currentScore: score, currentTotal: currentTotal) {
                            Text("+\(formatWeight(needed - currentTotal)) on your total to reach \(next.name)")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SBSLayout.space6)
                    .signatureCard()
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
                VStack(alignment: .leading, spacing: SBSLayout.space2) {
                    Text("Calculation Details")
                        .eyebrowStyle()
                        .foregroundStyle(Color.inkSecondary)
                    
                    HStack {
                        Text("Body Weight")
                            .font(SBSFonts.body())
                            .foregroundStyle(Color.inkSecondary)
                        Spacer()
                        Text(detailWeight(entered: bodyWeightValue, kilograms: bwKg))
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                    }
                    
                    Divider().overlay(Color.hairline)
                    
                    HStack {
                        Text("Total")
                            .font(SBSFonts.body())
                            .foregroundStyle(Color.inkSecondary)
                        Spacer()
                        Text(detailWeight(entered: totalValue, kilograms: tKg))
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                    }
                }
                .padding()
                .card()
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
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                Text(String(format: "%.1f", score))
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .chipBackground(isSelected: selectedFormula == formula)
        }
        .buttonStyle(.plain)
    }
    
    
    private var classificationGuideSection: some View {
        let thresholds = classificationThresholds(for: selectedFormula)
        
        return VStack(alignment: .leading, spacing: SBSLayout.space2) {
            Text("Classification Guide (\(selectedFormula.rawValue))")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
            
            Text(selectedFormula == .ipfGL 
                 ? "Approximate ranges. On the IPF GL scale, 100+ is roughly world class"
                 : "Approximate ranges for \(selectedFormula.rawValue)")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                classificationRow(name: "Beginner", range: "< \(Int(thresholds.novice))", color: Color.inkSecondary)
                classificationRow(name: "Novice", range: "\(Int(thresholds.novice)) - \(Int(thresholds.intermediate))", color: Color.inkSecondary)
                classificationRow(name: "Intermediate", range: "\(Int(thresholds.intermediate)) - \(Int(thresholds.advanced))", color: Color.ink)
                classificationRow(name: "Advanced", range: "\(Int(thresholds.advanced)) - \(Int(thresholds.elite))", color: Color.ink)
                classificationRow(name: "Elite", range: "\(Int(thresholds.elite)) - \(Int(thresholds.worldClass))", color: Color.success)
                classificationRow(name: "World Class", range: "\(Int(thresholds.worldClass))+", color: Color.orangeText)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func classificationRow(name: String, range: String, color: Color) -> some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
            Spacer()
            
            Text(range)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("About These Formulas")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                formulaInfoRow(
                    name: "Wilks",
                    description: "The classic formula used since 1994. Well-established but may favor middle weight classes."
                )
                
                Divider().overlay(Color.hairline)
                
                formulaInfoRow(
                    name: "DOTS",
                    description: "Created in 2019 to be more accurate for very light and very heavy lifters."
                )
                
                Divider().overlay(Color.hairline)
                
                formulaInfoRow(
                    name: "IPF GL",
                    description: "The IPF's official formula, adopted in 2020 to replace its earlier IPF Points."
                )
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func formulaInfoRow(name: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
            
            Text(description)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
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
