import Foundation
import SpecificationConfig

final class DemoContextProvider: ContextProviding {
    static let shared = DemoContextProvider()

    private let launchDate = Date()
    private let lock = NSLock()
    private var reloadCount = 0
    private var nightOverride: Bool?
    private var sleepOverride: Bool?

    private let calendar = Calendar(identifier: .gregorian)

    private init() {}

    func recordReload() {
        withLock {
            reloadCount += 1
        }
    }

    func toggleNightOverride() {
        withLock {
            if let override = nightOverride {
                nightOverride = override ? false : nil
            } else {
                nightOverride = true
            }
        }
    }

    func setNightOverride(_ value: Bool?) {
        withLock {
            nightOverride = value
        }
    }

    func setSleepOverride(_ value: Bool?) {
        withLock {
            sleepOverride = value
        }
    }

    private var isNighttime: Bool {
        let override = withLock { nightOverride }
        return isNighttime(override: override)
    }

    var contextSummary: String {
        let state = snapshotState()
        let isNighttime = isNighttime(override: state.nightOverride)
        return isNighttime
            ? "Nighttime · Reloads: \(state.reloadCount)"
            : "Daytime · Reloads: \(state.reloadCount)"
    }

    var isNightOverrideActive: Bool {
        withLock { nightOverride != nil }
    }

    var isSleepOverrideActive: Bool {
        withLock { sleepOverride != nil }
    }

    var isNightModeActive: Bool {
        let override = withLock { nightOverride }
        return isNighttime(override: override)
    }

    func currentContext() -> EvaluationContext {
        let state = snapshotState()
        let isNighttime = isNighttime(override: state.nightOverride)
        EvaluationContext(
            currentDate: Date(),
            launchDate: launchDate,
            userData: [:],
            counters: ["reloadCount": state.reloadCount],
            events: [:],
            flags: [
                "nightTime": isNighttime,
                "sleepOverride": state.sleepOverride ?? false,
                "sleepOverrideActive": state.sleepOverride != nil,
                "sleepOverrideSleeping": state.sleepOverride ?? false,
            ],
            segments: []
        )
    }

    private struct State {
        let reloadCount: Int
        let nightOverride: Bool?
        let sleepOverride: Bool?
    }

    private func snapshotState() -> State {
        withLock {
            State(
                reloadCount: reloadCount,
                nightOverride: nightOverride,
                sleepOverride: sleepOverride
            )
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private func isNighttime(override: Bool?) -> Bool {
        if let override {
            return override
        }
        let hour = calendar.component(.hour, from: Date())
        return hour < 6 || hour >= 19
    }
}
