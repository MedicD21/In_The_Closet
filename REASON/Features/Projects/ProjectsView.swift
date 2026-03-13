import SwiftUI

struct ProjectsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if appModel.projects.isEmpty {
                VStack(spacing: 18) {
                    Text("No saved projects yet")
                        .font(BrandTypography.screenTitle)
                    Text("Once you save a space, you’ll be able to revisit the score, shopping tools, and compare future progress here.")
                        .font(BrandTypography.body)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            } else {
                List {
                    ForEach(appModel.projects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            HStack(spacing: 14) {
                                ProjectImageView(projectImage: project.images.first)
                                    .frame(width: 74, height: 74)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.title)
                                        .font(BrandTypography.bodyStrong)
                                    Text(project.mode.longLabel)
                                        .font(BrandTypography.caption)
                                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                    if let score = project.currentScore {
                                        Text("Score \(score)")
                                            .font(BrandTypography.caption)
                                            .foregroundStyle(BrandColor.teal)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let project = appModel.projects[index]
                                await appModel.delete(projectID: project.id)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Saved Projects")
    }
}

struct ProjectDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @State private var isShowingCompareFlow = false
    @State private var selectedBudgetTier: BudgetTier = .budget

    let project: SpaceProject

    private var resolvedProject: SpaceProject {
        appModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectImageView(projectImage: resolvedProject.images.last)
                    .frame(height: 240)

                BrandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(resolvedProject.title)
                            .font(BrandTypography.screenTitle)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                        Text(resolvedProject.mode.longLabel)
                            .font(BrandTypography.caption)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        if let analysis = resolvedProject.latestAnalysis {
                            Text(analysis.summaryText)
                                .font(BrandTypography.body)
                                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                            ScoreChip(score: analysis.score.totalScore, title: "Current Score")
                        }
                    }
                }

                if let analysis = resolvedProject.latestAnalysis {
                    BrandCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Latest plan", subtitle: nil)
                            ForEach(analysis.resetPlan.prefix(3)) { step in
                                Text("\(step.order). \(step.title)")
                                    .font(BrandTypography.body)
                            }
                        }
                    }

                    NavigationLink {
                        ShoppingRecommendationsView(analysis: analysis, selectedBudgetTier: $selectedBudgetTier)
                    } label: {
                        PrimaryActionLabel(title: "Open Shopping Tools", systemImage: "cart.fill")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        VisualizationView(analysis: analysis, project: resolvedProject, selectedBudgetTier: selectedBudgetTier)
                    } label: {
                        SecondaryActionLabel(title: "See Concept Preview")
                    }
                    .buttonStyle(.plain)
                }

                PrimaryActionButton("Compare Progress", systemImage: "arrow.left.arrow.right.circle") {
                    isShowingCompareFlow = true
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Project Detail")
        .sheet(isPresented: $isShowingCompareFlow) {
            if let user = appModel.currentUser {
                UploadFlowContainerView(
                    container: appModel.container,
                    currentUser: user,
                    existingProject: resolvedProject,
                    initialDraft: UploadDraft(spaceType: resolvedProject.spaceType, customSpaceName: resolvedProject.customSpaceName ?? "", mode: .compareProgress, selectedImageData: nil, imageAssetName: nil, existingProjectID: resolvedProject.id)
                )
            }
        }
    }
}
