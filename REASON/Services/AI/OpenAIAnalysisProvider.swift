import Foundation

@MainActor
protocol OpenAIAnalyzing {
    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis
}

final class OpenAIAnalysisProvider: OpenAIAnalyzing {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        guard config.hasOpenAIKey else {
            throw AppError.configuration("OpenAI is not configured yet. Add OPENAI_API_KEY to enable the live provider.")
        }

        throw AppError.unavailable("OpenAI structured vision parsing still needs the final prompt contract and response decoding.")
    }
}
