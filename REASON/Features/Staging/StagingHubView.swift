import SwiftUI

struct StagingHubView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @State private var isShowingFlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BrandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Staging Mode")
                            .font(BrandTypography.screenTitle)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                        Text("Use Reset My Space to lighten visual clutter, hide personal cues, and build a showing-day checklist that feels achievable.")
                            .font(BrandTypography.body)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        PrimaryActionButton("Start a Staging Review", systemImage: "house.and.flag") {
                            isShowingFlow = true
                        }
                    }
                }

                BrandCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Common staging wins", subtitle: nil)
                        Text("Remove personal photos")
                        Text("Edit countertop overflow")
                        Text("Match baskets and hangers")
                        Text("Hide cords, pet items, and niche products")
                    }
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                }

                if !appModel.projects.filter({ $0.mode == .stageForSelling }).isEmpty {
                    SectionHeader(title: "Saved staging projects", subtitle: nil)
                    ForEach(appModel.projects.filter { $0.mode == .stageForSelling }) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            BrandCard {
                                HStack {
                                    ProjectImageView(projectImage: project.images.first)
                                        .frame(width: 88, height: 88)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.title)
                                            .font(BrandTypography.bodyStrong)
                                        Text(project.currentScore.map { "Readiness \($0)" } ?? "Pending")
                                            .font(BrandTypography.caption)
                                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Staging")
        .sheet(isPresented: $isShowingFlow) {
            if let user = appModel.currentUser {
                UploadFlowContainerView(
                    container: appModel.container,
                    currentUser: user,
                    initialDraft: UploadDraft(spaceType: .custom, customSpaceName: "", mode: .stageForSelling, selectedImageData: nil, imageAssetName: nil, existingProjectID: nil)
                )
            }
        }
    }
}
