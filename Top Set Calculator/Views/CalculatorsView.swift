import SwiftUI

// MARK: - Main Calculators View

struct CalculatorsView: View {
    var settings: AppSettings
    @State private var showingPaywall = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SBSLayout.sectionSpacing) {
                    // Calculator cards
                    VStack(spacing: SBSLayout.cardSpacing) {
                        NavigationLink {
                            OneRepMaxCalculatorView(useMetric: settings.useMetric)
                        } label: {
                            CalculatorCard(
                                icon: "trophy.fill",
                                iconColor: .orange,
                                title: "One-Rep Max",
                                description: "Estimate your 1RM from submaximal lifts"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            RPECalculatorView(useMetric: settings.useMetric)
                        } label: {
                            CalculatorCard(
                                icon: "gauge.with.needle.fill",
                                iconColor: .purple,
                                title: "RPE Calculator",
                                description: "Find weights for target RPE levels"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            StandalonePlateCalculatorView(
                                useMetric: settings.useMetric,
                                defaultBarWeight: settings.barWeight,
                                settings: settings
                            )
                        } label: {
                            CalculatorCard(
                                icon: "circle.grid.2x1.fill",
                                iconColor: .blue,
                                title: "Plate Calculator",
                                description: "Visualize which plates to load"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            TrainingMaxCalculatorView(useMetric: settings.useMetric)
                        } label: {
                            CalculatorCard(
                                icon: "percent",
                                iconColor: .green,
                                title: "Training Max",
                                description: "Calculate TM and percentage charts"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            StrengthScoresView(useMetric: settings.useMetric)
                        } label: {
                            CalculatorCard(
                                icon: "scalemass.fill",
                                iconColor: .mint,
                                title: "Strength Scores",
                                description: "Wilks, DOTS & IPF GL Points"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .sbsBackground()
            .navigationTitle("Top Set Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSettings) {
                PlateSettingsView(settings: settings)
            }
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
                    
                    // Premium badge
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
    let useMetric: Bool
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var showResults = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    private var weightValue: Double? {
        Double(weight)
    }
    
    private var repsValue: Int? {
        Int(reps)
    }
    
    private var canCalculate: Bool {
        guard let w = weightValue, let r = repsValue else { return false }
        return w > 0 && r > 0 && r <= 30
    }
    
    // Different formulas for calculating 1RM
    private var results: [(name: String, value: Double, description: String)] {
        guard let w = weightValue, let r = repsValue, r > 0 else { return [] }
        
        let repsDouble = Double(r)
        
        return [
            ("Epley", w * (1 + repsDouble / 30.0), "Most common formula"),
            ("Brzycki", w * (36.0 / (37.0 - repsDouble)), "Popular for lower reps"),
            ("Lombardi", w * pow(repsDouble, 0.10), "Simple power formula"),
            ("Mayhew", w * (100.0 / (52.2 + 41.9 * exp(-0.055 * repsDouble))), "Research-based"),
            ("O'Conner", w * (1 + 0.025 * repsDouble), "Conservative estimate"),
            ("Wathan", w * (100.0 / (48.8 + 53.8 * exp(-0.075 * repsDouble))), "Football-based")
        ]
    }
    
    private var averageE1RM: Double? {
        guard !results.isEmpty else { return nil }
        return results.map { $0.value }.reduce(0, +) / Double(results.count)
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Input section
                inputSection
                
                // Calculate button
                if canCalculate {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showResults = true
                        }
                        focusedField = nil
                        AppSettings.recordCalculationCompleted()
                    } label: {
                        Text("Calculate")
                            .font(SBSFonts.button())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SBSLayout.paddingMedium)
                            .background(SBSColors.accentFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
                    }
                    .padding(.horizontal)
                }
                
                // Results section
                if showResults && canCalculate {
                    resultsSection
                }
                
                // Info section
                infoSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .sbsBackground()
        .navigationTitle("One-Rep Max")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: weight) { _, _ in
            showResults = false
        }
        .onChange(of: reps) { _, _ in
            showResults = false
        }
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
                        .background(SBSColors.surfaceFallback)
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
                        .background(SBSColors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var resultsSection: some View {
        VStack(spacing: SBSLayout.paddingMedium) {
            // Average estimate (highlighted)
            if let avg = averageE1RM {
                VStack(spacing: 8) {
                    Text("Estimated 1RM")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                    
                    Text(formatWeight(avg))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(SBSColors.accentFallback)
                    
                    Text("Average of all formulas")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SBSLayout.paddingLarge)
                .background(
                    RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                        .fill(SBSColors.accentFallback.opacity(0.1))
                )
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
            
            // Training percentages
            if let avg = averageE1RM {
                trainingPercentagesSection(e1rm: avg)
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
                    VStack(spacing: 4) {
                        Text("\(percentage)%")
                            .font(SBSFonts.caption())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        
                        Text(formatWeight(e1rm * Double(percentage) / 100.0))
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SBSColors.surfaceElevatedFallback)
                    .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                }
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
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
            
            Text("Enter a weight and the number of reps you completed. The calculator uses multiple formulas to estimate your one-rep max. Results are most accurate for 1-10 reps; higher rep ranges become less reliable.")
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
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f \(unit)", weight)
    }
}

// MARK: - RPE Calculator

struct RPECalculatorView: View {
    let useMetric: Bool
    
    @State private var e1rm: String = ""
    @State private var targetReps: Int = 5
    @State private var selectedRPE: Double = 8.0
    @FocusState private var isE1RMFocused: Bool
    
    private var e1rmValue: Double? {
        Double(e1rm)
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
    }
    
    // RPE percentage table (based on Mike Tuchscherer's research)
    // Rows: reps (1-12), Columns: RPE (6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10)
    private let rpeTable: [[Double]] = [
        // 1 rep
        [0.88, 0.89, 0.91, 0.92, 0.94, 0.96, 0.98, 1.00],
        // 2 reps
        [0.85, 0.86, 0.88, 0.89, 0.91, 0.92, 0.94, 0.96],
        // 3 reps
        [0.82, 0.84, 0.85, 0.86, 0.88, 0.89, 0.91, 0.92],
        // 4 reps
        [0.79, 0.81, 0.82, 0.84, 0.85, 0.86, 0.88, 0.89],
        // 5 reps
        [0.77, 0.78, 0.79, 0.81, 0.82, 0.84, 0.85, 0.86],
        // 6 reps
        [0.74, 0.75, 0.77, 0.78, 0.79, 0.81, 0.82, 0.84],
        // 7 reps
        [0.71, 0.73, 0.74, 0.75, 0.77, 0.78, 0.79, 0.81],
        // 8 reps
        [0.68, 0.70, 0.71, 0.73, 0.74, 0.75, 0.77, 0.78],
        // 9 reps
        [0.65, 0.67, 0.68, 0.70, 0.71, 0.73, 0.74, 0.75],
        // 10 reps
        [0.63, 0.65, 0.66, 0.67, 0.68, 0.70, 0.71, 0.73],
        // 11 reps
        [0.60, 0.62, 0.63, 0.65, 0.66, 0.67, 0.68, 0.70],
        // 12 reps
        [0.58, 0.60, 0.61, 0.62, 0.63, 0.65, 0.66, 0.67]
    ]
    
    private let rpeValues: [Double] = [6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0]
    
    private func percentageFor(reps: Int, rpe: Double) -> Double {
        let repsIndex = min(max(reps - 1, 0), 11)
        let rpeIndex = rpeValues.firstIndex(of: rpe) ?? 3
        return rpeTable[repsIndex][rpeIndex]
    }
    
    private var calculatedWeight: Double? {
        guard let e1rm = e1rmValue else { return nil }
        let percentage = percentageFor(reps: targetReps, rpe: selectedRPE)
        return e1rm * percentage
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // E1RM input
                e1rmInputSection
                
                // Reps selector
                repsSection
                
                // RPE selector
                rpeSection
                
                // Result
                if let weight = calculatedWeight {
                    resultSection(weight: weight)
                }
                
                // RPE table
                rpeTableSection
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .sbsBackground()
        .navigationTitle("RPE Calculator")
        .navigationBarTitleDisplayMode(.inline)
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
            .background(SBSColors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            
            Text("Use the 1RM Calculator if you don't know your estimated max")
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
                    ForEach(1...12, id: \.self) { rep in
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
                                    targetReps == rep ? SBSColors.accentFallback : SBSColors.surfaceFallback
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
                            .foregroundStyle(selectedRPE == rpe ? .white : SBSColors.textPrimaryFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedRPE == rpe ? rpeColor(rpe) : SBSColors.surfaceFallback
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
        VStack(spacing: 8) {
            Text("Target Weight")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            Text(formatWeight(weight))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(SBSColors.accentFallback)
            
            let percentage = percentageFor(reps: targetReps, rpe: selectedRPE)
            Text("\(Int(percentage * 100))% of E1RM for \(targetReps) reps @ RPE \(String(format: "%.1f", selectedRPE))")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SBSLayout.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                .fill(SBSColors.accentFallback.opacity(0.1))
        )
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
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f \(unit)", weight)
    }
}

// MARK: - Standalone Plate Calculator

struct StandalonePlateCalculatorView: View {
    var settings: AppSettings
    let defaultBarWeight: Double
    
    @State private var targetWeight: String = ""
    @State private var barWeight: Double
    @State private var showingSettings = false
    @State private var showingCustomBarWeight = false
    @State private var customBarWeight: String = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isBarWeightFocused: Bool
    
    init(useMetric: Bool, defaultBarWeight: Double, settings: AppSettings? = nil) {
        self.settings = settings ?? AppSettings()
        self.defaultBarWeight = defaultBarWeight
        _barWeight = State(initialValue: defaultBarWeight)
    }
    
    private var useMetric: Bool {
        settings.useMetric
    }
    
    private var targetWeightValue: Double {
        Double(targetWeight) ?? 0
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
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
            }
        }
        .sheet(isPresented: $showingSettings) {
            PlateSettingsView(settings: settings)
        }
    }
    
    private var premiumNudgeSection: some View {
        Button {
            showingSettings = true
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
            
            HStack {
                TextField("0", text: $targetWeight)
                    .font(SBSFonts.weightLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isWeightFocused)
                
                Text(unit)
                    .font(SBSFonts.title2())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            .padding()
            .background(SBSColors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
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
                                    barWeight == weight && !showingCustomBarWeight ? SBSColors.accentFallback : SBSColors.surfaceFallback
                                )
                                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        }
                    }
                    
                    // Custom bar weight button (premium only)
                    if StoreManager.shared.canAccess(.extendedEquipment) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingCustomBarWeight = true
                                customBarWeight = String(format: "%.0f", barWeight)
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
                                showingCustomBarWeight || isCustomBarWeight ? SBSColors.accentFallback : SBSColors.surfaceFallback
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
                        .background(SBSColors.surfaceFallback)
                        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
                        .focused($isBarWeightFocused)
                        .onChange(of: customBarWeight) { _, newValue in
                            if let weight = Double(newValue), weight > 0 {
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
        
        // Use achievable weight for the barbell display when exact weight can't be made
        let displayWeight = result.isExact ? targetWeightValue : result.achievableWeight
        
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
                    
                    if settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) {
                        Text("Add more plates in Settings to reach this weight.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(.white.opacity(0.8))
                    } else if !StoreManager.shared.canAccess(.extendedEquipment) {
                        Text("Upgrade to Premium for 1.25 lb change plates.")
                            .font(SBSFonts.caption())
                            .foregroundStyle(.white.opacity(0.8))
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
            } else if targetWeightValue <= barWeight {
                Text("Bar only - no plates needed")
                    .font(SBSFonts.body())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private var quickWeightsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingSmall) {
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
                        targetWeight = formatWeightShort(weight)
                        isWeightFocused = false
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
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f \(unit)", weight)
    }
    
    private func formatWeightShort(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
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
            
            HStack(spacing: 12) {
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
    let useMetric: Bool
    
    @State private var actualMax: String = ""
    @State private var tmPercentage: Double = 90
    @FocusState private var isMaxFocused: Bool
    
    private var actualMaxValue: Double? {
        Double(actualMax)
    }
    
    private var trainingMax: Double? {
        guard let max = actualMaxValue else { return nil }
        return max * (tmPercentage / 100.0)
    }
    
    private var unit: String {
        useMetric ? "kg" : "lb"
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
        .sbsBackground()
        .navigationTitle("Training Max")
        .navigationBarTitleDisplayMode(.inline)
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
            .background(SBSColors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            
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
                Text("TM Percentage: \(Int(tmPercentage))%")
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
                        Text("\(Int(preset.value))%")
                            .font(SBSFonts.caption())
                            .foregroundStyle(tmPercentage == preset.value ? .white : SBSColors.textPrimaryFallback)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                tmPercentage == preset.value ? SBSColors.accentFallback : SBSColors.surfaceFallback
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
        VStack(spacing: 8) {
            Text("Training Max")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            Text(formatWeight(tm))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(SBSColors.accentFallback)
            
            if let max = actualMaxValue {
                Text("\(Int(tmPercentage))% of \(formatWeight(max))")
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
                            .frame(width: 40, alignment: .leading)
                        
                        Spacer()
                        
                        Text(formatWeight(weight))
                            .font(SBSFonts.bodyBold())
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
            
            // Common rep schemes
            VStack(alignment: .leading, spacing: 8) {
                Text("Common Programming")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                    .padding(.top, 8)
                
                programmingRow(name: "5/3/1 Week 1 (5s)", percentage: 85, tm: tm)
                programmingRow(name: "5/3/1 Week 2 (3s)", percentage: 90, tm: tm)
                programmingRow(name: "5/3/1 Week 3 (5/3/1)", percentage: 95, tm: tm)
                programmingRow(name: "Joker Sets", percentage: 100, tm: tm)
            }
        }
        .padding()
        .background(SBSColors.surfaceFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
        .padding(.horizontal)
    }
    
    private func programmingRow(name: String, percentage: Int, tm: Double) -> some View {
        let weight = tm * Double(percentage) / 100.0
        
        return HStack {
            Text(name)
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
            
            Spacer()
            
            Text("\(percentage)%")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
            
            Text(formatWeight(weight))
                .font(SBSFonts.captionBold())
                .foregroundStyle(SBSColors.textPrimaryFallback)
                .frame(width: 70, alignment: .trailing)
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
        // Round to nearest 2.5 (or 1 for metric)
        let roundingIncrement = useMetric ? 1.0 : 2.5
        let rounded = (weight / roundingIncrement).rounded() * roundingIncrement
        
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded)) \(unit)"
        }
        return String(format: "%.1f \(unit)", rounded)
    }
}

// MARK: - Strength Scores View

struct StrengthScoresView: View {
    let useMetric: Bool
    
    @State private var bodyWeight: String = ""
    @State private var total: String = ""
    @State private var squat: String = ""
    @State private var bench: String = ""
    @State private var deadlift: String = ""
    @State private var useIndividualLifts: Bool = false
    @State private var isMale: Bool = true
    @State private var showResults = false
    @State private var selectedFormula: StrengthFormula = .wilks
    @FocusState private var focusedField: StrengthField?
    
    enum StrengthField {
        case bodyWeight, total, squat, bench, deadlift
    }
    
    enum StrengthFormula: String, CaseIterable {
        case wilks = "Wilks"
        case dots = "DOTS"
        case ipfGL = "IPF GL"
    }
    
    private var bodyWeightValue: Double? {
        Double(bodyWeight)
    }
    
    private var squatValue: Double {
        Double(squat) ?? 0
    }
    
    private var benchValue: Double {
        Double(bench) ?? 0
    }
    
    private var deadliftValue: Double {
        Double(deadlift) ?? 0
    }
    
    private var calculatedTotal: Double {
        squatValue + benchValue + deadliftValue
    }
    
    private var totalValue: Double? {
        if useIndividualLifts {
            let sum = calculatedTotal
            return sum > 0 ? sum : nil
        } else {
            return Double(total)
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
    
    // MARK: - Wilks Calculation
    
    private var wilksScore: Double? {
        guard let bwKg = bodyWeightKg, let tKg = totalKg else { return nil }
        
        let a: Double, b: Double, c: Double, d: Double, e: Double, f: Double
        
        if isMale {
            a = -216.0475144
            b = 16.2606339
            c = -0.002388645
            d = -0.00113732
            e = 7.01863E-06
            f = -1.291E-08
        } else {
            a = 594.31747775582
            b = -27.23842536447
            c = 0.82112226871
            d = -0.00930733913
            e = 4.731582E-05
            f = -9.054E-08
        }
        
        let x = bwKg
        let coefficient = 500.0 / (a + b*x + c*pow(x, 2) + d*pow(x, 3) + e*pow(x, 4) + f*pow(x, 5))
        
        return tKg * coefficient
    }
    
    // MARK: - DOTS Calculation
    
    private var dotsScore: Double? {
        guard let bwKg = bodyWeightKg, let tKg = totalKg else { return nil }
        
        let a: Double, b: Double, c: Double, d: Double, e: Double
        
        if isMale {
            a = -0.0000010930
            b = 0.0007391293
            c = -0.1918759221
            d = 24.0900756
            e = -307.75076
        } else {
            a = -0.0000010706
            b = 0.0005158568
            c = -0.1126655495
            d = 13.6175032
            e = -57.96288
        }
        
        let x = bwKg
        let denominator = a*pow(x, 4) + b*pow(x, 3) + c*pow(x, 2) + d*x + e
        
        guard denominator != 0 else { return nil }
        
        return tKg * (500.0 / denominator)
    }
    
    // MARK: - IPF GL Points Calculation
    
    private var ipfGLScore: Double? {
        guard let bwKg = bodyWeightKg, let tKg = totalKg else { return nil }
        
        // IPF GL coefficients for raw lifting (classic)
        let a: Double, b: Double, c: Double
        
        if isMale {
            a = 1199.72839
            b = 1025.18162
            c = 0.00921
        } else {
            a = 610.32796
            b = 1045.59282
            c = 0.03048
        }
        
        let denominator = a - b * exp(-c * bwKg)
        
        guard denominator > 0 else { return nil }
        
        return tKg * (100.0 / denominator)
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
    
    private func scoreFor(_ formula: StrengthFormula) -> Double? {
        switch formula {
        case .wilks: return wilksScore
        case .dots: return dotsScore
        case .ipfGL: return ipfGLScore
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                // Sex selection
                sexSelectionSection
                
                // Input section
                inputSection
                
                // Calculate button
                if canCalculate {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showResults = true
                        }
                        focusedField = nil
                        AppSettings.recordCalculationCompleted()
                    } label: {
                        Text("Calculate Scores")
                            .font(SBSFonts.button())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SBSLayout.paddingMedium)
                            .background(SBSColors.accentFallback)
                            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
                    }
                    .padding(.horizontal)
                }
                
                // Results section
                if showResults && canCalculate {
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
        .sbsBackground()
        .navigationTitle("Strength Scores")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: bodyWeight) { _, _ in
            showResults = false
        }
        .onChange(of: total) { _, _ in
            showResults = false
        }
        .onChange(of: squat) { _, _ in
            showResults = false
        }
        .onChange(of: bench) { _, _ in
            showResults = false
        }
        .onChange(of: deadlift) { _, _ in
            showResults = false
        }
        .onChange(of: useIndividualLifts) { _, _ in
            showResults = false
        }
        .onChange(of: isMale) { _, _ in
            showResults = false
        }
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
                    .background(isMale ? SBSColors.accentFallback : SBSColors.surfaceFallback)
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
                    .background(!isMale ? SBSColors.accentFallback : SBSColors.surfaceFallback)
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
                    .background(SBSColors.surfaceFallback)
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
                        .background(!useIndividualLifts ? SBSColors.accentFallback : SBSColors.surfaceFallback)
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
                        .background(useIndividualLifts ? SBSColors.accentFallback : SBSColors.surfaceFallback)
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
                        .background(SBSColors.surfaceFallback)
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
                .frame(width: 70, alignment: .leading)
            
            TextField("0", text: value)
                .font(SBSFonts.number())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .focused($focusedField, equals: field)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(SBSColors.surfaceFallback)
                .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall))
            
            Text(unit)
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
                .frame(width: 24)
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        }
        return String(format: "%.1f \(unit)", weight)
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
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(formulaColor(selectedFormula))
                        
                        let classInfo = classification(for: score, formula: selectedFormula)
                        Text(classInfo.name)
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(classInfo.color)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SBSLayout.paddingLarge)
                    .background(
                        RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                            .fill(formulaColor(selectedFormula).opacity(0.1))
                    )
                }
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
                        Text(String(format: "%.1f kg", bwKg))
                            .font(SBSFonts.bodyBold())
                            .foregroundStyle(SBSColors.textPrimaryFallback)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(SBSFonts.body())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                        Spacer()
                        Text(String(format: "%.1f kg", tKg))
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
                 ? "IPF GL scale: 100 = world record level"
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
                    description: "Official IPF scoring since 2019. Based on world records and updated as records change."
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
        OneRepMaxCalculatorView(useMetric: false)
    }
}

#Preview("RPE Calculator") {
    NavigationStack {
        RPECalculatorView(useMetric: false)
    }
}

#Preview("Plate Calculator") {
    NavigationStack {
        StandalonePlateCalculatorView(useMetric: false, defaultBarWeight: 45)
    }
}

#Preview("Training Max Calculator") {
    NavigationStack {
        TrainingMaxCalculatorView(useMetric: false)
    }
}

#Preview("Strength Scores") {
    NavigationStack {
        StrengthScoresView(useMetric: false)
    }
}

