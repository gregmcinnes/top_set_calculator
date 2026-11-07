import SwiftUI

// MARK: - Strength Standards Calculator

struct StrengthStandardsView: View {
    let useMetric: Bool
    let isPremium: Bool
    
    @State private var bodyweight: String = ""
    @State private var isMale: Bool = true
    @State private var ageCategory: AgeCategory = .allAges
    @State private var squatMax: String = ""
    @State private var benchMax: String = ""
    @State private var deadliftMax: String = ""
    @State private var ohpMax: String = ""
    @State private var showResults = false
    @State private var showingShareSheet = false
    @State private var showingPaywall = false
    @State private var shareImage: UIImage?
    @FocusState private var focusedField: LiftField?
    
    init(useMetric: Bool, isPremium: Bool = true) {
        self.useMetric = useMetric
        self.isPremium = isPremium
    }
    
    enum LiftField {
        case bodyweight, squat, bench, deadlift, ohp
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
    }
    
    private var bodyweightValue: Double? {
        Double(bodyweight)
    }
    
    private var squatValue: Double? {
        Double(squatMax)
    }
    
    private var benchValue: Double? {
        Double(benchMax)
    }
    
    private var deadliftValue: Double? {
        Double(deadliftMax)
    }
    
    private var ohpValue: Double? {
        Double(ohpMax)
    }
    
    private var hasAnyLift: Bool {
        squatValue != nil || benchValue != nil || deadliftValue != nil || ohpValue != nil
    }
    
