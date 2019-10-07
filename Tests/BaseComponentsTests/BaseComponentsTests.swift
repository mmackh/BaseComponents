import XCTest
@testable import BaseComponents

final class BaseComponentsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BaseComponents().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
