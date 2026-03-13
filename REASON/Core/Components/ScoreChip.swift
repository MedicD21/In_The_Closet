import SwiftUI

struct ScoreChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let score: Int
    let title: String

    var body: some View {
        HStack(spacing: 12) {
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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
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
