import SwiftUI

struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BrandTypography.sectionTitle)
                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            if let subtitle {
                Text(subtitle)
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
