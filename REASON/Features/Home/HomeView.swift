import SwiftUI

struct HomeView: View {
    @ObservedObject var appModel: AppModel
    let onStartUpload: (UploadDraft) -> Void
    let onNavigateToProjects: () -> Void
    let onNavigateToSettings: () -> Void

    @State private var ringProgress: CGFloat = 0

    private var bestProject: SpaceProject? {
        appModel.projects.max(by: { ($0.currentScore ?? 0) < ($1.currentScore ?? 0) })
    }

    private var bestScore: Int { bestProject?.currentScore ?? 0 }

    private var greetingAdjective: String {
        guard !appModel.projects.isEmpty else { return "ready for their first reset" }
        switch bestScore {
        case ..<40:    return "like they need you"
        case ..<60:    return "like a work in progress"
        case ..<80:    return "pretty good"
        default:       return "fantastic"
        }
    }

    private var greetingName: String {
        // displayName is String (not optional), so no extra ?
        appModel.currentUser?.displayName.components(separatedBy: " ").first ?? "there"
    }

    var body: some View {
        ZStack(alignment: .top) {
            BrandColor.background.ignoresSafeArea()
            RadialGradient(
                colors: [BrandColor.tealMuted.opacity(0.3), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    greetingBlock
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    scoreRingSection
                        .padding(.bottom, 28)

                    quickActionRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    recentProjectsStrip
                        .padding(.bottom, 28)

                    spaceTypeStrip
                        .padding(.bottom, 120)
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image("AppIcon")
                    .resizable().frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("Reset My Space")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
            }
            Spacer()
            Button(action: onNavigateToSettings) {
                ZStack {
                    Circle()
                        .fill(BrandColor.surfaceElevated)
                        .frame(width: 36, height: 36)
                    Text(initials)
                        .font(BrandTypography.label)
                        .foregroundColor(BrandColor.teal)
                }
            }
        }
    }

    private var initials: String {
        let name = appModel.currentUser?.displayName ?? ""
        return String(name.prefix(1)).uppercased().isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "morning" }
        if hour < 17 { return "afternoon" }
        return "evening"
    }

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Good \(timeOfDay), \(greetingName).")
                .font(BrandTypography.screenTitle)
                .foregroundColor(BrandColor.textPrimary)
            Text("Your spaces are looking \(greetingAdjective).")
                .font(BrandTypography.body)
                .foregroundColor(BrandColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scoreRingSection: some View {
        VStack(spacing: 12) {
            ScoreRing(score: bestScore, size: 200, lineWidth: 10)

            if appModel.projects.isEmpty {
                Text("Tap ✦ to start")
                    .font(BrandTypography.micro)
                    .foregroundColor(BrandColor.textTertiary)
            } else if let project = bestProject {
                Text(project.title)
                    .font(BrandTypography.micro)
                    .foregroundColor(BrandColor.textSecondary)
            }
        }
    }

    private var quickActionRow: some View {
        HStack(spacing: 10) {
            PrimaryButton("New Reset") {
                onStartUpload(UploadDraft(mode: .organize))
            }
            SecondaryButton("Compare", accent: BrandColor.gold) {
                onStartUpload(UploadDraft(mode: .compareProgress))
            }
            SecondaryButton("Stage", accent: BrandColor.coral) {
                onStartUpload(UploadDraft(mode: .stageForSelling))
            }
        }
    }

    private var recentProjectsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Spaces")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                Spacer()
                GhostButton(title: "See all →", action: onNavigateToProjects)
            }
            .padding(.horizontal, 20)

            if appModel.projects.isEmpty {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(BrandColor.stroke)
                    .frame(width: 200, height: 140)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 28))
                            .foregroundColor(BrandColor.textTertiary)
                    )
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appModel.projects.prefix(6)) { project in
                            recentProjectCard(project)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder
    private func recentProjectCard(_ project: SpaceProject) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(BrandColor.surface)
            .frame(width: 200, height: 140)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(BrandTypography.bodyStrong)
                        .foregroundColor(BrandColor.textPrimary)
                        .lineLimit(1)
                    // ScoreChip requires both score AND title params
                    if let score = project.currentScore {
                        ScoreChip(score: score, title: project.title)
                    }
                }
                .padding(12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(BrandColor.stroke, lineWidth: 0.5)
            )
    }

    private var spaceTypeStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reset a space")
                .font(BrandTypography.label)
                .foregroundColor(BrandColor.textSecondary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Filter out .custom, use iconName (NOT systemSymbol)
                    ForEach(SpaceType.allCases.filter { $0 != .custom }, id: \.self) { type in
                        Button {
                            onStartUpload(UploadDraft(spaceType: type))
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                                    .font(BrandTypography.label)
                            }
                            .foregroundColor(BrandColor.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(BrandColor.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BrandColor.stroke, lineWidth: 0.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
