import SwiftUI

/// Appearance mode options
enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Simple settings model for the calculator app
@Observable
class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults
    
    /// Set while a gym profile is being applied, so its values aren't treated as user edits
    @ObservationIgnored private var isApplyingProfile = false
    
    /// Appearance mode (system, light, dark)
    var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    /// Whether to use metric (kg) or imperial (lb) units
    var useMetric: Bool {
        didSet {
            defaults.set(useMetric, forKey: "useMetric")
            guard useMetric != oldValue else { return }
            if !isApplyingProfile {
                barWeight = Self.barWeight(barWeight, convertedToMetric: useMetric)
            }
            saveActiveProfile()
        }
    }
    
    /// Default bar weight in the user's preferred unit system
    var barWeight: Double {
        didSet {
            defaults.set(barWeight, forKey: "barWeight")
            saveActiveProfile()
        }
    }
    
    /// Whether to use custom plate colors (premium feature)
    var useCustomPlateColors: Bool {
        didSet {
            defaults.set(useCustomPlateColors, forKey: "useCustomPlateColors")
        }
    }
    
    /// Custom colors for lb plates (hex strings by plate weight)
    var customPlateColors: [Double: String] {
        didSet {
            save(customPlateColors, forKey: "customPlateColors")
        }
    }
    
    /// Custom colors for kg plates (hex strings by plate weight)
    var customPlateColorsMetric: [Double: String] {
        didSet {
            save(customPlateColorsMetric, forKey: "customPlateColorsMetric")
        }
    }
    
    /// Whether to use only available plates (premium feature)
    var useMyPlates: Bool {
        didSet {
            defaults.set(useMyPlates, forKey: "useMyPlates")
            saveActiveProfile()
        }
    }
    
    /// Available lb plates and their quantities (plate weight -> count per side)
    var myPlates: [Double: Int] {
        didSet {
            save(myPlates, forKey: "myPlates")
            saveActiveProfile()
        }
    }
    
    /// Available kg plates and their quantities (plate weight -> count per side)
    var myPlatesMetric: [Double: Int] {
        didSet {
            save(myPlatesMetric, forKey: "myPlatesMetric")
            saveActiveProfile()
        }
    }
    
    /// Whether the plate calculator may use 55 lb plates when not limited by My Plates
    var use55LbPlates: Bool {
        didSet {
            defaults.set(use55LbPlates, forKey: "use55LbPlates")
            saveActiveProfile()
        }
    }
    
    /// User-defined lb plate sizes (premium feature)
    var customPlates: [Double] {
        didSet {
            defaults.set(customPlates, forKey: "customPlates")
            saveActiveProfile()
        }
    }
    
    /// User-defined kg plate sizes (premium feature)
    var customPlatesMetric: [Double] {
        didSet {
            defaults.set(customPlatesMetric, forKey: "customPlatesMetric")
            saveActiveProfile()
        }
    }
    
    /// Weight of one lb collar (premium feature)
    var collarWeightImperial: Double {
        didSet {
            defaults.set(collarWeightImperial, forKey: "collarWeightImperial")
            saveActiveProfile()
        }
    }
    
    /// Weight of one kg collar (premium feature)
    var collarWeightMetric: Double {
        didSet {
            defaults.set(collarWeightMetric, forKey: "collarWeightMetric")
            saveActiveProfile()
        }
    }
    
    /// Rounding step for suggested lb weights. Zero leaves them unrounded.
    var roundingIncrementImperial: Double {
        didSet {
            defaults.set(roundingIncrementImperial, forKey: "roundingIncrementImperial")
        }
    }
    
    /// Rounding step for suggested kg weights. Zero leaves them unrounded.
    var roundingIncrementMetric: Double {
        didSet {
            defaults.set(roundingIncrementMetric, forKey: "roundingIncrementMetric")
        }
    }
    
    /// Saved equipment setups (premium feature). Never empty after init.
    private(set) var gymProfiles: [GymProfile] {
        didSet {
            if let data = try? JSONEncoder().encode(gymProfiles) {
                defaults.set(data, forKey: "gymProfiles")
            }
        }
    }
    
    private(set) var activeGymProfileID: UUID? {
        didSet {
            defaults.set(activeGymProfileID?.uuidString, forKey: "activeGymProfileID")
        }
    }
    
    /// Whether the user has seen the onboarding flow
    var hasSeenOnboarding: Bool {
        didSet {
            defaults.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    /// Starting inventory. Premium plates (55 lb, 1.25 lb, 0.5 kg) start at zero.
    static let defaultImperialInventory: [Double: Int] = [55: 0, 45: 4, 35: 2, 25: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 0]
    static let defaultMetricInventory: [Double: Int] = [25: 4, 20: 4, 15: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 2, 0.5: 0]
    
    /// Record a completed calculation and potentially trigger a review request
    static func recordCalculationCompleted() {
        var count = UserDefaults.standard.integer(forKey: "calculationCount")
        count += 1
        UserDefaults.standard.set(count, forKey: "calculationCount")
        ReviewManager.requestReviewIfAppropriate(calculationCount: count)
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        let appearanceRawValue = defaults.integer(forKey: "appearanceMode")
        self.appearanceMode = AppearanceMode(rawValue: appearanceRawValue) ?? .system
        self.barWeight = defaults.double(forKey: "barWeight")
        self.useCustomPlateColors = defaults.bool(forKey: "useCustomPlateColors")
        self.useMyPlates = defaults.bool(forKey: "useMyPlates")
        self.use55LbPlates = defaults.bool(forKey: "use55LbPlates")
        self.customPlates = defaults.array(forKey: "customPlates") as? [Double] ?? []
        self.customPlatesMetric = defaults.array(forKey: "customPlatesMetric") as? [Double] ?? []
        self.collarWeightImperial = defaults.double(forKey: "collarWeightImperial")
        self.collarWeightMetric = defaults.double(forKey: "collarWeightMetric")
        self.roundingIncrementImperial = defaults.object(forKey: "roundingIncrementImperial") as? Double
            ?? WeightRounding.defaultIncrement(useMetric: false)
        self.roundingIncrementMetric = defaults.object(forKey: "roundingIncrementMetric") as? Double
            ?? WeightRounding.defaultIncrement(useMetric: true)
        let hasSeenOnboarding = defaults.bool(forKey: "hasSeenOnboarding")
        self.hasSeenOnboarding = hasSeenOnboarding
        
        // New installs start in the unit their region uses. Existing users keep their setting.
        let useMetric: Bool
        if defaults.object(forKey: "useMetric") == nil && !hasSeenOnboarding {
            useMetric = Locale.current.measurementSystem != .us
            defaults.set(useMetric, forKey: "useMetric")
        } else {
            useMetric = defaults.bool(forKey: "useMetric")
        }
        self.useMetric = useMetric
        
        // Colors and inventory used to share one dictionary across units. Anything saved
        // there by someone currently using kg belongs to the kg set on first load.
        let storedColors: [Double: String]? = Self.load(from: defaults, forKey: "customPlateColors")
        let storedPlates: [Double: Int]? = Self.load(from: defaults, forKey: "myPlates")
        
        self.customPlateColors = storedColors ?? [:]
        self.myPlates = storedPlates ?? Self.defaultImperialInventory
        
        if let metricColors: [Double: String] = Self.load(from: defaults, forKey: "customPlateColorsMetric") {
            self.customPlateColorsMetric = metricColors
        } else {
            self.customPlateColorsMetric = useMetric ? (storedColors ?? [:]) : [:]
        }
        
        if let metricPlates: [Double: Int] = Self.load(from: defaults, forKey: "myPlatesMetric") {
            self.myPlatesMetric = metricPlates
        } else if useMetric, let storedPlates {
            self.myPlatesMetric = Self.defaultMetricInventory.merging(storedPlates) { _, stored in stored }
        } else {
            self.myPlatesMetric = Self.defaultMetricInventory
        }
        
        if let data = defaults.data(forKey: "gymProfiles"),
           let profiles = try? JSONDecoder().decode([GymProfile].self, from: data) {
            self.gymProfiles = profiles
        } else {
            self.gymProfiles = []
        }
        self.activeGymProfileID = defaults.string(forKey: "activeGymProfileID").flatMap(UUID.init)
        
        // Set default bar weight if not previously set
        if self.barWeight == 0 {
            self.barWeight = useMetric ? 20 : 45
        }
        
        // Everyone starts with one profile holding their current setup
        if gymProfiles.isEmpty {
            let profile = currentSetup(named: "My Gym")
            gymProfiles = [profile]
            activeGymProfileID = profile.id
        }
    }
    
    /// The equivalent bar after a unit change: standard bars map to the matching bar in
    /// the other system, and custom bars convert numerically.
    static func barWeight(_ weight: Double, convertedToMetric toMetric: Bool) -> Double {
        let poundsToKilos: [Double: Double] = [55: 25, 45: 20, 35: 15, 30: 12, 25: 10, 15: 10]
        let kilosToPounds: [Double: Double] = [25: 55, 20: 45, 15: 35, 12: 25, 10: 25]
        
        if let standard = (toMetric ? poundsToKilos : kilosToPounds)[weight] {
            return standard
        }
        let converted = toMetric ? weight * 0.453592 : weight * 2.20462
        return max((converted * 2).rounded() / 2, 0.5)
    }
    
    // MARK: - Persistence
    
    /// Plist dictionaries need string keys, so plate weights are stored as strings.
    private func save<Value>(_ dictionary: [Double: Value], forKey key: String) {
        let stringKeyed = dictionary.reduce(into: [String: Value]()) { result, pair in
            result[String(pair.key)] = pair.value
        }
        defaults.set(stringKeyed, forKey: key)
    }
    
    private static func load<Value>(from defaults: UserDefaults, forKey key: String) -> [Double: Value]? {
        guard let stored = defaults.dictionary(forKey: key) as? [String: Value] else {
            return nil
        }
        return stored.reduce(into: [Double: Value]()) { result, pair in
            if let weight = Double(pair.key) {
                result[weight] = pair.value
            }
        }
    }
}

// MARK: - Plate Inventory

extension AppSettings {
    /// The plate inventory for the current unit system
    var activePlateInventory: [Double: Int] {
        useMetric ? myPlatesMetric : myPlates
    }
    
    func plateCount(for weight: Double) -> Int {
        activePlateInventory[weight] ?? 0
    }
    
    func setPlateCount(_ count: Int, for weight: Double) {
        if useMetric {
            myPlatesMetric[weight] = count
        } else {
            myPlates[weight] = count
        }
    }
    
    func resetPlateInventory() {
        if useMetric {
            myPlatesMetric = Self.defaultMetricInventory
        } else {
            myPlates = Self.defaultImperialInventory
        }
    }
}

// MARK: - Equipment

extension AppSettings {
    /// Weight of one collar in the current unit
    var collarWeight: Double {
        get { useMetric ? collarWeightMetric : collarWeightImperial }
        set {
            if useMetric {
                collarWeightMetric = newValue
            } else {
                collarWeightImperial = newValue
            }
        }
    }
    
    func customPlateWeights(useMetric: Bool) -> [Double] {
        useMetric ? customPlatesMetric : customPlates
    }
    
    /// Adds a user-defined plate size to the current unit, starting with one pair in the
    /// inventory. Returns false if that size already exists.
    @discardableResult
    func addCustomPlate(weight: Double) -> Bool {
        let standard = useMetric ? StandardPlates.allMetricPlates : StandardPlates.allImperialPlates
        let existing = standard.map(\.weight) + customPlateWeights(useMetric: useMetric)
        guard weight > 0, !existing.contains(weight) else { return false }
        
        if useMetric {
            customPlatesMetric.append(weight)
        } else {
            customPlates.append(weight)
        }
        setPlateCount(1, for: weight)
        return true
    }
    
    func removeCustomPlate(weight: Double) {
        if useMetric {
            customPlatesMetric.removeAll { $0 == weight }
            myPlatesMetric[weight] = nil
            customPlateColorsMetric[weight] = nil
        } else {
            customPlates.removeAll { $0 == weight }
            myPlates[weight] = nil
            customPlateColors[weight] = nil
        }
    }
}

// MARK: - Gym Profiles

/// One saved equipment setup
struct GymProfile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var useMetric: Bool
    var barWeight: Double
    var useMyPlates: Bool
    var use55LbPlates: Bool
    var myPlates: [Double: Int]
    var myPlatesMetric: [Double: Int]
    var customPlates: [Double]
    var customPlatesMetric: [Double]
    var collarWeightImperial: Double
    var collarWeightMetric: Double
}

