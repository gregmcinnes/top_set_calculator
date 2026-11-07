import SwiftUI

// MARK: - Plate Definition

struct Plate: Identifiable, Equatable {
    let weight: Double      // Weight value (in native unit)
    let isMetric: Bool      // Whether weight is in kg (true) or lbs (false)
    let color: Color
    let height: CGFloat     // relative height (0-1)
    
    var id: String { "\(weight)-\(isMetric)" }
    
    /// Weight in pounds (for calculations)
    var weightInLbs: Double {
        isMetric ? weight * 2.20462 : weight
    }
    
    /// Weight in kg (for calculations)
    var weightInKg: Double {
        isMetric ? weight : weight * 0.453592
    }
    
    var displayWeight: String {
        weight.weightString()
    }
    
    func displayWeight(useMetric: Bool) -> String {
        if useMetric == isMetric {
            return weight.weightString()
        }
        return (useMetric ? weightInKg : weightInLbs).weightString(maxFractionDigits: 1)
    }
    
    /// Create a copy with a different color
    func withColor(_ newColor: Color) -> Plate {
        Plate(weight: weight, isMetric: isMetric, color: newColor, height: height)
    }
}

// MARK: - Standard Plates

enum StandardPlates {
    // Default plate colors - keyed by (weight, isMetric) combination
    // For imperial (lbs)
    static let defaultColorsImperial: [Double: Color] = [
        55: Color(red: 0.85, green: 0.2, blue: 0.2),     // Red - 55lb (premium)
        45: Color(red: 0.2, green: 0.4, blue: 0.8),      // Blue
        35: Color(red: 0.9, green: 0.75, blue: 0.1),     // Yellow
        25: Color(red: 0.2, green: 0.7, blue: 0.3),      // Green
        10: Color(red: 0.95, green: 0.95, blue: 0.95),   // White
        5: Color(red: 0.85, green: 0.2, blue: 0.2),      // Red
        2.5: Color(red: 0.6, green: 0.6, blue: 0.65),    // Silver
        1.25: Color(red: 0.4, green: 0.4, blue: 0.45),   // Dark silver - 1.25lb (premium)
    ]
    
    // For metric (kg) - actual kg values
    static let defaultColorsMetric: [Double: Color] = [
        25: Color(red: 0.85, green: 0.2, blue: 0.2),     // Red - 25kg
        20: Color(red: 0.2, green: 0.4, blue: 0.8),      // Blue - 20kg
        15: Color(red: 0.9, green: 0.75, blue: 0.1),     // Yellow - 15kg
        10: Color(red: 0.2, green: 0.7, blue: 0.3),      // Green - 10kg
        5: Color(red: 0.95, green: 0.95, blue: 0.95),    // White - 5kg
        2.5: Color(red: 0.85, green: 0.2, blue: 0.2),    // Red small - 2.5kg
        1.25: Color(red: 0.6, green: 0.6, blue: 0.65),   // Silver - 1.25kg
        0.5: Color(red: 0.4, green: 0.4, blue: 0.45),    // Dark silver - 0.5kg (premium)
    ]
    
    static func defaultColor(for weight: Double, isMetric: Bool) -> Color? {
        isMetric ? defaultColorsMetric[weight] : defaultColorsImperial[weight]
    }
    
    // Premium plate weights (requires extendedEquipment feature)
    static let premiumImperialWeights: Set<Double> = [55, 1.25]
    static let premiumMetricWeights: Set<Double> = [0.5]
    
