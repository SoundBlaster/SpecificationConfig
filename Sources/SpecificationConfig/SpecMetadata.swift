import Foundation
import SpecificationCore

/// Human-readable metadata describing a specification for diagnostics.
public struct SpecMetadata: Sendable, Equatable {
    /// Optional description for display (e.g., from PredicateSpec).
    public let description: String?

    /// Stable type name for fallback display.
    public let typeName: String

    /// Preferred display name (description first, type name fallback).
    public var displayName: String {
        let trimmed = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return typeName
    }

    /// Creates spec metadata.
    ///
    /// - Parameters:
    ///   - description: Optional human-readable description.
    ///   - typeName: Fallback type name to use when description is missing.
    public init(description: String? = nil, typeName: String) {
        self.description = description
        self.typeName = typeName
    }
}

/// A specification wrapper that carries metadata for diagnostics.
public struct SpecEntry<T>: Specification {
    /// The type-erased specification.
    private let spec: AnySpecification<T>

    /// Metadata describing the spec.
    public let metadata: SpecMetadata

    /// Creates a spec entry from a concrete specification.
    ///
    /// - Parameters:
    ///   - spec: The concrete specification.
    ///   - description: Optional override description.
    public init<S: Specification>(_ spec: S, description: String? = nil) where S.T == T {
        let predicateDescription = (spec as? PredicateSpec<T>)?.description
        let resolvedDescription = description ?? predicateDescription
        spec = AnySpecification(spec)
        metadata = SpecMetadata(
            description: resolvedDescription,
            typeName: String(describing: S.self)
        )
    }

    /// Creates a spec entry from a type-erased specification.
    ///
    /// - Parameters:
    ///   - spec: The type-erased specification.
    ///   - description: Optional description for diagnostics.
    ///   - typeName: Optional type name for fallback display.
    public init(
        _ spec: AnySpecification<T>,
        description: String? = nil,
        typeName: String = String(describing: AnySpecification<T>.self)
    ) {
        self.spec = spec
        metadata = SpecMetadata(description: description, typeName: typeName)
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}
