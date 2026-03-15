import SwiftUI

struct ScoreChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let score: Int
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Text("\(score)")
                .font(BrandTypography.score)
                .foregroundStyle(scoreColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BrandTypography.sectionTitle)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                Text(scoreLabel)
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            scoreColor.opacity(colorScheme == .dark ? 0.24 : 0.14),
                            BrandColor.secondarySurface(for: colorScheme)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(BrandColor.cardStroke(for: colorScheme), lineWidth: 1)
                )
        )
    }

    private var scoreColor: Color {
        switch score {
        case ..<40: BrandColor.coral
        case ..<60: BrandColor.gold
        case ..<75: BrandColor.softTeal
        default: BrandColor.teal
        }
    }

    private var scoreLabel: String {
        ScoreInterpreter.label(for: score)
    }
}
