import Charts
import SwiftUI

// MARK: - My Lifts

struct MyLiftsView: View {
    var settings: AppSettings
    
    @State private var showingAddLift = false
    @State private var newLiftName = ""
    
    private let store = LiftStore.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: SBSLayout.space3) {
                ScreenTitle("My Lifts")
                    .padding(.horizontal, -SBSLayout.space4)
                ForEach(store.lifts) { lift in
                    NavigationLink(value: CalculatorRoute.liftDetail(lift.id)) {
                        liftCard(lift)
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Save a set from the One-Rep Max or RPE calculator, or open a lift to add one.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, SBSLayout.space2)
            }
            .padding()
        }
        .sbsBackground()
        .screenNavigation("My Lifts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newLiftName = ""
                    showingAddLift = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Lift")
            }
        }
        .alert("Add Lift", isPresented: $showingAddLift) {
            TextField("Name", text: $newLiftName)
            Button("Add") { store.addLift(named: newLiftName) }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func liftCard(_ lift: TrackedLift) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lift.name)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                if let best = store.best(for: lift.id) {
                    Text("Best e1RM \(best.e1RM(useMetric: settings.useMetric).weightString(maxFractionDigits: 1)) \(settings.unitLabel)")
                        .font(SBSFonts.numberSmall())
                        .foregroundStyle(Color.inkSecondary)
                } else {
                    Text("No sets saved yet")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            
            Spacer()
            
            if let latest = store.latest(for: lift.id) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(latest.e1RM(useMetric: settings.useMetric).weightString(maxFractionDigits: 1))
                        .font(SBSFonts.number())
                        .foregroundStyle(Color.ink)
                    Text("latest")
                        .font(SBSFonts.caption())
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkTertiary)
        }
        .padding()
        .card()
    }
}

// MARK: - Lift Detail

struct LiftDetailView: View {
    var settings: AppSettings
    let liftID: UUID
    
    @State private var showingAddSet = false
    @State private var showingDeleteLift = false
    @State private var selectedDate: Date?
    @State private var actionRoute: CalculatorRoute?
    @Environment(\.dismiss) private var dismiss
    
    private let store = LiftStore.shared
    
    private var lift: TrackedLift? {
        store.lifts.first { $0.id == liftID }
    }
    
    private var history: [LiftEntry] {
        store.history(for: liftID)
    }
    
    private var latestE1RM: Double? {
        store.latest(for: liftID).map { ($0.e1RM(useMetric: settings.useMetric) * 10).rounded() / 10 }
    }
    
    private var best: LiftEntry? {
        store.best(for: liftID)
    }
    
    var body: some View {
        List {
            ScreenTitle(lift?.name ?? "Lift")
                .listRowInsets(EdgeInsets(top: SBSLayout.space2, leading: 0, bottom: SBSLayout.space3, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            summarySection
            
            if history.count >= 2 {
                Section {
                    chart
                        .frame(height: 220)
                        .padding(.vertical, 8)
                } header: {
                    Text("Estimated 1RM (\(settings.unitLabel))")
                        .eyebrowStyle()
                        .foregroundStyle(Color.inkSecondary)
                }
                .listRowBackground(Color.surface)
            }
            
            if let latestE1RM {
                Section {
                    ResultActions {
                        actionButton("RPE Calculator", icon: "gauge.with.needle.fill", route: .rpe(e1RM: latestE1RM))
                        actionButton("Training Max", icon: "percent", route: .trainingMax(max: latestE1RM))
                        actionButton("Warm-ups", icon: "flame.fill", route: .warmups(topSet: settings.rounded(latestE1RM)))
                        actionButton("Load this max", icon: "circle.grid.2x1.fill", route: .plate(weight: settings.rounded(latestE1RM)))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: SBSLayout.space3, leading: SBSLayout.space4, bottom: SBSLayout.space3, trailing: SBSLayout.space4))
                .listRowSeparator(.hidden)
            }
            
            historySection
            
            Section {
                Button(role: .destructive) {
                    showingDeleteLift = true
                } label: {
                    Text("Delete Lift")
                        .font(SBSFonts.bodyStrong())
                        .foregroundStyle(Color.danger)
                }
            }
            .listRowBackground(Color.surface)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sbsBackground()
        .screenNavigation(lift?.name ?? "Lift")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Set")
            }
        }
        .navigationDestination(item: $actionRoute) { route in
            CalculatorDestination(route: route, settings: settings)
        }
        .sheet(isPresented: $showingAddSet) {
            AddSetView(settings: settings, liftID: liftID)
        }
        .confirmationDialog(
            "Delete \(lift?.name ?? "this lift") and its \(history.count) saved \(history.count == 1 ? "set" : "sets")?",
            isPresented: $showingDeleteLift,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteLift(id: liftID)
                dismiss()
            }
        }
    }
    
