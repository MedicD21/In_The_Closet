import SwiftUI

struct PrimaryActionLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.headline)
            }
            Text(title)
                .font(BrandTypography.button)
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(BrandPrimaryButtonChrome())
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct SecondaryActionLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String

    var body: some View {
        Text(title)
            .font(BrandTypography.button)
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BrandSecondaryButtonChrome())
    }
}
