import SwiftUI

struct ScoreChip: View {
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
                    .foregroundStyle(BrandColor.textPrimary)
                Text(scoreLabel)
                    .font(BrandTypography.label)
                    .foregroundStyle(BrandColor.textSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            scoreColor.opacity(0.20),
                            BrandColor.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(BrandColor.stroke, lineWidth: 1)
                )
        )
    }

    private var scoreColor: Color {
        switch score {
        case ..<40: BrandColor.coral
        case ..<60: BrandColor.gold
        case ..<75: BrandColor.tealMuted
        default: BrandColor.teal
        }
    }

    private var scoreLabel: String {
        ScoreInterpreter.label(for: score)
    }
}
