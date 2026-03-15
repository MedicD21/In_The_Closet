import Foundation

@MainActor
final class UnavailableAIAnalysisService: AIAnalysisService {
    private let message: String

    init(message: String) {
        self.message = message
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        throw AppError.configuration(message)
    }
}