    private var canCalculate: Bool {
        bodyweightValue != nil && bodyweightValue! > 0 && hasAnyLift
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Strength Standards")
                // Sex selector
                sexSelector
                
                // Age category selector
                ageCategorySelector
                
                // Bodyweight input
                bodyweightSection
                
                // Lift inputs
                liftInputsSection
                
                // Calculate button
                if canCalculate {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showResults = true
                        }
                        focusedField = nil
                    } label: {
                        Text("See My Rankings")
                    }
                    .buttonStyle(SBSPrimaryButtonStyle())
                    .padding(.horizontal)
                }
                
                // Results
                if showResults && canCalculate, let bw = bodyweightValue {
                    if isPremium {
                        resultsSection(bodyweight: bw)
                        
                        // Share button
                        shareButton(bodyweight: bw)
                    } else {
                        // Preview mode for non-premium users
                        previewResultsSection(bodyweight: bw)
                    }
                }
                
                // Info section
                infoSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .sbsBackground()
        .screenNavigation("Strength Standards")
        .onChange(of: bodyweight) { _, _ in showResults = false }
        .onChange(of: isMale) { _, _ in showResults = false }
        .onChange(of: ageCategory) { _, _ in showResults = false }
        .onChange(of: squatMax) { _, _ in showResults = false }
        .onChange(of: benchMax) { _, _ in showResults = false }
        .onChange(of: deadliftMax) { _, _ in showResults = false }
        .onChange(of: ohpMax) { _, _ in showResults = false }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private func shareButton(bodyweight: Double) -> some View {
        Button {
            generateShareImage(bodyweight: bodyweight)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share My Strength")
            }
        }
        .buttonStyle(SBSSecondaryButtonStyle())
        .padding(.horizontal)
    }
    
    @MainActor
    private func generateShareImage(bodyweight: Double) {
        let percentiles = calculateAllPercentiles(bodyweight: bodyweight)
        let avgPercentile = percentiles.isEmpty ? 0 : percentiles.reduce(0, +) / Double(percentiles.count)
        
        // Build lift data using the StrengthSummary struct
        var lifts: [StrengthSummary.LiftStandard] = []
        if let squat = squatValue {
            let standards = isMale ? StrengthStandards.maleSquat : StrengthStandards.femaleSquat
            lifts.append(.init(name: "Squat", weight: squat, percentile: standards.percentile(weight: squat, bodyweight: bodyweight)))
        }
        if let bench = benchValue {
            let standards = isMale ? StrengthStandards.maleBench : StrengthStandards.femaleBench
            lifts.append(.init(name: "Bench Press", weight: bench, percentile: standards.percentile(weight: bench, bodyweight: bodyweight)))
        }
        if let deadlift = deadliftValue {
            let standards = isMale ? StrengthStandards.maleDeadlift : StrengthStandards.femaleDeadlift
            lifts.append(.init(name: "Deadlift", weight: deadlift, percentile: standards.percentile(weight: deadlift, bodyweight: bodyweight)))
        }
        if let ohp = ohpValue {
            let standards = isMale ? StrengthStandards.maleOHP : StrengthStandards.femaleOHP
            lifts.append(.init(name: "OHP", weight: ohp, percentile: standards.percentile(weight: ohp, bodyweight: bodyweight)))
        }
        
        let summary = StrengthSummary(
            overallPercentile: avgPercentile,
            lifts: lifts,
            bodyweight: bodyweight,
            isMale: isMale,
            useMetric: useMetric
        )
        
        // Generate the image with a slight delay to ensure proper rendering
        Task {
            let shareableCard = ShareableStrengthCard(summary: summary)
            
            // Allow the view to fully render before snapshotting
            try? await Task.sleep(for: .milliseconds(100))
            
            shareImage = shareableCard.snapshot()
            showingShareSheet = true
        }
    }
    
    private var sexSelector: some View {
        HStack(spacing: SBSLayout.space2) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMale = true
                }
            } label: {
                Text("Male")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .chipBackground(isSelected: isMale)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMale = false
                }
            } label: {
                Text("Female")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .chipBackground(isSelected: !isMale)
            }
        }
        .padding(.horizontal)
    }
    
    private var ageCategorySelector: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Age Category")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("For competitive comparison")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Menu {
                ForEach(AgeCategory.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            ageCategory = category
                        }
                    } label: {
                        HStack {
                            Text(category.displayName)
                            if category == ageCategory {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(ageCategory.displayName)
                        .font(SBSFonts.body())
                        .foregroundStyle(Color.ink)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkSecondary)
                }
                .padding()
                .card()
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var bodyweightSection: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Bodyweight")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            HStack {
                TextField("Enter bodyweight", text: $bodyweight)
                    .font(SBSFonts.numberLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .bodyweight)
                
                Text(unit)
                    .font(SBSFonts.body())
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding()
            .card()
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var liftInputsSection: some View {
        VStack(spacing: SBSLayout.space2) {
            HStack {
                Text("Your Lifts (1RM or E1RM)")
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            
            VStack(spacing: 12) {
                liftInputRow(title: "Squat", value: $squatMax, field: .squat, icon: "figure.strengthtraining.traditional")
                liftInputRow(title: "Bench Press", value: $benchMax, field: .bench, icon: "figure.arms.open")
                liftInputRow(title: "Deadlift", value: $deadliftMax, field: .deadlift, icon: "figure.strengthtraining.functional")
                liftInputRow(title: "Overhead Press", value: $ohpMax, field: .ohp, icon: "arrow.up")
            }
            
            Text("Leave blank any lifts you don't want to include")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func liftInputRow(title: String, value: Binding<String>, field: LiftField, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.orangeText)
                .frame(width: 24)
            
            Text(title)
                .font(SBSFonts.body())
                .foregroundStyle(Color.ink)
            
            Spacer()
            
            HStack {
                TextField("—", text: value)
                    .font(SBSFonts.number())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: field)
                    .frame(width: 80)
                
                Text(unit)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 24)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .card()
        }
    }
    
    // MARK: - Preview Results (Non-Premium)
    
    private func previewResultsSection(bodyweight: Double) -> some View {
        let percentiles = calculateAllPercentiles(bodyweight: bodyweight)
        let avgPercentile = percentiles.isEmpty ? 0 : percentiles.reduce(0, +) / Double(percentiles.count)
        let classification = StrengthStandards.classification(for: avgPercentile)
        
        return VStack(spacing: SBSLayout.space4) {
            // Teaser summary - show classification but hide exact percentile
            VStack(spacing: 8) {
                Text("Overall Strength")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                // Show classification with mystery percentile
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("??")
                        .font(SBSFonts.timer())
                        .foregroundStyle(Color.ink)
                        .blur(radius: 8)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.ink)
                        )
                    
                    Text("th percentile")
                        .font(SBSFonts.numberUnit())
                        .foregroundStyle(Color.inkSecondary)
                }
                
                Text(classification.name)
                    .font(SBSFonts.heading())
                    .foregroundStyle(classification.color)
                
                Text("Among \(ageCategory == .allAges ? "" : "\(ageCategory.shortName) ")\(isMale ? "male" : "female") lifters")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.space6)
            .signatureCard()
            
            // Blurred preview of lift cards
            VStack(spacing: 12) {
                if squatValue != nil {
                    previewLiftCard(title: "Squat")
                }
                if benchValue != nil {
                    previewLiftCard(title: "Bench Press")
                }
                if deadliftValue != nil {
                    previewLiftCard(title: "Deadlift")
                }
                if ohpValue != nil {
                    previewLiftCard(title: "Overhead Press")
                }
            }
            
            // Unlock button
            VStack(spacing: SBSLayout.space2) {
                Button {
                    showingPaywall = true
                } label: {
                    Text("Unlock Full Results")
                }
                .buttonStyle(SBSPrimaryButtonStyle())

                Text("See exact percentiles & compare to 3.5M+ lifters")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private func previewLiftCard(title: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                HStack(spacing: 4) {
                    Text("??th percentile")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            
            Spacer()
            
            // Locked indicator
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.inkSecondary)
                .frame(width: 44, height: 44)
                .field()
        }
        .padding()
        .card()
    }
    
    // MARK: - Full Results (Premium)
    
    private func resultsSection(bodyweight: Double) -> some View {
        VStack(spacing: SBSLayout.space4) {
            // Overall summary
            overallSummary(bodyweight: bodyweight)
            
            // Color legend
            strengthColorLegend
            
            // Individual lift results
            VStack(spacing: 12) {
                if let squat = squatValue {
                    liftResultCard(
                        title: "Squat",
                        weight: squat,
                        bodyweight: bodyweight,
                        standards: isMale ? StrengthStandards.maleSquat : StrengthStandards.femaleSquat
                    )
                }
                
                if let bench = benchValue {
                    liftResultCard(
                        title: "Bench Press",
                        weight: bench,
                        bodyweight: bodyweight,
                        standards: isMale ? StrengthStandards.maleBench : StrengthStandards.femaleBench
                    )
                }
                
                if let deadlift = deadliftValue {
                    liftResultCard(
                        title: "Deadlift",
                        weight: deadlift,
                        bodyweight: bodyweight,
                        standards: isMale ? StrengthStandards.maleDeadlift : StrengthStandards.femaleDeadlift
                    )
                }
                
                if let ohp = ohpValue {
                    liftResultCard(
                        title: "Overhead Press",
                        weight: ohp,
                        bodyweight: bodyweight,
                        standards: isMale ? StrengthStandards.maleOHP : StrengthStandards.femaleOHP
                    )
                }
            }
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    /// Color legend explaining the strength level colors
    private var strengthColorLegend: some View {
        VStack(spacing: 8) {
            // Gradient bar showing all levels
            HStack(spacing: 0) {
                ForEach(StrengthLevel.allCases) { level in
                    Rectangle()
                        .fill(level.color)
                        .frame(height: 8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            
            // Labels
            HStack(spacing: 0) {
                ForEach(StrengthLevel.allCases) { level in
                    Text(level.shortName)
                        .font(SBSFonts.eyebrow())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundStyle(level.color)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .card()
    }
    
    private func overallSummary(bodyweight: Double) -> some View {
        let percentiles = calculateAllPercentiles(bodyweight: bodyweight)
        let avgPercentile = percentiles.isEmpty ? 0 : percentiles.reduce(0, +) / Double(percentiles.count)
        let classification = StrengthStandards.classification(for: avgPercentile)
        
        return VStack(spacing: 12) {
            Text("Overall Strength")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            
            VStack(spacing: 8) {
                Text("\(Int(avgPercentile.rounded()))th")
                    .font(SBSFonts.timer())
                    .foregroundStyle(Color.ink) +
                Text(" percentile")
                    .font(SBSFonts.numberUnit())
                    .foregroundStyle(Color.inkSecondary)
                
                Text(classification.name)
                    .font(SBSFonts.heading())
                    .foregroundStyle(classification.color)
            }
            
            Text("Among \(ageCategory == .allAges ? "" : "\(ageCategory.shortName) ")\(isMale ? "male" : "female") lifters")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SBSLayout.space6)
        .padding(.horizontal, SBSLayout.space4)
        .signatureCard()
    }
    
    private func calculateAllPercentiles(bodyweight: Double) -> [Double] {
        var percentiles: [Double] = []
        
        if let squat = squatValue {
            let standards = isMale ? StrengthStandards.maleSquat : StrengthStandards.femaleSquat
            percentiles.append(standards.percentile(weight: squat, bodyweight: bodyweight))
        }
        if let bench = benchValue {
            let standards = isMale ? StrengthStandards.maleBench : StrengthStandards.femaleBench
            percentiles.append(standards.percentile(weight: bench, bodyweight: bodyweight))
        }
        if let deadlift = deadliftValue {
            let standards = isMale ? StrengthStandards.maleDeadlift : StrengthStandards.femaleDeadlift
            percentiles.append(standards.percentile(weight: deadlift, bodyweight: bodyweight))
        }
        if let ohp = ohpValue {
            let standards = isMale ? StrengthStandards.maleOHP : StrengthStandards.femaleOHP
            percentiles.append(standards.percentile(weight: ohp, bodyweight: bodyweight))
        }
        
        return percentiles
    }
    
    private func liftResultCard(title: String, weight: Double, bodyweight: Double, standards: StrengthStandards.LiftStandard) -> some View {
        let percentile = standards.percentile(weight: weight, bodyweight: bodyweight)
        let classification = StrengthStandards.classification(for: percentile)
        let bwMultiplier = weight / bodyweight
        
        // Get competitive percentile
        let liftKey = liftKeyForTitle(title)
        let competitivePercentile = CompetitiveLiftingData.shared.percentile(
            forLift: liftKey,
            weight: useMetric ? weight : weight * 0.453592, // Convert to kg for lookup
            bodyweight: useMetric ? bodyweight : bodyweight * 0.453592,
            isMale: isMale,
            ageCategory: ageCategory
        )
        
        return VStack(spacing: 12) {
            // Header
            HStack {
                Text(title)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Spacer()
                
                Text(formatWeight(weight))
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            // Gym Standards visualization - Landmarks view
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkSecondary)
                    Text("vs Gym Population")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                    Spacer()
                }
                
                landmarkVisualization(weight: weight, bodyweight: bodyweight, standards: standards, percentile: percentile)
                
                HStack {
                    Text("\(Int(percentile.rounded()))th percentile")
                        .font(SBSFonts.numberSmall())
                        .foregroundStyle(classification.color)
                    
                    Spacer()
                    
                    Text(classification.name)
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            
            // Competitive lifter visualization
            if let compPercentile = competitivePercentile {
                Divider().overlay(Color.hairline)
                    .padding(.vertical, 4)
                
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "trophy")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.inkSecondary)
                        Text("vs Competitive Lifters")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                        Spacer()
                    }
                    
                    // Simple progress bar for competitive data
                    progressBarVisualization(percentile: compPercentile, color: Color.ink)
                    
                    HStack {
                        Text("\(Int(compPercentile.rounded()))th percentile")
                            .font(SBSFonts.numberSmall())
                            .foregroundStyle(Color.ink)
                        
                        Spacer()
                        
                        Text(ageCategory == .allAges ? "OpenPowerlifting data" : "\(ageCategory.displayName)")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
            }
            
            // BW multiplier
            HStack {
                Text("Bodyweight multiplier")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                Spacer()
                
                Text(String(format: "%.2fx BW", bwMultiplier))
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding()
        .card()
    }
    
    // MARK: - Visualization Components
    
    /// Original progress bar visualization
    private func progressBarVisualization(percentile: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .fill(Color.surfaceRaised)
                    .frame(height: 10)
                
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .fill(color)
                    .frame(width: geo.size.width * min(percentile / 100, 1.0), height: 10)
            }
        }
        .frame(height: 10)
    }
    
    /// Weight landmark visualization with actual weights shown
    private func landmarkVisualization(weight: Double, bodyweight: Double, standards: StrengthStandards.LiftStandard, percentile: Double) -> some View {
        let classification = StrengthStandards.classification(for: percentile)
        
        // Key percentile landmarks aligned with strength levels
        let landmarks: [(percentile: Double, level: StrengthLevel)] = [
            (20, .novice),
            (40, .intermediate),
            (60, .advanced),
            (80, .elite),
            (95, .worldClass)
        ]
        
        return GeometryReader { geo in
            let width = geo.size.width
            
            ZStack(alignment: .top) {
                // Track background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.surfaceRaised)
                    .frame(height: 12)
                    .offset(y: 20)
                
                // Color-coded segments matching the legend
                HStack(spacing: 0) {
                    ForEach(StrengthLevel.allCases) { level in
                        let segmentWidth = (level.percentileRange.upperBound - level.percentileRange.lowerBound) / 100
                        Rectangle()
                            .fill(level.color)
                            .overlay(Rectangle().strokeBorder(Color.surface, lineWidth: SBSLayout.strokeHairline))
                            .frame(width: width * segmentWidth)
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
                .offset(y: 20)
                
                // Landmark markers with weight targets
                ForEach(landmarks, id: \.percentile) { landmark in
                    let xPos = (landmark.percentile / 100) * width
                    let landmarkWeight = standards.weight(forPercentile: landmark.percentile, bodyweight: bodyweight) ?? 0
                    
                    VStack(spacing: 2) {
                        Text(formatWeightShort(landmarkWeight))
                            .font(SBSFonts.numberTiny())
                            .foregroundStyle(landmark.level.color)
                        
                        Rectangle()
                            .fill(landmark.level.color)
                            .frame(width: 1, height: 8)
                    }
                    .position(x: xPos, y: 12)
                }
                
                // User position
                let userXPos = min(max((percentile / 100) * width, 10), width - 10)
                
                VStack(spacing: 0) {
                    // Arrow pointing down
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(classification.color)
                    
                    Text("YOU")
                        .font(SBSFonts.eyebrow())
                        .foregroundStyle(classification.color)
                }
                .position(x: userXPos, y: 48)
            }
        }
        .frame(height: 60)
    }
    
    private func formatWeightShort(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.0f", weight)
    }
    
    private func liftKeyForTitle(_ title: String) -> String {
        switch title {
        case "Squat": return "squat"
        case "Bench Press": return "bench"
        case "Deadlift": return "deadlift"
        case "Overhead Press": return "ohp"
        default: return title.lowercased()
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.inkSecondary)
                Text("About These Standards")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkSecondary)
                        Text("Gym Population")
                            .eyebrowStyle()
                            .foregroundStyle(Color.inkSecondary)
                    }
                    Text("Based on estimated distributions of recreational gym-goers who train with weights. A good baseline for general strength.")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkSecondary)
                        Text("Competitive Lifters")
                            .eyebrowStyle()
                            .foregroundStyle(Color.inkSecondary)
                        
                        if !CompetitiveLiftingData.shared.isLoaded {
                            Text("(unavailable)")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.danger)
                        }
                    }
                    if CompetitiveLiftingData.shared.isLoaded {
                        Text("Based on OpenPowerlifting data from \(CompetitiveLiftingData.shared.lifterCount.formatted()) actual competition results. These lifters are specifically trained for maximum strength, so percentiles here are more competitive.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    } else {
                        Text("Competitive lifter data could not be loaded. Only gym population data will be shown.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.danger)
                    }
                }
            }
            
            Text("Note: OHP is not a competitive powerlifting movement, so only gym population data is shown.")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .italic()
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f \(unit)", weight)
    }
}

// MARK: - Strength Level (for color legend)

enum StrengthLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case novice = "Novice"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
    case worldClass = "World Class"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .beginner: return "Beg"
        case .novice: return "Nov"
        case .intermediate: return "Int"
        case .advanced: return "Adv"
        case .elite: return "Elite"
        case .worldClass: return "WC"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return Color.inkSecondary
        case .novice: return Color.inkSecondary
        case .intermediate: return Color.ink
        case .advanced: return Color.ink
        case .elite: return Color.success
        case .worldClass: return Color.orangeText
        }
    }
    
    var percentileRange: Range<Double> {
        switch self {
        case .beginner: return 0..<20
        case .novice: return 20..<40
        case .intermediate: return 40..<60
        case .advanced: return 60..<80
        case .elite: return 80..<95
        case .worldClass: return 95..<100
        }
    }
}