    // Olympic plates in lbs with competition-inspired colors
    // Includes premium plates (55 lb, 1.25 lb) - filtered based on access
    static let allImperialPlates: [Plate] = [
        Plate(weight: 55, isMetric: false, color: Color(red: 0.85, green: 0.2, blue: 0.2), height: 1.0),     // Red - 55lb (premium)
        Plate(weight: 45, isMetric: false, color: Color(red: 0.2, green: 0.4, blue: 0.8), height: 0.95),     // Blue - 45lb
        Plate(weight: 35, isMetric: false, color: Color(red: 0.9, green: 0.75, blue: 0.1), height: 0.85),    // Yellow - 35lb
        Plate(weight: 25, isMetric: false, color: Color(red: 0.2, green: 0.7, blue: 0.3), height: 0.75),     // Green - 25lb
        Plate(weight: 10, isMetric: false, color: Color(red: 0.95, green: 0.95, blue: 0.95), height: 0.55),  // White - 10lb
        Plate(weight: 5, isMetric: false, color: Color(red: 0.85, green: 0.2, blue: 0.2), height: 0.45),     // Red - 5lb
        Plate(weight: 2.5, isMetric: false, color: Color(red: 0.6, green: 0.6, blue: 0.65), height: 0.35),   // Silver - 2.5lb
        Plate(weight: 1.25, isMetric: false, color: Color(red: 0.4, green: 0.4, blue: 0.45), height: 0.3),   // Dark silver - 1.25lb (premium)
    ]
    
    // Standard plates (free tier) - excludes premium plates
    static var plates: [Plate] {
        allImperialPlates.filter { !premiumImperialWeights.contains($0.weight) }
    }
    
    // Metric plates (kg) with competition colors - stored in actual kg values
    // Includes premium plates (0.5 kg) - filtered based on access
    static let allMetricPlates: [Plate] = [
        Plate(weight: 25, isMetric: true, color: Color(red: 0.85, green: 0.2, blue: 0.2), height: 1.0),     // Red - 25kg
        Plate(weight: 20, isMetric: true, color: Color(red: 0.2, green: 0.4, blue: 0.8), height: 0.95),     // Blue - 20kg
        Plate(weight: 15, isMetric: true, color: Color(red: 0.9, green: 0.75, blue: 0.1), height: 0.85),    // Yellow - 15kg
        Plate(weight: 10, isMetric: true, color: Color(red: 0.2, green: 0.7, blue: 0.3), height: 0.75),     // Green - 10kg
        Plate(weight: 5, isMetric: true, color: Color(red: 0.95, green: 0.95, blue: 0.95), height: 0.6),    // White - 5kg
        Plate(weight: 2.5, isMetric: true, color: Color(red: 0.85, green: 0.2, blue: 0.2), height: 0.5),    // Red small - 2.5kg
        Plate(weight: 1.25, isMetric: true, color: Color(red: 0.6, green: 0.6, blue: 0.65), height: 0.4),   // Silver - 1.25kg
        Plate(weight: 0.5, isMetric: true, color: Color(red: 0.4, green: 0.4, blue: 0.45), height: 0.3),    // Dark silver - 0.5kg (premium)
    ]
    
    // Standard plates (free tier) - excludes premium plates
    static var metricPlates: [Plate] {
        allMetricPlates.filter { !premiumMetricWeights.contains($0.weight) }
    }
    
    /// Every plate the user could own: the ones to list in Settings for colors and counts
    static func configurablePlates(with settings: AppSettings, useMetric: Bool) -> [Plate] {
        guard StoreManager.shared.canAccess(.extendedEquipment) else {
            return useMetric ? metricPlates : plates
        }
        let custom = settings.customPlateWeights(useMetric: useMetric).map { customPlate(weight: $0, isMetric: useMetric) }
        return ((useMetric ? allMetricPlates : allImperialPlates) + custom).sorted { $0.weight > $1.weight }
    }
    
    /// A user-defined size, drawn at the height its weight would have among the standard plates
    static func customPlate(weight: Double, isMetric: Bool) -> Plate {
        let standard = (isMetric ? allMetricPlates : allImperialPlates).sorted { $0.weight < $1.weight }
        var height = standard.last?.height ?? 1
        if let lightest = standard.first, weight < lightest.weight {
            height = lightest.height * 0.8
        } else if let upperIndex = standard.firstIndex(where: { $0.weight >= weight }), upperIndex > 0 {
            let lower = standard[upperIndex - 1]
            let upper = standard[upperIndex]
            let fraction = (weight - lower.weight) / (upper.weight - lower.weight)
            height = lower.height + (upper.height - lower.height) * fraction
        }
        return Plate(weight: weight, isMetric: isMetric, color: Color(white: 0.3), height: height)
    }
    
