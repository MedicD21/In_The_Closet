import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("REASON")
                    .font(.system(size: 54, weight: .bold, design: .serif))
                    .foregroundStyle(colorScheme == .dark ? BrandColor.gold : BrandColor.teal)

                Text("Find your space again.")
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                Text("Staging + organizational support with a calmer plan forward.")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }

            Image("ResultsMockup")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 12)

            Spacer()
        }
        .padding(24)
    }
}