// MARK: - Strength Standards Data

enum StrengthStandards {
    
    struct Classification {
        let name: String
        let color: Color
    }
    
    static func classification(for percentile: Double) -> Classification {
        switch percentile {
        case 0..<20:
            return Classification(name: "Beginner", color: Color.inkSecondary)
        case 20..<40:
            return Classification(name: "Novice", color: Color.inkSecondary)
        case 40..<60:
            return Classification(name: "Intermediate", color: Color.ink)
        case 60..<80:
            return Classification(name: "Advanced", color: Color.ink)
        case 80..<95:
            return Classification(name: "Elite", color: Color.success)
        default:
            return Classification(name: "World Class", color: Color.orangeText)
        }
    }
    
    struct LiftStandard {
        // BW multipliers at each percentile level
        // Based on aggregated data from Symmetric Strength, Strength Level, and competition results
        let percentileMultipliers: [(percentile: Double, multiplier: Double)]
        
        func percentile(weight: Double, bodyweight: Double) -> Double {
            let multiplier = weight / bodyweight
            
            // Find where this multiplier falls in the distribution
            for i in 0..<percentileMultipliers.count - 1 {
                let lower = percentileMultipliers[i]
                let upper = percentileMultipliers[i + 1]
                
                if multiplier >= lower.multiplier && multiplier < upper.multiplier {
                    // Linear interpolation between the two percentile points
                    let ratio = (multiplier - lower.multiplier) / (upper.multiplier - lower.multiplier)
                    return lower.percentile + ratio * (upper.percentile - lower.percentile)
                }
            }
            
            // Below minimum
            if multiplier < percentileMultipliers.first!.multiplier {
                let first = percentileMultipliers.first!
                return max(1, first.percentile * (multiplier / first.multiplier))
            }
            
            // Above maximum
            return min(99.9, percentileMultipliers.last!.percentile)
        }
        
