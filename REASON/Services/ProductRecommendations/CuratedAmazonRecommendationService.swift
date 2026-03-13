import Foundation

final class CuratedAmazonRecommendationService: ProductRecommendationService {
    private let linkBuilder: AmazonAffiliateLinkBuilder

    init(linkBuilder: AmazonAffiliateLinkBuilder) {
        self.linkBuilder = linkBuilder
    }

    func recommendations(for context: RecommendationContext) async -> [BudgetRecommendation] {
        let tierDefinitions: [(BudgetTier, Decimal, String)] = [
            (.budget, 55, "Fast essentials that create the clearest lift per dollar."),
            (.mid, 135, "A cleaner, more durable setup with better visual consistency."),
            (.premium, 295, "The most cohesive, polished, and staging-friendly version of the reset.")
        ]

        return tierDefinitions.map { tier, total, explanation in
            BudgetRecommendation(
                id: UUID(),
                budgetTier: tier,
                estimatedTotalSpend: total,
                whyItHelps: explanation,
                expectedImpactOnScore: expectedImpact(for: tier, mode: context.mode),
                items: makeItems(for: context.spaceType, tier: tier, analysisID: context.analysisID)
            )
        }
    }

    private func makeItems(for spaceType: SpaceType, tier: BudgetTier, analysisID: UUID) -> [ProductRecommendation] {
        let baseQueries = spaceType.searchKeywords

        return baseQueries.prefix(tier == .budget ? 2 : tier == .mid ? 3 : 4).enumerated().map { index, query in
            ProductRecommendation(
                id: UUID(),
                analysisID: analysisID,
                category: category(for: index),
                budgetTier: tier,
                itemTitle: query.capitalized,
                amazonURL: linkBuilder.searchURL(for: query),
                asin: nil,
                imageURL: nil,
                price: price(for: tier, index: index),
                reasonText: reason(for: spaceType, query: query),
                expectedImpact: impact(for: query),
                retailer: .amazon
            )
        }
    }

    private func category(for index: Int) -> RecommendationCategory {
        let mapping: [RecommendationCategory] = [.containment, .labels, .risers, .baskets]
        return mapping[index % mapping.count]
    }

    private func price(for tier: BudgetTier, index: Int) -> Decimal {
        switch tier {
        case .budget:
            Decimal(12 + (index * 7))
        case .mid:
            Decimal(22 + (index * 12))
        case .premium:
            Decimal(35 + (index * 18))
        }
    }

    private func reason(for spaceType: SpaceType, query: String) -> String {
        "Useful for \(spaceType.displayName.lowercased()) resets because it supports cleaner zoning and reduces visual spill without adding complexity."
    }

    private func impact(for query: String) -> String {
        "Supports clearer categories and faster resets by introducing \(query.lowercased())."
    }

    private func expectedImpact(for tier: BudgetTier, mode: ProjectMode) -> String {
        switch (tier, mode) {
        case (.budget, .stageForSelling):
            "A sharper first impression with a lighter visible load."
        case (.budget, _):
            "Immediate usability gains from the most-needed basics."
        case (.mid, .stageForSelling):
            "A noticeably more cohesive presentation for photos and showings."
        case (.mid, _):
            "Stronger structure, cleaner repetition, and easier maintenance."
        case (.premium, .stageForSelling):
            "The most elevated and listing-ready presentation."
        case (.premium, _):
            "The calmest, most finished version of the system."
        }
    }
}
