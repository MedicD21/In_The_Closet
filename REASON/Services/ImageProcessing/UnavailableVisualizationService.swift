import Foundation

@MainActor
final class UnavailableVisualizationService: VisualizationService {
    private let message: String

    init(message: String) {
        self.message = message
    }

    func generateVisualization(for project: SpaceProject, analysis: SpaceAnalysis) async throws -> VisualizationConcept {
        throw AppError.configuration(message)
    }
}
