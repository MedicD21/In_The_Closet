import XCTest
@testable import REASON

final class ScoreEngineTests: XCTestCase {
    func testCompareModeImprovesBaselineScore() {
        let organize = ScoreEngine.breakdown(for: .pantry, mode: .organize)
        let compare = ScoreEngine.breakdown(for: .pantry, mode: .compareProgress)

        XCTAssertGreaterThan(compare.totalScore, organize.totalScore)
    }

    func testScoreInterpreterRangesStayReadable() {
        XCTAssertEqual(ScoreInterpreter.label(for: 30), "Overloaded, but fixable")
        XCTAssertEqual(ScoreInterpreter.label(for: 50), "Functional, still stressful")
        XCTAssertEqual(ScoreInterpreter.label(for: 68), "Solid with room to improve")
        XCTAssertEqual(ScoreInterpreter.label(for: 82), "Strong and user-friendly")
        XCTAssertEqual(ScoreInterpreter.label(for: 96), "Highly optimized and calm")
    }
}
