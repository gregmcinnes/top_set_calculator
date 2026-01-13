import Foundation

// MARK: - Premium Features

/// Features that require a premium purchase
public enum PremiumFeature: String, CaseIterable {
    
    /// Custom plate colors
    case customPlateColors
    
    /// Configure available plates ("My Plates")
    case myPlates
    
    /// Extended plates (55 lb, 1.25 lb) and bar weights (55 lb, 30 lb)
    case extendedEquipment
    
    /// Display name for the feature
    public var displayName: String {
        switch self {
        case .customPlateColors:
            return "Custom Plate Colors"
        case .myPlates:
            return "My Plates"
        case .extendedEquipment:
            return "Extended Equipment"
        }
    }
    
    /// Description of the feature
    public var featureDescription: String {
        switch self {
        case .customPlateColors:
            return "Personalize your barbell visualization with custom colors"
        case .myPlates:
            return "Configure which plates you own for accurate loading calculations"
        case .extendedEquipment:
            return "Access 55 lb & 1.25 lb plates, plus specialty bar weights like 55 lb"
        }
    }
    
    /// SF Symbol icon for the feature
    public var iconName: String {
        switch self {
        case .customPlateColors:
            return "paintpalette.fill"
        case .myPlates:
            return "tray.full.fill"
        case .extendedEquipment:
            return "dumbbell.fill"
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

