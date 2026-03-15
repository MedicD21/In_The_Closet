import Foundation

@MainActor
final class UploadFlowViewModel: ObservableObject {
    enum Step {
        case chooseSpace
        case customName
        case upload
        case analyzing
        case results
        case confirmation
    }

    @Published var draft: UploadDraft
    @Published var step: Step
    @Published var selectedBudgetTier: BudgetTier = .budget
    @Published var analysis: SpaceAnalysis?
    @Published var project: SpaceProject?
    @Published var comparison: ProjectComparison?
    @Published var errorMessage: String?
    @Published var isSaving = false

    let currentUser: UserProfile

    private let container: AppContainer
    private let existingProject: SpaceProject?
    private var persistedImagePath: String?

    init(container: AppContainer, currentUser: UserProfile, existingProject: SpaceProject? = nil, initialDraft: UploadDraft) {
        self.container = container
        self.currentUser = currentUser
        self.existingProject = existingProject
        self.draft = initialDraft

        if initialDraft.spaceType == .custom && initialDraft.customSpaceName.isEmpty {
            self.step = .customName
        } else if initialDraft.imageAssetName != nil || initialDraft.selectedImageData != nil {
            self.step = .upload
        } else if initialDraft.spaceType != .pantry || existingProject != nil {
            self.step = .upload
        } else {
            self.step = .chooseSpace
        }

        if let existingProject {
            self.draft.spaceType = existingProject.spaceType
            self.draft.customSpaceName = existingProject.customSpaceName ?? ""
            self.draft.mode = .compareProgress
            self.draft.existingProjectID = existingProject.id
            self.step = .upload
        }
    }

    func continueFromSpaceSelection() {
        step = draft.spaceType == .custom ? .customName : .upload
    }

    func continueFromCustomName() {
        guard !draft.customSpaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Add a custom space name before continuing."
            return
        }

