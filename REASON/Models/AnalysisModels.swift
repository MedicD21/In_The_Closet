import Foundation

enum ScoreCategory: String, Codable, CaseIterable, Identifiable {
    case clutter
    case accessibility
    case zoning
    case visibility
    case shelfEfficiency
    case visualCalm
    case stagingReadiness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clutter: "Clutter"
        case .accessibility: "Accessibility"
        case .zoning: "Zoning"
        case .visibility: "Visibility"
        case .shelfEfficiency: "Shelf Efficiency"
        case .visualCalm: "Visual Calm"
        case .stagingReadiness: "Staging Readiness"
        }
    }
}

struct ScoreBreakdown: Codable, Hashable {
    var totalScore: Int
    var clutterScore: Int
    var accessibilityScore: Int
    var zoningScore: Int
    var visibilityScore: Int
    var shelfEfficiencyScore: Int
    var visualCalmScore: Int
    var stagingReadinessScore: Int

    subscript(category: ScoreCategory) -> Int {
        switch category {
        case .clutter: clutterScore
        case .accessibility: accessibilityScore
        case .zoning: zoningScore
        case .visibility: visibilityScore
        case .shelfEfficiency: shelfEfficiencyScore
        case .visualCalm: visualCalmScore
        case .stagingReadiness: stagingReadinessScore
        }
    }

    var metrics: [ScoreMetric] {
        ScoreCategory.allCases.map { category in
            ScoreMetric(category: category, score: self[category])
        }
    }
}

struct ScoreMetric: Identifiable, Hashable {
    let id = UUID()
    let category: ScoreCategory
    let score: Int
}

struct ResetPlanStep: Identifiable, Codable, Hashable {
    let id: UUID
    var order: Int
    var title: String
    var detail: String
    var estimatedMinutes: Int
    var impactNote: String
}

struct ProductRecommendation: Identifiable, Codable, Hashable {
    let id: UUID
    var analysisID: UUID?
    var category: RecommendationCategory
    var budgetTier: BudgetTier
    var itemTitle: String
    var amazonURL: URL
    var asin: String?
    var imageURL: URL?
    var price: Decimal?
    var reasonText: String
    var expectedImpact: String
    var retailer: Retailer
}

struct BudgetRecommendation: Identifiable, Codable, Hashable {
    let id: UUID
    var budgetTier: BudgetTier
    var estimatedTotalSpend: Decimal
    var whyItHelps: String
    var expectedImpactOnScore: String
    var items: [ProductRecommendation]
}

struct VisualizationConcept: Codable, Hashable {
    var projectedImprovedScore: Int
    var promptSummary: String
    var whatImproved: [String]
    var stillNeedsWork: [String]
    var conceptCaption: String
    var generatedImageURL: URL?
}

struct StagingAdvice: Codable, Hashable {
    var readinessScore: Int
    var removeItems: [String]
    var hideItems: [String]
    var addItems: [String]
    var quickWins: [String]
    var showingDayChecklist: [ChecklistItem]
}

struct SpaceAnalysis: Identifiable, Codable, Hashable {
    let id: UUID
    var projectID: UUID?
    var providerPrimary: AIProvider
    var providerSecondary: AIProvider?
    var rawInputSummary: String
    var score: ScoreBreakdown
    var summaryText: String
    var supportiveCoachingText: String
    var biggestProblems: [String]
    var bestOpportunities: [String]
    var resetPlan: [ResetPlanStep]
    var estimatedResetMinutes: Int
    var confidenceNotes: [String]
    var budgetRecommendations: [BudgetRecommendation]
    var visualizationConcept: VisualizationConcept?
    var stagingAdvice: StagingAdvice?
    var createdAt: Date
}

struct MetricDelta: Identifiable, Codable, Hashable {
    let id: UUID
    var category: ScoreCategory
    var beforeScore: Int
    var afterScore: Int

    var delta: Int { afterScore - beforeScore }
}

struct ProjectComparison: Identifiable, Codable, Hashable {
    let id: UUID
    var projectID: UUID
    var beforeAnalysisID: UUID
    var afterAnalysisID: UUID
    var scoreDelta: Int
    var summaryText: String
    var metricDeltas: [MetricDelta]
    var createdAt: Date
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
    var priority: Int
}

struct StagingChecklist: Identifiable, Codable, Hashable {
    let id: UUID
    var projectID: UUID
    var checklistItems: [ChecklistItem]
    var createdAt: Date
}
