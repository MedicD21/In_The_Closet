import XCTest
@testable import REASON

final class AmazonAffiliateLinkBuilderTests: XCTestCase {
    func testSearchURLIncludesAssociateTagAndQuery() {
        let builder = AmazonAffiliateLinkBuilder(
            baseURL: URL(string: "https://www.amazon.com")!,
            associateTag: "reason-20"
        )

        let url = builder.searchURL(for: "clear pantry bins")

        XCTAssertEqual(url.host, "www.amazon.com")
        XCTAssertTrue(url.absoluteString.contains("k=clear%20pantry%20bins"))
        XCTAssertTrue(url.absoluteString.contains("tag=reason-20"))
    }
}
