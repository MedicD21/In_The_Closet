import SwiftUI

struct BrandCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content
    private let cornerRadius: CGFloat = 30

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BrandColor.surface(for: colorScheme), BrandColor.surfaceHighlight(for: colorScheme)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(BrandColor.cardStroke(for: colorScheme), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(colorScheme == .dark ? 0.06 : 0.32), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .allowsHitTesting(false)
                    }
                    .shadow(color: BrandColor.shadowColor(for: colorScheme), radius: 28, x: 0, y: 18)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.04), radius: 6, x: 0, y: 2)
            )
    }
}
