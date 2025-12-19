import SpecificationCore

/// Evaluation context forwarded from SpecificationCore.
public typealias EvaluationContext = SpecificationCore.EvaluationContext

/// Re-export of SpecificationCore's `ContextProviding` protocol.
public typealias ContextProviding = SpecificationCore.ContextProviding

/// Type-erased context provider tied to the exported `EvaluationContext`.
public typealias AnyContextProvider = SpecificationCore.AnyContextProvider<EvaluationContext>

/// Decision specification marker re-exported from SpecificationCore.
public typealias DecisionSpec = SpecificationCore.DecisionSpec

/// Type-erased decision helper available in SpecificationCore.
public typealias AnyDecisionSpec = SpecificationCore.AnyDecisionSpec

/// Convenience helpers for working with decision entries without importing SpecificationCore.
public enum SpecificationCoreHelpers {
    /// Creates a `DecisionEntry` from a predicate.
    public static func decisionEntry<Context, Result>(
        description: String? = nil,
        predicate: @escaping (Context) -> Bool,
        result: Result
    ) -> DecisionEntry<Context, Result> {
        DecisionEntry(description: description, predicate: predicate, result: result)
    }

    /// Wraps a `SpecificationCore.DecisionSpec`.
    public static func decisionEntry<Spec: DecisionSpec>(
        _ spec: Spec,
        description: String? = nil
    ) -> DecisionEntry<Spec.Context, Spec.Result> {
        DecisionEntry(spec, description: description)
    }
}
