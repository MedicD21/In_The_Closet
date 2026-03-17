import SwiftUI

struct RMSCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(BrandColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(BrandColor.stroke, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 4)
    }
}