    /// Get plates with custom colors applied and premium plates included if accessible
    static func plates(with settings: AppSettings, useMetric: Bool) -> [Plate] {
        let hasPremiumEquipment = StoreManager.shared.canAccess(.extendedEquipment)
        let usesInventory = settings.useMyPlates && StoreManager.shared.canAccess(.myPlates)
        
        // Most gyms don't have 55s, so largest-first must not reach for them by default.
        // With an inventory the owned count decides instead.
        let basePlates = configurablePlates(with: settings, useMetric: useMetric).filter { plate in
            useMetric || plate.weight != 55 || !hasPremiumEquipment || settings.use55LbPlates || usesInventory
        }
        
        guard settings.useCustomPlateColors && StoreManager.shared.canAccess(.customPlateColors) else {
            return basePlates
        }
        
        return basePlates.map { plate in
            let customColor = settings.plateColor(for: plate.weight, defaultColor: plate.color)
            return plate.withColor(customColor)
        }
    }
}

// MARK: - Plate Calculator Logic

struct PlateCalculatorResult {
    let platesPerSide: [Plate]
    let totalWeight: Double      // The target weight requested
    let barWeight: Double
    var collarWeight: Double = 0
    
    /// The actual weight on the bar with these plates
    var achievableWeight: Double {
        barWeight + 2 * (collarWeight + platesPerSide.reduce(0) { $0 + $1.weight })
    }
    
    /// Weight per side that couldn't be made up with available plates
    var remainder: Double {
        max(0, (totalWeight - achievableWeight) / 2)
    }
    
    var isExact: Bool { remainder < 0.005 }
    
    /// Weight per side with the available plates
    var weightPerSide: Double {
        platesPerSide.reduce(0) { $0 + $1.weight }
    }
}

struct PlateCalculator {
    /// Heaviest total the calculator accepts. Well past any real lift, and it keeps
    /// the number of plates (and views) bounded.
    static let maximumTotalWeight = 2500.0
    
    let barWeight: Double
    let availablePlates: [Plate]
    let plateInventory: [Double: Int]?  // weight -> count per side (nil = unlimited)
    var collarWeight: Double = 0        // weight of one collar
    
    init(barWeight: Double, availablePlates: [Plate], plateInventory: [Double: Int]?, collarWeight: Double = 0) {
        self.barWeight = barWeight
        self.availablePlates = availablePlates
        self.plateInventory = plateInventory
        self.collarWeight = collarWeight
    }
    
    init(barWeight: Double = 45, useMetric: Bool = false) {
        self.barWeight = barWeight
        self.availablePlates = useMetric ? StandardPlates.metricPlates : StandardPlates.plates
        self.plateInventory = nil
    }
    
