import Foundation

// MARK: - Weight Input Parsing

enum WeightInput {
    /// Upper bound for any typed weight. Keeps later math and formatting sane when
    /// someone types or pastes an absurdly long number.
    static let maximumValue = 100_000.0
    
    /// Parses a positive number from a text field. The decimal pad types a comma in
    /// many locales, so both "102.5" and "102,5" are accepted.
    static func parse(_ text: String, maximum: Double = maximumValue) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite, value > 0, value <= maximum else {
            return nil
        }
        return value
    }
}

// MARK: - Units

enum Units {
    static let poundsPerKilogram = 2.20462
    static let kilogramsPerPound = 0.453592
    
    static func convert(_ weight: Double, fromMetric: Bool, toMetric: Bool) -> Double {
        guard fromMetric != toMetric else { return weight }
        return toMetric ? weight * kilogramsPerPound : weight * poundsPerKilogram
    }
    
    static func kilograms(_ weight: Double, isMetric: Bool) -> Double {
        convert(weight, fromMetric: isMetric, toMetric: true)
    }
}

// MARK: - Rounding

enum WeightRounding {
    /// Choices offered in Settings. Zero leaves weights unrounded.
    static func options(useMetric: Bool) -> [Double] {
        useMetric ? [0, 0.5, 1, 1.25, 2.5, 5] : [0, 1, 2.5, 5, 10]
    }
    
    /// The smallest jump the free plate set can load in each unit
    static func defaultIncrement(useMetric: Bool) -> Double {
        useMetric ? 2.5 : 5
    }
    
    static func round(_ weight: Double, to increment: Double) -> Double {
        guard increment > 0 else { return weight }
        return (weight / increment).rounded() * increment
    }
}

// MARK: - Recent Weights

/// The plate calculator's recent list, stored as a short string for @AppStorage
enum RecentWeights {
    static let limit = 6
    
    static func adding(_ weight: Double, to list: [Double]) -> [Double] {
        Array(([weight] + list.filter { $0 != weight }).prefix(limit))
    }
    
    static func encode(_ list: [Double]) -> String {
        list.map { String($0) }.joined(separator: ",")
    }
    
    static func decode(_ text: String) -> [Double] {
        text.split(separator: ",").compactMap { Double($0) }
    }
}

// MARK: - One-Rep Max

enum OneRepMax {
    struct Estimate {
        let name: String
        let value: Double
        let description: String
    }
    
    static let maximumReps = 30
    
    /// Estimates from each formula. A single rep is already a one-rep max, so every
    /// formula reports the lifted weight rather than extrapolating above it.
    static func estimates(weight: Double, reps: Int) -> [Estimate] {
        guard weight > 0, reps > 0, reps <= maximumReps else { return [] }
        
        let r = Double(reps)
        let formulas: [(name: String, multiplier: Double, description: String)] = [
            ("Epley", 1 + r / 30.0, "Most common formula"),
            ("Brzycki", 36.0 / (37.0 - r), "Popular for lower reps"),
            ("Lombardi", pow(r, 0.10), "Simple power formula"),
            ("Mayhew", 100.0 / (52.2 + 41.9 * exp(-0.055 * r)), "Research-based"),
            ("O'Conner", 1 + 0.025 * r, "Conservative estimate"),
            ("Wathan", 100.0 / (48.8 + 53.8 * exp(-0.075 * r)), "Football-based")
        ]
        
        return formulas.map { formula in
            Estimate(
                name: formula.name,
                value: reps == 1 ? weight : weight * formula.multiplier,
                description: formula.description
            )
        }
    }
    
    /// The headline estimate. Brzycki climbs steeply at high reps (5.1x the lifted weight
    /// at 30), so the median is used because one runaway formula can't drag it upward.
    static func median(weight: Double, reps: Int) -> Double? {
        let values = estimates(weight: weight, reps: reps).map(\.value).sorted()
        guard !values.isEmpty else { return nil }
        let middle = values.count / 2
        return values.count.isMultiple(of: 2)
            ? (values[middle - 1] + values[middle]) / 2
            : values[middle]
    }
}

