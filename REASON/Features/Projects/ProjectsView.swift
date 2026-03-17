import SwiftUI

struct ProjectsView: View {
    @ObservedObject var appModel: AppModel
    let onStartUpload: (UploadDraft) -> Void

    @State private var searchText = ""
    @State private var selectedProject: SpaceProject?

    private var filtered: [SpaceProject] {
        if searchText.isEmpty { return appModel.projects }
        return appModel.projects.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.spaceType.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()
            if appModel.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
        .navigationDestination(item: $selectedProject) { project in
            ProjectDetailView(project: project, appModel: appModel, onStartUpload: onStartUpload)
        }
    }

    private var projectList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(BrandColor.textTertiary)
                    TextField("Search spaces…", text: $searchText)
                        .font(BrandTypography.body)
                        .foregroundColor(BrandColor.textPrimary)
                }
                .padding(12)
                .background(BrandColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BrandColor.stroke, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                LazyVStack(spacing: 12) {
                    ForEach(filtered) { project in
                        projectCard(project)
                            .onTapGesture { selectedProject = project }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("My Spaces")
                .font(BrandTypography.screenTitle)
                .foregroundColor(BrandColor.textPrimary)
            Spacer()
            Button {
                var draft = UploadDraft()
                draft.mode = .organize
                onStartUpload(draft)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(BrandColor.teal)
                    .frame(width: 36, height: 36)
                    .background(BrandColor.surfaceElevated)
                    .clipShape(Circle())
            }
        }
    }

    private func projectCard(_ project: SpaceProject) -> some View {
        RMSCard {
            HStack(spacing: 16) {
                // Score badge
                ZStack {
                    Circle()
                        .fill(BrandColor.goldMuted)
                        .frame(width: 52, height: 52)
                    if let score = project.currentScore {
                        Text("\(score)")
                            .font(BrandTypography.scoreSmall)
                            .foregroundColor(BrandColor.gold)
                    } else {
                        Image(systemName: project.spaceType.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(BrandColor.gold)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(BrandTypography.bodyStrong)
                        .foregroundColor(BrandColor.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        TagChip(title: project.spaceType.displayName, accent: BrandColor.textSecondary)
                        TagChip(title: project.mode.displayName, accent: BrandColor.teal)
                    }
                    Text(project.updatedAt.formatted(.relative(presentation: .named)))
                        .font(BrandTypography.micro)
                        .foregroundColor(BrandColor.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(BrandColor.textTertiary)
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)

            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundColor(BrandColor.textTertiary)
                Text("No spaces yet")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Text("Analyze your first space to get started.")
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
                PrimaryButton("Analyze a Space") {
                    var draft = UploadDraft()
                    draft.mode = .organize
                    onStartUpload(draft)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
        }
    }
}
