import Foundation

@MainActor
final class OpenRouterVisualizationService: VisualizationService {
    private let client: OpenRouterClient
    private let qualityMode: AIQualityMode

    // Stage 4 — image generation
    // Note: OpenRouter does not offer image generation models.
    // generateVisualization() gracefully returns a text-only concept when image gen fails.
    // To enable real image generation, integrate a separate provider (e.g. Replicate, Together AI).
    private var imageModel: String {
        // Placeholder until a real image-capable provider is wired in.
        return "openrouter/unavailable"
    }

    init(client: OpenRouterClient, qualityMode: AIQualityMode = .free) {
        self.client = client
        self.qualityMode = qualityMode
    }

    func generateVisualization(for project: SpaceProject, analysis: SpaceAnalysis) async throws -> VisualizationConcept {
        let base = analysis.visualizationConcept ?? VisualizationConcept(
            projectedImprovedScore: min(100, analysis.score.totalScore + 16),
            promptSummary: "A calmer, more cohesive \(project.title.lowercased()) with matching storage and better zoning.",
            whatImproved: ["Better organization", "Cleaner surfaces"],
            stillNeedsWork: ["Regular maintenance required"],
            conceptCaption: "AI concept preview of an organized version of this space.",
            generatedImageURL: nil
        )

        guard !client.apiKey.isEmpty else { return base }
        guard imageModel != "openrouter/unavailable" else { return base }

        let imagePromptText = buildImagePrompt(for: project, concept: base)
        let payload: [String: Any] = [
            "model": imageModel,
            "prompt": imagePromptText,
            "n": 1,
            "size": "1024x1024"
        ]

        do {
            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            let imageURL = try await client.generateImage(payload: payloadData)
            return VisualizationConcept(
                projectedImprovedScore: base.projectedImprovedScore,
                promptSummary: base.promptSummary,
                whatImproved: base.whatImproved,
                stillNeedsWork: base.stillNeedsWork,
                conceptCaption: base.conceptCaption,
                generatedImageURL: imageURL
            )
        } catch {
            // Return text concept without image rather than failing the whole flow
            return base
        }
    }

    private func buildImagePrompt(for project: SpaceProject, concept: VisualizationConcept) -> String {
        """
        Create a photorealistic organized version of a \(project.spaceType.displayName.lowercased()).
        \(concept.promptSummary)
        Requirements: minimal clutter, organized surfaces, cable management, neutral storage bins, clean modern interior.
        The result should look like the same room but neatly organized and styled.
        Photorealistic, bright natural lighting, high quality interior photography.
        """
    }
}
