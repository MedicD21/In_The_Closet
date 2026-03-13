import Foundation

enum ScoreInterpreter {
    static func label(for score: Int) -> String {
        switch score {
        case ..<40: "Overloaded, but fixable"
        case ..<60: "Functional, still stressful"
        case ..<75: "Solid with room to improve"
        case ..<90: "Strong and user-friendly"
        default: "Highly optimized and calm"
        }
    }
}

enum ScoreEngine {
    static func breakdown(for spaceType: SpaceType, mode: ProjectMode) -> ScoreBreakdown {
        let base: Int
        switch spaceType {
        case .pantry: base = 58
        case .closet: base = 62
        case .drawer: base = 68
        case .bathroom: base = 56
        case .garage: base = 48
        case .custom: base = 60
        }

        let modeOffset: Int
        switch mode {
        case .organize: modeOffset = 0
        case .stageForSelling: modeOffset = -4
        case .compareProgress: modeOffset = 8
        }

        let total = max(26, min(94, base + modeOffset))
        return ScoreBreakdown(
            totalScore: total,
            clutterScore: clamp(total - 8),
            accessibilityScore: clamp(total + 4),
            zoningScore: clamp(total - 3),
            visibilityScore: clamp(total - 1),
            shelfEfficiencyScore: clamp(total + 2),
            visualCalmScore: clamp(total - 5),
            stagingReadinessScore: clamp(total - (mode == .stageForSelling ? 0 : 6))
        )
    }

    private static func clamp(_ score: Int) -> Int {
        max(0, min(100, score))
    }
}
