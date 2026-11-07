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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with classification
            headerSection
            
            // Lifts summary
            liftsSection
            
            // Footer with branding
            footerSection
        }
        .background(Color.surface)
        .signatureCard()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: SBSLayout.space2) {
            // Icon and title
            HStack(spacing: 8) {
                Text("Strength Standards")
                    .eyebrowStyle()
            }
            .foregroundStyle(Color.inkSecondary)
            .padding(.top, SBSLayout.space4)
            
            // Main percentile display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(Int(summary.overallPercentile.rounded()))")
                        .font(SBSFonts.workingWeight())
                        .foregroundStyle(Color.ink)
                    
                    Text("th")
                        .font(SBSFonts.numberUnit())
                        .foregroundStyle(Color.inkSecondary)
                }
                
                Text("Percentile")
                    .eyebrowStyle()
                    .foregroundStyle(Color.inkSecondary)
            }
            
            // Classification badge
            StatusBadge(text: summary.classification.name, color: summary.classification.color)
            
            Text("Among \(summary.isMale ? "male" : "female") gym-goers")
                .font(SBSFonts.caption())
                .foregroundStyle(Color.inkSecondary)
                .padding(.bottom, SBSLayout.space4)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Lifts Section
    
    private var liftsSection: some View {
        VStack(spacing: SBSLayout.space2) {
            Divider().overlay(Color.hairline)
            
            ForEach(summary.lifts) { lift in
                StrengthLiftRow(lift: lift, unit: summary.unit)
                
                if lift.id != summary.lifts.last?.id {
                    Divider().overlay(Color.hairline)
                }
            }
        }
        .padding(.horizontal, SBSLayout.space6)
        .padding(.vertical, SBSLayout.space4)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image("TopSetMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24)
                
                Text("Top Set Calculator")
                    .eyebrowStyle()
                    .foregroundStyle(Color.ink)
            }
            
            Spacer()
            
            Text("\(Int(summary.bodyweight)) \(summary.unit) BW")
                .font(SBSFonts.numberSmall())
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.horizontal, SBSLayout.space6)
        .padding(.vertical, SBSLayout.space4)
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
        HStack(spacing: SBSLayout.space4) {
            // Lift name and weight
            VStack(alignment: .leading, spacing: 2) {
                Text(lift.name)
                    .font(SBSFonts.bodyStrong())
                    .foregroundStyle(Color.ink)
                
                Text("\(Int(lift.weight)) \(unit)")
                    .font(SBSFonts.numberSmall())
                    .foregroundStyle(Color.inkSecondary)
            }
            
            Spacer()
            
            // Percentile and classification
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(lift.percentile.rounded()))th")
                    .font(SBSFonts.number())
                    .foregroundStyle(Color.ink)
                
                Text(classification.name)
                    .eyebrowStyle()
                    .foregroundStyle(classification.color)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shareable Strength Card Wrapper

struct ShareableStrengthCard: View {
    let summary: StrengthSummary
    
    var body: some View {
        StrengthShareCard(summary: summary)
            .frame(width: 360)
            .padding(.horizontal, SBSLayout.space6)
            .padding(.top, SBSLayout.space6)
            .padding(.bottom, SBSLayout.space6)
            .background(Color.bg)
            // Shared cards are always Iron, whatever the app's appearance
            .environment(\.colorScheme, .dark)
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

