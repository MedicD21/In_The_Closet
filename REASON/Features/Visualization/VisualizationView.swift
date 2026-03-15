import SwiftUI

struct VisualizationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let analysis: SpaceAnalysis
    let project: SpaceProject
    let selectedBudgetTier: BudgetTier

    private var sourceProjectImage: ProjectImage? {
        project.images.last ?? project.images.first
    }

    private var selectedTier: BudgetRecommendation? {
        analysis.budgetRecommendations.first(where: { $0.budgetTier == selectedBudgetTier })
    }

    private var concept: VisualizationConcept {
        if let visualizationConcept = analysis.visualizationConcept {
            return visualizationConcept
        }

        let improvements = Array((analysis.bestOpportunities.isEmpty ? [
            "Cleaner surfaces",
            "Stronger storage zones",
            "More visual calm"
        ] : analysis.bestOpportunities).prefix(3))

        let remainingWork = Array((analysis.biggestProblems.isEmpty ? [
            "The system will still need quick weekly resets."
        ] : analysis.biggestProblems).prefix(2))

        return VisualizationConcept(
            projectedImprovedScore: min(100, analysis.score.totalScore + 16),
            promptSummary: "A calmer, more cohesive \(project.title.lowercased()) with stronger zoning, edited surfaces, and storage that is easier to maintain.",
            whatImproved: improvements,
            stillNeedsWork: remainingWork,
            conceptCaption: "Styled concept based on your current photo and recommended reset plan.",
            generatedImageURL: nil
        )
    }

    private var conceptHighlights: [String] {
        let highlights = concept.whatImproved.isEmpty ? analysis.bestOpportunities : concept.whatImproved
        let fallback = ["Clearer zones", "Calmer surfaces"]
        return Array((highlights.isEmpty ? fallback : highlights).prefix(2))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "AI Optimization Preview", subtitle: "Conceptual inspiration, not an exact remodel or dimensional rendering")
                comparisonSection
                summaryCard
                improvementsCard

                if let selectedTier {
                    itemsCard(for: selectedTier)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .navigationTitle("Concept Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var comparisonSection: some View {
        if horizontalSizeClass == .compact {
            VStack(spacing: 18) {
                previewPanel(title: "Current Photo") {
                    ProjectImageView(projectImage: sourceProjectImage)
                        .frame(height: 240)
                }

                previewPanel(title: "Concept Direction") {
                    ConceptPreviewImageView(
                        concept: concept,
                        projectImage: sourceProjectImage,
                        budgetTier: selectedBudgetTier,
                        highlights: conceptHighlights
                    )
                    .frame(height: 240)
                }
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                previewPanel(title: "Current Photo") {
                    ProjectImageView(projectImage: sourceProjectImage)
                        .frame(height: 220)
                }

                previewPanel(title: "Concept Direction") {
                    ConceptPreviewImageView(
                        concept: concept,
                        projectImage: sourceProjectImage,
                        budgetTier: selectedBudgetTier,
                        highlights: conceptHighlights
                    )
                    .frame(height: 220)
                }
            }
        }
    }

    private var summaryCard: some View {
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
    }

    private var improvementsCard: some View {
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

    private func itemsCard(for tier: BudgetRecommendation) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Items used in this concept", subtitle: tier.budgetTier.displayName)
                ForEach(tier.items.prefix(3)) { item in
                    Link(destination: item.amazonURL) {
                        HStack(alignment: .top, spacing: 12) {
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
                                .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }

    private func previewPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BrandTypography.caption)
                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ConceptPreviewImageView: View {
    let concept: VisualizationConcept
    let projectImage: ProjectImage?
    let budgetTier: BudgetTier
    let highlights: [String]

    private let cornerRadius: CGFloat = 26

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            artwork

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.14), Color.black.opacity(0.58)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                Label("Concept direction", systemImage: "sparkles")
                    .font(BrandTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.96))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.22), in: Capsule(style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(budgetTier.displayName)
                        .font(BrandTypography.bodyStrong)
                        .foregroundStyle(Color.white)
                    Text(concept.conceptCaption)
                        .font(BrandTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(2)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                    ForEach(highlights, id: \.self) { highlight in
                        Text(highlight.trimmingCharacters(in: CharacterSet(charactersIn: ". ")))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            if concept.generatedImageURL == nil {
                Text("Fallback Preview")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.2), in: Capsule(style: .continuous))
                    .padding(14)
            }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = concept.generatedImageURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    fallbackArtwork
                @unknown default:
                    fallbackArtwork
                }
            }
        } else {
            fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        ZStack {
            ProjectImageView(projectImage: projectImage)
                .saturation(0.8)
                .brightness(0.06)
                .contrast(1.03)

            LinearGradient(
                colors: [
                    BrandColor.softTeal.opacity(0.22),
                    Color.white.opacity(0.06),
                    BrandColor.gold.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(Color.white.opacity(0.05))
        }
    }
}
