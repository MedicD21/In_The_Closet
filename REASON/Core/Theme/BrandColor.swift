import SwiftUI

enum BrandColor {
    // MARK: — Backgrounds
    static let background       = Color(hex: "#09141A")
    static let surface          = Color(hex: "#0F2029")
    static let surfaceElevated  = Color(hex: "#162C38")

    // MARK: — Accents
    static let teal             = Color(hex: "#3D8C9E")
    static let tealMuted        = Color(hex: "#1E4F5C")
    static let gold             = Color(hex: "#DEC187")
    static let goldMuted        = Color(hex: "#3B3020")
    static let coral            = Color(hex: "#E36A3E")

    // MARK: — Text
    static let textPrimary      = Color(hex: "#F0E8DB")
    static let textSecondary    = Color(hex: "#8A9BA3")
    static let textTertiary     = Color(hex: "#4A6470")

    // MARK: — UI
    static let stroke            = Color.white.opacity(0.07)
    static let divider           = Color.white.opacity(0.05)
    static let overlay           = BrandColor.background.opacity(0.72)
}

// MARK: — Hex initializer
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
