import Foundation
import SpecificationConfig

final class DemoContextProvider: ContextProviding {
    static let shared = DemoContextProvider()

    private let launchDate = Date()
    private var reloadCount = 0
    private var nightOverride: Bool?

    private let calendar = Calendar(identifier: .gregorian)

    private init() {}
}
