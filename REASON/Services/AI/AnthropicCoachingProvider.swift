import Foundation

@MainActor
protocol AnthropicCoachingProviding {
    func supportiveCoaching(for request: AnalysisRequest, analysis: SpaceAnalysis) async throws -> String
}

final class AnthropicCoachingProvider: AnthropicCoachingProviding {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    func supportiveCoaching(for request: AnalysisRequest, analysis: SpaceAnalysis) async throws -> String {
        guard config.hasAnthropicKey else {
            throw AppError.configuration("Anthropic is not configured yet. Add ANTHROPIC_API_KEY to enable the coaching layer.")
        }

        throw AppError.unavailable("Anthropic coaching refinement still needs the final prompt and parser implementation.")
    }
}