    init(barWeight: Double = 45, settings: AppSettings) {
        self.barWeight = barWeight
        let useMetric = settings.useMetric
        self.availablePlates = StandardPlates.plates(with: settings, useMetric: useMetric)
        self.collarWeight = StoreManager.shared.canAccess(.extendedEquipment) ? settings.collarWeight : 0
        
        // Use plate inventory if My Plates is enabled
        if settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) {
            self.plateInventory = settings.activePlateInventory
        } else {
            self.plateInventory = nil
        }
    }
    
    func calculate(totalWeight: Double) -> PlateCalculatorResult {
        guard totalWeight > emptyLoad else {
            return PlateCalculatorResult(platesPerSide: [], totalWeight: emptyLoad, barWeight: barWeight, collarWeight: collarWeight)
        }
        
        let target = (totalWeight - emptyLoad) / 2.0
        let sortedPlates = availablePlates.sorted { $0.weight > $1.weight }
        var plates = largestFirstPlates(for: target, from: sortedPlates)
        
        // Largest-first always works with unlimited plates, but a limited inventory can
        // strand it: 45 + 25 fails with one 45 and no 25s, where 35 + 35 would work.
        if let inventory = plateInventory, target - plates.reduce(0, { $0 + $1.weight }) >= 0.005 {
            plates = closestPlates(to: target, from: sortedPlates, inventory: inventory)
        }
        
        return PlateCalculatorResult(platesPerSide: plates, totalWeight: totalWeight, barWeight: barWeight, collarWeight: collarWeight)
    }
    
    /// The bar and collars with no plates
    var emptyLoad: Double {
        barWeight + 2 * collarWeight
    }
    
    /// The lightest buildable total at or above a target, or nil if the plates can't reach it
    func closestLoad(atOrAbove totalWeight: Double) -> Double? {
        guard totalWeight > emptyLoad else { return emptyLoad }
        
        let targetUnits = Int((((totalWeight - emptyLoad) / 2 * 100) - 0.01).rounded(.up))
        let plateUnits = availablePlates.map { (weight: $0.weight, units: Int(($0.weight * 100).rounded())) }
        guard let largest = plateUnits.map(\.units).max(), let smallest = plateUnits.map(\.units).min(), smallest > 0 else {
            return nil
        }
        
        var perSide: Int?
        if let inventory = plateInventory {
            // Removing any plate from the lightest qualifying load drops it below the target,
            // so that load can't be more than one plate past it.
            var sums: Set<Int> = [0]
            for plate in plateUnits {
                let stock = inventory[plate.weight] ?? 0
                guard stock > 0 else { continue }
                for sum in sums {
                    for count in 1...stock {
                        let newSum = sum + count * plate.units
                        if newSum >= targetUnits + largest { break }
                        sums.insert(newSum)
                    }
                }
            }
            perSide = sums.filter { $0 >= targetUnits }.min()
        } else {
            // Unlimited plates: walk multiples of the smallest plate until one builds exactly
            var candidate = (targetUnits + smallest - 1) / smallest * smallest
            for _ in 0..<64 {
                var remaining = candidate
                for units in plateUnits.map(\.units).sorted(by: >) {
                    remaining %= units
                }
                if remaining == 0 {
                    perSide = candidate
                    break
                }
                candidate += smallest
            }
        }
        return perSide.map { emptyLoad + 2 * Double($0) / 100 }
    }
    
    /// Plates sorted largest-to-smallest, which matches how they should be loaded
    private func largestFirstPlates(for target: Double, from sortedPlates: [Plate]) -> [Plate] {
        var remaining = target
        var plates: [Plate] = []
        
        for plate in sortedPlates {
            var available = plateInventory.map { $0[plate.weight] ?? 0 } ?? Int.max
            while remaining + 0.001 >= plate.weight && available > 0 {
                plates.append(plate)
                remaining -= plate.weight
                available -= 1
            }
        }
        return plates
    }
    
    /// The heaviest combination of inventory plates that doesn't exceed the target.
    /// Among equal weights, prefers fewer plates and then heavier ones.
    private func closestPlates(to target: Double, from sortedPlates: [Plate], inventory: [Double: Int]) -> [Plate] {
        // Whole hundredths avoid floating point drift in the sums
        let targetUnits = Int((target * 100).rounded(.down))
        let plateUnits = sortedPlates.map { Int(($0.weight * 100).rounded()) }
        
        // Reachable sum -> how many of each plate makes it
        var combinations: [Int: [Int]] = [0: Array(repeating: 0, count: sortedPlates.count)]
        
        for index in sortedPlates.indices {
            let stock = inventory[sortedPlates[index].weight] ?? 0
            guard stock > 0 else { continue }
            
            for (sum, counts) in combinations {
                for count in 1...stock {
                    let newSum = sum + count * plateUnits[index]
                    guard newSum <= targetUnits else { break }
                    
                    var newCounts = counts
                    newCounts[index] = count
                    if let existing = combinations[newSum], !isPreferred(newCounts, over: existing) {
                        continue
                    }
                    combinations[newSum] = newCounts
                }
            }
        }
        
        guard let bestSum = combinations.keys.max(), let best = combinations[bestSum] else { return [] }
        return sortedPlates.indices.flatMap { index in
            Array(repeating: sortedPlates[index], count: best[index])
        }
    }
    
    private func isPreferred(_ counts: [Int], over existing: [Int]) -> Bool {
        let total = counts.reduce(0, +)
        let existingTotal = existing.reduce(0, +)
        if total != existingTotal {
            return total < existingTotal
        }
        // Counts run heaviest-first, so a lexicographically larger array has heavier plates
        return existing.lexicographicallyPrecedes(counts)
    }
}