        /// Get the bodyweight multiplier for a given percentile
        func multiplier(forPercentile targetPercentile: Double) -> Double? {
            // Find where this percentile falls in the distribution
            for i in 0..<percentileMultipliers.count - 1 {
                let lower = percentileMultipliers[i]
                let upper = percentileMultipliers[i + 1]
                
                if targetPercentile >= lower.percentile && targetPercentile <= upper.percentile {
                    // Linear interpolation between the two multiplier points
                    let ratio = (targetPercentile - lower.percentile) / (upper.percentile - lower.percentile)
                    return lower.multiplier + ratio * (upper.multiplier - lower.multiplier)
                }
            }
            
            // Below minimum percentile
            if targetPercentile < percentileMultipliers.first!.percentile {
                return percentileMultipliers.first!.multiplier * (targetPercentile / percentileMultipliers.first!.percentile)
            }
            
            // Above maximum percentile
            return percentileMultipliers.last!.multiplier
        }
        
        /// Get the weight for a given percentile and bodyweight
        func weight(forPercentile targetPercentile: Double, bodyweight: Double) -> Double? {
            guard let mult = multiplier(forPercentile: targetPercentile) else { return nil }
            return bodyweight * mult
        }
    }
    
    // MARK: - Male Standards (BW multipliers)
    // Based on aggregated data from strength sports and gym populations
    
