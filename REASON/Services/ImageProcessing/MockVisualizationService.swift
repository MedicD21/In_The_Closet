import Foundation

final class MockVisualizationService: VisualizationService {
    func generateVisualization(for project: SpaceProject, analysis: SpaceAnalysis) async throws -> VisualizationConcept {
        VisualizationConcept(
            projectedImprovedScore: min(100, analysis.score.totalScore + 16),
            promptSummary: "Create a calmer, brighter, more cohesive \(project.title.lowercased()) using matching storage, stronger zoning, and a lightly styled front-facing finish.",
            whatImproved: [
                "Categories are easier to scan at a glance.",
                "Containment reduces visual spill.",
                "The front-facing surfaces feel more intentional."
            ],
            stillNeedsWork: [
                "Maintenance depends on keeping duplicate items edited down.",
                "Any open packaging will still need regular resets."
            ],
            conceptCaption: "AI concept preview for a more edited, supportive version of this space."
        )
    }
}
