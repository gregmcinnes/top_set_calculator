import SwiftUI
import CoreText

// Top Set design system: Chalk (light) and Iron (dark).
//
// Colour tokens live in Assets.xcassets/Colors and arrive through generated asset symbols:
// Color.bg, .surface, .surfaceRaised, .ink, .inkSecondary, .inkTertiary, .hairline, .rule,
// .orangeFill, .orangeInk, .orangeText, .orangeSoft, .success, .warning, .danger, .knurl, .bar.
//
// The `orange` token is named `orangeFill` because `Color.orange` is SwiftUI's own colour and
// using it by mistake would compile silently. Never write a bare `.orange` in a view.
//
// The 2px rule and hard shadow are rationed: `.signatureCard()` on one result per screen,
// `SBSPrimaryButtonStyle`, nothing else.

// MARK: - Plate Colours

/// Competition colours. Plates are physical objects, so they're the same in both themes.
enum PlateColor {
    static let red = Color(red: 0xd9 / 255, green: 0x33 / 255, blue: 0x33 / 255)
    static let blue = Color(red: 0x2b / 255, green: 0x63 / 255, blue: 0xe0 / 255)
    static let yellow = Color(red: 0xe6 / 255, green: 0xbf / 255, blue: 0x1a / 255)
    static let green = Color(red: 0x2a / 255, green: 0x9d / 255, blue: 0x4b / 255)
    static let white = Color(red: 0xf5 / 255, green: 0xf5 / 255, blue: 0xf5 / 255)
    static let silver = Color(red: 0x99 / 255, green: 0x99 / 255, blue: 0xa6 / 255)
}

// MARK: - Fonts

enum BrandFonts {
    private static let files = [
        "Archivo-Regular", "Archivo-Medium", "Archivo-SemiBold", "Archivo-Bold", "Archivo-ExtraBold",
        "Archivo-Black", "ArchivoSemiCondensed-Bold",
        "BarlowCondensed-Bold",
        "IBMPlexMono-Medium", "IBMPlexMono-SemiBold", "IBMPlexMono-Bold"
    ]

