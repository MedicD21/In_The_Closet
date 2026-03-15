import Foundation

struct RecommendationContext: Hashable {
    let spaceType: SpaceType
    let mode: ProjectMode
    let analysisID: UUID
    var problems: [String] = []
    var opportunities: [String] = []
}

@MainActor
protocol ProductRecommendationService {
    func recommendations(for context: RecommendationContext) async throws -> [BudgetRecommendation]
}
