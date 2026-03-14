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
            print("⚠️ [AIRouterService] Primary provider failed: \(error)")
            return try await fallback.analyze(request: request)
        }
    }
}