extension AppSettings {
    var activeGymProfile: GymProfile? {
        gymProfiles.first { $0.id == activeGymProfileID }
    }
    
    fileprivate func currentSetup(named name: String, id: UUID = UUID()) -> GymProfile {
        GymProfile(
            id: id,
            name: name,
            useMetric: useMetric,
            barWeight: barWeight,
            useMyPlates: useMyPlates,
            use55LbPlates: use55LbPlates,
            myPlates: myPlates,
            myPlatesMetric: myPlatesMetric,
            customPlates: customPlates,
            customPlatesMetric: customPlatesMetric,
            collarWeightImperial: collarWeightImperial,
            collarWeightMetric: collarWeightMetric
        )
    }
    
    /// Keeps the active profile matching what the user has changed in Settings
    fileprivate func saveActiveProfile() {
        guard !isApplyingProfile,
              let index = gymProfiles.firstIndex(where: { $0.id == activeGymProfileID }) else { return }
        let updated = currentSetup(named: gymProfiles[index].name, id: gymProfiles[index].id)
        if gymProfiles[index] != updated {
            gymProfiles[index] = updated
        }
    }
    
    func selectGymProfile(id: UUID) {
        guard let profile = gymProfiles.first(where: { $0.id == id }) else { return }
        
        isApplyingProfile = true
        defer { isApplyingProfile = false }
        
        useMetric = profile.useMetric
        barWeight = profile.barWeight
        useMyPlates = profile.useMyPlates
        use55LbPlates = profile.use55LbPlates
        myPlates = profile.myPlates
        myPlatesMetric = profile.myPlatesMetric
        customPlates = profile.customPlates
        customPlatesMetric = profile.customPlatesMetric
        collarWeightImperial = profile.collarWeightImperial
        collarWeightMetric = profile.collarWeightMetric
        activeGymProfileID = id
    }
    
