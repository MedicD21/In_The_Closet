import SwiftUI

struct BrandPrimaryButtonChrome: View {
    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: BrandColor.primaryGradient(for: colorScheme),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(BrandColor.coral.opacity(colorScheme == .dark ? 0.24 : 0.18))
                    .frame(width: 90, height: 90)
                    .blur(radius: 28)
                    .offset(x: 16, y: -24)
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: BrandColor.teal.opacity(colorScheme == .dark ? 0.24 : 0.18), radius: 22, x: 0, y: 12)
    }
}

struct BrandSecondaryButtonChrome: View {
    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(BrandColor.elevatedBackground(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(BrandColor.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.05), radius: 16, x: 0, y: 8)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
}

struct SecondaryActionButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandTypography.button)
                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(BrandSecondaryButtonChrome())
        }
        .buttonStyle(.plain)
    }
}