    /// Fonts are registered in code because the target generates its Info.plist, which has no
    /// build-setting key for UIAppFonts. Call once, before anything is drawn.
    static func register() {
        for file in files {
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(file)")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

enum SBSFonts {
    // Numerals: the two that get read from the floor
    static func workingWeight() -> Font { .custom("BarlowCondensed-Bold", size: 68, relativeTo: .largeTitle) }
    static func timer() -> Font { .custom("BarlowCondensed-Bold", size: 56, relativeTo: .largeTitle) }

    // Display
    static func titleLarge() -> Font { .custom("Archivo-Black", size: 34, relativeTo: .largeTitle) }
    static func title() -> Font { .custom("Archivo-ExtraBold", size: 24, relativeTo: .title2) }
    static func heading() -> Font { .custom("Archivo-Bold", size: 20, relativeTo: .title3) }
    static func body() -> Font { .custom("Archivo-Regular", size: 17, relativeTo: .body) }
    static func bodyStrong() -> Font { .custom("Archivo-SemiBold", size: 17, relativeTo: .body) }
    static func caption() -> Font { .custom("Archivo-Medium", size: 13, relativeTo: .footnote) }
    static func eyebrow() -> Font { .custom("ArchivoSemiCondensed-Bold", size: 11, relativeTo: .caption2) }
    static func button() -> Font { .custom("Archivo-ExtraBold", size: 15, relativeTo: .body) }

    // Data: every other number
    static func numberLarge() -> Font { .custom("IBMPlexMono-Bold", size: 28, relativeTo: .title2).monospacedDigit() }
    static func number() -> Font { .custom("IBMPlexMono-SemiBold", size: 20, relativeTo: .title3).monospacedDigit() }
    static func numberSmall() -> Font { .custom("IBMPlexMono-Medium", size: 13, relativeTo: .footnote).monospacedDigit() }
    static func numberUnit() -> Font { .custom("IBMPlexMono-SemiBold", size: 16, relativeTo: .callout).monospacedDigit() }
    /// Labels on plates and chart landmarks, where nothing larger fits
    static func numberTiny() -> Font { .custom("IBMPlexMono-SemiBold", size: 9, relativeTo: .caption2).monospacedDigit() }
}

extension View {
    /// Uppercase label above a value: font, tracking and case travel together.
    func eyebrowStyle() -> some View {
        font(SBSFonts.eyebrow())
            .tracking(1.1)
            .textCase(.uppercase)
    }

    func titleLargeStyle() -> some View {
        font(SBSFonts.titleLarge())
            .tracking(-0.34)
            .textCase(.uppercase)
    }

    func buttonTextStyle() -> some View {
        font(SBSFonts.button())
            .tracking(1.2)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - Hero Number

enum HeroNumberStyle {
    /// A weight the lifter is about to load
    case workingWeight
    /// Any other calculator result
    case result

    var font: Font { self == .workingWeight ? SBSFonts.workingWeight() : SBSFonts.timer() }
}

/// The one big number on a screen. A trailing unit ("335 lb") is split off and set in
/// `number-unit` beside it, on the baseline.
struct HeroNumber: View {
    let value: String
    var style: HeroNumberStyle = .result

    private var parts: (number: String, unit: String?) {
        guard let space = value.lastIndex(of: " ") else { return (value, nil) }
        let unit = String(value[value.index(after: space)...])
        guard unit.allSatisfy(\.isLetter) else { return (value, nil) }
        return (String(value[..<space]), unit)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: SBSLayout.space1) {
            Text(parts.number)
                .font(style.font)
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            if let unit = parts.unit {
                Text(unit)
                    .font(SBSFonts.numberUnit())
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value)
    }
}

// MARK: - Spacing & Layout

enum SBSLayout {
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32

    static let radiusNone: CGFloat = 0
    static let radiusSm: CGFloat = 2
    static let radiusMd: CGFloat = 4

    static let strokeRule: CGFloat = 2
    static let strokeHairline: CGFloat = 1

    /// Minimum height of a button
    static let buttonHeight: CGFloat = 48
}

// MARK: - Surfaces

extension View {
    /// Hard offset in ink, no blur. Only the signature card and the primary button.
    func hardShadow() -> some View {
        background(Rectangle().fill(Color.rule).offset(x: 4, y: 4))
    }

    /// The default card: `surface`, `radius-sm`, hairline edge, no shadow.
    func card() -> some View {
        background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(Color.hairline, lineWidth: SBSLayout.strokeHairline)
            )
    }

    /// The one signature surface on a screen: square corners, 2px rule, hard shadow.
    func signatureCard() -> some View {
        background(Color.surface)
            .overlay(Rectangle().strokeBorder(Color.rule, lineWidth: SBSLayout.strokeRule))
            .hardShadow()
    }

    /// Anything sitting on a card: fields, chips, tiles.
    func field() -> some View {
        background(Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(Color.hairline, lineWidth: SBSLayout.strokeHairline)
            )
    }

    func sbsBackground() -> some View {
        background(Color.bg.ignoresSafeArea())
    }

    /// The selected state shared by chips and tiles: `orange-soft` with a 1pt `rule` edge, the
    /// same treatment as the current cell in a set grid.
    func chipBackground(isSelected: Bool) -> some View {
        background(isSelected ? Color.orangeSoft : Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(isSelected ? Color.rule : Color.hairline, lineWidth: SBSLayout.strokeHairline)
            )
    }
}

/// Diagonal knurl stripe: 1px lines at 135°, 6pt pitch. Texture, never meaning.
struct KnurlStripe: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 6 * 2.squareRoot()
            }
            context.stroke(path, with: .color(.knurl), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

/// A section title with the knurl stripe running out to the gutter
struct KnurlSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: SBSLayout.space3) {
            Text(title)
                .font(SBSFonts.title())
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            KnurlStripe()
                .frame(height: 12)
        }
    }
}

// MARK: - Screen Title

/// `title-large` at the top of a screen's content. It lives in the scroll view rather than the
/// navigation bar because UIKit's large titles truncate where this wraps, and most of the app's
/// names are too long for one line at this width.
struct ScreenTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .titleLargeStyle()
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SBSLayout.space4)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Pair with a `ScreenTitle` in the content. The title still names the navigation bar, for
    /// back buttons and accessibility, but isn't drawn twice.
    func screenNavigation(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityHidden(true)
                }
            }
    }
}

