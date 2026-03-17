import SwiftUI

struct CompareView: View {
    let beforeAnalysis: SpaceAnalysis
    let afterAnalysis: SpaceAnalysis
    let comparison: ProjectComparison
    let project: SpaceProject
    let onSave: () -> Void

    @State private var dividerPosition: CGFloat = 0.5
    @State private var isDragging = false

    private var delta: Int { comparison.scoreDelta }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                deltaHero
                splitPreview
                metricsComparison
                insightsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) { actionStrip }
        .background(BrandColor.background)
    }

    private var deltaHero: some View {
        RMSCard {
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(beforeAnalysis.score.totalScore)")
                            .font(BrandTypography.score)
                            .foregroundColor(BrandColor.textSecondary)
                        Text("Before")
                            .font(BrandTypography.label)
                            .foregroundColor(BrandColor.textTertiary)
                    }
                    VStack(spacing: 4) {
                        Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                            .font(BrandTypography.scoreSmall)
                            .foregroundColor(delta >= 0 ? BrandColor.teal : BrandColor.coral)
                        Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(delta >= 0 ? BrandColor.teal : BrandColor.coral)
                    }
                    VStack(spacing: 4) {
                        Text("\(afterAnalysis.score.totalScore)")
                            .font(BrandTypography.score)
                            .foregroundColor(BrandColor.teal)
                        Text("After")
                            .font(BrandTypography.label)
                            .foregroundColor(BrandColor.textTertiary)
                    }
                }
            }
            .padding(20)
        }
    }

    private var splitPreview: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Before image (full width, clipped on right)
                Rectangle()
                    .fill(BrandColor.surface)
                    .overlay(
                        Text("Before")
                            .font(BrandTypography.label)
                            .foregroundColor(BrandColor.textSecondary)
                    )

                // After overlay (left portion)
                Rectangle()
                    .fill(BrandColor.surfaceElevated)
                    .overlay(
                        Text("After")
                            .font(BrandTypography.label)
                            .foregroundColor(BrandColor.teal)
                    )
                    .frame(width: geo.size.width * dividerPosition)
                    .clipped()

                // Draggable divider
                Rectangle()
                    .fill(BrandColor.teal)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .offset(x: geo.size.width * dividerPosition - 1)
                    .overlay(
                        Circle()
                            .fill(BrandColor.teal)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(BrandColor.background)
                            )
                            .offset(x: geo.size.width * dividerPosition - 1)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        let newPos = value.location.x / geo.size.width
                                        dividerPosition = max(0.1, min(0.9, newPos))
                                    }
                                    .onEnded { _ in isDragging = false }
                            )
                    )
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(BrandColor.stroke, lineWidth: 0.5)
        )
    }

    private var metricsComparison: some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Score Breakdown")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                    .padding(20)

                ForEach(Array(comparison.metricDeltas.enumerated()), id: \.element.id) { i, metricDelta in
                    VStack(spacing: 0) {
                        if i > 0 {
                            Divider()
                                .background(BrandColor.divider)
                                .padding(.horizontal, 20)
                        }
                        HStack {
                            Text(metricDelta.category.displayName)
                                .font(BrandTypography.body)
                                .foregroundColor(BrandColor.textPrimary)
                            Spacer()
                            Text(metricDelta.delta >= 0 ? "+\(metricDelta.delta)" : "\(metricDelta.delta)")
                                .font(BrandTypography.label)
                                .foregroundColor(metricDelta.delta >= 0 ? BrandColor.teal : BrandColor.coral)
                            Text("\(metricDelta.beforeScore) → \(metricDelta.afterScore)")
                                .font(BrandTypography.label)
                                .foregroundColor(BrandColor.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private var insightsCard: some View {
        RMSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("What Changed")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Text(comparison.summaryText)
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
            }
            .padding(20)
        }
    }

    private var actionStrip: some View {
        VStack(spacing: 10) {
            PrimaryButton("Save Progress", action: onSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(BrandColor.background)
    }
}

struct ResetTrackingConfirmationView: View {
    let projectTitle: String
    let delta: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            RMSCard {
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 40))
                        .foregroundColor(BrandColor.gold)
                    Text("Progress Saved")
                        .font(BrandTypography.screenTitle)
                        .foregroundColor(BrandColor.textPrimary)
                    Text(projectTitle)
                        .font(BrandTypography.bodyStrong)
                        .foregroundColor(BrandColor.textPrimary)
                    Text(delta >= 0 ? "Your score moved up by \(delta) points." : "Your latest comparison has been saved.")
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }

            PrimaryButton("Back to Projects", action: onDone)

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(BrandColor.background)
    }
}
