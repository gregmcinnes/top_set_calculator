import SwiftUI

// MARK: - Navigation

/// Every screen reachable from the home screen. Using values lets any result link to any
/// calculator with its number already filled in.
enum CalculatorRoute: Hashable {
    case oneRepMax
    case rpe(e1RM: Double? = nil)
    case plate(weight: Double? = nil)
    case trainingMax(max: Double? = nil)
    case scores
    case warmups(topSet: Double? = nil)
    case backoff(topSet: Double? = nil)
    case meetPlanner
    case myLifts
    case liftDetail(UUID)
}

/// The screen for a route
struct CalculatorDestination: View {
    let route: CalculatorRoute
    let settings: AppSettings
    
    var body: some View {
        switch route {
        case .oneRepMax:
            OneRepMaxCalculatorView(settings: settings)
        case .rpe(let e1RM):
            RPECalculatorView(settings: settings, initialE1RM: e1RM)
        case .plate(let weight):
            StandalonePlateCalculatorView(settings: settings, initialWeight: weight)
        case .trainingMax(let max):
            TrainingMaxCalculatorView(settings: settings, initialMax: max)
        case .scores:
            StrengthScoresView(settings: settings)
        case .warmups(let topSet):
            WarmupView(settings: settings, initialTopSet: topSet)
        case .backoff(let topSet):
            BackoffView(settings: settings, initialTopSet: topSet)
        case .meetPlanner:
            MeetPlannerView(settings: settings)
        case .myLifts:
            MyLiftsView(settings: settings)
        case .liftDetail(let id):
            LiftDetailView(settings: settings, liftID: id)
        }
    }
}

extension View {
    func calculatorDestinations(settings: AppSettings) -> some View {
        navigationDestination(for: CalculatorRoute.self) { route in
            CalculatorDestination(route: route, settings: settings)
        }
    }
}

// MARK: - Result Actions

/// The small outlined button used for "what next" actions under a result
struct ResultActionLabel: View {
    let title: String
    let icon: String
    var isLocked = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isLocked ? "lock.fill" : icon)
                .font(.footnote.weight(.semibold))
            Text(title)
                .font(SBSFonts.caption())
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44)
        .card()
    }
}

/// Lays result actions out two across, wrapping as needed
struct ResultActions<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            content
        }
    }
}

/// Links to a free calculator
struct ResultLink: View {
    let title: String
    let icon: String
    let route: CalculatorRoute
    
