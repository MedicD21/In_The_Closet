import SwiftUI

struct VisualizationView: View {
    @Environment(\.colorScheme) private var colorScheme

    let analysis: SpaceAnalysis
    let project: SpaceProject
    let selectedBudgetTier: BudgetTier

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "AI Optimization Preview", subtitle: "Conceptual inspiration, not an exact remodel or dimensional rendering")

                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Before")
                            .font(BrandTypography.caption)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        ProjectImageView(projectImage: project.images.first)
                            .frame(height: 220)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Concept")
                            .font(BrandTypography.caption)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        ReferenceImageView(assetName: "ResultsMockup", bundleFileName: "results-mockup", fileExtension: "png")
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                }

                if let concept = analysis.visualizationConcept {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            ScoreChip(score: concept.projectedImprovedScore, title: "Projected Score")
                            Text(concept.conceptCaption)
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                            Text(concept.promptSummary)
                                .font(BrandTypography.caption)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        }
                    }

                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "What improved", subtitle: nil)
                            ForEach(concept.whatImproved, id: \.self) { item in
                                bullet(item, accent: BrandColor.teal)
                            }
                            Divider()
                            SectionHeader(title: "Still needs work", subtitle: nil)
                            ForEach(concept.stillNeedsWork, id: \.self) { item in
                                bullet(item, accent: BrandColor.coral)
                            }
                        }
                    }
                }

                if let tier = analysis.budgetRecommendations.first(where: { $0.budgetTier == selectedBudgetTier }) {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Items used in this concept", subtitle: tier.budgetTier.displayName)
                            ForEach(tier.items.prefix(3)) { item in
                                Link(destination: item.amazonURL) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.itemTitle)
                                                .font(BrandTypography.bodyStrong)
                                            Text(item.reasonText)
                                                .font(BrandTypography.caption)
                                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(BrandColor.teal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.top, 4)
        .navigationTitle("Concept Preview")
    }

    private func bullet(_ text: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(BrandTypography.body)
                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
        }
    }
}
