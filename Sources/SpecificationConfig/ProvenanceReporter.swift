import Configuration
import Foundation

/// Records provider metadata for each resolved configuration key.
///
/// `ResolvedValueProvenanceReporter` is wired into `ConfigReader` and the
/// configuration pipeline to capture which provider supplied a value. The
/// pipeline then uses this metadata to populate `ResolvedValue.provenance`
/// so UIs can explain whether a value came from a file, environment, or default.
public final class ResolvedValueProvenanceReporter: AccessReporter, @unchecked Sendable {
    private let lock = NSLock()
    private var provenanceByKey: [String: Provenance] = [:]

    /// Creates a new reporter.
    public init() {}

    /// Resets the recorded provenance for a fresh build cycle.
    public func reset() {
        lock.lock()
        provenanceByKey.removeAll()
        lock.unlock()
    }

    /// Returns the most recently recorded provenance for `key`, if any.
    public func provenance(forKey key: String) -> Provenance? {
        lock.lock()
        defer { lock.unlock() }
        return provenanceByKey[key]
    }

    public func report(_ event: AccessEvent) {
        guard case .success(.some) = event.result else {
            return
        }

        let key = event.metadata.key.description
        guard !key.isEmpty else {
            return
        }

        for providerResult in event.providerResults {
            guard case let .success(lookup) = providerResult.result,
                  lookup.value != nil
            else {
                continue
            }

            let provenance = Self.provenance(fromProviderName: providerResult.providerName)
            lock.lock()
            provenanceByKey[key] = provenance
            lock.unlock()
            return
        }
    }

    private static func provenance(fromProviderName providerName: String) -> Provenance {
        if providerName.contains("EnvironmentVariablesProvider") {
            return .environmentVariable
        }

        if let nameInBrackets = nameInsideBrackets(providerName) {
            return .fileProvider(name: nameInBrackets)
        }

        guard !providerName.isEmpty else {
            return .unknown
        }

        return .fileProvider(name: providerName)
    }

    private static func nameInsideBrackets(_ providerName: String) -> String? {
        guard
            let start = providerName.firstIndex(of: "["),
            let end = providerName.lastIndex(of: "]"),
            start < end
        else {
            return nil
        }

        let nameRange = providerName.index(after: start) ..< end
        let extracted = providerName[nameRange].trimmingCharacters(in: .whitespaces)
        return extracted.isEmpty ? nil : extracted
    }
}
