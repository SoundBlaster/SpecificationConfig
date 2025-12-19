import Foundation
import SpecificationCore

final class DemoContextProvider: ContextProviding {
    static let shared = DemoContextProvider()

    private let launchDate = Date()
    private var reloadCount = 0
    private var nightOverride: Bool?

    private let calendar = Calendar(identifier: .gregorian)

    private init() {}

    func recordReload() {
        reloadCount += 1
    }

    func toggleNightOverride() {
        if let override = nightOverride {
            nightOverride = override ? false : nil
        } else {
            nightOverride = true
        }
    }

    func setNightOverride(_ value: Bool?) {
        nightOverride = value
    }

    private var isNighttime: Bool {
        if let override = nightOverride {
            return override
        }
        let hour = calendar.component(.hour, from: Date())
        return hour < 6 || hour >= 19
    }

    var contextSummary: String {
        let reloads = reloadCount
        return isNighttime
            ? "Nighttime · Reloads: \(reloads)"
            : "Daytime · Reloads: \(reloads)"
    }

    var isNightOverrideActive: Bool {
        nightOverride != nil
    }

    var isNightModeActive: Bool {
        isNighttime
    }

    func currentContext() -> EvaluationContext {
        EvaluationContext(
            currentDate: Date(),
            launchDate: launchDate,
            userData: [:],
            counters: ["reloadCount": reloadCount],
            events: [:],
            flags: [
                "nightTime": isNighttime,
                "sleepOverride": nightOverride ?? false,
            ],
            segments: []
        )
    }
}