    static let maleSquat = LiftStandard(percentileMultipliers: [
        (5, 0.50),      // Just starting out
        (10, 0.70),     // Very early training
        (20, 0.90),     // Beginner
        (30, 1.10),     // Late beginner
        (40, 1.30),     // Early intermediate
        (50, 1.50),     // Intermediate
        (60, 1.70),     // Late intermediate
        (70, 1.90),     // Early advanced
        (80, 2.10),     // Advanced
        (90, 2.40),     // Elite
        (95, 2.70),     // Very elite
        (99, 3.00)      // World class
    ])
    
    static let maleBench = LiftStandard(percentileMultipliers: [
        (5, 0.35),
        (10, 0.50),
        (20, 0.65),
        (30, 0.80),
        (40, 0.95),
        (50, 1.10),
        (60, 1.25),
        (70, 1.40),
        (80, 1.55),
        (90, 1.80),
        (95, 2.00),
        (99, 2.30)
    ])
    
    static let maleDeadlift = LiftStandard(percentileMultipliers: [
        (5, 0.70),
        (10, 0.90),
        (20, 1.10),
        (30, 1.35),
        (40, 1.55),
        (50, 1.80),
        (60, 2.00),
        (70, 2.25),
        (80, 2.50),
        (90, 2.85),
        (95, 3.10),
        (99, 3.50)
    ])
    
