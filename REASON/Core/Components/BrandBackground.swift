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
                .fill(BrandColor.gold.opacity(colorScheme == .dark ? 0.16 : 0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -150, y: -290)

            Circle()
                .fill(BrandColor.softTeal.opacity(colorScheme == .dark ? 0.2 : 0.24))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: 170, y: -220)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            BrandColor.teal.opacity(colorScheme == .dark ? 0.18 : 0.14),
                            BrandColor.coral.opacity(colorScheme == .dark ? 0.16 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 360, height: 260)
                .blur(radius: 110)
                .offset(x: -120, y: 320)

            RoundedRectangle(cornerRadius: 56, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.22))
                .frame(width: 340, height: 340)
                .blur(radius: 140)
                .offset(x: 150, y: 150)
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                BrandColor.background(for: colorScheme),
                BrandColor.deepBackground,
                BrandColor.darkAccent
            ]
        }

        return [BrandColor.warmWhite, Color.white, BrandColor.mist]
    }
}
