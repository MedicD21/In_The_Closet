import Foundation

struct AnalysisRequest: Hashable {
    var projectID: UUID?
    var spaceType: SpaceType
    var customSpaceName: String?
    var mode: ProjectMode
    var imageData: Data?
    var previousAnalysis: SpaceAnalysis?
}

@MainActor
protocol AIAnalysisService {
    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis
}
