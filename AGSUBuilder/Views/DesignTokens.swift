import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// Army gold used for primary text, buttons, and highlights.
    static let brandGold  = Color(hex: "#B8933A")
    /// Slightly deeper amber used for out-of-policy warning dots and secondary accents.
    static let brandAmber = Color(hex: "#C17A2A")
}

extension Color {
    /// Creates a `Color` from a CSS hex string (`#RGB`, `#RRGGBB`, or `#AARRGGBB`).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography

/// Factory for Barlow Condensed font instances at specific weights.
///
/// All text in the app should flow through `AppFont` so that swapping or
/// adjusting the typeface family requires changes in only one place.
/// Font files are registered via `UIAppFonts` in `Info.plist`.
struct AppFont {
    static func light(_ size: CGFloat)   -> Font { .custom("BarlowCondensed-Light",    size: size) }
    static func regular(_ size: CGFloat) -> Font { .custom("BarlowCondensed-Regular",  size: size) }
    static func semiBold(_ size: CGFloat)-> Font { .custom("BarlowCondensed-SemiBold", size: size) }
    static func bold(_ size: CGFloat)    -> Font { .custom("BarlowCondensed-Bold",      size: size) }
}

// MARK: - Type Scale

extension AppFont {
    /// Large screen-title used on `HomeView` (26 pt bold).
    static let screenTitle    = bold(26)
    /// Section-header labels inside lists and sheets (13 pt semibold).
    static let sectionHeader  = semiBold(13)
    /// Default body copy (16 pt regular).
    static let bodyPrimary    = regular(16)
    /// Secondary body copy, e.g. subtitles (15 pt light).
    static let bodySecondary  = light(15)
    /// Fine-print captions, e.g. regulation citation footer (12 pt light).
    static let caption        = light(12)
    /// Primary call-to-action button labels (16 pt bold).
    static let buttonLabel    = bold(16)
    /// Measurement values in the regulation sheet (14 pt semibold).
    static let measurement    = semiBold(14)
}

// MARK: - Spacing

/// Named spacing constants matching an 8-pt grid.
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius

/// Named corner-radius constants for `RoundedRectangle` and `.cornerRadius(_:)`.
struct Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}
