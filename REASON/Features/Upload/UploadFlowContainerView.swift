import PhotosUI
import SwiftUI

struct UploadFlowContainerView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UploadFlowViewModel

    init(container: AppContainer, currentUser: UserProfile, existingProject: SpaceProject? = nil, initialDraft: UploadDraft) {
        _viewModel = StateObject(
            wrappedValue: UploadFlowViewModel(
                container: container,
                currentUser: currentUser,
                existingProject: existingProject,
                initialDraft: initialDraft
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .chooseSpace:
                    ChooseSpaceTypeView(draft: $viewModel.draft) {
                        viewModel.continueFromSpaceSelection()
                    }
                case .customName:
                    CustomSpaceNameView(name: $viewModel.draft.customSpaceName) {
                        viewModel.continueFromCustomName()
                    }
                case .upload:
                    PhotoUploadView(viewModel: viewModel)
                case .analyzing:
                    AnalysisLoadingView(mode: viewModel.draft.mode)
                case .results:
                    resultsDestination
                case .confirmation:
                    ResetTrackingConfirmationView(
                        projectTitle: viewModel.project?.title ?? "Project",
                        delta: viewModel.comparison?.scoreDelta ?? 0
                    ) {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(BrandColor.teal)
                }
            }
            .alert(
                "Something Needs Attention",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                actions: {
                    Button("OK", role: .cancel) { }
                },
                message: {
                    Text(viewModel.errorMessage ?? "")
                }
            )
        }
    }

    @ViewBuilder
    private var resultsDestination: some View {
        if viewModel.draft.mode == .stageForSelling, let analysis = viewModel.analysis, let project = viewModel.project {
            StagingResultsView(
                analysis: analysis,
                project: project,
                selectedBudgetTier: $viewModel.selectedBudgetTier
            ) {
                Task {
                    await viewModel.save(using: appModel)
                    dismiss()
                }
            }
        } else if viewModel.draft.mode == .compareProgress,
                  let analysis = viewModel.analysis,
                  let comparison = viewModel.comparison,
                  let project = viewModel.project,
                  let previous = project.analyses.dropLast().last {
            CompareView(
                beforeAnalysis: previous,
                afterAnalysis: analysis,
                comparison: comparison,
                project: project
            ) {
                Task {
                    await viewModel.save(using: appModel)
                }
            }
        } else if let analysis = viewModel.analysis, let project = viewModel.project {
            ResultsView(
                analysis: analysis,
                project: project,
                imageData: viewModel.draft.selectedImageData,
                selectedBudgetTier: $viewModel.selectedBudgetTier
            ) {
                Task {
                    await viewModel.save(using: appModel)
                    dismiss()
                }
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.step {
        case .chooseSpace: "Choose Space Type"
        case .customName: "Name Your Space"
        case .upload: "Upload Photo"
        case .analyzing: "Analyzing"
        case .results: "Results"
        case .confirmation: "Progress Saved"
        }
    }
}

private struct ChooseSpaceTypeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var draft: UploadDraft
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Pick the space you're resetting", subtitle: "You can always refine the name and mode on the next screen.")

                ForEach(SpaceType.allCases, id: \.id) { type in
                    Button {
                        draft.spaceType = type
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type.iconName)
                                .frame(width: 42, height: 42)
                                .background(type == draft.spaceType ? BrandColor.teal.opacity(0.18) : BrandColor.gold.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(BrandTypography.bodyStrong)
                                    .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                                Text(type == .custom ? "Kitchen cabinet, entry drop zone, linen shelf, and more." : "Use a tailored reset flow for this space.")
                                    .font(BrandTypography.caption)
                                    .foregroundStyle(BrandColor.secondaryText(for: colorScheme))
                            }
                            Spacer()
                            if type == draft.spaceType {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BrandColor.teal)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(BrandColor.surface(for: colorScheme))
                        )
                    }
                    .buttonStyle(.plain)
                }

                PrimaryActionButton("Continue") {
                    onContinue()
                }
                .padding(.top, 8)
            }
        }
    }
}

private struct CustomSpaceNameView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var name: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Name the space", subtitle: "Examples: Linen Closet, Under Sink, Entryway Drop Zone")
            TextField("Custom space name", text: $name)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(BrandColor.surface(for: colorScheme))
                )

            PrimaryActionButton("Continue") {
                onContinue()
            }

            Spacer()
        }
    }
}

private struct PhotoUploadView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: UploadFlowViewModel
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Add your photo", subtitle: "Single-photo analysis is live in v1, with room for extra angles later.")

                ProjectImageView(
                    projectImage: viewModel.project?.images.last,
                    imageData: viewModel.draft.selectedImageData
                )
                .frame(height: 260)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Text(viewModel.draft.selectedImageData == nil ? "Choose Photo" : "Replace Photo")
                            .font(BrandTypography.button)
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BrandColor.surface(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(BrandColor.divider(for: colorScheme), lineWidth: 1)
                            )
                    )
                }
                .onChange(of: selectedItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            viewModel.draft.selectedImageData = data
                            viewModel.draft.imageAssetName = nil
                        }
                    }
                }

                SecondaryActionButton(title: "Use Sample Pantry Photo") {
                    viewModel.draft.imageAssetName = "PantrySample"
                    viewModel.draft.selectedImageData = nil
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mode")
                        .font(BrandTypography.sectionTitle)
                        .foregroundStyle(BrandColor.primaryText(for: colorScheme))

                    ForEach(ProjectMode.allCases, id: \.id) { mode in
                        Button {
                            viewModel.draft.mode = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.longLabel)
                                        .font(BrandTypography.bodyStrong)
                                    Text(mode == .organize ? "Get a warm reset plan and shopping suggestions." : mode == .stageForSelling ? "Focus on listing- and showing-ready presentation." : "Measure progress with an updated photo.")
                                        .font(BrandTypography.caption)
                                }
                                Spacer()
                                if viewModel.draft.mode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BrandColor.teal)
                                }
                            }
                            .foregroundStyle(BrandColor.primaryText(for: colorScheme))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(BrandColor.surface(for: colorScheme))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                PrimaryActionButton("Analyze This Space", systemImage: "sparkles") {
                    Task {
                        await viewModel.runAnalysis()
                    }
                }
                .disabled(viewModel.draft.selectedImageData == nil && viewModel.draft.imageAssetName == nil)
                .opacity((viewModel.draft.selectedImageData == nil && viewModel.draft.imageAssetName == nil) ? 0.6 : 1)
            }
        }
    }
}
