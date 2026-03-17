import SwiftUI

struct ResultsView: View {
    let analysis: SpaceAnalysis
    let project: SpaceProject
    let imageData: Data?
    @Binding var selectedBudgetTier: BudgetTier
    let onSave: () -> Void

    @State private var metricsExpanded = true
    @State private var shoppingPath = false
    @State private var visualizationPath = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                photoHero
                VStack(spacing: 16) {
                    scoreCard
                    metricsAccordion
                    resetPlanCard
                    budgetPicker
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .safeAreaInset(edge: .bottom) { actionStrip }
        .background(BrandColor.background)
        .navigationDestination(isPresented: $shoppingPath) {
            ShoppingView(analysis: analysis, selectedBudgetTier: $selectedBudgetTier)
        }
        .navigationDestination(isPresented: $visualizationPath) {
            VisualizationView(analysis: analysis, project: project,
                              selectedBudgetTier: selectedBudgetTier)
        }
    }

    // MARK: — Photo hero
    private var photoHero: some View {
        ZStack(alignment: .bottom) {
            if let data = imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            } else {
                ProjectImageView(projectImage: project.images.first, imageData: nil)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            }
            LinearGradient(colors: [BrandColor.background, .clear],
                           startPoint: .bottom, endPoint: .center)
                .frame(height: 280)
        }
        .overlay(alignment: .topLeading) {
            TagChip(title: project.mode.displayName, accent: BrandColor.teal, variant: .filled)
                .padding(16)
        }
        .overlay(alignment: .bottomLeading) {
            HStack {
                Text(project.title)
                    .font(BrandTypography.screenTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Spacer()
                Text("\(analysis.score.totalScore)")
                    .font(BrandTypography.scoreSmall)
                    .foregroundColor(BrandColor.gold)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 280)
    }

    // MARK: — Score card
    private var scoreCard: some View {
        RMSCard {
            VStack(spacing: 16) {
                ScoreRing(score: analysis.score.totalScore, size: 120, lineWidth: 8,
                          subtitle: scoreInterpretation)
                Text(analysis.summaryText)
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text(analysis.supportiveCoachingText)
                    .font(BrandTypography.body.italic())
                    .foregroundColor(BrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    TagChip(title: "~\(analysis.estimatedResetMinutes) min", accent: BrandColor.teal)
                    TagChip(title: scoreInterpretation, accent: BrandColor.gold)
                }
            }
            .padding(20)
        }
    }

    private var scoreInterpretation: String {
        switch analysis.score.totalScore {
        case ..<40: return "Needs Work"
        case ..<70: return "In Progress"
        case ..<90: return "Looking Good"
        default:    return "Outstanding"
        }
    }

    // MARK: — Metrics accordion
    private var metricsAccordion: some View {
        RMSCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.4)) { metricsExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Score Breakdown")
                            .font(BrandTypography.sectionTitle)
                            .foregroundColor(BrandColor.textPrimary)
                        Spacer()
                        Image(systemName: metricsExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(BrandColor.textSecondary)
                    }
                    .padding(20)
                }

                if metricsExpanded {
                    VStack(spacing: 14) {
                        ForEach(analysis.score.metrics.indices, id: \.self) { i in
                            MetricBar(
                                label: analysis.score.metrics[i].category.displayName,
                                value: analysis.score.metrics[i].score,
                                index: i
                            )
                        }

                        if !analysis.bestOpportunities.isEmpty {
                            Divider()
                                .background(BrandColor.divider)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Best opportunities")
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundColor(BrandColor.textPrimary)
                                ForEach(analysis.bestOpportunities, id: \.self) { opp in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(BrandColor.teal)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 6)
                                        Text(opp)
                                            .font(BrandTypography.body)
                                            .foregroundColor(BrandColor.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: — Reset plan card
    private var resetPlanCard: some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Your Reset Plan")
                        .font(BrandTypography.sectionTitle)
                        .foregroundColor(BrandColor.textPrimary)
                    Spacer()
                    TagChip(title: "~\(analysis.estimatedResetMinutes) min", accent: BrandColor.teal)
                }
                .padding(20)

                ForEach(analysis.resetPlan.indices, id: \.self) { i in
                    let step = analysis.resetPlan[i]
                    VStack(spacing: 0) {
                        if i > 0 {
                            Divider()
                                .background(BrandColor.divider)
                                .padding(.horizontal, 20)
                        }
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(BrandColor.goldMuted)
                                    .frame(width: 32, height: 32)
                                Text("\(step.order)")
                                    .font(BrandTypography.label)
                                    .foregroundColor(BrandColor.gold)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundColor(BrandColor.textPrimary)
                                Text(step.detail)
                                    .font(BrandTypography.body)
                                    .foregroundColor(BrandColor.textSecondary)
                                Text(step.impactNote)
                                    .font(BrandTypography.label)
                                    .foregroundColor(BrandColor.teal)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                }
            }
        }
    }

    // MARK: — Budget picker
    private var budgetPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Options")
                .font(BrandTypography.sectionTitle)
                .foregroundColor(BrandColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(analysis.budgetRecommendations) { rec in
                        let isSelected = selectedBudgetTier == rec.budgetTier
                        Button { selectedBudgetTier = rec.budgetTier } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(rec.budgetTier.displayName)
                                    .font(BrandTypography.label)
                                    .foregroundColor(BrandColor.textSecondary)
                                Text(rec.estimatedTotalSpend.formatted(.currency(code: "USD")))
                                    .font(BrandTypography.screenTitle)
                                    .foregroundColor(BrandColor.textPrimary)
                                Text(rec.whyItHelps)
                                    .font(BrandTypography.body)
                                    .foregroundColor(BrandColor.textSecondary)
                                    .lineLimit(2)
                                TagChip(title: "\(rec.items.count) items", accent: BrandColor.textSecondary)
                            }
                            .padding(16)
                            .frame(width: 220, height: 160, alignment: .topLeading)
                            .background(isSelected ? BrandColor.surfaceElevated : BrandColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        isSelected ? BrandColor.teal : BrandColor.stroke,
                                        lineWidth: isSelected ? 1.5 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(BudgetCardPressStyle())
                    }
                }
                .padding(.horizontal, 16)
            }

            // Top 3 products preview for selected tier
            if let rec = analysis.budgetRecommendations.first(where: { $0.budgetTier == selectedBudgetTier }) {
                VStack(spacing: 10) {
                    ForEach(rec.items.prefix(3)) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.itemTitle)
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundColor(BrandColor.textPrimary)
                                Text(item.reasonText)
                                    .font(BrandTypography.body)
                                    .foregroundColor(BrandColor.textSecondary)
                            }
                            Spacer()
                            Link(destination: item.amazonURL) {
                                Text("Shop")
                                    .font(BrandTypography.label)
                                    .foregroundColor(BrandColor.textPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(height: 30)
                                    .background(BrandColor.teal)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    // MARK: — Action strip
    private var actionStrip: some View {
        VStack(spacing: 10) {
            PrimaryButton("Save Project", action: onSave)
            if !analysis.budgetRecommendations.isEmpty {
                SecondaryButton("View Shopping") { shoppingPath = true }
            }
            GhostButton(title: "See AI Concept") { visualizationPath = true }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(BrandColor.background)
    }
}
