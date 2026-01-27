import SpecificationCore

/// An asynchronous specification wrapper that carries metadata for diagnostics.
public struct AsyncSpecEntry<T>: AsyncSpecification {
    /// The type-erased async specification.
    private let spec: AnyAsyncSpecification<T>

    /// Metadata describing the spec.
    public let metadata: SpecMetadata

    /// Creates an async spec entry from a concrete async specification.
    ///
    /// - Parameters:
    ///   - specification: The async specification to evaluate.
    ///   - description: Optional description for diagnostics.
    public init<S: AsyncSpecification>(_ specification: S, description: String? = nil) where S.T == T {
        spec = AnyAsyncSpecification(specification)
        metadata = SpecMetadata(
            description: description,
            typeName: String(describing: S.self)
        )
    }

    /// Creates an async spec entry from an async closure.
    ///
    /// - Parameters:
    ///   - description: Optional description for diagnostics.
    ///   - predicate: Async predicate that returns true when the candidate is valid.
    public init(description: String? = nil, _ predicate: @escaping (T) async throws -> Bool) {
        spec = AnyAsyncSpecification(predicate)
        metadata = SpecMetadata(
            description: description,
            typeName: String(describing: AnyAsyncSpecification<T>.self)
        )
    }

    /// Creates an async spec entry from a synchronous specification.
    ///
    /// - Parameters:
    ///   - specification: The synchronous specification to bridge.
    ///   - description: Optional description for diagnostics.
    public init<S: Specification>(_ specification: S, description: String? = nil) where S.T == T {
        let predicateDescription = (specification as? PredicateSpec<T>)?.description
        let resolvedDescription = description ?? predicateDescription
        spec = AnyAsyncSpecification(specification)
        metadata = SpecMetadata(
            description: resolvedDescription,
            typeName: String(describing: S.self)
        )
    }

    /// Creates an async spec entry from a type-erased async specification.
    ///
    /// - Parameters:
    ///   - spec: The type-erased async specification.
    ///   - description: Optional description for diagnostics.
    ///   - typeName: Optional type name for fallback display.
    public init(
        _ spec: AnyAsyncSpecification<T>,
        description: String? = nil,
        typeName: String = String(describing: AnyAsyncSpecification<T>.self)
    ) {
        self.spec = spec
        metadata = SpecMetadata(description: description, typeName: typeName)
    }

    public func isSatisfiedBy(_ candidate: T) async throws -> Bool {
        try await spec.isSatisfiedBy(candidate)
    }
}
