import SwiftUI

struct BrandBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(BrandColor.gold.opacity(colorScheme == .dark ? 0.12 : 0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 150, y: -280)

            Circle()
                .fill(BrandColor.softTeal.opacity(colorScheme == .dark ? 0.2 : 0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: -160, y: 260)

            Circle()
                .fill(BrandColor.plum.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: -120, y: -160)
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [BrandColor.deepBackground, BrandColor.darkAccent, Color(hex: "#0D4553")]
        }

        return [BrandColor.warmWhite, Color.white, BrandColor.mist]
    }
}
