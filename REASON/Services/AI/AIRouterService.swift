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
            var fallbackAnalysis = try await fallback.analyze(request: request)
            fallbackAnalysis.confidenceNotes.append("Using built-in scaffold — live provider unavailable: \(error.localizedDescription)")
            return fallbackAnalysis
        }
    }
}