    /// Buttons rather than NavigationLinks: inside a List, links get a disclosure chevron
    private func actionButton(_ title: String, icon: String, route: CalculatorRoute) -> some View {
        Button {
            actionRoute = route
        } label: {
            ResultActionLabel(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }
    
    private var summarySection: some View {
        Section {
            HStack {
                summaryStat(title: "Latest e1RM", value: latestE1RM)
                Divider().overlay(Color.hairline)
                summaryStat(title: "Best e1RM", value: best?.e1RM(useMetric: settings.useMetric))
            }
        }
        .listRowBackground(Color.surface)
    }
    
    private func summaryStat(title: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
            Text(value.map { "\($0.weightString(maxFractionDigits: 1)) \(settings.unitLabel)" } ?? "—")
                .font(SBSFonts.numberLarge())
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: Chart
    
    /// Touch-and-drag selects the nearest set
    private var selectedEntry: LiftEntry? {
        guard let selectedDate else { return nil }
        return history.min {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        }
    }
    
    private var chart: some View {
        let values = history.map { $0.e1RM(useMetric: settings.useMetric) }
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        let padding = max((high - low) * 0.15, high * 0.02, 1)
        
        return Chart {
            ForEach(history) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Estimated 1RM", entry.e1RM(useMetric: settings.useMetric))
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.orangeText)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Estimated 1RM", entry.e1RM(useMetric: settings.useMetric))
                )
                .symbolSize(50)
                .foregroundStyle(Color.orangeText)
            }
            
            if let selectedEntry {
                RuleMark(x: .value("Selected", selectedEntry.date))
                    .foregroundStyle(Color.inkSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        VStack(spacing: 2) {
                            Text("\(selectedEntry.e1RM(useMetric: settings.useMetric).weightString(maxFractionDigits: 1)) \(settings.unitLabel)")
                                .font(SBSFonts.numberSmall())
                                .foregroundStyle(Color.ink)
                            Text(selectedEntry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(Color.inkSecondary)
                        }
                        .padding(6)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: (low - padding)...(high + padding))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisTick().foregroundStyle(Color.inkSecondary)
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Color.hairline)
                AxisValueLabel()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chart of estimated one-rep max over time. The same values are listed in History.")
    }
    
    // MARK: History
    
    private var historySection: some View {
        Section {
            if history.isEmpty {
                Text("No sets saved yet. Tap + to add one.")
                    .font(SBSFonts.caption())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            ForEach(history.reversed()) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(setDescription(entry))
                            .font(SBSFonts.number())
                            .foregroundStyle(Color.ink)
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(SBSFonts.numberSmall())
                            .foregroundStyle(Color.inkSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.e1RM(useMetric: settings.useMetric).weightString(maxFractionDigits: 1))
                            .font(SBSFonts.number())
                            .foregroundStyle(Color.ink)
                        
                        if entry.id == best?.id {
                            Label("Best", systemImage: "trophy.fill")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.orangeText)
                        } else {
                            Text("e1RM")
                                .font(SBSFonts.caption())
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        store.delete(entryID: entry.id)
                    }
                }
            }
        } header: {
            Text("History")
                .eyebrowStyle()
                .foregroundStyle(Color.inkSecondary)
        }
        .listRowBackground(Color.surface)
    }
    
    private func setDescription(_ entry: LiftEntry) -> String {
        let weight = entry.displayWeight(useMetric: settings.useMetric).weightString(maxFractionDigits: 1)
        let set = "\(weight) \(settings.unitLabel) × \(entry.reps)"
        guard let rpe = entry.rpe else { return set }
        return "\(set) @ \(String(format: "%.1f", rpe))"
    }
}

// MARK: - Add Set

private struct AddSetView: View {
    var settings: AppSettings
    let liftID: UUID
    
    @State private var weight = ""
    @State private var reps = ""
    @State private var usesRPE = false
    @State private var rpe = 8.0
    @State private var date = Date.now
    @State private var prMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    private var weightValue: Double? { WeightInput.parse(weight) }
    private var repsValue: Int? { Int(reps) }
    
    private var maximumReps: Int {
        usesRPE ? RPETable.repRange.upperBound : OneRepMax.maximumReps
    }
    
    private var canSave: Bool {
        guard weightValue != nil, let repsValue else { return false }
        return repsValue > 0 && repsValue <= maximumReps
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Weight (\(settings.unitLabel))", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Reps (up to \(maximumReps))", text: $reps)
                        .keyboardType(.numberPad)
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
                .listRowBackground(Color.surface)
                
                Section {
                    Toggle("Record RPE", isOn: $usesRPE)
                        .tint(Color.orangeFill)
                    
                    if usesRPE {
                        Picker("RPE", selection: $rpe) {
                            ForEach(RPETable.rpeValues, id: \.self) { value in
                                Text(String(format: "%.1f", value)).tag(value)
                            }
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }
            .font(SBSFonts.body())
            .toggleStyle(SBSToggleStyle())
            .scrollContentBackground(.hidden)
            .sbsBackground()
            .navigationTitle("Add Set")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sensoryFeedback(.success, trigger: prMessage)
            .alert("New PR!", isPresented: Binding(
                get: { prMessage != nil },
                set: { if !$0 { dismiss() } }
            )) {
                Button("OK") { dismiss() }
            } message: {
                Text(prMessage ?? "")
            }
        }
    }
    
    private func save() {
        guard let weightValue, let repsValue else { return }
        let entry = LiftEntry(
            liftID: liftID,
            date: date,
            weight: weightValue,
            reps: repsValue,
            rpe: usesRPE ? rpe : nil,
            isMetric: settings.useMetric
        )
        if let improvement = LiftStore.shared.add(entry).prImprovement {
            prMessage = "Your estimated 1RM is up \(improvement.weightString(maxFractionDigits: 1)) \(settings.unitLabel)."
        } else {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        MyLiftsView(settings: AppSettings())
            .calculatorDestinations(settings: AppSettings())
    }
}
