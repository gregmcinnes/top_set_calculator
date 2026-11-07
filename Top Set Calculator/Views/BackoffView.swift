import SwiftUI

// MARK: - Back-off Sets

struct BackoffView: View {
    var settings: AppSettings
    private let initialTopSet: Double?
    
    private enum Mode: String, CaseIterable, Identifiable {
        case percent = "% Drop"
        case rpe = "Target RPE"
        var id: String { rawValue }
    }
    
    @AppStorage private var topSet: String
    @AppStorage("backoff.topReps") private var topReps = 3
    @AppStorage("backoff.topRPE") private var topRPE = 8.0
    @AppStorage("backoff.mode") private var modeRaw = Mode.percent.rawValue
    @AppStorage("backoff.drop") private var dropPercent = 10
    @AppStorage("backoff.targetRPE") private var targetRPE = 7.0
    @AppStorage("backoff.reps") private var backoffReps = 5
    @AppStorage("backoff.sets") private var setCount = 3
    @State private var didApplyInitial = false
    
    init(settings: AppSettings, initialTopSet: Double? = nil) {
        self.settings = settings
        self.initialTopSet = initialTopSet
        _topSet = AppStorage(wrappedValue: "", "backoff.topSet.\(settings.unitLabel)")
    }
    
    private var mode: Mode {
        Mode(rawValue: modeRaw) ?? .percent
    }
    
    private var topSetValue: Double? {
        WeightInput.parse(topSet, maximum: PlateCalculator.maximumTotalWeight)
    }
    
    private var backoffWeight: Double? {
        guard let top = topSetValue else { return nil }
        let target: BackoffPlan.Target = mode == .percent
            ? .percentDrop(Double(dropPercent) / 100)
            : .rpe(targetRPE)
        return BackoffPlan.weight(topSet: top, topReps: topReps, topRPE: topRPE, backoffReps: backoffReps, target: target)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Back-off Sets")
                topSetSection
                backoffSection
                
                if let weight = backoffWeight, let top = topSetValue {
                    resultSection(weight: weight, top: top)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .screenNavigation("Back-off Sets")
        .recordsCalculation(key: backoffWeight.map { "\($0)-\(setCount)" })
        .onAppear {
            if let initialTopSet, !didApplyInitial {
                topSet = initialTopSet.weightString()
            }
            didApplyInitial = true
        }
    }
    
    private var topSetSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            Text("Today's Top Set")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
            
            WeightField(label: "Weight", text: $topSet, unit: settings.unitLabel)
            
            chipGroup("Reps") {
                ChoiceChips(options: Array(RPETable.repRange), selection: $topReps) { "\($0)" }
            }
            
            chipGroup("RPE") {
                ChoiceChips(options: RPETable.rpeValues, selection: $topRPE) { String(format: "%.1f", $0) }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private var backoffSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            Text("Back-off Sets")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
            
            Picker("Method", selection: $modeRaw) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            if mode == .percent {
                chipGroup("Drop from Top Set") {
                    ChoiceChips(options: [5, 10, 15, 20, 25], selection: $dropPercent) { "\($0)%" }
                }
            } else {
                chipGroup("Target RPE") {
                    ChoiceChips(options: RPETable.rpeValues, selection: $targetRPE) { String(format: "%.1f", $0) }
                }
            }
            
            chipGroup("Reps per Set") {
                ChoiceChips(options: Array(RPETable.repRange), selection: $backoffReps) { "\($0)" }
            }
            
            chipGroup("Sets") {
                ChoiceChips(options: Array(1...6), selection: $setCount) { "\($0)" }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func resultSection(weight: Double, top: Double) -> some View {
        let load = settings.rounded(weight)
        let calculator = PlateCalculator(barWeight: settings.barWeight, settings: settings)
        
        return VStack(spacing: SBSLayout.space4) {
            VStack(spacing: 8) {
                Text("Back-off Weight")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                HeroNumber(value: settings.loadString(weight), style: .workingWeight)
                
                Text("\(setCount) × \(backoffReps), \(Int(((1 - load / top) * 100).rounded()))% below your top set")
                    .font(SBSFonts.numberSmall())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                
                PlateLoadText(result: calculator.calculate(totalWeight: load))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SBSLayout.space6)
            .signatureCard()
            
            ResultActions {
                ResultLink(title: "Load this weight", icon: "circle.grid.2x1.fill", route: .plate(weight: load))
                SaveSetButton(weight: top, reps: topReps, rpe: topRPE, useMetric: settings.useMetric)
            }
        }
        .padding(.horizontal)
    }
    
    private func chipGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        BackoffView(settings: AppSettings(), initialTopSet: 315)
            .calculatorDestinations(settings: AppSettings())
    }
}
