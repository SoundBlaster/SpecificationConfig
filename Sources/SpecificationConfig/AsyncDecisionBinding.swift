import SpecificationCore

/// An async decision entry that can derive a value when an async predicate matches.
public struct AsyncDecisionEntry<Context, Result> {
    private let decide: (Context) async -> Result?
    public let metadata: SpecMetadata

    /// Creates an async decision entry from a custom async decision closure.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - decide: Async closure that returns a result when the decision matches.
    public init(description: String? = nil, decide: @escaping (Context) async -> Result?) {
        self.decide = decide
        metadata = SpecMetadata(
            description: description,
            typeName: "AsyncDecisionEntry"
        )
    }

    /// Creates an async decision entry from an async predicate and result.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - predicate: Async predicate that decides whether to return the result.
    ///   - result: Result to return when the predicate matches.
    public init(
        description: String? = nil,
        predicate: @escaping (Context) async -> Bool,
        result: Result
    ) {
        decide = { context in
            await predicate(context) ? result : nil
        }
        metadata = SpecMetadata(
            description: description,
            typeName: "AsyncDecisionEntry"
        )
    }

    /// Creates an async decision entry from a synchronous decision entry.
    ///
    /// - Parameter syncEntry: The synchronous decision entry to bridge.
    public init(_ syncEntry: DecisionEntry<Context, Result>) {
        decide = { context in
            syncEntry.resolve(context)
        }
        metadata = syncEntry.metadata
    }

    func resolve(_ context: Context) async -> Result? {
        await decide(context)
    }
}

/// A binding that derives a value using ordered async decision entries when missing.
public struct AsyncDecisionBinding<Draft, Value> {
    public let key: String
    public let keyPath: WritableKeyPath<Draft, Value?>
    public let decisions: [AsyncDecisionEntry<Draft, Value>]
    public let stringify: (Value) -> String
    public let isSecret: Bool

    /// Creates an async decision binding.
    ///
    /// - Parameters:
    ///   - key: The configuration key to resolve.
    ///   - keyPath: Where to write the derived value in the draft.
    ///   - decisions: Ordered async decisions to evaluate when the value is missing.
    ///   - stringify: Stringifier used when capturing values for snapshots.
    ///   - isSecret: Whether the derived value should be redacted.
    public init(
        key: String,
        keyPath: WritableKeyPath<Draft, Value?>,
        decisions: [AsyncDecisionEntry<Draft, Value>],
        stringify: @escaping (Value) -> String = { String(describing: $0) },
        isSecret: Bool = false
    ) {
        self.key = key
        self.keyPath = keyPath
        self.decisions = decisions
        self.stringify = stringify
        self.isSecret = isSecret
    }

    fileprivate func applyAsync(to draft: inout Draft) async -> DecisionResolution {
        if draft[keyPath: keyPath] != nil {
            return .skipped
        }

        for (index, decision) in decisions.enumerated() {
            if let value = await decision.resolve(draft) {
                draft[keyPath: keyPath] = value
                let trace = DecisionTrace(
                    key: key,
                    matchedIndex: index,
                    decisionName: decision.metadata.displayName,
                    decisionType: decision.metadata.typeName
                )
                return .applied(
                    trace: trace,
                    stringifiedValue: stringify(value)
                )
            }
        }

        return .noMatch
    }
}

/// Type-erased async decision binding for heterogeneous collections.
public struct AnyAsyncDecisionBinding<Draft> {
    public let key: String
    public let isSecret: Bool

    private let applyDecision: (inout Draft) async -> DecisionResolution

    public init(_ binding: AsyncDecisionBinding<Draft, some Any>) {
        key = binding.key
        isSecret = binding.isSecret
        applyDecision = { draft in
            await binding.applyAsync(to: &draft)
        }
    }

    func applyAsync(to draft: inout Draft) async -> DecisionResolution {
        await applyDecision(&draft)
    }
}
