import SwiftUI

struct StagingHubView: View {
    @ObservedObject var appModel: AppModel
    let onStartUpload: (UploadDraft) -> Void

    private var stagingProjects: [SpaceProject] {
        appModel.projects.filter { $0.mode == .stageForSelling }
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    if stagingProjects.isEmpty {
                        emptyState
                    } else {
                        projectList
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { actionStrip }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Staging")
                    .font(BrandTypography.screenTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Text("Prepare your space for sale")
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
            }
            Spacer()
        }
    }

    private var projectList: some View {
        LazyVStack(spacing: 12) {
            ForEach(stagingProjects) { project in
                stagingCard(project)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }

    private func stagingCard(_ project: SpaceProject) -> some View {
        RMSCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(BrandColor.tealMuted)
                        .frame(width: 52, height: 52)
                    if let score = project.currentScore {
                        Text("\(score)")
                            .font(BrandTypography.scoreSmall)
                            .foregroundColor(BrandColor.teal)
                    } else {
                        Image(systemName: project.spaceType.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(BrandColor.teal)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(BrandTypography.bodyStrong)
                        .foregroundColor(BrandColor.textPrimary)
                        .lineLimit(1)
                    TagChip(title: project.spaceType.displayName, accent: BrandColor.teal)
                    Text(project.updatedAt.formatted(.relative(presentation: .named)))
                        .font(BrandTypography.micro)
                        .foregroundColor(BrandColor.textTertiary)
                }

                Spacer()

                if let score = project.currentScore {
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(BrandTypography.scoreSmall)
                            .foregroundColor(readinessColor(score))
                        Text(readinessLabel(score))
                            .font(BrandTypography.micro)
                            .foregroundColor(BrandColor.textTertiary)
                    }
                }
            }
            .padding(16)
        }
    }

    private func readinessColor(_ score: Int) -> Color {
        switch score {
        case ..<60: BrandColor.coral
        case ..<80: BrandColor.gold
        default: BrandColor.teal
        }
    }

    private func readinessLabel(_ score: Int) -> String {
        switch score {
        case ..<60: return "Not Ready"
        case ..<80: return "Getting There"
        default:    return "Show-Ready"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.and.flag")
                .font(.system(size: 48))
                .foregroundColor(BrandColor.textTertiary)
            Text("No staging projects yet")
                .font(BrandTypography.sectionTitle)
                .foregroundColor(BrandColor.textPrimary)
            Text("Analyze a space to prepare it for sale.")
                .font(BrandTypography.body)
                .foregroundColor(BrandColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 60)
    }

    private var actionStrip: some View {
        VStack(spacing: 10) {
            PrimaryButton("Stage a Space") {
                var draft = UploadDraft()
                draft.mode = .stageForSelling
                onStartUpload(draft)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(BrandColor.background)
    }
}