// MARK: - UIKit Appearance

enum BrandAppearance {
    /// Styles the UIKit chrome SwiftUI doesn't reach. Call once, after `BrandFonts.register()`.
    static func apply() {
        let bar = UINavigationBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(Color.bg)
        bar.shadowColor = .clear
        bar.titleTextAttributes = [
            .font: UIFont(name: "Archivo-ExtraBold", size: 17) ?? .boldSystemFont(ofSize: 17),
            .foregroundColor: UIColor(Color.ink)
        ]
        let plainButton = UIBarButtonItemAppearance()
        plainButton.normal.titleTextAttributes = [
            .font: UIFont(name: "Archivo-SemiBold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        ]
        bar.buttonAppearance = plainButton
        bar.backButtonAppearance = plainButton
        bar.doneButtonAppearance = plainButton
        UINavigationBar.appearance().standardAppearance = bar
        UINavigationBar.appearance().scrollEdgeAppearance = bar
        UINavigationBar.appearance().compactAppearance = bar
        UINavigationBar.appearance().tintColor = UIColor(Color.orangeText)

        let segment = UISegmentedControl.appearance()
        segment.selectedSegmentTintColor = UIColor(Color.orangeSoft)
        segment.backgroundColor = UIColor(Color.surfaceRaised)
        let font = UIFont(name: "Archivo-SemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        segment.setTitleTextAttributes([.font: font, .foregroundColor: UIColor(Color.inkSecondary)], for: .normal)
        segment.setTitleTextAttributes([.font: font, .foregroundColor: UIColor(Color.ink)], for: .selected)
    }
}

// MARK: - Button Styles

struct SBSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .buttonTextStyle()
            .frame(maxWidth: .infinity, minHeight: SBSLayout.buttonHeight)
            .padding(.horizontal, SBSLayout.space4)

        return Group {
            if isEnabled {
                label
                    .foregroundStyle(Color.orangeInk)
                    .background(Color.orangeFill)
                    .overlay(Rectangle().strokeBorder(Color.rule, lineWidth: SBSLayout.strokeRule))
                    .background(
                        // Pressed, the button sits down onto its shadow
                        Rectangle()
                            .fill(Color.rule)
                            .offset(x: configuration.isPressed ? 0 : 4, y: configuration.isPressed ? 0 : 4)
                    )
                    .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            } else {
                label
                    .foregroundStyle(Color.inkTertiary)
                    .background(Color.surface)
                    .overlay(Rectangle().strokeBorder(Color.hairline, lineWidth: SBSLayout.strokeHairline))
            }
        }
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SBSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonTextStyle()
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: SBSLayout.buttonHeight)
            .padding(.horizontal, SBSLayout.space4)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(Color.hairline, lineWidth: SBSLayout.strokeHairline)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SBSDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonTextStyle()
            .foregroundStyle(Color.danger)
            .frame(maxWidth: .infinity, minHeight: SBSLayout.buttonHeight)
            .padding(.horizontal, SBSLayout.space4)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: SBSLayout.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: SBSLayout.radiusSm)
                    .strokeBorder(Color.danger, lineWidth: SBSLayout.strokeHairline)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Square toggle: `surface-raised` with an `ink` knob off, `orange` with an `orange-ink` knob on.
struct SBSToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: SBSLayout.space3)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Rectangle()
                        .fill(configuration.isOn ? Color.orangeFill : Color.surfaceRaised)
                        .overlay(
                            Rectangle().strokeBorder(
                                configuration.isOn ? Color.rule : Color.hairline,
                                lineWidth: SBSLayout.strokeHairline
                            )
                        )
                    Rectangle()
                        .fill(configuration.isOn ? Color.orangeInk : Color.ink)
                        .frame(width: 18, height: 18)
                        .padding(3)
                }
                .frame(width: 46, height: 26)
                .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
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
