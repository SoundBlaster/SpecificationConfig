import Configuration
import SpecificationCore

/// A reusable profile that applies bindings to a draft configuration and finalizes it.
///
/// `SpecProfile` coordinates three stages:
/// 1. Create a draft using a supplied factory closure.
/// 2. Apply an ordered set of bindings to populate that draft from a `ConfigReader`.
/// 3. Apply ordered decision bindings to derive missing values.
/// 4. Finalize the populated draft into a strongly-typed `Final` value.
/// 5. Run optional post-finalization specifications to enforce cross-field invariants.
///
/// The profile preserves the ordering of the supplied bindings and surfaces any decode
/// or specification failures immediately. Diagnostics will be expanded in B4; until then
/// errors are surfaced through `ConfigError`.
public struct SpecProfile<Draft, Final> {
    /// The ordered bindings that populate the draft from configuration values.
    public let bindings: [AnyBinding<Draft>]

    /// Optional decision bindings that derive missing values.
    public let decisionBindings: [AnyDecisionBinding<Draft>]

    /// The finalize function that converts a populated draft into a final configuration value.
    public let finalize: (Draft) throws -> Final

    /// Optional specifications that validate the finalized configuration, with metadata.
    public let finalSpecs: [SpecEntry<Final>]

    /// Factory closure that creates an empty draft before bindings are applied.
    public let makeDraft: () -> Draft

    /// Creates a specification profile.
    ///
    /// - Parameters:
    ///   - bindings: Ordered bindings to apply to the draft.
    ///   - decisionBindings: Ordered decision bindings to derive missing values.
    ///   - finalize: Closure that converts a populated draft into a final configuration value.
    ///   - finalSpecs: Optional specs with metadata to validate the finalized configuration.
    ///   - makeDraft: Factory closure that creates a new draft before bindings are applied.
    public init(
        bindings: [AnyBinding<Draft>],
        decisionBindings: [AnyDecisionBinding<Draft>] = [],
        finalize: @escaping (Draft) throws -> Final,
        finalSpecs: [SpecEntry<Final>] = [],
        makeDraft: @escaping () -> Draft
    ) {
        self.bindings = bindings
        self.decisionBindings = decisionBindings
        self.finalize = finalize
        self.finalSpecs = finalSpecs
        self.makeDraft = makeDraft
    }

    /// Applies all bindings to a new draft using the provided configuration reader.
    ///
    /// - Parameter reader: The configuration reader supplying values for each binding.
    /// - Returns: A populated draft configuration.
    /// - Throws: Errors thrown by individual bindings while decoding or validating values.
    public func applyBindings(reader: Configuration.ConfigReader) throws -> Draft {
        var draft = makeDraft()
        try applyBindings(to: &draft, reader: reader)
        return draft
    }

    /// Applies all bindings in order to the supplied draft.
    ///
    /// - Parameters:
    ///   - draft: The draft to mutate.
    ///   - reader: The configuration reader supplying values for each binding.
    /// - Throws: Errors thrown by binding decoders or value specifications.
    public func applyBindings(to draft: inout Draft, reader: Configuration.ConfigReader) throws {
        for binding in bindings {
            try binding.apply(to: &draft, reader: reader)
        }
    }

    /// Finalizes a populated draft and runs any post-finalization specifications.
    ///
    /// - Parameter draft: The populated draft configuration to finalize.
    /// - Returns: The finalized configuration value.
    /// - Throws: Errors thrown by the finalize closure or final specification failures.
    public func finalizeDraft(_ draft: Draft) throws -> Final {
        let finalConfig = try finalize(draft)
        try validate(finalConfig)
        return finalConfig
    }

    /// Builds the final configuration value by applying bindings, decision bindings,
    /// finalizing the draft, and enforcing post-finalization specifications.
    ///
    /// - Parameter reader: The configuration reader supplying values for each binding.
    /// - Returns: The finalized configuration value.
    /// - Throws: Errors surfaced by binding application, finalization, or specification failures.
    public func build(reader: Configuration.ConfigReader) throws -> Final {
        var draft = try applyBindings(reader: reader)
        try applyDecisionBindings(to: &draft)
        return try finalizeDraft(draft)
    }

    private func validate(_ finalValue: Final) throws {
        for spec in finalSpecs {
            if !spec.isSatisfiedBy(finalValue) {
                throw ConfigError.finalSpecFailed(spec: spec.metadata)
            }
        }
    }

    private func applyDecisionBindings(to draft: inout Draft) throws {
        for decisionBinding in decisionBindings {
            switch decisionBinding.apply(to: &draft) {
            case .skipped, .applied:
                continue
            case .noMatch:
                throw ConfigError.decisionFallbackFailed(key: decisionBinding.key)
            }
        }
    }
}
