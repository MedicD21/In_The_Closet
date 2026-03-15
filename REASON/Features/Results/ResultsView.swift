import SwiftUI

struct ResultsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let analysis: SpaceAnalysis
    let project: SpaceProject
    let imageData: Data?
    @Binding var selectedBudgetTier: BudgetTier
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photoHeader
                summaryCard
                metricsCard
                planCard
                budgetPreviewCard
                actionsCard
            }
            .padding(.bottom, 30)
        }
    }

    private var photoHeader: some View {
        ZStack(alignment: .bottomLeading) {
            ProjectImageView(projectImage: project.images.last, imageData: imageData)
                .frame(height: 250)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                TagChip(title: project.mode.longLabel, accent: BrandColor.gold)
                Text(project.title)
                    .font(BrandTypography.screenTitle)
                    .foregroundStyle(Color.white)
                Text("Score \(analysis.score.totalScore)")
                    .font(BrandTypography.bodyStrong)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(20)
        }
    }

    private var summaryCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                ScoreChip(score: analysis.score.totalScore, title: "Space Score")
                Text(analysis.summaryText)
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                Text(analysis.supportiveCoachingText)
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                HStack {
                    TagChip(title: "\(analysis.estimatedResetMinutes) min reset", accent: BrandColor.teal)
                    TagChip(title: ScoreInterpreter.label(for: analysis.score.totalScore), accent: BrandColor.gold)
                }
                if !analysis.confidenceNotes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live service notes")
                            .font(BrandTypography.bodyStrong)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                        ForEach(analysis.confidenceNotes, id: \.self) { note in
                            bullet(note)
                        }
                    }
                }
            }
        }
    }

    private var metricsCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Score Breakdown", subtitle: "Clear, motivating categories instead of one vague grade")

                ForEach(analysis.score.metrics, id: \.id) { metric in
                    MetricBarView(title: metric.category.displayName, score: metric.score)
                }

                Divider()

                Text("Best opportunities")
                    .font(BrandTypography.bodyStrong)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))

                ForEach(analysis.bestOpportunities, id: \.self) { item in
                    bullet(item)
                }
            }
        }
    }

    private var planCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Reset Plan", subtitle: "Quick wins first, polish second")

                ForEach(analysis.resetPlan) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.order)")
                            .font(BrandTypography.bodyStrong)
                            .frame(width: 30, height: 30)
                            .background(BrandColor.gold.opacity(0.24))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.title)
                                .font(BrandTypography.bodyStrong)
                            Text(step.detail)
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                            Text(step.impactNote)
                                .font(BrandTypography.caption)
                                .foregroundStyle(BrandColor.teal)
                        }
                    }
                }
            }
        }
    }

    private var budgetPreviewCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Budget Options", subtitle: "Amazon-only links with affiliate-ready search URLs")

                if analysis.budgetRecommendations.isEmpty {
                    Text("Live shopping suggestions were not returned for this analysis.")
                        .font(BrandTypography.body)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                } else {
                    HStack {
                        ForEach(BudgetTier.allCases, id: \.id) { tier in
                            Button {
                                selectedBudgetTier = tier
                            } label: {
                                Text(tier.displayName)
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(selectedBudgetTier == tier ? Color.white : BrandColor.primaryText(for: colorScheme))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(selectedBudgetTier == tier ? BrandColor.teal : BrandColor.elevatedBackground(for: colorScheme))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let selectedTier = analysis.budgetRecommendations.first(where: { $0.budgetTier == selectedBudgetTier }) {
                    Text(selectedTier.whyItHelps)
                        .font(BrandTypography.body)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                    Text(selectedTier.estimatedTotalSpend.formatted(.currency(code: "USD")))
                        .font(BrandTypography.sectionTitle)
                        .foregroundStyle(BrandColor.primaryText(for: colorScheme))

                    ForEach(selectedTier.items.prefix(2)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemTitle)
                                .font(BrandTypography.bodyStrong)
                            Text(item.reasonText)
                                .font(BrandTypography.caption)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        }
                    }
                }

                if !analysis.budgetRecommendations.isEmpty {
                    NavigationLink {
                        BudgetTierSelectorView(analysis: analysis, selectedBudgetTier: $selectedBudgetTier)
                    } label: {
                        SecondaryActionLabel(title: "Choose Budget Tier")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionsCard: some View {
        BrandCard {
            VStack(spacing: 12) {
                if !analysis.budgetRecommendations.isEmpty {
                    NavigationLink {
                        ShoppingRecommendationsView(analysis: analysis, selectedBudgetTier: $selectedBudgetTier)
                    } label: {
                        PrimaryActionLabel(title: "View Shopping Tools", systemImage: "cart.fill")
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    VisualizationView(analysis: analysis, project: project, selectedBudgetTier: selectedBudgetTier)
                } label: {
                    SecondaryActionLabel(title: "See AI Concept Preview")
                }
                .buttonStyle(.plain)

                PrimaryActionButton("Save Project", systemImage: "bookmark.fill") {
                    onSave()
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(BrandColor.gold)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(BrandTypography.body)
                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
        }
    }
}

struct BudgetTierSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme

    let analysis: SpaceAnalysis
    @Binding var selectedBudgetTier: BudgetTier

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Budget Tier Selector", subtitle: "Choose the spend level that feels realistic right now")

                ForEach(analysis.budgetRecommendations) { recommendation in
                    Button {
                        selectedBudgetTier = recommendation.budgetTier
                    } label: {
                        BrandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(recommendation.budgetTier.displayName)
                                        .font(BrandTypography.sectionTitle)
                                    Spacer()
                                    if selectedBudgetTier == recommendation.budgetTier {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(BrandColor.teal)
                                    }
                                }
                                Text(recommendation.estimatedTotalSpend.formatted(.currency(code: "USD")))
                                    .font(BrandTypography.screenTitle)
                                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                                Text(recommendation.whyItHelps)
                                    .font(BrandTypography.body)
                                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                Text(recommendation.expectedImpactOnScore)
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(BrandColor.teal)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Budget Tiers")
    }
}

struct ShoppingRecommendationsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let analysis: SpaceAnalysis
    @Binding var selectedBudgetTier: BudgetTier

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Recommended Tools", subtitle: "Amazon-only suggestions grouped by the budget path you choose")

                if !analysis.budgetRecommendations.isEmpty {
                    Picker("Budget", selection: $selectedBudgetTier) {
                        ForEach(BudgetTier.allCases, id: \.id) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if analysis.budgetRecommendations.isEmpty {
                    BrandCard {
                        Text("Live shopping suggestions were not returned for this analysis.")
                            .font(BrandTypography.body)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                    }
                } else if let tier = analysis.budgetRecommendations.first(where: { $0.budgetTier == selectedBudgetTier }) {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(tier.whyItHelps)
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                            ForEach(tier.items) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(item.itemTitle)
                                            .font(BrandTypography.bodyStrong)
                                        Spacer()
                                        if let price = item.price {
                                            Text(price.formatted(.currency(code: "USD")))
                                                .font(BrandTypography.caption)
                                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                        }
                                    }
                                    Text(item.reasonText)
                                        .font(BrandTypography.body)
                                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                    Text(item.expectedImpact)
                                        .font(BrandTypography.caption)
                                        .foregroundStyle(BrandColor.teal)
                                    Link(destination: item.amazonURL) {
                                        Text("Open on Amazon")
                                            .font(BrandTypography.caption)
                                            .foregroundStyle(Color.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule(style: .continuous)
                                                    .fill(BrandColor.teal)
                                            )
                                    }
                                }
                                .padding(.vertical, 8)
                                if item.id != tier.items.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Shopping")
    }
}
