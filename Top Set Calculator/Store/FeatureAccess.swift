import Foundation

// MARK: - Premium Features

/// Features that require a premium purchase. The paywall lists them in this order.
public enum PremiumFeature: String, CaseIterable, Identifiable {
    
    /// Warm-up sets with plate loads, ramping to a top set
    case warmups
    
    /// Saved maxes, PRs and progress charts
    case myLifts
    
    /// Saved equipment setups
    case gymProfiles
    
    /// Back-off sets from a top set
    case backoffSets
    
    /// Meet attempts and projected scores
    case meetPlanner
    
    /// Configure available plates ("My Plates")
    case myPlates
    
    /// Extended plates (55 lb, 1.25 lb, 0.5 kg), bar weights (55 lb, 30 lb, 25 kg, 12 kg),
    /// custom plate sizes, custom bars and collars
    case extendedEquipment
    
    /// Custom plate colors
    case customPlateColors
    
    public var id: String { rawValue }
    
    /// Display name for the feature
    public var displayName: String {
        switch self {
        case .warmups:
            return "Warm-up Generator"
        case .myLifts:
            return "My Lifts"
        case .gymProfiles:
            return "Gym Profiles"
        case .backoffSets:
            return "Back-off Sets"
        case .meetPlanner:
            return "Meet Planner"
        case .myPlates:
            return "My Plates"
        case .extendedEquipment:
            return "Extended Equipment"
        case .customPlateColors:
            return "Custom Plate Colors"
        }
    }
    
    /// Description of the feature
    public var featureDescription: String {
        switch self {
        case .warmups:
            return "Ramp up to any top set, with the plates to load for each set"
        case .myLifts:
            return "Save your maxes, catch PRs and chart your progress"
        case .gymProfiles:
            return "Switch between home, commercial and meet setups"
        case .backoffSets:
            return "Work out back-off weights from today's top set"
        case .meetPlanner:
            return "Plan attempts and see your projected total and scores"
        case .myPlates:
            return "Configure which plates you own for accurate loading calculations"
        case .extendedEquipment:
            return "Custom plate sizes, collars, custom bars, and 55 lb, 1.25 lb & 0.5 kg plates"
        case .customPlateColors:
            return "Personalize your barbell visualization with custom colors"
        }
    }
    
    /// SF Symbol icon for the feature
    public var iconName: String {
        switch self {
        case .warmups:
            return "flame.fill"
        case .myLifts:
            return "chart.line.uptrend.xyaxis"
        case .gymProfiles:
            return "building.2.fill"
        case .backoffSets:
            return "arrow.down.right"
        case .meetPlanner:
            return "flag.checkered"
        case .myPlates:
            return "tray.full.fill"
        case .extendedEquipment:
            return "dumbbell.fill"
        case .customPlateColors:
            return "paintpalette.fill"
        }
    }
}

// MARK: - Feature Access Extension

extension StoreManager {
    /// Check if a premium feature is accessible
    /// - Parameter feature: The feature to check
    /// - Returns: True if the user has access (premium purchased)
    public func canAccess(_ feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    /// Get the list of locked features for display
    /// - Returns: Array of premium features the user doesn't have access to
    public func lockedFeatures() -> [PremiumFeature] {
        if isPremium {
            return []
        }
        return PremiumFeature.allCases
    }
}

