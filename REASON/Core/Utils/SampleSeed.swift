import Foundation

enum SampleSeed {
    static func projects(for userID: UUID) -> [SpaceProject] {
        let projectID = UUID()
        let beforeImage = ProjectImage(
            id: UUID(),
            projectID: projectID,
            userID: userID,
            imageType: .before,
            storagePath: nil,
            remoteURL: nil,
            localAssetName: "PantrySample",
            createdAt: .now
        )

        var analysis = SpaceAnalysis(
            id: UUID(),
            projectID: projectID,
            providerPrimary: .mock,
            providerSecondary: .mock,
            rawInputSummary: "Seeded pantry analysis",
            score: ScoreBreakdown(
                totalScore: 64,
                clutterScore: 58,
                accessibilityScore: 69,
                zoningScore: 62,
                visibilityScore: 63,
                shelfEfficiencyScore: 67,
                visualCalmScore: 57,
                stagingReadinessScore: 54
            ),
            summaryText: "A few simple container and zoning changes can make this pantry noticeably calmer and easier to use.",
            supportiveCoachingText: "You do not need a full makeover to feel better here. A tighter front row and clearer categories will go a long way.",
            biggestProblems: [
                "Open packaging creates visual clutter.",
                "Snack and meal zones blend together.",
                "Shelf depth is not working hard enough."
            ],
            bestOpportunities: [
                "Contain snacks in matching bins.",
                "Use labels for quick returns.",
                "Introduce one or two risers."
            ],
            resetPlan: [
                ResetPlanStep(id: UUID(), order: 1, title: "Edit out duplicates", detail: "Remove anything expired or unlikely to get used.", estimatedMinutes: 6, impactNote: "Creates working room quickly."),
                ResetPlanStep(id: UUID(), order: 2, title: "Build zones", detail: "Create one shelf story for snacks, breakfast, and backstock.", estimatedMinutes: 8, impactNote: "Improves visibility."),
                ResetPlanStep(id: UUID(), order: 3, title: "Contain the drift", detail: "Use bins and risers to stop categories from spilling.", estimatedMinutes: 8, impactNote: "Keeps the space stable."),
                ResetPlanStep(id: UUID(), order: 4, title: "Label the friction points", detail: "Name the places that usually unravel first.", estimatedMinutes: 5, impactNote: "Helps the reset stick.")
            ],
            estimatedResetMinutes: 27,
            confidenceNotes: [],
            budgetRecommendations: [],
            visualizationConcept: VisualizationConcept(
                projectedImprovedScore: 78,
                promptSummary: "Elevated pantry concept with matching bins, labels, and edited front rows.",
                whatImproved: ["Cleaner lines", "Better snack zoning", "Clearer shelf hierarchy"],
                stillNeedsWork: ["Family habits need a labeled return zone"],
                conceptCaption: "Concept preview showing a calmer pantry direction."
            ),
            stagingAdvice: nil,
            createdAt: .now.addingTimeInterval(-86_400 * 4)
        )

        let linkBuilder = AmazonAffiliateLinkBuilder(baseURL: URL(string: "https://www.amazon.com")!, associateTag: "yourtag-20")
        analysis.budgetRecommendations = [
            BudgetRecommendation(
                id: UUID(),
                budgetTier: .budget,
                estimatedTotalSpend: 54,
                whyItHelps: "Fast essentials that bring the most visible pantry relief right away.",
                expectedImpactOnScore: "Adds quick structure and easier reset points.",
                items: [
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .containment,
                        budgetTier: .budget,
                        itemTitle: "Clear Pantry Bins",
                        amazonURL: linkBuilder.searchURL(for: "clear pantry bins"),
                        asin: nil,
                        imageURL: nil,
                        price: 24,
                        reasonText: "Creates clean visual boundaries for snack and baking zones.",
                        expectedImpact: "Improves clutter and zoning.",
                        retailer: .amazon
                    ),
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .labels,
                        budgetTier: .budget,
                        itemTitle: "Pantry Labels",
                        amazonURL: linkBuilder.searchURL(for: "pantry labels"),
                        asin: nil,
                        imageURL: nil,
                        price: 14,
                        reasonText: "Helps the reset stick after the first pass.",
                        expectedImpact: "Improves visibility and maintenance.",
                        retailer: .amazon
                    )
                ]
            ),
            BudgetRecommendation(
                id: UUID(),
                budgetTier: .mid,
                estimatedTotalSpend: 132,
                whyItHelps: "Adds more durable containment and better shelf hierarchy.",
                expectedImpactOnScore: "Creates a cleaner, more polished pantry system.",
                items: [
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .containment,
                        budgetTier: .mid,
                        itemTitle: "Acrylic Pantry Container Set",
                        amazonURL: linkBuilder.searchURL(for: "acrylic pantry container set"),
                        asin: nil,
                        imageURL: nil,
                        price: 58,
                        reasonText: "Repeats one finish across the most visible shelves.",
                        expectedImpact: "Improves visual calm.",
                        retailer: .amazon
                    ),
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .risers,
                        budgetTier: .mid,
                        itemTitle: "Expandable Shelf Risers",
                        amazonURL: linkBuilder.searchURL(for: "expandable shelf risers"),
                        asin: nil,
                        imageURL: nil,
                        price: 28,
                        reasonText: "Uses vertical space more intentionally.",
                        expectedImpact: "Improves shelf efficiency.",
                        retailer: .amazon
                    )
                ]
            ),
            BudgetRecommendation(
                id: UUID(),
                budgetTier: .premium,
                estimatedTotalSpend: 286,
                whyItHelps: "Builds the most cohesive, staging-friendly final look.",
                expectedImpactOnScore: "Adds the calmest, most elevated finish.",
                items: [
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .containment,
                        budgetTier: .premium,
                        itemTitle: "Matching Pantry Canister Set",
                        amazonURL: linkBuilder.searchURL(for: "matching pantry canister set"),
                        asin: nil,
                        imageURL: nil,
                        price: 92,
                        reasonText: "Gives the front-facing shelves a more editorial finish.",
                        expectedImpact: "Improves calm and readiness.",
                        retailer: .amazon
                    ),
                    ProductRecommendation(
                        id: UUID(),
                        analysisID: analysis.id,
                        category: .baskets,
                        budgetTier: .premium,
                        itemTitle: "Natural Water Hyacinth Baskets",
                        amazonURL: linkBuilder.searchURL(for: "water hyacinth pantry baskets"),
                        asin: nil,
                        imageURL: nil,
                        price: 48,
                        reasonText: "Softens overflow zones while keeping categories hidden.",
                        expectedImpact: "Improves clutter and styling.",
                        retailer: .amazon
                    )
                ]
            )
        ]

        let checklist = StagingChecklist(
            id: UUID(),
            projectID: projectID,
            checklistItems: [
                ChecklistItem(id: UUID(), title: "Align front labels", isDone: false, priority: 1),
                ChecklistItem(id: UUID(), title: "Clear countertop overflow", isDone: false, priority: 2)
            ],
            createdAt: .now
        )

        let project = SpaceProject(
            id: projectID,
            userID: userID,
            title: "Pantry Reset",
            spaceType: .pantry,
            customSpaceName: nil,
            mode: .organize,
            status: .ready,
            currentScore: analysis.score.totalScore,
            createdAt: .now.addingTimeInterval(-86_400 * 4),
            updatedAt: .now.addingTimeInterval(-3_200),
            archivedAt: nil,
            images: [beforeImage],
            analyses: [analysis],
            comparisons: [],
            savedProducts: analysis.budgetRecommendations.flatMap(\.items),
            stagingChecklist: checklist
        )

        return [project]
    }
}
