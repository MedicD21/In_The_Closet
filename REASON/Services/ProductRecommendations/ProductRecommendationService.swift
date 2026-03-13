import Foundation

struct RecommendationContext: Hashable {
    let spaceType: SpaceType
    let mode: ProjectMode
    let analysisID: UUID
}

@MainActor
protocol ProductRecommendationService {
    func recommendations(for context: RecommendationContext) async -> [BudgetRecommendation]
}
