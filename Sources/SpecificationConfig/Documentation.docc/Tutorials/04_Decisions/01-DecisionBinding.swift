import Foundation
import SpecificationCore

/// A decision entry that can derive a value when a predicate matches.
public struct DecisionEntry<Context, Result> {
    private let decide: (Context) -> Result?
    public let metadata: SpecMetadata

    /// Creates a decision entry from a DecisionSpec.
    ///
    /// - Parameters:
    ///   - spec: The decision specification to evaluate.
    ///   - description: Optional override description for diagnostics.
    // swiftformat:disable:next opaqueGenericParameters
    public init<S: DecisionSpec>(_ spec: S, description: String? = nil)
        where S.Context == Context, S.Result == Result
    {
        decide = spec.decide
        metadata = SpecMetadata(
            description: description,
            typeName: String(describing: S.self)
        )
    }

    /// Creates a decision entry from a custom decision closure.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - decide: Closure that returns a result when the decision matches.
    public init(description: String? = nil, decide: @escaping (Context) -> Result?) {
        self.decide = decide
        metadata = SpecMetadata(
            description: description,
            typeName: "DecisionEntry"
        )
    }

    /// Creates a decision entry from a predicate and result.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - predicate: Predicate that decides whether to return the result.
    ///   - result: Result to return when the predicate matches.
    public init(
        description: String? = nil,
        predicate: @escaping (Context) -> Bool,
        result: Result
    ) {
        decide = { context in
            predicate(context) ? result : nil
        }
        metadata = SpecMetadata(
            description: description,
            typeName: "DecisionEntry"
        )
    }

    func resolve(_ context: Context) -> Result? {
        decide(context)
    }
}

/// A binding that derives a value using ordered decision entries when missing.
public struct DecisionBinding<Draft, Value> {
    public let key: String
    public let keyPath: WritableKeyPath<Draft, Value?>
    public let decisions: [DecisionEntry<Draft, Value>]
    public let isSecret: Bool

    /// Creates a decision binding.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - keyPath: Where to write the derived value in the draft.
    ///   - decisions: Ordered decisions to evaluate when the value is missing.
    ///   - isSecret: Whether the derived value should be redacted.
    public init(
        key: String,
        keyPath: WritableKeyPath<Draft, Value?>,
        decisions: [DecisionEntry<Draft, Value>],
        isSecret: Bool = false
    ) {
        self.key = key
        self.keyPath = keyPath
        self.decisions = decisions
        self.isSecret = isSecret
    }

    fileprivate func apply(to draft: inout Draft) -> DecisionResolution {
        if draft[keyPath: keyPath] != nil {
            return .skipped
        }

        for (index, decision) in decisions.enumerated() {
            if let value = decision.resolve(draft) {
                draft[keyPath: keyPath] = value
                let trace = DecisionTrace(
                    key: key,
                    matchedIndex: index,
                    decisionName: decision.metadata.displayName,
                    decisionType: decision.metadata.typeName
                )
                return .applied(
                    trace: trace,
                    stringifiedValue: String(describing: value)
                )
            }
        }

        return .noMatch
    }
}

/// Type-erased decision binding for heterogeneous collections.
public struct AnyDecisionBinding<Draft> {
    public let key: String
    public let isSecret: Bool

    private let applyDecision: (inout Draft) -> DecisionResolution

    public init(_ binding: DecisionBinding<Draft, some Any>) {
        key = binding.key
        isSecret = binding.isSecret
        applyDecision = { draft in
            binding.apply(to: &draft)
        }
    }

    func apply(to draft: inout Draft) -> DecisionResolution {
        applyDecision(&draft)
    }
}

enum DecisionResolution {
    case skipped
    case applied(trace: DecisionTrace, stringifiedValue: String)
    case noMatch
}