    static let maleOHP = LiftStandard(percentileMultipliers: [
        (5, 0.20),
        (10, 0.30),
        (20, 0.40),
        (30, 0.50),
        (40, 0.60),
        (50, 0.70),
        (60, 0.80),
        (70, 0.90),
        (80, 1.00),
        (90, 1.15),
        (95, 1.30),
        (99, 1.50)
    ])
    
    // MARK: - Female Standards (BW multipliers)
    // Generally ~60-70% of male standards for upper body, ~75-80% for lower body
    
    static let femaleSquat = LiftStandard(percentileMultipliers: [
        (5, 0.35),
        (10, 0.50),
        (20, 0.70),
        (30, 0.85),
        (40, 1.00),
        (50, 1.15),
        (60, 1.30),
        (70, 1.50),
        (80, 1.70),
        (90, 2.00),
        (95, 2.25),
        (99, 2.60)
    ])
    
    static let femaleBench = LiftStandard(percentileMultipliers: [
        (5, 0.20),
        (10, 0.30),
        (20, 0.40),
        (30, 0.50),
        (40, 0.60),
        (50, 0.70),
        (60, 0.80),
        (70, 0.90),
        (80, 1.05),
        (90, 1.20),
        (95, 1.40),
        (99, 1.65)
    ])
    
