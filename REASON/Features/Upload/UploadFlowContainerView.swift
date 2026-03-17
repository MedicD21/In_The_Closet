import SwiftUI
import PhotosUI

struct UploadFlowContainerView: View {
    let container: AppContainer
    let initialDraft: UploadDraft
    let onDismiss: () -> Void

    @ObservedObject var appModel: AppModel
    @StateObject private var viewModel: UploadFlowViewModel
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var rotation: Double = 0
    @State private var statusIndex = 0
    @State private var photosItem: PhotosPickerItem?
    @State private var statusTimer: Timer?

    private let statusMessages = [
        "Reading surfaces…",
        "Scoring organization…",
        "Building your reset plan…",
        "Finding smart products…",
        "Generating concept preview…"
    ]

    init(container: AppContainer, appModel: AppModel, currentUser: UserProfile?,
         initialDraft: UploadDraft, onDismiss: @escaping () -> Void) {
        self.container = container
        self.initialDraft = initialDraft
        self.onDismiss = onDismiss
        self._appModel = ObservedObject(wrappedValue: appModel)
        // Fall back to a minimal guest profile if needed; auth flow should prevent nil
        let effectiveUser = currentUser ?? UserProfile(
            id: UUID(), email: "", displayName: "Guest",
            avatarURL: nil, createdAt: .now, updatedAt: .now,
            preferredTheme: .system, preferredTone: "warm",
            onboardingCompleted: true, authMethod: .guest
        )
        _viewModel = StateObject(wrappedValue: UploadFlowViewModel(
            container: container,
            currentUser: effectiveUser,
            initialDraft: initialDraft
        ))
    }

