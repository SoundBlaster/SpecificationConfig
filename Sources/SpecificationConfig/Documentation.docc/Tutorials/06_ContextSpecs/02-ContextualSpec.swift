import Foundation
import SpecificationCore

/// A context-aware specification wrapper evaluated with an EvaluationContext.
public struct ContextualSpecEntry<Value> {
    private let predicate: (EvaluationContext, Value) -> Bool
    public let metadata: SpecMetadata

    /// Creates a contextual spec entry.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - predicate: Predicate that evaluates the context and candidate value.
    public init(
        description: String? = nil,
        _ predicate: @escaping (EvaluationContext, Value) -> Bool
    ) {
        self.predicate = predicate
        metadata = SpecMetadata(
            description: description,
            typeName: "ContextualSpecEntry"
        )
    }

    func isSatisfiedBy(
        _ candidate: Value,
        using provider: AnyContextProvider
    ) -> Bool {
        predicate(provider.currentContext(), candidate)
    }
}
