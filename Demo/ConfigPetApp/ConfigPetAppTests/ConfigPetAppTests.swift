@testable import ConfigPetApp
import XCTest

final class ConfigPetAppTests: XCTestCase {
    func testAppConfigProfileHasBindings() {
        XCTAssertEqual(AppConfig.profile.bindings.count, 2)
    }
}
