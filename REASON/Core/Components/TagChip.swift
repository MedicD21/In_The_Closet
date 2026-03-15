import SwiftUI

struct TagChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var accent: Color = BrandColor.gold

    var body: some View {
        Text(title)
            .font(BrandTypography.caption)
            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(colorScheme == .dark ? 0.18 : 0.14))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(accent.opacity(colorScheme == .dark ? 0.26 : 0.18), lineWidth: 1)
                    )
            )
    }
}
