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
            // Re-throw so the user sees the real error rather than silent mock fallback
            throw error
        }
    }
}