    var body: some View {
        ZStack {
            BrandColor.surface.ignoresSafeArea()
            content
        }
        .presentationDetents([.medium, .large, .fraction(1.0)], selection: $sheetDetent)
        .presentationDragIndicator(.hidden)
        .onChange(of: viewModel.step) { _, newStep in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                sheetDetent = detent(for: newStep)
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    private func detent(for step: UploadFlowViewModel.Step) -> PresentationDetent {
        switch step {
        case .chooseSpace, .customName: return .medium
        case .upload:                  return .large
        case .analyzing, .results:     return .fraction(1.0)
        case .confirmation:            return .medium
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .chooseSpace, .customName:
            stage1View
        case .upload:
            stage2View
        case .analyzing:
            stage3AnalyzingView
        case .results:
            stage4ResultsView
        case .confirmation:
            stage5ConfirmationView
        }
    }

    // MARK: — Stage 1: Choose photo + space type
    private var stage1View: some View {
        VStack(spacing: 20) {
            sheetHandle

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(BrandColor.teal)

            Text("Choose a space")
                .font(BrandTypography.sectionTitle)
                .foregroundColor(BrandColor.textPrimary)

            PhotosPicker(selection: $photosItem, matching: .images) {
                PrimaryButton("Choose from Library") {}
            }
            .onChange(of: photosItem) { _, newItem in
                Task {
                    do {
                        if let data = try await newItem?.loadTransferable(type: Data.self) {
                            viewModel.draft.selectedImageData = data
                            viewModel.continueFromSpaceSelection()
                        }
                    } catch {
                        viewModel.errorMessage = "Could not load the selected photo. Please try again."
                    }
                }
            }

            GhostButton(title: "Skip to space type →") {
                viewModel.continueFromSpaceSelection()
            }

            spaceTypeScroll
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: — Stage 2: Upload / confirm
    private var stage2View: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                sheetHandle

                if let data = viewModel.draft.selectedImageData, let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(BrandColor.gold, lineWidth: 1)
                        )
                } else {
                    // No image yet — show photo picker again
                    PhotosPicker(selection: $photosItem, matching: .images) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(BrandColor.surfaceElevated)
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundColor(BrandColor.teal)
                                    Text("Add Photo")
                                        .font(BrandTypography.label)
                                        .foregroundColor(BrandColor.textSecondary)
                                }
                            )
                    }
                    .onChange(of: photosItem) { _, newItem in
                        Task {
                            do {
                                if let data = try await newItem?.loadTransferable(type: Data.self) {
                                    viewModel.draft.selectedImageData = data
                                }
                            } catch {
                                viewModel.errorMessage = "Could not load the selected photo. Please try again."
                            }
                        }
                    }
                }

                spaceTypeScroll
                modePicker

                Spacer(minLength: 0)

                PrimaryButton(
                    "Analyze My Space",
                    isDisabled: viewModel.draft.selectedImageData == nil && viewModel.draft.imageAssetName == nil
                ) {
                    Task { await viewModel.runAnalysis() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: — Stage 3: Analyzing
    private var stage3AnalyzingView: some View {
        ZStack {
            if let data = viewModel.draft.selectedImageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 14)
            }
            BrandColor.overlay.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(BrandColor.textTertiary.opacity(0.2), lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Canvas { ctx, sz in
                        let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
                        let startAngle = Angle.degrees(-90)
                        let endAngle = Angle.degrees(230)
                        var path = Path()
                        path.addArc(center: center, radius: 37,
                                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        ctx.stroke(
                            path,
                            with: .angularGradient(
                                Gradient(colors: [BrandColor.teal, BrandColor.gold]),
                                center: center,
                                startAngle: startAngle,
                                endAngle: endAngle
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                    }
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                    startStatusCycling()
                }
                .onDisappear {
                    statusTimer?.invalidate()
                    statusTimer = nil
                }

                Text("Analyzing your space…")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)

                Text(statusMessages[statusIndex])
                    .font(BrandTypography.body)
                    .foregroundColor(BrandColor.textSecondary)
                    .animation(.easeInOut(duration: 0.4), value: statusIndex)
            }
        }
    }

    // MARK: — Stage 4: Results
    @ViewBuilder
    private var stage4ResultsView: some View {
        if let analysis = viewModel.analysis, let project = viewModel.project {
            NavigationStack {
                Group {
                    if viewModel.draft.mode == .stageForSelling {
                        StagingResultsView(
                            analysis: analysis,
                            project: project,
                            selectedBudgetTier: $viewModel.selectedBudgetTier
                        ) {
                            Task { await viewModel.save(using: appModel); onDismiss() }
                        }
                    } else if viewModel.draft.mode == .compareProgress,
                              let comparison = viewModel.comparison,
                              let previous = project.analyses.dropLast().last {
                        CompareView(
                            beforeAnalysis: previous,
                            afterAnalysis: analysis,
                            comparison: comparison,
                            project: project
                        ) {
                            Task { await viewModel.save(using: appModel) }
                        }
                    } else {
                        ResultsView(
                            analysis: analysis,
                            project: project,
                            imageData: viewModel.draft.selectedImageData,
                            selectedBudgetTier: $viewModel.selectedBudgetTier
                        ) {
                            Task { await viewModel.save(using: appModel); onDismiss() }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { onDismiss() }
                            .foregroundColor(BrandColor.teal)
                    }
                }
            }
        } else {
            // Fallback: analysis data missing at results step — surface error and allow dismissal
            VStack(spacing: 20) {
                sheetHandle
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(BrandColor.coral)
                Text("Something went wrong")
                    .font(BrandTypography.sectionTitle)
                    .foregroundColor(BrandColor.textPrimary)
                GhostButton(title: "Dismiss") { onDismiss() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: — Stage 5: Confirmation
    private var stage5ConfirmationView: some View {
        VStack(spacing: 20) {
            sheetHandle

            Text("Progress Saved")
                .font(BrandTypography.sectionTitle)
                .foregroundColor(BrandColor.textPrimary)

            if let delta = viewModel.comparison?.scoreDelta,
               let afterScore = viewModel.analysis?.score.totalScore {
                let beforeScore = afterScore - delta
                Text(delta >= 0 ? "+\(delta) pts" : "\(delta) pts")
                    .font(BrandTypography.scoreSmall)
                    .foregroundColor(delta >= 0 ? BrandColor.teal : BrandColor.coral)

                HStack(spacing: 16) {
                    TagChip(title: "Before: \(beforeScore)", accent: BrandColor.textSecondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(BrandColor.textTertiary)
                    TagChip(title: "After: \(afterScore)", accent: BrandColor.teal)
                }
            }

            PrimaryButton("View Full Comparison") { onDismiss() }
            GhostButton(title: "Done") { onDismiss() }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: — Shared subviews
    private var sheetHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(BrandColor.textTertiary)
            .frame(width: 36, height: 4)
            .padding(.top, 8)
    }

    private var spaceTypeScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpaceType.allCases.filter { $0 != .custom }, id: \.self) { type in
                    let isSelected = viewModel.draft.spaceType == type
                    Button { viewModel.draft.spaceType = type } label: {
                        Text(type.displayName)
                            .font(BrandTypography.label)
                            .foregroundColor(isSelected ? BrandColor.textPrimary : BrandColor.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? BrandColor.teal : BrandColor.surfaceElevated)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach([ProjectMode.organize, .stageForSelling, .compareProgress], id: \.self) { mode in
                let isSelected = viewModel.draft.mode == mode
                Button { withAnimation { viewModel.draft.mode = mode } } label: {
                    Text(mode.displayName)
                        .font(BrandTypography.label)
                        .foregroundColor(isSelected ? BrandColor.textPrimary : BrandColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? BrandColor.teal : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .background(BrandColor.surfaceElevated)
        .clipShape(Capsule())
    }

    private func startStatusCycling() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            withAnimation { statusIndex = (statusIndex + 1) % statusMessages.count }
            if viewModel.step != .analyzing {
                timer.invalidate()
                statusTimer = nil
            }
        }
    }
}
