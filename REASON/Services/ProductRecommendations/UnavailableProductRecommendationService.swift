import Foundation

@MainActor
final class UnavailableProductRecommendationService: ProductRecommendationService {
    private let message: String

    init(message: String) {
        self.message = message
    }

    func recommendations(for context: RecommendationContext) async throws -> [BudgetRecommendation] {
        throw AppError.configuration(message)
    }
}
