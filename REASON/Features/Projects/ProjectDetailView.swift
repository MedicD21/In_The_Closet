import SwiftUI

struct ProjectDetailView: View {
    let project: SpaceProject
    @ObservedObject var appModel: AppModel
    let onStartUpload: (UploadDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    private var latestAnalysis: SpaceAnalysis? { project.latestAnalysis }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    VStack(spacing: 16) {
                        if let analysis = latestAnalysis {
                            latestScoreCard(analysis: analysis)
                            metricsCard(analysis: analysis)
                            resetPlanCard(analysis: analysis)
                        } else {
                            noAnalysisCard
                        }
                        if project.analyses.count > 1 {
                            historyCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .safeAreaInset(edge: .bottom) { actionStrip }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            BrandColor.surfaceElevated
                .frame(height: 200)

            LinearGradient(
                colors: [BrandColor.background, .clear],
                startPoint: .bottom, endPoint: .center
            )
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 8) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Spaces")
                            .font(BrandTypography.label)
                    }
                    .foregroundColor(BrandColor.teal)
                }
                .padding(.bottom, 4)

                Text(project.title)
                    .font(BrandTypography.screenTitle)
                    .foregroundColor(BrandColor.textPrimary)
                HStack(spacing: 8) {
                    TagChip(title: project.spaceType.displayName, accent: BrandColor.textSecondary)
                    TagChip(title: project.mode.displayName, accent: BrandColor.teal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 200)
    }

    private func latestScoreCard(analysis: SpaceAnalysis) -> some View {
        RMSCard {
            VStack(spacing: 16) {
                ScoreChip(score: analysis.score.totalScore, title: "Latest Score")
                Text(analysis.summaryText)
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 8) {
                    TagChip(title: "~\(analysis.estimatedResetMinutes) min", accent: BrandColor.teal)
                    TagChip(title: scoreLabel(analysis.score.totalScore), accent: BrandColor.gold)
                }
            }
            .padding(20)
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case ..<40: return "Needs Work"
        case ..<70: return "In Progress"
        case ..<90: return "Looking Good"
        default:    return "Outstanding"
        }
    }

    private func metricsCard(analysis: SpaceAnalysis) -> some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Score Breakdown")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                    .padding(20)
                VStack(spacing: 14) {
                    ForEach(Array(analysis.score.metrics.enumerated()), id: \.offset) { i, metric in
                        MetricBar(label: metric.category.displayName, value: metric.score, index: i)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func resetPlanCard(analysis: SpaceAnalysis) -> some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Reset Plan")
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

    private var noAnalysisCard: some View {
        RMSCard {
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 36))
                    .foregroundColor(BrandColor.teal)
                Text("No analysis yet")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Text("Analyze this space to get your score and reset plan.")
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }

    private var historyCard: some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Score History")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                    .padding(20)

                ForEach(Array(project.analyses.reversed().prefix(5)), id: \.id) { analysis in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(analysis.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(BrandTypography.body)
                                .foregroundColor(BrandColor.textPrimary)
                            Text(analysis.summaryText)
                                .font(BrandTypography.micro)
                                .foregroundColor(BrandColor.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(analysis.score.totalScore)")
                            .font(BrandTypography.scoreSmall)
                            .foregroundColor(scoreColor(analysis.score.totalScore))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    Divider()
                        .background(BrandColor.divider)
                        .padding(.horizontal, 20)
                }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case ..<40: BrandColor.coral
        case ..<70: BrandColor.gold
        default: BrandColor.teal
        }
    }

    private var actionStrip: some View {
        VStack(spacing: 10) {
            PrimaryButton("New Analysis") {
                var draft = UploadDraft()
                draft.spaceType = project.spaceType
                draft.mode = .organize
                onStartUpload(draft)
            }
            SecondaryButton("Compare Progress", accent: BrandColor.gold) {
                var draft = UploadDraft()
                draft.spaceType = project.spaceType
                draft.mode = .compareProgress
                onStartUpload(draft)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(BrandColor.background)
    }
}