// MARK: - RPE Table

/// Percentages of 1RM by reps and RPE, based on Mike Tuchscherer's research.
enum RPETable {
    static let repRange = 1...12
    static let rpeValues: [Double] = [6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0]
    
    // Rows: reps (1-12), Columns: RPE (6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10)
    private static let table: [[Double]] = [
        [0.88, 0.89, 0.91, 0.92, 0.94, 0.96, 0.98, 1.00],
        [0.85, 0.86, 0.88, 0.89, 0.91, 0.92, 0.94, 0.96],
        [0.82, 0.84, 0.85, 0.86, 0.88, 0.89, 0.91, 0.92],
        [0.79, 0.81, 0.82, 0.84, 0.85, 0.86, 0.88, 0.89],
        [0.77, 0.78, 0.79, 0.81, 0.82, 0.84, 0.85, 0.86],
        [0.74, 0.75, 0.77, 0.78, 0.79, 0.81, 0.82, 0.84],
        [0.71, 0.73, 0.74, 0.75, 0.77, 0.78, 0.79, 0.81],
        [0.68, 0.70, 0.71, 0.73, 0.74, 0.75, 0.77, 0.78],
        [0.65, 0.67, 0.68, 0.70, 0.71, 0.73, 0.74, 0.75],
        [0.63, 0.65, 0.66, 0.67, 0.68, 0.70, 0.71, 0.73],
        [0.60, 0.62, 0.63, 0.65, 0.66, 0.67, 0.68, 0.70],
        [0.58, 0.60, 0.61, 0.62, 0.63, 0.65, 0.66, 0.67]
    ]
    
    static func percentage(reps: Int, rpe: Double) -> Double {
        let repsIndex = min(max(reps - 1, 0), repRange.upperBound - 1)
        let rpeIndex = rpeValues.firstIndex(of: rpe) ?? 3
        return table[repsIndex][rpeIndex]
    }
    
    /// Weight for a set of `reps` at `rpe`, given an estimated max
    static func weight(e1RM: Double, reps: Int, rpe: Double) -> Double {
        e1RM * percentage(reps: reps, rpe: rpe)
    }
    
    /// The max implied by a completed set
    static func e1RM(weight: Double, reps: Int, rpe: Double) -> Double {
        weight / percentage(reps: reps, rpe: rpe)
    }
}

// MARK: - Warm-ups

enum WarmupPlan {
    enum Length: String, CaseIterable, Identifiable {
        case short = "Short"
        case standard = "Standard"
        case long = "Long"
        
        var id: String { rawValue }
        
        fileprivate var barReps: Int {
            self == .short ? 8 : 10
        }
        
        fileprivate var steps: [(percentage: Double, reps: Int)] {
            switch self {
            case .short: return [(0.6, 3), (0.8, 1)]
            case .standard: return [(0.5, 5), (0.7, 3), (0.85, 1)]
            case .long: return [(0.4, 8), (0.55, 5), (0.7, 3), (0.8, 2), (0.9, 1)]
            }
        }
    }
    
    struct WarmupSet: Equatable, Identifiable {
        let weight: Double
        let reps: Int
        var id: Double { weight }
    }
    
    /// Empty-bar set first, then a ramp toward the top set. `loadable` maps a target to a
    /// weight the lifter can build, and steps that collapse onto a neighbor are dropped.
    static func sets(
        topSet: Double,
        barLoad: Double,
        length: Length,
        loadable: (Double) -> Double
    ) -> [WarmupSet] {
        guard topSet > barLoad else { return [] }
        
        var sets = [WarmupSet(weight: barLoad, reps: length.barReps)]
        for step in length.steps {
            let weight = loadable(topSet * step.percentage)
            if weight > sets[sets.count - 1].weight && weight < topSet {
                sets.append(WarmupSet(weight: weight, reps: step.reps))
            }
        }
        return sets
    }
}

