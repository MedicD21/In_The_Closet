import Foundation

final class AIRouterService: AIAnalysisService {
    private let primary: OpenAIAnalyzing
    private let coach: AnthropicCoachingProviding
    private let fallback: AIAnalysisService

    init(primary: OpenAIAnalyzing, coach: AnthropicCoachingProviding, fallback: AIAnalysisService) {
        self.primary = primary
        self.coach = coach
        self.fallback = fallback
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        do {
            var analysis = try await primary.analyze(request: request)
            analysis.providerPrimary = .openAI

            if let coaching = try? await coach.supportiveCoaching(for: request, analysis: analysis) {
                analysis.supportiveCoachingText = coaching
                analysis.providerSecondary = .anthropic
            }

            return analysis
        } catch {
            var fallbackAnalysis = try await fallback.analyze(request: request)
            fallbackAnalysis.confidenceNotes.append("Using the built-in local analysis scaffold while the live provider setup is still being finalized.")
            return fallbackAnalysis
        }
    }
}
