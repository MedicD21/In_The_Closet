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
        AppConsole.analysis.notice("starting OpenAI analysis with Anthropic coaching fallback")
        var analysis = try await analyzer.analyze(request: request)

        guard let coachingProvider else {
            AppConsole.analysis.notice("no Anthropic coaching provider configured")
            return analysis
        }

        do {
            let coaching = try await coachingProvider.supportiveCoaching(for: request, analysis: analysis)
            analysis.supportiveCoachingText = coaching
            analysis.providerSecondary = .anthropic
            AppConsole.analysis.notice("Anthropic coaching attached")
        } catch {
            AppConsole.analysis.error("Anthropic coaching failed: \(error.localizedDescription, privacy: .public)")
        }

        return analysis
    }
}
