@testable import SpecificationConfig
import XCTest

final class PathUtilsTests: XCTestCase {
    func testJoinedPathFromRoot() {
        XCTAssertEqual(PathUtils.joinedPath("/", "config.json"), "/config.json")
    }

    func testJoinedPathFromDirectory() {
        XCTAssertEqual(PathUtils.joinedPath("/tmp", "config.json"), "/tmp/config.json")
        XCTAssertEqual(PathUtils.joinedPath("/tmp/", "config.json"), "/tmp/config.json")
    }
}
