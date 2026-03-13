import Foundation

final class MockAIAnalysisService: AIAnalysisService {
    func analyze(request: AnalysisRequest) async throws -> SpaceAnalysis {
        let breakdown = ScoreEngine.breakdown(for: request.spaceType, mode: request.mode)
        let roomName = request.customSpaceName?.isEmpty == false ? request.customSpaceName! : request.spaceType.displayName
        let bigProblems = biggestProblems(for: request.spaceType, mode: request.mode)
        let opportunities = bestOpportunities(for: request.spaceType, mode: request.mode)
        let stagingAdvice = request.mode == .stageForSelling ? makeStagingAdvice(score: breakdown.stagingReadinessScore) : nil

        return SpaceAnalysis(
            id: UUID(),
            projectID: request.projectID,
            providerPrimary: .mock,
            providerSecondary: request.mode == .stageForSelling ? .mock : nil,
            rawInputSummary: "Single photo analysis for \(roomName) in \(request.mode.longLabel.lowercased()) mode.",
            score: breakdown,
            summaryText: summary(for: roomName, score: breakdown.totalScore, mode: request.mode),
            supportiveCoachingText: supportiveCoaching(for: roomName, mode: request.mode),
            biggestProblems: bigProblems,
            bestOpportunities: opportunities,
            resetPlan: makePlan(spaceType: request.spaceType, mode: request.mode),
            estimatedResetMinutes: request.mode == .stageForSelling ? 35 : 28,
            confidenceNotes: request.imageData == nil ? ["Using seeded sample imagery. Replace with your own photo for a sharper read."] : [],
            budgetRecommendations: [],
            visualizationConcept: nil,
            stagingAdvice: stagingAdvice,
            createdAt: .now
        )
    }

    private func summary(for roomName: String, score: Int, mode: ProjectMode) -> String {
        switch mode {
        case .organize:
            "Your \(roomName.lowercased()) already has a workable foundation. A few intentional edits can make it calmer, easier to maintain, and much faster to use."
        case .stageForSelling:
            "This \(roomName.lowercased()) can present more spaciously with a lighter visual load, fewer personal cues, and a tighter edit before photos or showings."
        case .compareProgress:
            "You’ve already improved the feel of this \(roomName.lowercased()). The next pass is mostly about refinement, consistency, and making the wins easier to keep."
        }
    }

    private func supportiveCoaching(for roomName: String, mode: ProjectMode) -> String {
        switch mode {
        case .organize:
            "Nothing here needs to be perfect. Focus on one zone at a time, remove the obvious friction first, and let the space earn better systems as you go."
        case .stageForSelling:
            "Think edit first, style second. Buyers and guests read openness quickly, so small reductions in visual noise often create the biggest emotional lift."
        case .compareProgress:
            "You’ve already done the hard part by starting. This round is about reinforcing what worked and trimming the pieces that still slow the space down."
        }
    }

    private func biggestProblems(for spaceType: SpaceType, mode: ProjectMode) -> [String] {
        if mode == .stageForSelling {
            return [
                "Too many visible everyday items pull focus from the storage itself.",
                "Color and container styles feel a little mixed, which makes the area read busier.",
                "The front-facing surfaces could look more open with a quicker edit."
            ]
        }

        switch spaceType {
        case .pantry:
            return [
                "Open packaging makes the shelves feel visually crowded.",
                "Snack and meal-prep items are not fully zoned yet.",
                "Shelf depth is available, but not being used intentionally."
            ]
        case .closet:
            return [
                "Hanger inconsistency makes the section feel less cohesive.",
                "Folded and hanging storage compete for the same visual zone.",
                "Top shelf items are harder to access than they need to be."
            ]
        case .drawer:
            return [
                "Small items can shift out of place between uses.",
                "Similar tools are grouped too loosely.",
                "There’s room for a cleaner top layer."
            ]
        case .bathroom:
            return [
                "Daily-use items are fighting with backup stock.",
                "Countertop styling feels busier than necessary.",
                "Under-sink zones could work harder."
            ]
        case .garage:
            return [
                "Large items are visually competing without clear categories.",
                "Vertical space is available but underused.",
                "Fast-grab items need a clearer home."
            ]
        case .custom:
            return [
                "The space would benefit from stronger category boundaries.",
                "The most-used items are not the easiest ones to reach.",
                "Visual repetition is missing, which makes the area feel fuller."
            ]
        }
    }

