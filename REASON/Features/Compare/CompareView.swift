import SwiftUI

struct CompareView: View {
    @Environment(\.colorScheme) private var colorScheme

    let beforeAnalysis: SpaceAnalysis
    let afterAnalysis: SpaceAnalysis
    let comparison: ProjectComparison
    let project: SpaceProject
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    scoreCard(title: "Before", score: beforeAnalysis.score.totalScore, accent: BrandColor.gold)
                    scoreCard(title: "After", score: afterAnalysis.score.totalScore, accent: BrandColor.teal)
                }

                BrandCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(comparison.scoreDelta >= 0 ? "+\(comparison.scoreDelta) point improvement" : "\(comparison.scoreDelta) point change")
                            .font(BrandTypography.screenTitle)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                        Text(comparison.summaryText)
                            .font(BrandTypography.body)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                    }
                }

                BrandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "What improved", subtitle: "Category-by-category movement")
                        ForEach(comparison.metricDeltas) { delta in
                            HStack {
                                Text(delta.category.displayName)
                                    .font(BrandTypography.bodyStrong)
                                Spacer()
                                Text("\(delta.beforeScore) -> \(delta.afterScore)")
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                Text(delta.delta >= 0 ? "+\(delta.delta)" : "\(delta.delta)")
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(delta.delta >= 0 ? BrandColor.teal : BrandColor.coral)
                            }
                        }
                    }
                }

                BrandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Next best actions", subtitle: nil)
                        ForEach(afterAnalysis.resetPlan.prefix(3)) { step in
                            Text("\(step.order). \(step.title)")
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        }

                        PrimaryActionButton("Save Progress", systemImage: "sparkles") {
                            onSave()
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    private func scoreCard(title: String, score: Int, accent: Color) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                Text("\(score)")
                    .font(BrandTypography.score)
                    .foregroundStyle(accent)
                Text(ScoreInterpreter.label(for: score))
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            }
        }
    }
}

struct ResetTrackingConfirmationView: View {
    let projectTitle: String
    let delta: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            BrandCard {
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(BrandColor.gold)
                    Text("Progress Saved")
                        .font(BrandTypography.screenTitle)
                    Text(projectTitle)
                        .font(BrandTypography.bodyStrong)
                    Text(delta >= 0 ? "Your score moved up by \(delta) points." : "Your latest comparison has been saved.")
                        .font(BrandTypography.body)
                        .multilineTextAlignment(.center)
                }
            }

            PrimaryActionButton("Back to Projects") {
                onDone()
            }

            Spacer()
        }
    }
}