// MARK: - Back-off Sets

enum BackoffPlan {
    enum Target: Equatable {
        /// Percent below the top set, e.g. 0.1 for a 10% drop
        case percentDrop(Double)
        /// The weight the table gives for these reps at this RPE
        case rpe(Double)
    }
    
    static func weight(topSet: Double, topReps: Int, topRPE: Double, backoffReps: Int, target: Target) -> Double {
        switch target {
        case .percentDrop(let drop):
            return topSet * (1 - drop)
        case .rpe(let rpe):
            let e1RM = RPETable.e1RM(weight: topSet, reps: topReps, rpe: topRPE)
            return RPETable.weight(e1RM: e1RM, reps: backoffReps, rpe: rpe)
        }
    }
}

// MARK: - Meet Planning

enum MeetPlan {
    /// Federation loading: attempts move in 2.5 kg steps on a 20 kg bar with 2.5 kg collars
    static let attemptIncrementKg = 2.5
    static let barKg = 20.0
    static let collarKg = 2.5
    
    enum Style: String, CaseIterable, Identifiable {
        case conservative = "Conservative"
        case standard = "Standard"
        case aggressive = "Aggressive"
        
        var id: String { rawValue }
        
        fileprivate var fractions: (opener: Double, second: Double) {
            switch self {
            case .conservative: return (0.88, 0.94)
            case .standard: return (0.91, 0.96)
            case .aggressive: return (0.93, 0.97)
            }
        }
    }
    
    struct Attempts: Equatable {
        let opener: Double
        let second: Double
        let third: Double
    }
    
    /// Attempts in kilograms, working back from the third
    static func attempts(thirdKg: Double, style: Style) -> Attempts {
        let fractions = style.fractions
        return Attempts(
            opener: WeightRounding.round(thirdKg * fractions.opener, to: attemptIncrementKg),
            second: WeightRounding.round(thirdKg * fractions.second, to: attemptIncrementKg),
            third: WeightRounding.round(thirdKg, to: attemptIncrementKg)
        )
    }
    
    static var calculator: PlateCalculator {
        PlateCalculator(
            barWeight: barKg,
            availablePlates: StandardPlates.metricPlates,
            plateInventory: nil,
            collarWeight: collarKg
        )
    }
}

// MARK: - Strength Scores

/// Powerlifting scoring formulas. All inputs are in kilograms.
///
/// Bodyweights are clamped to each formula's usable range: outside it the polynomials
/// head toward zero or negative denominators and produce meaningless scores.
enum StrengthScoring {
    static func wilks(totalKg: Double, bodyweightKg: Double, isMale: Bool) -> Double {
        let x = isMale ? clamp(bodyweightKg, 40, 201.9) : clamp(bodyweightKg, 26.51, 154.53)
        
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
        
        let denominator = a + b*x + c*pow(x, 2) + d*pow(x, 3) + e*pow(x, 4) + f*pow(x, 5)
        return totalKg * (500.0 / denominator)
    }
    
    static func dots(totalKg: Double, bodyweightKg: Double, isMale: Bool) -> Double {
        let x = isMale ? clamp(bodyweightKg, 40, 210) : clamp(bodyweightKg, 40, 150)
        
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
        
        let denominator = a*pow(x, 4) + b*pow(x, 3) + c*pow(x, 2) + d*x + e
        return totalKg * (500.0 / denominator)
    }
    
    /// IPF GL points, using the coefficients for raw (classic) powerlifting.
    static func ipfGL(totalKg: Double, bodyweightKg: Double, isMale: Bool) -> Double {
        let x = max(bodyweightKg, 40)
        
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
        
        return totalKg * (100.0 / (a - b * exp(-c * x)))
    }
    
    /// Every formula scales linearly with total, so the total for any score follows from
    /// a known score at the same bodyweight.
    static func total(forScore target: Double, currentScore: Double, currentTotal: Double) -> Double? {
        guard currentScore > 0 else { return nil }
        return currentTotal * target / currentScore
    }
    
    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}