    private func bestOpportunities(for spaceType: SpaceType, mode: ProjectMode) -> [String] {
        if mode == .stageForSelling {
            return [
                "Reduce visible volume by about 20 percent before photos.",
                "Swap mismatched containers for a simpler repeating set.",
                "Create one clean focal zone that feels intentionally styled."
            ]
        }

        switch spaceType {
        case .pantry:
            return ["Create snack zones", "Use clear containment", "Label the most frequently reached items"]
        case .closet:
            return ["Unify hangers", "Reserve one shelf for edited storage", "Use matching bins on upper shelves"]
        case .drawer:
            return ["Introduce modular trays", "Create one category per lane", "Keep only the daily essentials up top"]
        case .bathroom:
            return ["Use trays for daily products", "Separate overflow stock", "Hide the least attractive packaging"]
        case .garage:
            return ["Move tools vertical", "Label bins by use", "Keep the floor line visually open"]
        case .custom:
            return ["Repeat one container style", "Prioritize quick-access zones", "Edit duplicates first"]
        }
    }

    private func makePlan(spaceType: SpaceType, mode: ProjectMode) -> [ResetPlanStep] {
        let details: [(String, String, Int, String)]
        if mode == .stageForSelling {
            details = [
                ("Edit visible clutter", "Pull out the least essential items until the shelves and surfaces can breathe.", 8, "Creates immediate visual calm."),
                ("Remove personal cues", "Hide photos, notes, and niche items that make the area feel highly personalized.", 6, "Helps the space feel broader and more market-ready."),
                ("Repeat one finish", "Use a tighter mix of baskets, trays, or hangers so the space reads more intentionally.", 10, "Boosts polish quickly."),
                ("Style one anchor moment", "Leave one tidy, lightly styled zone to signal capacity and order.", 8, "Adds a premium final impression.")
            ]
        } else {
            details = [
                ("Pull the easy exits first", "Remove expired, duplicate, or low-value items before reorganizing anything else.", 6, "Creates space to work."),
                ("Build clear zones", "Group like-with-like based on how the space gets used day to day.", 9, "Improves visibility and speed."),
                ("Add supportive containers", "Use bins, risers, trays, or dividers to keep categories from drifting.", 8, "Raises usability with less upkeep."),
                ("Label the friction points", "Name the spots that tend to slip so the system stays easier to reset.", 5, "Helps the progress stick.")
            ]
        }

        return details.enumerated().map { index, item in
            ResetPlanStep(
                id: UUID(),
                order: index + 1,
                title: item.0,
                detail: item.1,
                estimatedMinutes: item.2,
                impactNote: item.3
            )
        }
    }

    private func makeStagingAdvice(score: Int) -> StagingAdvice {
        StagingAdvice(
            readinessScore: score,
            removeItems: ["Bulky appliances", "Highly personal decor", "Overflow baskets with mixed items"],
            hideItems: ["Visible cords", "Pet supplies", "Extra toiletries or cleaning tools"],
            addItems: ["Neutral basket pair", "Simple tray", "Soft greenery or one restrained accent"],
            quickWins: ["Clear 20 percent of visible volume", "Match the front row of containers", "Wipe reflective surfaces before photos"],
            showingDayChecklist: [
                ChecklistItem(id: UUID(), title: "Counters cleared", isDone: false, priority: 1),
                ChecklistItem(id: UUID(), title: "Personal items tucked away", isDone: false, priority: 1),
                ChecklistItem(id: UUID(), title: "Lights on and bins aligned", isDone: false, priority: 2)
            ]
        )
    }
}
