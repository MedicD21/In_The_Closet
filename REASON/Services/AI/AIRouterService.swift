import Foundation

@MainActor
final class AIRouterService: AIAnalysisService {
    private let primary: AIAnalysisService
    private let fallback: AIAnalysisService

    init(primary: AIAnalysisService, fallback: AIAnalysisService) {
        self.primary = primary
        self.fallback = fallback
    }

    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        do {
            return try await primary.analyze(request: request)
        } catch {
            AppConsole.analysis.error("primary analysis provider failed: \(error.localizedDescription, privacy: .public)")
            AppConsole.analysis.notice("falling back to secondary analysis provider")
            return try await fallback.analyze(request: request)
        }
    }
}
