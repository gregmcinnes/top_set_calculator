import SwiftUI

// MARK: - Color Theme

enum SBSColors {
    // Fallback colors (used throughout since we don't have asset catalog colors)
    static let backgroundFallback = Color(light: .init(white: 0.96), dark: .init(white: 0.08))
    static let surfaceFallback = Color(light: .white, dark: .init(white: 0.12))
    /// For fields, chips and tiles sitting on top of a surface
    static let surfaceElevatedFallback = Color(light: .init(white: 0.95), dark: .init(white: 0.16))
    static let accentFallback = Color(light: .init(red: 0.95, green: 0.5, blue: 0.2), dark: .init(red: 1.0, green: 0.6, blue: 0.3))
    static let accentSecondaryFallback = Color(light: .init(red: 0.2, green: 0.4, blue: 0.8), dark: .init(red: 0.4, green: 0.6, blue: 1.0))
    static let textPrimaryFallback = Color(light: .init(white: 0.1), dark: .init(white: 0.95))
    static let textSecondaryFallback = Color(light: .init(white: 0.4), dark: .init(white: 0.6))
    static let textTertiaryFallback = Color(light: .init(white: 0.6), dark: .init(white: 0.4))
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}

// MARK: - Typography

enum SBSFonts {
    // Large titles
    static func largeTitle() -> Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }
    
    // Section headers
    static func title() -> Font {
        .system(.title2, design: .rounded, weight: .bold)
    }
    
    static func title2() -> Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }
    
    static func title3() -> Font {
        .system(.title3, design: .rounded, weight: .semibold)
    }
    
    // Body text
    static func body() -> Font {
        .system(.body)
    }
    
    static func bodyBold() -> Font {
        .system(.body, weight: .semibold)
    }
    
    // Weight/number display - monospaced for alignment
    static func weight() -> Font {
        .system(.title2, design: .monospaced, weight: .bold)
    }
    
    static func weightLarge() -> Font {
        .system(.largeTitle, design: .monospaced, weight: .bold)
    }
    
    static func number() -> Font {
        .system(.title3, design: .monospaced, weight: .semibold)
    }
    
    // Small text
    static func caption() -> Font {
        .system(.footnote, weight: .medium)
    }
    
    static func captionBold() -> Font {
        .system(.footnote, weight: .semibold)
    }
    
    // Button text
    static func button() -> Font {
        .system(.body, design: .rounded, weight: .semibold)
    }
}

/// A big rounded result number that follows Dynamic Type but shrinks to stay on one line
private struct HeroNumberFont: ViewModifier {
    let size: CGFloat
    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size * scale, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}

extension View {
    func heroNumberFont(size: CGFloat = 48) -> some View {
        modifier(HeroNumberFont(size: size))
    }
}

// MARK: - Spacing & Layout

enum SBSLayout {
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32
    
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    
    static let cardSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
}

// MARK: - View Extensions

extension View {
    func sbsCard() -> some View {
        self
            .background(SBSColors.surfaceFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.1), radius: SBSLayout.shadowRadius, x: 0, y: SBSLayout.shadowY)
    }
    
    func sbsCardElevated() -> some View {
        self
            .background(SBSColors.surfaceElevatedFallback)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.15), radius: SBSLayout.shadowRadius, x: 0, y: SBSLayout.shadowY)
    }
    
    func sbsBackground() -> some View {
        self
            .background(SBSColors.backgroundFallback.ignoresSafeArea())
    }
}

// MARK: - Button Styles

struct SBSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBSFonts.button())
            .foregroundStyle(.white)
            .padding(.horizontal, SBSLayout.paddingLarge)
            .padding(.vertical, SBSLayout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .fill(isEnabled ? SBSColors.accentFallback : SBSColors.textTertiaryFallback)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SBSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBSFonts.button())
            .foregroundStyle(SBSColors.accentFallback)
            .padding(.horizontal, SBSLayout.paddingLarge)
            .padding(.vertical, SBSLayout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusMedium)
                    .strokeBorder(SBSColors.accentFallback, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SBSNumberPadButtonStyle: ButtonStyle {
    let isHighlighted: Bool
    
    init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBSFonts.number())
            .foregroundStyle(isHighlighted ? .white : SBSColors.textPrimaryFallback)
            .frame(width: 64, height: 64)
            .background(
                RoundedRectangle(cornerRadius: SBSLayout.cornerRadiusSmall)
                    .fill(isHighlighted ? SBSColors.accentFallback : SBSColors.surfaceFallback)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Color Extension for Light/Dark

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Weight Formatting

extension Double {
    /// Formats a weight without unit conversion: "135", "102.5", "1.25".
    /// Trailing zeros are dropped and the decimal separator follows the locale.
    func weightString(maxFractionDigits: Int = 2, locale: Locale = .autoupdatingCurrent) -> String {
        formatted(
            .number
                .precision(.fractionLength(0...maxFractionDigits))
                .grouping(.never)
                .locale(locale)
        )
    }
}

// MARK: - Keyboard

extension View {
    /// Adds a Done button above the keyboard. Number pads have no return key, so
    /// without this the only way to dismiss them is to scroll.
    func keyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }
}
