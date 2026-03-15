import SwiftUI

enum BrandColor {
    // Inspired by the RMS brand board: deep blue-green, warm sand, and bright orange.
    static let deepBackground = Color(hex: "#0A2D36")
    static let darkAccent = Color(hex: "#133B46")
    static let teal = Color(hex: "#377F8F")
    static let softTeal = Color(hex: "#9EBEC3")
    static let mist = Color(hex: "#EAE9E3")
    static let warmWhite = Color(hex: "#F7F3EC")
    static let cardLight = Color(hex: "#FEFCF8")
    static let cardDark = Color(hex: "#15323B")
    static let gold = Color(hex: "#DEC187")
    static let coral = Color(hex: "#E36A3E")
    static let plum = Color(hex: "#7C3157")
    static let textPrimaryLight = Color(hex: "#183844")
    static let textPrimaryDark = Color(hex: "#F3ECDF")
    static let textSecondaryLight = Color(hex: "#6D7C82")
    static let textSecondaryDark = Color(hex: "#C9C8C1")

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#09262E") : warmWhite
    }

    static func elevatedBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.82)
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardDark : cardLight
    }

    static func secondarySurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#102A33") : Color(hex: "#F6F2EB")
    }

    static func surfaceHighlight(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#1A404C") : Color(hex: "#F2EEE7")
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimaryDark : textPrimaryLight
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondaryDark : textSecondaryLight
    }

    static func divider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07)
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    static func shadowColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.34) : Color(hex: "#355160").opacity(0.12)
    }

    static func primaryGradient(for scheme: ColorScheme) -> [Color] {
        if scheme == .dark {
            return [Color(hex: "#4690A1"), teal, Color(hex: "#1E5C6A")]
        }

        return [Color(hex: "#4A93A4"), teal, Color(hex: "#285E6D")]
    }

    static func tabBarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#0E2830").opacity(0.94) : Color.white.opacity(0.94)
    }
}
