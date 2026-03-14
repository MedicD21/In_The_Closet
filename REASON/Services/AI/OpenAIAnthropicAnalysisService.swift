import Foundation

@MainActor
final class OpenAIAnthropicAnalysisService: AIAnalysisService {
    private let analyzer: OpenAIAnalysisProvider
    private let coachingProvider: AnthropicCoachingProviding?

    init(analyzer: OpenAIAnalysisProvider, coachingProvider: AnthropicCoachingProviding? = nil) {
        self.analyzer = analyzer
        self.coachingProvider = coachingProvider
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        var analysis = try await analyzer.analyze(request: request)

        guard let coachingProvider else {
            return analysis
        }

        do {
            let coaching = try await coachingProvider.supportiveCoaching(for: request, analysis: analysis)
            analysis.supportiveCoachingText = coaching
            analysis.providerSecondary = .anthropic
        } catch {
            print("⚠️ [OpenAIAnthropicAnalysisService] Coaching provider failed: \(error)")
        }

        return analysis
    }
}
