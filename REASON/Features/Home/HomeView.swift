import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @State private var isShowingUpload = false
    @State private var uploadDraft = UploadDraft()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                heroCard
                spaceTypeSection
                recentProjectsSection
                inspirationSection
            }
            .padding(20)
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingUpload) {
            if let currentUser = appModel.currentUser {
                UploadFlowContainerView(
                    container: appModel.container,
                    currentUser: currentUser,
                    initialDraft: uploadDraft
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REASON")
                .font(BrandTypography.brandTitle)
                .foregroundStyle(colorScheme == .dark ? BrandColor.gold : BrandColor.teal)
            Text("Find your space again.")
                .font(BrandTypography.bodyStrong)
                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
        }
    }

    private var heroCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Start with one small space.")
                    .font(BrandTypography.screenTitle)
                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                Text("Upload a photo, get a supportive score, and build a polished reset plan with shopping suggestions that feel doable.")
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                PrimaryActionButton("Upload a Photo", systemImage: "camera.fill") {
                    uploadDraft = UploadDraft()
                    isShowingUpload = true
                }
            }
        }
    }

    private var spaceTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Choose a space", subtitle: "Quick starts for the most common resets")
            ForEach(SpaceType.allCases, id: \.id) { type in
                Button {
                    uploadDraft = UploadDraft(spaceType: type, customSpaceName: "", mode: .organize, selectedImageData: nil, imageAssetName: nil, existingProjectID: nil)
                    isShowingUpload = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: type.iconName)
                            .frame(width: 34, height: 34)
                            .background(BrandColor.gold.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text(type.displayName)
                            .font(BrandTypography.bodyStrong)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(BrandColor.surface(for: colorScheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentProjectsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent Projects", subtitle: appModel.projects.isEmpty ? "Your saved spaces will land here." : nil)

            if let latest = appModel.projects.first {
                NavigationLink {
                    ProjectDetailView(project: latest)
                } label: {
                    BrandCard {
                        HStack(spacing: 16) {
                            ProjectImageView(projectImage: latest.images.first)
                                .frame(width: 110, height: 110)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(latest.title)
                                    .font(BrandTypography.sectionTitle)
                                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                                Text(latest.mode.longLabel)
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                                if let score = latest.currentScore {
                                    ScoreChip(score: score, title: "Latest Score")
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                BrandCard {
                    Text("No saved projects yet. Start with a photo and we’ll hold onto the plan for you.")
                        .font(BrandTypography.body)
                        .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                }
            }
        }
    }

    private var inspirationSection: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Brand direction", subtitle: "Current visual reference included in the build")
                Image("HomeMockup")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("Soft rounded cards, warm neutral space, and teal-gold accents guide the UI language throughout the app.")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }
        }
    }
}
