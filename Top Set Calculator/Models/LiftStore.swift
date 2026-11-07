import Foundation

// MARK: - Model

/// A lift the user tracks, such as Squat
struct TrackedLift: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
}

/// One logged set. The set is stored as performed, in the unit it was lifted in, so the
/// estimate can be recomputed and shown in either unit.
struct LiftEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var liftID: UUID
    var date: Date
    var weight: Double
    var reps: Int
    var rpe: Double?
    var isMetric: Bool
    
    /// Estimated max in the unit it was lifted in. RPE sets use the table, which only runs
    /// to 12 reps; anything else uses the formula median.
    private var nativeE1RM: Double {
        if let rpe, RPETable.repRange.contains(reps) {
            return RPETable.e1RM(weight: weight, reps: reps, rpe: rpe)
        }
        return OneRepMax.median(weight: weight, reps: reps) ?? weight
    }
    
    func e1RM(useMetric: Bool) -> Double {
        Units.convert(nativeE1RM, fromMetric: isMetric, toMetric: useMetric)
    }
    
    func displayWeight(useMetric: Bool) -> Double {
        Units.convert(weight, fromMetric: isMetric, toMetric: useMetric)
    }
}

// MARK: - Store

/// Saved lifts and history, kept as a JSON file in Application Support
@Observable
final class LiftStore {
    static let shared = LiftStore()
    
    private(set) var lifts: [TrackedLift]
    private(set) var entries: [LiftEntry]
    
    @ObservationIgnored private let fileURL: URL
    
    private struct Stored: Codable {
        var lifts: [TrackedLift]
        var entries: [LiftEntry]
    }
    
    static let defaultLifts = ["Squat", "Bench Press", "Deadlift", "Overhead Press"]
    
    static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "lifts.json")
    }
    
    init(fileURL: URL = LiftStore.defaultFileURL) {
        self.fileURL = fileURL
        
        if let data = try? Data(contentsOf: fileURL) {
            if let stored = try? JSONDecoder().decode(Stored.self, from: data) {
                self.lifts = stored.lifts
                self.entries = stored.entries
                return
            }
            // Keep an unreadable file rather than overwriting someone's history
            let backup = fileURL.appendingPathExtension("unreadable")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
        }
        
        self.lifts = Self.defaultLifts.map { TrackedLift(name: $0) }
        self.entries = []
    }
    
    // MARK: Reading
    
    /// A lift's sets, oldest first
    func history(for liftID: UUID) -> [LiftEntry] {
        entries.filter { $0.liftID == liftID }.sorted { $0.date < $1.date }
    }
    
    /// The most recent set: what the lifter is working from now
    func latest(for liftID: UUID) -> LiftEntry? {
        history(for: liftID).last
    }
    
    /// The set with the highest estimated max
    func best(for liftID: UUID) -> LiftEntry? {
        entries.filter { $0.liftID == liftID }.max { $0.e1RM(useMetric: true) < $1.e1RM(useMetric: true) }
    }
    
    /// A lift whose name matches, for filling in the squat, bench and deadlift
    func lift(named name: String) -> TrackedLift? {
        lifts.first { $0.name.localizedCaseInsensitiveContains(name) }
    }
    
    // MARK: Writing
    
    struct AddResult: Equatable {
        /// Set when this entry beats an earlier best, by this much in the entry's unit
        let prImprovement: Double?
    }
    
    /// Saves a set and reports whether it's a PR. A lift's first set isn't one: there's
    /// nothing to have beaten yet.
    @discardableResult
    func add(_ entry: LiftEntry) -> AddResult {
        let previousBest = best(for: entry.liftID)?.e1RM(useMetric: entry.isMetric)
        entries.append(entry)
        save()
        
        let estimate = entry.e1RM(useMetric: entry.isMetric)
        if let previousBest, estimate > previousBest {
            return AddResult(prImprovement: estimate - previousBest)
        }
        return AddResult(prImprovement: nil)
    }
    
    func delete(entryID: UUID) {
        entries.removeAll { $0.id == entryID }
        save()
    }
    
    /// Adds a lift, unless one already has that name
    @discardableResult
    func addLift(named name: String) -> TrackedLift? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !lifts.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return nil
        }
        let lift = TrackedLift(name: trimmed)
        lifts.append(lift)
        save()
        return lift
    }
    
    func deleteLift(id: UUID) {
        lifts.removeAll { $0.id == id }
        entries.removeAll { $0.liftID == id }
        save()
    }
    
    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(Stored(lifts: lifts, entries: entries))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save lifts: \(error)")
        }
    }
}

#if DEBUG
extension LiftStore {
    /// A few months of squat history, for screenshots and UI tests
    func seedSampleHistoryForTesting() {
        guard entries.isEmpty, let squat = lifts.first else { return }
        for (weeksAgo, weight) in [(16, 285.0), (12, 295), (8, 290), (4, 305), (1, 315)] {
            add(LiftEntry(
                liftID: squat.id,
                date: Date(timeIntervalSinceNow: Double(-weeksAgo) * 604_800),
                weight: weight,
                reps: 3,
                rpe: 8,
                isMetric: false
            ))
        }
    }
}
#endif
