import SwiftUI

struct MetricBarView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                Spacer()
                Text("\(score)")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(BrandColor.divider(for: colorScheme))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [BrandColor.teal, BrandColor.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 10)
        }
    }
}
