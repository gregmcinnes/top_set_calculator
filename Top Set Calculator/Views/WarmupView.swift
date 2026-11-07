import SwiftUI

// MARK: - Warm-up Generator

struct WarmupView: View {
    var settings: AppSettings
    private let initialTopSet: Double?
    
    @AppStorage private var topSet: String
    @AppStorage("warmups.length") private var lengthRaw = WarmupPlan.Length.standard.rawValue
    @State private var didApplyInitial = false
    
    init(settings: AppSettings, initialTopSet: Double? = nil) {
        self.settings = settings
        self.initialTopSet = initialTopSet
        _topSet = AppStorage(wrappedValue: "", "warmups.topSet.\(settings.unitLabel)")
    }
    
    private var length: WarmupPlan.Length {
        WarmupPlan.Length(rawValue: lengthRaw) ?? .standard
    }
    
    private var calculator: PlateCalculator {
        PlateCalculator(barWeight: settings.barWeight, settings: settings)
    }
    
    private var topSetValue: Double? {
        WeightInput.parse(topSet, maximum: PlateCalculator.maximumTotalWeight)
    }
    
    /// What can actually go on the bar for a target
    private func loadable(_ target: Double) -> Double {
        calculator.calculate(totalWeight: settings.rounded(target)).achievableWeight
    }
    
    private var sets: [WarmupPlan.WarmupSet] {
        guard let top = topSetValue else { return [] }
        return WarmupPlan.sets(topSet: top, barLoad: calculator.emptyLoad, length: length, loadable: loadable)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.sectionSpacing) {
                inputSection
                
                if let top = topSetValue {
                    if sets.isEmpty {
                        Text("Your top set is at or below the empty bar (\(calculator.emptyLoad.weightString()) \(settings.unitLabel)), so there's nothing to ramp through.")
                            .font(SBSFonts.body())
                            .foregroundStyle(SBSColors.textSecondaryFallback)
                            .padding(.horizontal)
                    } else {
                        planSection(top: top)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneToolbar()
        .sbsBackground()
        .navigationTitle("Warm-ups")
        .navigationBarTitleDisplayMode(.inline)
        .recordsCalculation(key: topSetValue.map { "\($0)-\(lengthRaw)" })
        .onAppear {
            if let initialTopSet, !didApplyInitial {
                topSet = initialTopSet.weightString()
            }
            didApplyInitial = true
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: SBSLayout.paddingMedium) {
            WeightField(label: "Top Set Weight", text: $topSet, unit: settings.unitLabel)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Warm-up Length")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                Picker("Warm-up Length", selection: $lengthRaw) {
                    ForEach(WarmupPlan.Length.allCases) { length in
                        Text(length.rawValue).tag(length.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Text("Uses your \(settings.barWeight.weightString()) \(settings.unitLabel) bar\(settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) ? " and My Plates" : "").")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding()
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func planSection(top: Double) -> some View {
        VStack(spacing: 0) {
            ForEach(sets) { set in
                row(weight: set.weight, reps: "\(set.reps)", isTopSet: false)
                Divider()
            }
            row(weight: loadable(top), reps: "Top set", isTopSet: true)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .sbsCard()
        .padding(.horizontal)
    }
    
    private func row(weight: Double, reps: String, isTopSet: Bool) -> some View {
        NavigationLink(value: CalculatorRoute.plate(weight: weight)) {
            HStack(spacing: SBSLayout.paddingMedium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(weight.weightString()) \(settings.unitLabel)")
                        .font(SBSFonts.bodyBold())
                        .foregroundStyle(isTopSet ? SBSColors.accentFallback : SBSColors.textPrimaryFallback)
                    
                    PlateLoadText(result: calculator.calculate(totalWeight: weight))
                }
                
                Spacer()
                
                Text(isTopSet ? reps : "× \(reps)")
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(isTopSet ? SBSColors.accentFallback : SBSColors.textSecondaryFallback)
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SBSColors.textTertiaryFallback)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        WarmupView(settings: AppSettings(), initialTopSet: 315)
            .calculatorDestinations(settings: AppSettings())
    }
}
