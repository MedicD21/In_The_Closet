import SwiftUI

struct BrandCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(BrandColor.surface(for: colorScheme))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 20, x: 0, y: 12)
            )
    }
}