    /// Starts a new profile from the current setup and switches to it
    func addGymProfile(named name: String) {
        let profile = currentSetup(named: name)
        gymProfiles.append(profile)
        activeGymProfileID = profile.id
    }
    
    func renameGymProfile(id: UUID, to name: String) {
        guard let index = gymProfiles.firstIndex(where: { $0.id == id }) else { return }
        gymProfiles[index].name = name
    }
    
    /// Deletes a profile. The last one stays, since the current setup always belongs to one.
    func deleteGymProfile(id: UUID) {
        guard gymProfiles.count > 1 else { return }
        gymProfiles.removeAll { $0.id == id }
        if activeGymProfileID == id, let first = gymProfiles.first {
            selectGymProfile(id: first.id)
        }
    }
}

// MARK: - Rounding

extension AppSettings {
    var unitLabel: String {
        useMetric ? "kg" : "lb"
    }
    
    var roundingIncrement: Double {
        get { useMetric ? roundingIncrementMetric : roundingIncrementImperial }
        set {
            if useMetric {
                roundingIncrementMetric = newValue
            } else {
                roundingIncrementImperial = newValue
            }
        }
    }
    
    func rounded(_ weight: Double) -> Double {
        WeightRounding.round(weight, to: roundingIncrement)
    }
    
