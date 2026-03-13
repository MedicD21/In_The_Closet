import SwiftUI

enum BrandColor {
    static let deepBackground = Color(hex: "#052D37")
    static let darkAccent = Color(hex: "#141E20")
    static let teal = Color(hex: "#3B859F")
    static let softTeal = Color(hex: "#7FA9B8")
    static let mist = Color(hex: "#EDE8E2")
    static let warmWhite = Color(hex: "#F8F5F1")
    static let cardLight = Color(hex: "#FFFDFC")
    static let cardDark = Color(hex: "#123B46")
    static let gold = Color(hex: "#E5C58F")
    static let coral = Color(hex: "#E55C3E")
    static let plum = Color(hex: "#94286F")
    static let textPrimaryLight = Color(hex: "#294A57")
    static let textPrimaryDark = Color(hex: "#F4EBD8")
    static let textSecondaryLight = Color(hex: "#6F7E85")
    static let textSecondaryDark = Color(hex: "#D1C5B6")

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? deepBackground : warmWhite
    }

    static func elevatedBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkAccent.opacity(0.92) : Color.white.opacity(0.88)
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardDark : cardLight
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimaryDark : textPrimaryLight
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondaryDark : textSecondaryLight
    }

    static func divider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
}
