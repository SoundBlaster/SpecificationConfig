import XCTest
@testable import ConfigPetApp

final class ConfigPetAppTests: XCTestCase {
    func testAppConfigProfileHasBindings() {
        XCTAssertEqual(AppConfig.profile.bindings.count, 2)
    }
}