    static let femaleDeadlift = LiftStandard(percentileMultipliers: [
        (5, 0.50),
        (10, 0.70),
        (20, 0.90),
        (30, 1.10),
        (40, 1.30),
        (50, 1.50),
        (60, 1.70),
        (70, 1.95),
        (80, 2.20),
        (90, 2.50),
        (95, 2.80),
        (99, 3.20)
    ])
    
    static let femaleOHP = LiftStandard(percentileMultipliers: [
        (5, 0.15),
        (10, 0.20),
        (20, 0.28),
        (30, 0.35),
        (40, 0.42),
        (50, 0.50),
        (60, 0.58),
        (70, 0.65),
        (80, 0.75),
        (90, 0.85),
        (95, 0.95),
        (99, 1.10)
    ])
}

// MARK: - Age Category

/// Age categories matching the OpenPowerlifting data
enum AgeCategory: String, CaseIterable, Identifiable {
    case allAges = "all_ages"
    case junior = "junior"
    case open = "open"
    case masters40 = "masters_40"
    case masters50 = "masters_50"
    case masters60 = "masters_60"
    case masters70 = "masters_70"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .allAges: return "All Ages"
        case .junior: return "Junior (U23)"
        case .open: return "Open (23-39)"
        case .masters40: return "Masters 40+"
        case .masters50: return "Masters 50+"
        case .masters60: return "Masters 60+"
        case .masters70: return "Masters 70+"
        }
    }
    
    var shortName: String {
        switch self {
        case .allAges: return "all ages"
        case .junior: return "junior"
        case .open: return "open"
        case .masters40: return "masters 40+"
        case .masters50: return "masters 50+"
        case .masters60: return "masters 60+"
        case .masters70: return "masters 70+"
        }
    }
    
    /// JSON key used in byAge dictionary
    var jsonKey: String {
        switch self {
        case .allAges: return "all_ages"
        case .junior: return "junior"
        case .open: return "open"
        case .masters40: return "masters_40"
        case .masters50: return "masters_50"
        case .masters60: return "masters_60"
        case .masters70: return "masters_70"
        }
    }
}

// MARK: - Competitive Lifting Data (OpenPowerlifting)

/// Loads and provides access to competitive powerlifting percentile data
class CompetitiveLiftingData {
    static let shared = CompetitiveLiftingData()
    
    private var data: PowerliftingPercentileData?
    private(set) var loadError: String?
    
    /// Whether competitive data is available
    var isLoaded: Bool { data != nil }
    
    /// Get lifter count from metadata
    var lifterCount: Int { data?.metadata.lifterCount ?? 0 }
    
