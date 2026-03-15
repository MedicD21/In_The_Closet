import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @State private var isShowingUpload = false
    @State private var uploadDraft = UploadDraft()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                heroCard
                spaceTypeSection
                recentProjectsSection
                inspirationSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
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
        VStack(alignment: .leading, spacing: 12) {
            TagChip(title: "AI-guided reset studio", accent: BrandColor.gold)
            Text("Reset My Space")
                .font(BrandTypography.brandTitle)
                .foregroundStyle(colorScheme == .dark ? BrandColor.gold : BrandColor.teal)
            Text("By REASON")
                .font(BrandTypography.caption)
                .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            Text("Sharper guidance for real rooms, calmer surfaces, and budget-friendly resets that still feel doable.")
                .font(BrandTypography.body)
                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
        }
    }

    private var heroCard: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start with one small space.")
                            .font(BrandTypography.caption)
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                        Text("Modern resets that feel realistic.")
                            .font(BrandTypography.screenTitle)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BrandColor.teal)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(BrandColor.softTeal.opacity(colorScheme == .dark ? 0.18 : 0.2))
                        )
                }

                Text("Upload a photo, get a supportive score, and build a polished reset plan with shopping suggestions that feel doable.")
                    .font(BrandTypography.body)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    HomeFeatureBadge(title: "Live analysis", systemImage: "waveform.path.ecg", accent: BrandColor.teal)
                    HomeFeatureBadge(title: "Budget paths", systemImage: "dollarsign.circle", accent: BrandColor.gold)
                    HomeFeatureBadge(title: "Concept preview", systemImage: "photo.on.rectangle", accent: BrandColor.coral)
                }

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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(BrandColor.gold.opacity(colorScheme == .dark ? 0.18 : 0.2))
                            )
                        Text(type.displayName)
                            .font(BrandTypography.bodyStrong)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(BrandColor.elevatedBackground(for: colorScheme))
                            )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [BrandColor.surface(for: colorScheme), BrandColor.secondarySurface(for: colorScheme)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(BrandColor.cardStroke(for: colorScheme), lineWidth: 1)
                            )
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
                ReferenceImageView(assetName: "HomeMockup", bundleFileName: "home-mockup", fileExtension: "png")
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text("Soft rounded cards, warm neutral space, and teal-gold accents guide the UI language throughout the app.")
                    .font(BrandTypography.caption)
                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
            }
        }
    }
}

private struct HomeFeatureBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(accent)
            Text(title)
                .font(BrandTypography.caption)
                .foregroundStyle(BrandColor.primaryText(for: colorScheme))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandColor.elevatedBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandColor.cardStroke(for: colorScheme), lineWidth: 1)
                )
        )
    }
}
