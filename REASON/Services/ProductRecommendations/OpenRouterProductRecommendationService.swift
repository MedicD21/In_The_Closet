import Foundation

@MainActor
final class OpenRouterProductRecommendationService: ProductRecommendationService {
    private let client: OpenRouterClient
    private let linkBuilder: AmazonAffiliateLinkBuilder
    private let qualityMode: AIQualityMode

    // Stage 3 — product recommendation models (confirmed available 2026-03)
    private var model: String {
        switch qualityMode {
        case .free:        "meta-llama/llama-3.3-70b-instruct:free"
        case .budget:      "nousresearch/hermes-3-llama-3.1-405b:free"
        case .highQuality: "nousresearch/hermes-3-llama-3.1-405b:free"
        }
    }

    init(client: OpenRouterClient, linkBuilder: AmazonAffiliateLinkBuilder, qualityMode: AIQualityMode = .free) {
        self.client = client
        self.linkBuilder = linkBuilder
        self.qualityMode = qualityMode
    }

    func recommendations(for context: RecommendationContext) async -> [BudgetRecommendation] {
        guard !client.apiKey.isEmpty else { return curatedFallback(for: context) }
        do {
            return try await aiRecommendations(for: context)
        } catch {
            return curatedFallback(for: context)
        }
    }

    // MARK: - Stage 3: AI-driven recommendations

    private func aiRecommendations(for context: RecommendationContext) async throws -> [BudgetRecommendation] {
        let promptText = buildPrompt(for: context)
        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 1000,
            "response_format": ["type": "json_object"],
            "messages": [["role": "user", "content": promptText]]
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let result = try await client.chat(payload: payloadData)
        return try parseRecommendations(result, context: context)
    }

    private func buildPrompt(for context: RecommendationContext) -> String {
        let problems = context.problems.isEmpty
            ? ["general clutter", "poor zoning"]
            : context.problems
        let opps = context.opportunities.prefix(3).joined(separator: "; ")

        return """
        Recommend organization products for a \(context.spaceType.displayName.lowercased()) reset.
        Problems: \(problems.joined(separator: "; "))
        \(opps.isEmpty ? "" : "Opportunities: \(opps)")
        Mode: \(context.mode.longLabel)

        Do NOT invent specific product names or brands. Return Amazon search terms only.
        Each item needs: search_term, category (containment|labels|risers|baskets|stagingDecor|closetTools|drawerOrganizers), reason, estimated_price (integer USD).

        Return JSON:
        {
          "budget": [<2 items>],
          "mid": [<3 items>],
          "premium": [<4 items>]
        }
        """
    }

    private func parseRecommendations(_ content: String, context: RecommendationContext) throws -> [BudgetRecommendation] {
        let normalizedContent = JSONResponseSanitizer.clean(content)
        guard
            let data = normalizedContent.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw AppError.parsing("Could not parse product recommendations JSON.")
        }

        let tierDefinitions: [(BudgetTier, String, Decimal, String)] = [
            (.budget, "budget", 55, "Fast essentials that create the clearest lift per dollar."),
            (.mid, "mid", 135, "A cleaner, more durable setup with better visual consistency."),
            (.premium, "premium", 295, "The most cohesive and polished version of the reset.")
        ]

        return tierDefinitions.compactMap { tier, key, totalSpend, whyItHelps in
            guard let items = json[key] as? [[String: Any]], !items.isEmpty else { return nil }
            let products = items.enumerated().map { idx, item -> ProductRecommendation in
                let fallbackKeywords = context.spaceType.searchKeywords
                let searchTerm = item["search_term"] as? String
                    ?? fallbackKeywords[safe: idx]
                    ?? "organization bins"
                let rawCategory = item["category"] as? String ?? "containment"
                let reason = item["reason"] as? String ?? "Supports organized storage."
                let price = Decimal(item["estimated_price"] as? Int ?? (15 + idx * 8))

                return ProductRecommendation(
                    id: UUID(),
                    analysisID: context.analysisID,
                    category: RecommendationCategory(rawValue: rawCategory) ?? .containment,
                    budgetTier: tier,
                    itemTitle: searchTerm.capitalized,
                    amazonURL: linkBuilder.searchURL(for: searchTerm),
                    asin: nil,
                    imageURL: nil,
                    price: price,
                    reasonText: reason,
                    expectedImpact: "Supports cleaner zoning and reduced visual spill.",
                    retailer: .amazon
                )
            }

            return BudgetRecommendation(
                id: UUID(),
                budgetTier: tier,
                estimatedTotalSpend: totalSpend,
                whyItHelps: whyItHelps,
                expectedImpactOnScore: "Targets specific issues found in your \(context.spaceType.displayName.lowercased()).",
                items: products
            )
        }
    }

    // MARK: - Curated fallback

    private func curatedFallback(for context: RecommendationContext) -> [BudgetRecommendation] {
        let tierDefinitions: [(BudgetTier, Decimal, String)] = [
            (.budget, 55, "Fast essentials that create the clearest lift per dollar."),
            (.mid, 135, "A cleaner, more durable setup with better visual consistency."),
            (.premium, 295, "The most cohesive, polished version of the reset.")
        ]

        return tierDefinitions.map { tier, total, explanation in
            let keywords = context.spaceType.searchKeywords
            let count = tier == .budget ? 2 : tier == .mid ? 3 : 4
            let cats: [RecommendationCategory] = [.containment, .labels, .risers, .baskets]
            let items = keywords.prefix(count).enumerated().map { idx, query -> ProductRecommendation in
                ProductRecommendation(
                    id: UUID(),
                    analysisID: context.analysisID,
                    category: cats[idx % cats.count],
                    budgetTier: tier,
                    itemTitle: query.capitalized,
                    amazonURL: linkBuilder.searchURL(for: query),
                    asin: nil,
                    imageURL: nil,
                    price: Decimal(12 + (idx * 7)),
                    reasonText: "Useful for \(context.spaceType.displayName.lowercased()) resets.",
                    expectedImpact: "Cleaner categories and faster resets.",
                    retailer: .amazon
                )
            }
            return BudgetRecommendation(
                id: UUID(),
                budgetTier: tier,
                estimatedTotalSpend: total,
                whyItHelps: explanation,
                expectedImpactOnScore: "Immediate usability gains.",
                items: Array(items)
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