    var body: some View {
        NavigationLink(value: route) {
            ResultActionLabel(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }
}

/// Links to a premium screen, or opens the paywall for anyone who doesn't have it
struct PremiumResultLink: View {
    let title: String
    let icon: String
    let feature: PremiumFeature
    let route: CalculatorRoute
    
    @State private var paywallFeature: PremiumFeature?
    
    var body: some View {
        if StoreManager.shared.canAccess(feature) {
            ResultLink(title: title, icon: icon, route: route)
        } else {
            Button {
                paywallFeature = feature
            } label: {
                ResultActionLabel(title: title, icon: icon, isLocked: true)
            }
            .buttonStyle(.plain)
            .sheet(item: $paywallFeature) { feature in
                PaywallView(triggeredByFeature: feature)
            }
        }
    }
}

// MARK: - PRO Badge

struct PremiumBadge: View {
    var body: some View {
        Text("PRO")
            .eyebrowStyle()
            .foregroundStyle(Color.bg)
            .padding(.horizontal, SBSLayout.space2)
            .padding(.vertical, 3)
            .background(Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
    }
}

// MARK: - Status Badge

/// Names a state. The word does the work; the colour only reinforces it.
struct StatusBadge: View {
    let text: String
    var color: Color = .ink

    var body: some View {
        Text(text)
            .eyebrowStyle()
            .foregroundStyle(color)
            .padding(.horizontal, SBSLayout.space2)
            .padding(.vertical, 3)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(color, lineWidth: SBSLayout.strokeHairline)
            )
    }
}

// MARK: - Save to My Lifts

/// Saves a completed set to a chosen lift and calls out PRs
struct SaveSetButton: View {
    let weight: Double
    let reps: Int
    var rpe: Double?
    let useMetric: Bool
    
    @State private var paywallFeature: PremiumFeature?
    @State private var message: String?
    @State private var savedCount = 0
    
    private let store = LiftStore.shared
    
    var body: some View {
        Group {
            if StoreManager.shared.canAccess(.myLifts) {
                Menu {
                    ForEach(store.lifts) { lift in
                        Button(lift.name) { save(to: lift) }
                    }
                } label: {
                    ResultActionLabel(title: message ?? "Save to My Lifts", icon: message == nil ? "plus.circle" : "checkmark.circle.fill")
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    paywallFeature = .myLifts
                } label: {
                    ResultActionLabel(title: "Save to My Lifts", icon: "plus.circle", isLocked: true)
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.success, trigger: savedCount)
        .sheet(item: $paywallFeature) { feature in
            PaywallView(triggeredByFeature: feature)
        }
        .onChange(of: weight) { _, _ in message = nil }
        .onChange(of: reps) { _, _ in message = nil }
        .onChange(of: rpe) { _, _ in message = nil }
    }
    
    private func save(to lift: TrackedLift) {
        let entry = LiftEntry(liftID: lift.id, date: .now, weight: weight, reps: reps, rpe: rpe, isMetric: useMetric)
        let result = store.add(entry)
        if let improvement = result.prImprovement {
            message = "New PR! +\(improvement.weightString(maxFractionDigits: 1)) \(useMetric ? "kg" : "lb")"
        } else {
            message = "Saved to \(lift.name)"
        }
        savedCount += 1
    }
}

// MARK: - Fill from My Lifts

/// Chips that fill a max field from saved lifts. Hidden until there's something to offer.
struct LiftFillChips: View {
    let useMetric: Bool
    let onSelect: (Double) -> Void
    
    private let store = LiftStore.shared
    
    private var options: [(lift: TrackedLift, e1RM: Double)] {
        guard StoreManager.shared.canAccess(.myLifts) else { return [] }
        return store.lifts.compactMap { lift in
            store.latest(for: lift.id).map { (lift, ($0.e1RM(useMetric: useMetric) * 10).rounded() / 10) }
        }
    }
    
    var body: some View {
        if !options.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.lift.id) { option in
                        Button {
                            onSelect(option.e1RM)
                        } label: {
                            Text("\(option.lift.name) \(option.e1RM.weightString(maxFractionDigits: 1))")
                                .font(SBSFonts.numberSmall())
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .field()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sharing

/// Renders a result as an image and opens the share sheet. Free for everyone.
struct ShareResultButton: View {
    let title: String
    let value: String
    let detail: String
    
    @State private var image: UIImage?
    
    var body: some View {
        Button {
            let renderer = ImageRenderer(content: ResultShareCard(title: title, value: value, detail: detail))
            renderer.scale = 3
            image = renderer.uiImage
        } label: {
            ResultActionLabel(title: "Share", icon: "square.and.arrow.up")
        }
        .buttonStyle(.plain)
        .sheet(item: Binding(
            get: { image.map(ShareableImage.init) },
            set: { if $0 == nil { image = nil } }
        )) { shareable in
            ShareSheet(items: [shareable.image])
        }
    }
    
    private struct ShareableImage: Identifiable {
        let id = UUID()
        let image: UIImage
    }
}

struct ResultShareCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space3) {
            Text(title)
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)

            HeroNumber(value: value)

            Text(detail)
                .font(SBSFonts.numberSmall())
                .foregroundStyle(Color.inkSecondary)

            HStack(spacing: SBSLayout.space2) {
                Image("TopSetMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                Text("Top Set Calculator")
                    .eyebrowStyle()
                    .foregroundStyle(Color.ink)
            }
            .padding(.top, SBSLayout.space4)
        }
        .padding(SBSLayout.space8)
        .frame(width: 360, alignment: .leading)
        .background(Color.bg)
        // Shared cards are always Iron, whatever the app's appearance
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Plate Load Text

/// The compact plate strip with its per-side list: "45 · 45 · 10 per side"
struct PlateLoadText: View {
    let result: PlateCalculatorResult

    private var description: String {
        guard !result.platesPerSide.isEmpty else { return "Bar only" }
        let plates = result.platesPerSide.sorted { $0.weight > $1.weight }
        return plates.map { $0.weight.weightString() }.joined(separator: " · ") + " per side"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SBSLayout.space2) {
            if !result.platesPerSide.isEmpty {
                PlateStrip(plates: result.platesPerSide)
            }
            Text(description)
                .font(SBSFonts.numberSmall())
                .foregroundStyle(Color.inkSecondary)
        }
    }
}

// MARK: - Inputs

/// Labeled weight field matching the calculators' large input style
struct WeightField: View {
    let label: String
    @Binding var text: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            
            HStack {
                TextField("0", text: $text)
                    .font(SBSFonts.numberLarge())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(label)
                
                Text(unit)
                    .font(SBSFonts.numberUnit())
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding()
            .field()
        }
    }
}

/// A row of single-select chips
struct ChoiceChips<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(label(option))
                            .font(SBSFonts.numberSmall())
                            .foregroundStyle(Color.ink)
                            .frame(minWidth: 32, minHeight: 28)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .chipBackground(isSelected: selection == option)
                    }
                    .accessibilityAddTraits(selection == option ? .isSelected : [])
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - Review Prompt Tracking

/// Counts a calculation once a live result has held for a moment. Results update on every
/// keystroke, so counting immediately would reach the review milestones mid-number. Values
/// restored when the screen opens don't count.
private struct CalculationRecorder: ViewModifier {
    let key: String?
    @State private var initialKey: String?
    
    init(key: String?) {
        self.key = key
        _initialKey = State(initialValue: key)
    }
    
    func body(content: Content) -> some View {
        content.task(id: key) {
            guard let key, key != initialKey else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            AppSettings.recordCalculationCompleted()
        }
    }
}

extension View {
    /// `key` identifies the current inputs, and is nil until they produce a result
    func recordsCalculation(key: String?) -> some View {
        modifier(CalculationRecorder(key: key))
    }
}
