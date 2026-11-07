import SwiftUI

// MARK: - Meet Planner

struct MeetPlannerView: View {
    var settings: AppSettings
    
    @AppStorage private var bodyWeight: String
    @AppStorage private var squatTarget: String
    @AppStorage private var benchTarget: String
    @AppStorage private var deadliftTarget: String
    @AppStorage("scores.isMale") private var isMale = true
    @AppStorage("meet.style") private var styleRaw = MeetPlan.Style.standard.rawValue
    
    init(settings: AppSettings) {
        self.settings = settings
        let unit = settings.unitLabel
        _bodyWeight = AppStorage(wrappedValue: "", "scores.bodyWeight.\(unit)")
        _squatTarget = AppStorage(wrappedValue: "", "meet.squat.\(unit)")
        _benchTarget = AppStorage(wrappedValue: "", "meet.bench.\(unit)")
        _deadliftTarget = AppStorage(wrappedValue: "", "meet.deadlift.\(unit)")
    }
    
    private var style: MeetPlan.Style {
        MeetPlan.Style(rawValue: styleRaw) ?? .standard
    }
    
    private func attempts(for text: String) -> MeetPlan.Attempts? {
        WeightInput.parse(text, maximum: PlateCalculator.maximumTotalWeight).map {
            MeetPlan.attempts(thirdKg: Units.kilograms($0, isMetric: settings.useMetric), style: style)
        }
    }
    
    private var plannedLifts: [(name: String, attempts: MeetPlan.Attempts)] {
        [("Squat", squatTarget), ("Bench", benchTarget), ("Deadlift", deadliftTarget)].compactMap { lift in
            attempts(for: lift.1).map { (lift.0, $0) }
        }
    }
    
    private var canFillFromLifts: Bool {
        guard StoreManager.shared.canAccess(.myLifts) else { return false }
        let store = LiftStore.shared
        return ["Squat", "Bench", "Deadlift"].contains { name in
            store.lift(named: name).flatMap { store.latest(for: $0.id) } != nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.space6) {
                ScreenTitle("Meet Planner")
                inputSection
                
                if !plannedLifts.isEmpty {
                    attemptsSection
                }
                
                if plannedLifts.count == 3 {
                    totalsSection
                }
                
                Text("Attempts move in 2.5 kg steps. Plate loads assume a 20 kg bar, 2.5 kg collars and kilo plates, the usual setup at a federation meet. Check your federation's rules.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .screenNavigation("Meet Planner")
        .recordsCalculation(key: plannedLifts.count == 3 ? "\(squatTarget)-\(benchTarget)-\(deadliftTarget)-\(styleRaw)" : nil)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            Text("Third Attempt Goals")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
            
            targetField("Squat", text: $squatTarget)
            targetField("Bench", text: $benchTarget)
            targetField("Deadlift", text: $deadliftTarget)
            
            if canFillFromLifts {
                Button {
                    fillFromLifts()
                } label: {
                    ResultActionLabel(title: "Fill from My Lifts", icon: "chart.line.uptrend.xyaxis")
                }
                .buttonStyle(.plain)
            }
            
            Picker("Attempt Style", selection: $styleRaw) {
                ForEach(MeetPlan.Style.allCases) { style in
                    Text(style.rawValue).tag(style.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            Divider().overlay(Color.hairline)
            
            targetField("Body Weight", text: $bodyWeight)
            
            Picker("Sex", selection: $isMale) {
                Text("Male").tag(true)
                Text("Female").tag(false)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func targetField(_ label: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(SBSFonts.bodyStrong())
                .foregroundStyle(Color.ink)
                .frame(minWidth: 100, alignment: .leading)
            
            TextField("0", text: text)
                .font(SBSFonts.number())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .field()
                .accessibilityLabel(label)
            
            Text(settings.unitLabel)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
        }
    }
    
    private var attemptsSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space4) {
            ForEach(plannedLifts, id: \.name) { lift in
                VStack(alignment: .leading, spacing: 8) {
                    Text(lift.name)
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.ink)
                    
                    attemptRow("Opener", lift.attempts.opener)
                    attemptRow("Second", lift.attempts.second)
                    attemptRow("Third", lift.attempts.third)
                }
                
                if lift.name != plannedLifts.last?.name {
                    Divider().overlay(Color.hairline)
                }
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func attemptRow(_ name: String, _ kilograms: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                
                Spacer()
                
                Text(displayWeight(kilograms))
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
            }
            
            PlateLoadText(result: MeetPlan.calculator.calculate(totalWeight: kilograms))
        }
    }
    
    private func displayWeight(_ kilograms: Double) -> String {
        let metric = "\(kilograms.weightString()) kg"
        if settings.useMetric { return metric }
        return "\(metric) (\((kilograms * Units.poundsPerKilogram).weightString(maxFractionDigits: 0)) lb)"
    }
    
    private var totalsSection: some View {
        let totals: [(name: String, kilograms: Double)] = [
            ("All openers", plannedLifts.reduce(0) { $0 + $1.attempts.opener }),
            ("All seconds", plannedLifts.reduce(0) { $0 + $1.attempts.second }),
            ("All thirds", plannedLifts.reduce(0) { $0 + $1.attempts.third })
        ]
        let bodyWeightKg = WeightInput.parse(bodyWeight).map { Units.kilograms($0, isMetric: settings.useMetric) }
        
        return VStack(alignment: .leading, spacing: SBSLayout.space4) {
            Text("Projected Totals")
                .font(SBSFonts.heading())
                .foregroundStyle(Color.ink)
            
            ForEach(totals, id: \.name) { total in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(total.name)
                            .font(SBSFonts.body())
                            .foregroundStyle(Color.inkSecondary)
                        Spacer()
                        Text(displayWeight(total.kilograms))
                            .font(SBSFonts.bodyStrong())
                            .foregroundStyle(Color.ink)
                    }
                    
                    if let bodyWeightKg {
                        Text(scores(totalKg: total.kilograms, bodyWeightKg: bodyWeightKg))
                            .font(SBSFonts.caption())
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
            }
            
            if bodyWeightKg == nil {
                Text("Add your body weight to see projected scores.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .padding()
        .card()
        .padding(.horizontal)
    }
    
    private func scores(totalKg: Double, bodyWeightKg: Double) -> String {
        let dots = StrengthScoring.dots(totalKg: totalKg, bodyweightKg: bodyWeightKg, isMale: isMale)
        let gl = StrengthScoring.ipfGL(totalKg: totalKg, bodyweightKg: bodyWeightKg, isMale: isMale)
        return String(format: "DOTS %.1f · IPF GL %.1f", dots, gl)
    }
    
    private func fillFromLifts() {
        let store = LiftStore.shared
        func latest(_ name: String) -> String? {
            store.lift(named: name).flatMap { store.latest(for: $0.id) }.map {
                $0.e1RM(useMetric: settings.useMetric).weightString(maxFractionDigits: 1)
            }
        }
        squatTarget = latest("Squat") ?? squatTarget
        benchTarget = latest("Bench") ?? benchTarget
        deadliftTarget = latest("Deadlift") ?? deadliftTarget
    }
}

#Preview {
    NavigationStack {
        MeetPlannerView(settings: AppSettings())
    }
}
