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
    /// Appearance mode (system, light, dark)
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    /// Whether to use metric (kg) or imperial (lb) units
    var useMetric: Bool {
        didSet {
            UserDefaults.standard.set(useMetric, forKey: "useMetric")
        }
    }
    
    /// Default bar weight in the user's preferred unit system
    var barWeight: Double {
        didSet {
            UserDefaults.standard.set(barWeight, forKey: "barWeight")
        }
    }
    
    /// Whether to use custom plate colors (premium feature)
    var useCustomPlateColors: Bool {
        didSet {
            UserDefaults.standard.set(useCustomPlateColors, forKey: "useCustomPlateColors")
        }
    }
    
    /// Custom plate colors (stored as hex strings by weight in lbs)
    var customPlateColors: [Double: String] {
        didSet {
            // Convert to a storable format
            let stringDict = customPlateColors.reduce(into: [String: String]()) { result, pair in
                result[String(pair.key)] = pair.value
            }
            UserDefaults.standard.set(stringDict, forKey: "customPlateColors")
        }
    }
    
    /// Whether to use only available plates (premium feature)
    var useMyPlates: Bool {
        didSet {
            UserDefaults.standard.set(useMyPlates, forKey: "useMyPlates")
        }
    }
    
    /// Available plates and their quantities (weight in lbs -> count per side)
    var myPlates: [Double: Int] {
        didSet {
            // Convert to a storable format
            let stringDict = myPlates.reduce(into: [String: Int]()) { result, pair in
                result[String(pair.key)] = pair.value
            }
            UserDefaults.standard.set(stringDict, forKey: "myPlates")
        }
    }
    
    /// Whether the user has seen the onboarding flow
    var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    /// Number of calculations the user has completed (for review prompt timing)
    var calculationCount: Int {
        didSet {
            UserDefaults.standard.set(calculationCount, forKey: "calculationCount")
        }
    }
    
    /// Increment calculation count and potentially trigger review request
    func recordCalculation() {
        calculationCount += 1
        ReviewManager.requestReviewIfAppropriate(calculationCount: calculationCount)
    }
    
    /// Static method to record a calculation without needing an AppSettings instance
    static func recordCalculationCompleted() {
        var count = UserDefaults.standard.integer(forKey: "calculationCount")
        count += 1
        UserDefaults.standard.set(count, forKey: "calculationCount")
        ReviewManager.requestReviewIfAppropriate(calculationCount: count)
    }
    
    init() {
        let appearanceRawValue = UserDefaults.standard.integer(forKey: "appearanceMode")
        self.appearanceMode = AppearanceMode(rawValue: appearanceRawValue) ?? .system
        self.useMetric = UserDefaults.standard.bool(forKey: "useMetric")
        self.barWeight = UserDefaults.standard.double(forKey: "barWeight")
        self.useCustomPlateColors = UserDefaults.standard.bool(forKey: "useCustomPlateColors")
        self.useMyPlates = UserDefaults.standard.bool(forKey: "useMyPlates")
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.calculationCount = UserDefaults.standard.integer(forKey: "calculationCount")
        
        // Load custom plate colors
        if let colorDict = UserDefaults.standard.dictionary(forKey: "customPlateColors") as? [String: String] {
            self.customPlateColors = colorDict.reduce(into: [Double: String]()) { result, pair in
                if let weight = Double(pair.key) {
                    result[weight] = pair.value
                }
            }
        } else {
            self.customPlateColors = [:]
        }
        
        // Load my plates
        if let platesDict = UserDefaults.standard.dictionary(forKey: "myPlates") as? [String: Int] {
            self.myPlates = platesDict.reduce(into: [Double: Int]()) { result, pair in
                if let weight = Double(pair.key) {
                    result[weight] = pair.value
                }
            }
        } else {
            // Default: assume user has standard plates (2 of each per side)
            // Includes premium plates (55 lb, 1.25 lb) with 0 count by default
            self.myPlates = [55: 0, 45: 4, 35: 2, 25: 2, 10: 2, 5: 2, 2.5: 2, 1.25: 0]
        }
        
        // Set default bar weight if not previously set
        if self.barWeight == 0 {
            self.barWeight = self.useMetric ? 20 : 45
        }
    }
}

// MARK: - Color Helpers

extension AppSettings {
    /// Get the color for a plate weight, using custom color if enabled and available
    func plateColor(for weight: Double, defaultColor: Color) -> Color {
        guard useCustomPlateColors,
              StoreManager.shared.canAccess(.customPlateColors),
              let hexString = customPlateColors[weight] else {
            return defaultColor
        }
        return Color(hex: hexString) ?? defaultColor
    }
    
    /// Set a custom color for a plate weight
    func setPlateColor(_ color: Color, for weight: Double) {
        customPlateColors[weight] = color.toHex()
    }
}

// MARK: - Color Hex Conversion

extension Color {
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
        guard let components = UIColor(self).cgColor.components else { return "000000" }
        
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

