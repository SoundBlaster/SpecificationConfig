import Foundation

/// Records which decision matched for a derived configuration value.
public struct DecisionTrace: Sendable, Equatable {
    /// The configuration key this decision resolved.
    public let key: String

    /// The index of the matched decision in declaration order.
    public let matchedIndex: Int

    /// Human-readable name for the matched decision.
    public let decisionName: String

    /// Type name for the matched decision.
    public let decisionType: String

    /// Creates a decision trace.
    ///
    /// - Parameters:
    ///   - key: The configuration key resolved by the decision.
    ///   - matchedIndex: The index of the matched decision in declaration order.
    ///   - decisionName: Human-readable name for the decision.
    ///   - decisionType: Type name for the decision.
    public init(
        key: String,
        matchedIndex: Int,
        decisionName: String,
        decisionType: String
    ) {
        self.key = key
        self.matchedIndex = matchedIndex
        self.decisionName = decisionName
        self.decisionType = decisionType
    }
}
