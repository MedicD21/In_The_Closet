import SwiftUI

struct TagChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var accent: Color = BrandColor.gold

    var body: some View {
        Text(title)
            .font(BrandTypography.caption)
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(colorScheme == .dark ? 0.16 : 0.15))
            )
    }
}