    // Weight classes in kg
    private let maleWeightClasses: [Double] = [59, 66, 74, 83, 93, 105, 120, 140]
    private let femaleWeightClasses: [Double] = [47, 52, 57, 63, 69, 76, 84, 100]
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "powerlifting_percentiles", withExtension: "json") else {
            loadError = "Could not find powerlifting_percentiles.json in bundle"
            print("CompetitiveLiftingData: \(loadError!)")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            data = try decoder.decode(PowerliftingPercentileData.self, from: jsonData)
            print("CompetitiveLiftingData: Successfully loaded data for \(data?.metadata.lifterCount ?? 0) lifters")
        } catch {
            loadError = "Failed to decode JSON: \(error.localizedDescription)"
            print("CompetitiveLiftingData: \(loadError!)")
        }
    }
    
    /// Get the appropriate weight class for a given bodyweight (in kg)
    func weightClass(for bodyweight: Double, isMale: Bool) -> String {
        let classes = isMale ? maleWeightClasses : femaleWeightClasses
        
        for wc in classes {
            if bodyweight <= wc {
                return String(Int(wc))
            }
        }
        
        // Super heavyweight - return the highest class (JSON uses "140" not "140+")
        return String(Int(classes.last!))
    }
    
    /// Calculate percentile for a lift among competitive lifters
    /// - Parameters:
    ///   - lift: The lift type ("squat", "bench", "deadlift")
    ///   - weight: The weight lifted in kg
    ///   - bodyweight: The lifter's bodyweight in kg
    ///   - isMale: Whether the lifter is male
    ///   - ageCategory: The age category to compare against (defaults to all ages)
    /// - Returns: The percentile (0-100) or nil if data not available
    func percentile(forLift lift: String, weight: Double, bodyweight: Double, isMale: Bool, ageCategory: AgeCategory = .allAges) -> Double? {
        guard let data = data else { return nil }
        
        // OHP is not in competitive powerlifting data
        if lift == "ohp" { return nil }
        
        let sexData = isMale ? data.male : data.female
        let wc = weightClass(for: bodyweight, isMale: isMale)
        
        guard let wcData = sexData[wc] else { return nil }
        
        // Get lift data based on age category
        let liftData: LiftPercentileData?
        if ageCategory == .allAges {
            liftData = wcData.allAges[lift]
        } else {
            liftData = wcData.byAge?[ageCategory.jsonKey]?[lift]
        }
        
        guard let liftData = liftData, !liftData.percentiles.isEmpty else {
            return nil
        }
        
        // Find where this weight falls in the percentile distribution
        let percentileKeys = liftData.percentiles.keys.compactMap { Int($0) }.sorted()
        
        for i in 0..<percentileKeys.count - 1 {
            let lowerPercentile = percentileKeys[i]
            let upperPercentile = percentileKeys[i + 1]
            
            guard let lowerWeight = liftData.percentiles[String(lowerPercentile)],
                  let upperWeight = liftData.percentiles[String(upperPercentile)] else {
                continue
            }
            
            if weight >= lowerWeight && weight < upperWeight {
                // Linear interpolation
                let ratio = (weight - lowerWeight) / (upperWeight - lowerWeight)
                return Double(lowerPercentile) + ratio * Double(upperPercentile - lowerPercentile)
            }
        }
        
        // Below minimum
        if let firstPercentile = percentileKeys.first,
           let firstWeight = liftData.percentiles[String(firstPercentile)],
           weight < firstWeight {
            return max(1, Double(firstPercentile) * (weight / firstWeight))
        }
        
        // Above maximum
        if let lastPercentile = percentileKeys.last,
           let lastWeight = liftData.percentiles[String(lastPercentile)],
           weight >= lastWeight {
            return min(99.9, Double(lastPercentile))
        }
        
        return nil
    }
    
    /// Check if data is available for a specific age category
    func hasData(for ageCategory: AgeCategory, isMale: Bool) -> Bool {
        guard let data = data else { return false }
        
        let sexData = isMale ? data.male : data.female
        
        // Check any weight class for the age category
        for (_, wcData) in sexData {
            if ageCategory == .allAges {
                if !wcData.allAges.isEmpty { return true }
            } else if let byAge = wcData.byAge, byAge[ageCategory.jsonKey] != nil {
                return true
            }
        }
        return false
    }
}

// MARK: - Powerlifting JSON Data Models

struct PowerliftingPercentileData: Codable {
    let metadata: PowerliftingMetadata
    let male: [String: WeightClassData]
    let female: [String: WeightClassData]
}

struct PowerliftingMetadata: Codable {
    let source: String
    let url: String
    let lifterCount: Int
    let description: String
    let units: String
    let percentiles: [Int]
    
    enum CodingKeys: String, CodingKey {
        case source, url, description, units, percentiles
        case lifterCount = "lifter_count"
    }
}

struct WeightClassData: Codable {
    let allAges: [String: LiftPercentileData]
    let byAge: [String: [String: LiftPercentileData]]?
    
    enum CodingKeys: String, CodingKey {
        case allAges = "all_ages"
        case byAge = "by_age"
    }
}

struct LiftPercentileData: Codable {
    let count: Int
    let percentiles: [String: Double]
}

// MARK: - Previews

#Preview("Strength Standards") {
    NavigationStack {
        StrengthStandardsView(useMetric: false)
    }
}