// MARK: - Barbell Visual View

struct BarbellView: View {
    let weight: Double
    let useMetric: Bool
    var barWeight: Double = 45
    var showLabels: Bool = true
    var compact: Bool = false
    var settings: AppSettings?
    
    private var calculator: PlateCalculator {
        if let settings = settings {
            return PlateCalculator(barWeight: barWeight, settings: settings)
        }
        return PlateCalculator(barWeight: barWeight, useMetric: useMetric)
    }
    
    private var result: PlateCalculatorResult {
        calculator.calculate(totalWeight: weight)
    }
    
    /// Smallest first: index 0 sits at the sleeve end, so the largest plates end up
    /// closest to the center of the bar
    private var loadedPlates: [Plate] {
        result.platesPerSide.sorted { $0.weight < $1.weight }
    }
    
    private let maxPlateHeight: CGFloat = 80
    private let plateWidth: CGFloat = 14
    private let plateSpacing: CGFloat = 2
    private let barHeight: CGFloat = 12
    private let sleeveHeight: CGFloat = 20
    private let collarWidth: CGFloat = 8
    
    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            // Barbell visualization
            barbellGraphic
            
            // Weight breakdown text
            if showLabels && !compact {
                weightBreakdown
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: loadedPlates.map(\.weight))
    }
    
    private var barbellGraphic: some View {
        GeometryReader { geo in
            let centerY = geo.size.height / 2
            let startX: CGFloat = 16
            let plates = loadedPlates
            let fittedWidth = fittedPlateWidth(containerWidth: geo.size.width, plateCount: plates.count)
            
            ZStack {
                // Bar (horizontal line through center)
                barGraphic(centerY: centerY, width: geo.size.width)
                
                // Left side plates
                platesGraphic(
                    centerY: centerY,
                    startX: startX,
                    plates: plates,
                    plateWidth: fittedWidth,
                    mirrored: false
                )
                
                // Right side plates (mirrored)
                platesGraphic(
                    centerY: centerY,
                    startX: geo.size.width - startX,
                    plates: plates,
                    plateWidth: fittedWidth,
                    mirrored: true
                )
            }
        }
        .frame(height: compact ? 60 : maxPlateHeight + 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        let unit = useMetric ? "kilograms" : "pounds"
        guard !loadedPlates.isEmpty else {
            return "Barbell with no plates"
        }
        let plates = result.platesPerSide.map(\.displayWeight).joined(separator: ", ")
        return "Barbell loaded per side with \(plates) \(unit)"
    }
    
    /// Plates narrow as needed so heavy loads meet in the middle instead of overlapping
    private func fittedPlateWidth(containerWidth: CGFloat, plateCount: Int) -> CGFloat {
        guard plateCount > 0 else { return plateWidth }
        let availablePerSide = containerWidth / 2 - 16 - collarWidth / 2 - 4
        return max(3, min(plateWidth, availablePerSide / CGFloat(plateCount) - plateSpacing))
    }
    
    private func barGraphic(centerY: CGFloat, width: CGFloat) -> some View {
        ZStack {
            // Main bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.75),
                            Color(white: 0.85),
                            Color(white: 0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width - 32, height: barHeight)
                .position(x: width / 2, y: centerY)
            
            // Knurling pattern (subtle texture in center)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.65).opacity(0.5))
                .frame(width: 60, height: barHeight - 2)
                .position(x: width / 2, y: centerY)
        }
    }
    
    private func platesGraphic(centerY: CGFloat, startX: CGFloat, plates: [Plate], plateWidth: CGFloat, mirrored: Bool) -> some View {
        // Left side (mirrored=false): plates go RIGHT (positive x) toward center, so direction = 1
        // Right side (mirrored=true): plates go LEFT (negative x) toward center, so direction = -1
        let direction: CGFloat = mirrored ? -1 : 1
        let baseX = startX + (direction * collarWidth / 2)
        
        return ZStack {
            // Collar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.5), Color(white: 0.65), Color(white: 0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: collarWidth, height: sleeveHeight)
                .position(x: startX, y: centerY)
            
            // Plates
            ForEach(Array(plates.enumerated()), id: \.offset) { index, plate in
                let plateHeight = plate.height * (compact ? maxPlateHeight * 0.7 : maxPlateHeight)
                let xPos = baseX + (direction * (plateWidth / 2 + plateSpacing + CGFloat(index) * (plateWidth + plateSpacing)))
                
                PlateView(
                    plate: plate,
                    height: plateHeight,
                    width: plateWidth,
                    showLabel: showLabels && !compact && plateWidth >= 12,
                    useMetric: useMetric
                )
                .position(x: xPos, y: centerY)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var weightBreakdown: some View {
        HStack(spacing: 16) {
            // Bar weight
            VStack(spacing: 2) {
                Text("Bar")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                Text(formatWeight(barWeight))
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            if calculator.collarWeight > 0 {
                Text("+")
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                
                VStack(spacing: 2) {
                    Text("Collars")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.textTertiaryFallback)
                    Text(formatWeight(calculator.collarWeight * 2))
                        .font(SBSFonts.captionBold())
                        .foregroundStyle(SBSColors.textSecondaryFallback)
                }
            }
            
            Text("+")
                .foregroundStyle(SBSColors.textTertiaryFallback)
            
            // Per side
            VStack(spacing: 2) {
                Text("Each side")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                Text(formatWeight(result.weightPerSide))
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Text("=")
                .foregroundStyle(SBSColors.textTertiaryFallback)
            
            // Total
            VStack(spacing: 2) {
                Text("Total")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                Text(formatWeight(weight))
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.accentFallback)
            }
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        // Weights are already in the display unit
        "\(weight.weightString()) \(useMetric ? "kg" : "lb")"
    }
}

// MARK: - Individual Plate View

struct PlateView: View {
    let plate: Plate
    let height: CGFloat
    let width: CGFloat
    var showLabel: Bool = true
    var useMetric: Bool = false
    
    var body: some View {
        ZStack {
            // Plate body with 3D effect
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [
                            plate.color.opacity(0.7),
                            plate.color,
                            plate.color.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 0)
            
            // Inner ring detail
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: width - 2, height: height - 4)
            
            // Weight label (rotated for vertical plates)
            if showLabel && height > 30 {
                Text(plate.displayWeight(useMetric: useMetric))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(plate.color.isLight ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

// MARK: - Plate Legend View

struct PlateLegendView: View {
    let useMetric: Bool
    var settings: AppSettings?
    
    private var plates: [Plate] {
        if let settings = settings {
            return StandardPlates.plates(with: settings, useMetric: useMetric)
        }
        return useMetric ? StandardPlates.metricPlates : StandardPlates.plates
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Plate Colors")
                    .font(SBSFonts.captionBold())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
                
                if let settings = settings, settings.useCustomPlateColors && StoreManager.shared.canAccess(.customPlateColors) {
                    Text("(Custom)")
                        .font(SBSFonts.caption())
                        .foregroundStyle(SBSColors.accentFallback)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(plates) { plate in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(plate.color)
                            .frame(width: 16, height: 24)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(plate.displayWeight(useMetric: useMetric))
                                .font(SBSFonts.caption())
                                .foregroundStyle(SBSColors.textPrimaryFallback)
                            
                            // Show count if using My Plates
                            if let settings = settings,
                               settings.useMyPlates && StoreManager.shared.canAccess(.myPlates) {
                                let count = settings.plateCount(for: plate.weight)
                                Text("×\(count)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(count > 0 ? SBSColors.textSecondaryFallback : SBSColors.error.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                .fill(SBSColors.surfaceFallback)
        )
    }
}

// MARK: - Compact Plate List (alternative display)

struct PlateListView: View {
    let weight: Double
    let barWeight: Double
    let useMetric: Bool
    
    private var result: PlateCalculatorResult {
        PlateCalculator(barWeight: barWeight, useMetric: useMetric)
            .calculate(totalWeight: weight)
    }
    
    var body: some View {
        if result.platesPerSide.isEmpty {
            Text("Bar only")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textSecondaryFallback)
        } else {
            // Group plates by weight, sorted largest first (closest to bar)
            let grouped = Dictionary(grouping: result.platesPerSide) { $0.weight }
            let sortedWeights = grouped.keys.sorted(by: >)  // Largest first
            
            HStack(spacing: 4) {
                Text("Load:")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textTertiaryFallback)
                
                ForEach(sortedWeights, id: \.self) { weight in
                    if let plates = grouped[weight], let plate = plates.first {
                        HStack(spacing: 2) {
                            if plates.count > 1 {
                                Text("\(plates.count)×")
                                    .font(SBSFonts.caption())
                                    .foregroundStyle(SBSColors.textSecondaryFallback)
                            }
                            
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(plate.color)
                                    .frame(width: 10, height: 10)
                                Text(plate.displayWeight(useMetric: useMetric))
                                    .font(SBSFonts.captionBold())
                                    .foregroundStyle(SBSColors.textPrimaryFallback)
                            }
                        }
                        
                        if weight != sortedWeights.last {
                            Text("+")
                                .font(SBSFonts.caption())
                                .foregroundStyle(SBSColors.textTertiaryFallback)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Barbell View") {
    VStack(spacing: 24) {
        Text("135 lb")
            .font(.headline)
        BarbellView(weight: 135, useMetric: false)
        
        Divider()
        
        Text("225 lb")
            .font(.headline)
        BarbellView(weight: 225, useMetric: false)
        
        Divider()
        
        Text("315 lb")
            .font(.headline)
        BarbellView(weight: 315, useMetric: false)
        
        Divider()
        
        Text("405 lb")
            .font(.headline)
        BarbellView(weight: 405, useMetric: false)
    }
    .padding()
    .sbsBackground()
}

#Preview("Compact") {
    VStack(spacing: 16) {
        BarbellView(weight: 185, useMetric: false, compact: true)
        BarbellView(weight: 225, useMetric: false, compact: true)
        BarbellView(weight: 275, useMetric: false, compact: true)
    }
    .padding()
    .sbsBackground()
}

#Preview("Plate List") {
    VStack(spacing: 16) {
        PlateListView(weight: 45, barWeight: 45, useMetric: false)
        PlateListView(weight: 135, barWeight: 45, useMetric: false)
        PlateListView(weight: 225, barWeight: 45, useMetric: false)
        PlateListView(weight: 315, barWeight: 45, useMetric: false)
    }
    .padding()
    .sbsBackground()
}

#Preview("Legend") {
    VStack(spacing: 24) {
        PlateLegendView(useMetric: false)
        PlateLegendView(useMetric: true)
    }
    .padding()
    .sbsBackground()
}