        step = .upload
    }

    func runAnalysis() async {
        step = .analyzing
        errorMessage = nil
        AppConsole.analysis.notice("upload flow analyze requested mode=\(self.draft.mode.rawValue, privacy: .public) space=\(self.draft.spaceType.rawValue, privacy: .public)")

        do {
            guard let analysisImageData = resolvedAnalysisImageData() else {
                throw AppError.validation("Choose a photo before starting a live analysis.")
            }
            AppConsole.analysis.notice("analysis source image bytes=\(analysisImageData.count, privacy: .public)")

            var analysis = try await container.analysisService.analyze(
                request: AnalysisRequest(
                    projectID: existingProject?.id,
                    spaceType: draft.spaceType,
                    customSpaceName: draft.customSpaceName.isEmpty ? nil : draft.customSpaceName,
                    mode: draft.mode,
                    imageData: analysisImageData,
                    previousAnalysis: existingProject?.latestAnalysis
                )
            )
            AppConsole.analysis.notice("analysis finished score=\(analysis.score.totalScore, privacy: .public) resetMinutes=\(analysis.estimatedResetMinutes, privacy: .public)")

            do {
                analysis.budgetRecommendations = try await container.productRecommendationService.recommendations(
                    for: RecommendationContext(
                        spaceType: draft.spaceType,
                        mode: draft.mode,
                        analysisID: analysis.id,
                        problems: analysis.biggestProblems,
                        opportunities: analysis.bestOpportunities
                    )
                )
                let totalRecommendationItems = analysis.budgetRecommendations.reduce(0) { $0 + $1.items.count }
                AppConsole.recommendations.notice("analysis received \(totalRecommendationItems, privacy: .public) recommendation items")
            } catch {
                AppConsole.recommendations.error("shopping suggestions unavailable: \(error.localizedDescription, privacy: .public)")
                analysis.confidenceNotes.append("Live shopping suggestions were unavailable for this run: \(error.localizedDescription)")
            }

            let builtProject = buildProject(with: analysis)
            do {
                analysis.visualizationConcept = try await container.visualizationService.generateVisualization(for: builtProject, analysis: analysis)
                AppConsole.visualization.notice("analysis received generated concept image=\((analysis.visualizationConcept?.generatedImageURL != nil), privacy: .public)")
            } catch {
                AppConsole.visualization.error("concept render unavailable: \(error.localizedDescription, privacy: .public)")
                analysis.confidenceNotes.append("Live concept render was unavailable for this run: \(error.localizedDescription)")
            }

            let finalizedProject = buildProject(with: analysis)
            project = finalizedProject
            comparison = makeComparisonIfNeeded(for: finalizedProject)
            self.analysis = analysis
            step = .results
            AppConsole.analysis.notice("upload flow transitioned to results")
        } catch {
            AppConsole.analysis.error("analysis flow failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            step = .upload
        }
    }

    func save(using appModel: AppModel) async {
        guard var project, let analysis else { return }
        isSaving = true
        defer { isSaving = false }

        if project.analyses.isEmpty || project.analyses.last?.id != analysis.id {
            project.analyses.append(analysis)
        }
        project.currentScore = analysis.score.totalScore
        project.updatedAt = .now
        project.savedProducts = analysis.budgetRecommendations.flatMap(\.items)
        project.comparisons = comparison.map { [ $0 ] } ?? project.comparisons
        await appModel.save(project: project)
        self.project = project
        if draft.mode == .compareProgress {
            step = .confirmation
        }
    }

    private func buildProject(with analysis: SpaceAnalysis) -> SpaceProject {
        let projectID = existingProject?.id ?? UUID()
        let title = existingProject?.title ?? draft.title
        let currentImage = ProjectImage(
            id: UUID(),
            projectID: projectID,
            userID: currentUser.id,
            imageType: existingProject == nil ? .before : (draft.mode == .compareProgress ? .after : .before),
            storagePath: persistImageIfNeeded(),
            remoteURL: nil,
            localAssetName: draft.imageAssetName,
            createdAt: .now
        )

        var images = existingProject?.images ?? []
        images.append(currentImage)

        var analyses = existingProject?.analyses ?? []
        analyses.append(analysis)

        return SpaceProject(
            id: projectID,
            userID: currentUser.id,
            title: title,
            spaceType: draft.spaceType,
            customSpaceName: draft.customSpaceName.isEmpty ? nil : draft.customSpaceName,
            mode: draft.mode,
            status: .ready,
            currentScore: analysis.score.totalScore,
            createdAt: existingProject?.createdAt ?? .now,
            updatedAt: .now,
            archivedAt: nil,
            images: images,
            analyses: analyses,
            comparisons: existingProject?.comparisons ?? [],
            savedProducts: analysis.budgetRecommendations.flatMap(\.items),
            stagingChecklist: analysis.stagingAdvice.map {
                StagingChecklist(id: UUID(), projectID: projectID, checklistItems: $0.showingDayChecklist, createdAt: .now)
            }
        )
    }

    private func makeComparisonIfNeeded(for project: SpaceProject) -> ProjectComparison? {
        guard draft.mode == .compareProgress,
              let previous = existingProject?.latestAnalysis,
              let latest = project.latestAnalysis else {
            return nil
        }

        return ProjectComparison(
            id: UUID(),
            projectID: project.id,
            beforeAnalysisID: previous.id,
            afterAnalysisID: latest.id,
            scoreDelta: latest.score.totalScore - previous.score.totalScore,
            summaryText: "Your updated photo shows a calmer, more intentional space with a better sense of structure.",
            metricDeltas: ScoreCategory.allCases.map { category in
                MetricDelta(
                    id: UUID(),
                    category: category,
                    beforeScore: previous.score[category],
                    afterScore: latest.score[category]
                )
            },
            createdAt: .now
        )
    }

    private func persistImageIfNeeded() -> String? {
        if let persistedImagePath {
            return persistedImagePath
        }

        guard let imageData = draft.selectedImageData else { return nil }
        let persistedData = ReferenceImageLoader.normalizedJPEGData(from: imageData) ?? imageData
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("reason/images", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        try? persistedData.write(to: fileURL, options: .atomic)
        persistedImagePath = fileURL.path
        return persistedImagePath
    }

    private func resolvedAnalysisImageData() -> Data? {
        if let selectedImageData = draft.selectedImageData {
            return ReferenceImageLoader.normalizedJPEGData(from: selectedImageData) ?? selectedImageData
        }

        guard let imageAssetName = draft.imageAssetName else {
            return nil
        }

        let imageData = ReferenceImageLoader.imageData(named: imageAssetName)
        return imageData.flatMap { ReferenceImageLoader.normalizedJPEGData(from: $0) ?? $0 }
    }
}