    /// A suggested training weight, rounded to the user's step: "265 lb"
    func loadString(_ weight: Double) -> String {
        "\(rounded(weight).weightString(maxFractionDigits: roundingIncrement > 0 ? 2 : 1)) \(unitLabel)"
    }
    
    /// The step the user's plates can actually move in, or nil with no plates
    var smallestLoadStep: Double? {
        StandardPlates.plates(with: self, useMetric: useMetric).map(\.weight).min().map { $0 * 2 }
    }
}

// MARK: - Color Helpers

extension AppSettings {
    /// Get the color for a plate weight, using custom color if enabled and available
    func plateColor(for weight: Double, defaultColor: Color) -> Color {
        let colors = useMetric ? customPlateColorsMetric : customPlateColors
        guard useCustomPlateColors,
              StoreManager.shared.canAccess(.customPlateColors),
              let hexString = colors[weight] else {
            return defaultColor
        }
        return Color(hex: hexString) ?? defaultColor
    }
    
    /// Set a custom color for a plate weight
    func setPlateColor(_ color: Color, for weight: Double) {
        if useMetric {
            customPlateColorsMetric[weight] = color.toHex()
        } else {
            customPlateColors[weight] = color.toHex()
        }
    }
    
    func resetPlateColors() {
        if useMetric {
            customPlateColorsMetric = [:]
        } else {
            customPlateColors = [:]
        }
    }
}

// MARK: - Color Hex Conversion

extension Color {
    /// Near-white plates need an outline to survive on the chalk background
    var needsPlateOutline: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        return 0.299 * r + 0.587 * g + 0.114 * b > 0.85
    }

    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        // getRed converts grayscale and wide-gamut colors, which have different
        // component layouts, into RGB.
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return "000000" }
        
        func channel(_ value: CGFloat) -> Int {
            Int((min(max(value, 0), 1) * 255).rounded())
        }
        return String(format: "%02X%02X%02X", channel(r), channel(g), channel(b))
    }
    
    /// Whether dark text reads better than white text on top of this color
    var isLight: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        return 0.299 * r + 0.587 * g + 0.114 * b > 0.7
    }
}
