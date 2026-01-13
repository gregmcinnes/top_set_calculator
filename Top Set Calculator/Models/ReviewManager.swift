import StoreKit

/// Handles App Store review request logic
enum ReviewManager {
    /// Minimum number of calculations before we ask for a review
    private static let minimumCalculations = 5
    
    /// Request a review if conditions are appropriate
    /// - Parameter calculationCount: The number of calculations the user has completed
    static func requestReviewIfAppropriate(calculationCount: Int) {
        // Only request after the user has done enough calculations to find value
        guard calculationCount >= minimumCalculations else { return }
        
        // Only trigger on specific milestones to avoid being annoying
        // iOS will further limit this to ~3 times per year
        let milestones = [5, 15, 50, 100]
        guard milestones.contains(calculationCount) else { return }
        
        requestReview()
    }
    
    /// Request a review using the system prompt
    private static func requestReview() {
        // Get the current window scene
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
}

