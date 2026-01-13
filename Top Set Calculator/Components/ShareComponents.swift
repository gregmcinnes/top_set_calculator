import SwiftUI

// MARK: - Strength Standards Summary Data

/// Summary of strength standards for sharing
struct StrengthSummary: Equatable {
    let overallPercentile: Double
    let lifts: [LiftStandard]
    let bodyweight: Double
    let isMale: Bool
    let useMetric: Bool
    
    struct LiftStandard: Equatable, Identifiable {
        let id = UUID()
        let name: String
        let weight: Double
        let percentile: Double
    }
    
    var classification: StrengthStandards.Classification {
        StrengthStandards.classification(for: overallPercentile)
    }
    
    var unit: String {
        useMetric ? "kg" : "lb"
    }
}

// MARK: - Strength Share Card View

struct StrengthShareCard: View {
    let summary: StrengthSummary
    
    private var isElite: Bool {
        summary.overallPercentile >= 90
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with classification
            headerSection
            
            // Lifts summary
            liftsSection
            
            // Footer with branding
            footerSection
        }
        .background(SBSColors.backgroundFallback)
        .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusLarge)
                .strokeBorder(
                    LinearGradient(
                        colors: [summary.classification.color.opacity(0.6), summary.classification.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isElite ? 2 : 1
                )
        )
        .shadow(color: isElite ? summary.classification.color.opacity(0.3) : Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            // Icon and title
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("STRENGTH STANDARDS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(2)
            }
            .foregroundStyle(summary.classification.color)
            .padding(.top, SBSLayout.paddingMedium)
            
            // Main percentile display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(Int(summary.overallPercentile.rounded()))")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(summary.classification.color)
                    
                    Text("th")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(summary.classification.color.opacity(0.8))
                }
                
                Text("PERCENTILE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            // Classification badge
            Text(summary.classification.name.uppercased())
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(summary.classification.color)
                )
            
            Text("Among \(summary.isMale ? "male" : "female") gym-goers")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
                .padding(.bottom, SBSLayout.paddingMedium)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [summary.classification.color.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Lifts Section
    
    private var liftsSection: some View {
        VStack(spacing: SBSLayout.paddingSmall) {
            Divider()
                .background(SBSColors.textTertiaryFallback.opacity(0.2))
            
            ForEach(summary.lifts) { lift in
                StrengthLiftRow(lift: lift, unit: summary.unit)
                
                if lift.id != summary.lifts.last?.id {
                    Divider()
                        .background(SBSColors.textTertiaryFallback.opacity(0.15))
                }
            }
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
        .padding(.vertical, SBSLayout.paddingMedium)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SBSColors.accentFallback)
                
                Text("Strength Calculator")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Spacer()
            
            Text("\(Int(summary.bodyweight)) \(summary.unit) BW")
                .font(SBSFonts.caption())
                .foregroundStyle(SBSColors.textTertiaryFallback)
        }
        .padding(.horizontal, SBSLayout.paddingLarge)
        .padding(.vertical, SBSLayout.paddingMedium)
        .background(SBSColors.surfaceFallback.opacity(0.5))
    }
}

// MARK: - Strength Lift Row

private struct StrengthLiftRow: View {
    let lift: StrengthSummary.LiftStandard
    let unit: String
    
    private var classification: StrengthStandards.Classification {
        StrengthStandards.classification(for: lift.percentile)
    }
    
    var body: some View {
        HStack(spacing: SBSLayout.paddingMedium) {
            // Lift name and weight
            VStack(alignment: .leading, spacing: 2) {
                Text(lift.name)
                    .font(SBSFonts.bodyBold())
                    .foregroundStyle(SBSColors.textPrimaryFallback)
                
                Text("\(Int(lift.weight)) \(unit)")
                    .font(SBSFonts.caption())
                    .foregroundStyle(SBSColors.textSecondaryFallback)
            }
            
            Spacer()
            
            // Percentile and classification
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(lift.percentile.rounded()))th")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(classification.color)
                
                Text(classification.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(classification.color.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shareable Strength Card Wrapper

struct ShareableStrengthCard: View {
    let summary: StrengthSummary
    
    // Extra padding to account for shadow (radius + y offset)
    private let shadowPadding: CGFloat = 28
    
    var body: some View {
        StrengthShareCard(summary: summary)
            .frame(width: 360)
            .padding(.horizontal, SBSLayout.paddingLarge)
            .padding(.top, SBSLayout.paddingLarge)
            .padding(.bottom, SBSLayout.paddingLarge + shadowPadding)
            .background(
                ZStack {
                    Color(light: .init(white: 0.95), dark: .init(white: 0.05))
                    
                    GeometryReader { geo in
                        Path { path in
                            let spacing: CGFloat = 20
                            for x in stride(from: 0, to: geo.size.width, by: spacing) {
                                for y in stride(from: 0, to: geo.size.height, by: spacing) {
                                    path.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                                }
                            }
                        }
                        .fill(Color.white.opacity(0.03))
                    }
                }
            )
    }
}

// MARK: - View Snapshot Extension

extension View {
    @MainActor
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view!
        
        // Calculate the size needed
        let targetSize = controller.sizeThatFits(in: CGSize(width: 400, height: CGFloat.greatestFiniteMagnitude))
        
        // Set up the view hierarchy
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear
        
        // Force multiple layout passes to ensure everything is rendered
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Add to a window temporarily for proper rendering
        let window = UIWindow(frame: view.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        
        // Force another layout pass
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Run the render loop to process any pending updates
        RunLoop.current.run(until: Date())
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Clean up
        window.isHidden = true
        
        return image
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("Strength Card - Advanced") {
    ScrollView {
        StrengthShareCard(
            summary: StrengthSummary(
                overallPercentile: 78,
                lifts: [
                    .init(name: "Squat", weight: 315, percentile: 82),
                    .init(name: "Bench Press", weight: 225, percentile: 75),
                    .init(name: "Deadlift", weight: 405, percentile: 85),
                    .init(name: "OHP", weight: 135, percentile: 70)
                ],
                bodyweight: 180,
                isMale: true,
                useMetric: false
            )
        )
        .padding()
    }
    .sbsBackground()
}

#Preview("Strength Card - Elite") {
    ScrollView {
        StrengthShareCard(
            summary: StrengthSummary(
                overallPercentile: 95,
                lifts: [
                    .init(name: "Squat", weight: 500, percentile: 97),
                    .init(name: "Bench Press", weight: 365, percentile: 95),
                    .init(name: "Deadlift", weight: 600, percentile: 98)
                ],
                bodyweight: 200,
                isMale: true,
                useMetric: false
            )
        )
        .padding()
    }
    .sbsBackground()
}

