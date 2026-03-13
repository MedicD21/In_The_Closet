import Foundation

@MainActor
protocol VisualizationService {
    func generateVisualization(for project: SpaceProject, analysis: SpaceAnalysis) async throws -> VisualizationConcept
}
