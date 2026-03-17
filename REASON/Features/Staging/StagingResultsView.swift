import SwiftUI

struct StagingResultsView: View {
    let analysis: SpaceAnalysis
    let project: SpaceProject
    @Binding var selectedBudgetTier: BudgetTier
    let visualizationService: VisualizationService
    let onSave: () -> Void

    @State private var shoppingPath = false
    @State private var visualizationPath = false
    @State private var checklistStates: [UUID: Bool] = [:]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                readinessCard
                if let advice = analysis.stagingAdvice {
                    stagingActionsCard(advice: advice)
                    if !advice.showingDayChecklist.isEmpty {
                        showingDayCard(checklist: advice.showingDayChecklist)
                    }
                    if !advice.quickWins.isEmpty {
                        quickWinsCard(wins: advice.quickWins)
                    }
                }
                budgetSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) { actionStrip }
        .background(BrandColor.background)
        .navigationDestination(isPresented: $shoppingPath) {
            ShoppingView(analysis: analysis, selectedBudgetTier: $selectedBudgetTier)
        }
        .navigationDestination(isPresented: $visualizationPath) {
            VisualizationView(analysis: analysis, project: project,
                              visualizationService: visualizationService)
        }
    }

    private var readinessCard: some View {
        RMSCard {
            VStack(spacing: 16) {
                let score = analysis.stagingAdvice?.readinessScore ?? analysis.score.totalScore
                ScoreRing(score: score, size: 120, lineWidth: 8,
                          subtitle: readinessLabel(score))
                Text("Staging Readiness")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                HStack(spacing: 8) {
                    TagChip(title: readinessLabel(score), accent: BrandColor.gold)
                    TagChip(title: "~\(analysis.estimatedResetMinutes) min", accent: BrandColor.teal)
                }
            }
            .padding(20)
        }
    }

    private func readinessLabel(_ score: Int) -> String {
        switch score {
        case ..<40: return "Not Ready"
        case ..<60: return "Getting There"
        case ..<80: return "Almost Ready"
        default:    return "Show-Ready"
        }
    }

    private func stagingActionsCard(advice: StagingAdvice) -> some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Staging Actions")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                    .padding(20)

                if !advice.removeItems.isEmpty {
                    actionGroup(title: "Remove", items: advice.removeItems, accent: BrandColor.coral)
                    Divider().background(BrandColor.divider).padding(.horizontal, 20)
                }
                if !advice.hideItems.isEmpty {
                    actionGroup(title: "Hide", items: advice.hideItems, accent: BrandColor.gold)
                    Divider().background(BrandColor.divider).padding(.horizontal, 20)
                }
                if !advice.addItems.isEmpty {
                    actionGroup(title: "Add", items: advice.addItems, accent: BrandColor.teal)
                        .padding(.bottom, 4)
                }
            }
        }
    }

    private func actionGroup(title: String, items: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(BrandTypography.label)
                .foregroundColor(accent)
                .padding(.horizontal, 20)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(accent)
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textSecondary)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
    }

    private func showingDayCard(checklist: [ChecklistItem]) -> some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Showing Day Checklist")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                    .padding(20)

                ForEach(checklist) { item in
                    let checked = checklistStates[item.id] ?? item.isDone
                    Button {
                        checklistStates[item.id] = !checked
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(checked ? BrandColor.teal : BrandColor.textTertiary)
                            Text(item.title)
                                .font(BrandTypography.body)
                                .foregroundColor(checked ? BrandColor.textSecondary : BrandColor.textPrimary)
                                .strikethrough(checked)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickWinsCard(wins: [String]) -> some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Wins")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                ForEach(wins, id: \.self) { win in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(BrandColor.gold)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        Text(win)
                            .font(BrandTypography.body)
                            .foregroundColor(BrandColor.textSecondary)
                    }
                }
            }
            .padding(20)
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Staging Budget")
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
        }
    }

    private var actionStrip: some View {
        VStack(spacing: 10) {
            PrimaryButton("Save & Continue", action: onSave)
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
