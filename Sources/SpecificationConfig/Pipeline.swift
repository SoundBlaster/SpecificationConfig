import Configuration
import Foundation

/// Error handling strategy for configuration pipeline.
///
/// Determines whether the pipeline stops at the first error or collects
/// all errors before failing.
public enum ErrorHandlingMode: Sendable {
    /// Collect all binding errors before failing.
    ///
    /// The pipeline will attempt to apply all bindings even if some fail,
    /// collecting diagnostic messages for all failures. This is the default
    /// mode and is recommended for user-facing configuration validation
    /// where showing all errors at once provides better user experience.
    case collectAll

    /// Stop at the first binding error.
    ///
    /// The pipeline will return immediately upon encountering the first
    /// binding failure. Useful for development and debugging where you
    /// want to fail quickly and fix issues one at a time.
    case failFast
}

/// Result of building a configuration through the pipeline.
///
/// The pipeline always produces diagnostics and a snapshot, whether the build
/// succeeds or fails. On success, the final configuration is included.
///
/// ## Example
///
/// ```swift
/// let result = ConfigPipeline.build(profile: myProfile, reader: configReader)
/// switch result {
/// case let .success(final, snapshot):
///     print("Config built successfully")
///     print("Resolved \(snapshot.resolvedValues.count) values")
/// case let .failure(diagnostics, snapshot):
///     print("Build failed with \(diagnostics.errorCount) errors")
///     for diagnostic in diagnostics.diagnostics where diagnostic.severity == .error {
///         print("Error: \(diagnostic.displayMessage)")
///     }
/// }
/// ```
public enum BuildResult<Final> {
    /// Configuration built successfully with final config and snapshot.
    ///
    /// - Parameters:
    ///   - final: The validated final configuration.
    ///   - snapshot: Snapshot containing resolved values, provenance, and any non-fatal diagnostics.
    case success(final: Final, snapshot: Snapshot)

    /// Configuration build failed with diagnostics and partial snapshot.
    ///
    /// - Parameters:
    ///   - diagnostics: Error and warning messages explaining the failure.
    ///   - snapshot: Snapshot containing any successfully resolved values before failure.
    case failure(diagnostics: DiagnosticsReport, snapshot: Snapshot)

    /// The diagnostics from this build result.
    public var diagnostics: DiagnosticsReport {
        switch self {
        case let .success(_, snapshot):
            snapshot.diagnostics
        case let .failure(diagnostics, _):
            diagnostics
        }
    }

    /// The snapshot from this build result.
    public var snapshot: Snapshot {
        switch self {
        case let .success(_, snapshot):
            snapshot
        case let .failure(_, snapshot):
            snapshot
        }
    }
}

/// Configuration pipeline that orchestrates binding application, finalization,
/// and validation with comprehensive diagnostics and snapshot generation.
///
/// `ConfigPipeline` wraps `SpecProfile` to provide observable, testable configuration
/// building with deterministic error reporting and value provenance tracking.
///
/// ## Example
///
/// ```swift
/// let profile = SpecProfile(
///     bindings: [appNameBinding, apiKeyBinding],
///     finalize: { draft in MyConfig(draft: draft) },
///     makeDraft: { MyConfigDraft() }
/// )
///
/// let result = ConfigPipeline.build(profile: profile, reader: configReader)
/// switch result {
/// case let .success(config, snapshot):
///     // Use config and inspect snapshot for debugging
///     print("App name: \(snapshot.value(forKey: "app.name")?.displayValue ?? "unknown")")
/// case let .failure(diagnostics, _):
///     // Handle errors with detailed diagnostics
///     for error in diagnostics.diagnostics where error.severity == .error {
///         print(error.formattedDescription())
///     }
/// }
/// ```
public enum ConfigPipeline {
    /// Builds a configuration using the profile and reader, producing a result
    /// with diagnostics and snapshot.
    ///
    /// The pipeline executes in order:
    /// 1. Apply bindings to populate draft from configuration reader
    /// 2. Track resolved values with provenance for the snapshot
    /// 3. Finalize the draft into the final configuration type
    /// 4. Run post-finalization specifications
    ///
    /// If any step fails, the pipeline returns `.failure` with diagnostics explaining
    /// the error and a partial snapshot containing successfully resolved values.
    ///
    /// - Parameters:
    ///   - profile: The specification profile defining bindings, finalization, and specs.
    ///   - reader: The configuration reader supplying values.
    ///   - provenanceReporter: Records provider metadata for each resolved configuration key.
    ///   - errorHandlingMode: Strategy for handling binding errors. Default is `.collectAll`,
    ///     which collects all binding errors before failing. Use `.failFast` to stop at
    ///     the first error (useful for development/debugging).
    /// - Returns: Build result containing either success (final config + snapshot) or
    ///            failure (diagnostics + partial snapshot).
    public static func build<Final>(
        profile: SpecProfile<some Any, Final>,
        reader: Configuration.ConfigReader,
        provenanceReporter: ResolvedValueProvenanceReporter? = nil,
        errorHandlingMode: ErrorHandlingMode = .collectAll
    ) -> BuildResult<Final> {
        let clock = ContinuousClock()
        let totalStart = clock.now
        var bindingDurations: [String: Duration] = [:]
        var decisionBindingDurations: [String: Duration] = [:]
        var finalizationDuration: Duration = .zero

        var diagnostics = DiagnosticsReport()
        var resolvedValues: [ResolvedValue] = []
        var decisionTraces: [DecisionTrace] = []

        func snapshot() -> Snapshot {
            Snapshot(
                resolvedValues: resolvedValues,
                decisionTraces: decisionTraces,
                diagnostics: diagnostics,
                performanceMetrics: PerformanceMetrics(
                    bindingDurations: bindingDurations,
                    decisionBindingDurations: decisionBindingDurations,
                    finalizationDuration: finalizationDuration,
                    totalDuration: clock.now - totalStart
                )
            )
        }

        provenanceReporter?.reset()

        // Create draft
        var draft = profile.makeDraft()

        // Apply bindings, collecting resolved values and diagnostics
        for binding in profile.bindings {
            let bindingStart = clock.now
            do {
                let (stringifiedValue, usedDefault) = try binding.applyAndCapture(
                    to: &draft,
                    reader: reader,
                    contextProvider: profile.contextProvider
                )
                bindingDurations[binding.key] = clock.now - bindingStart

                let provenance = Self.provenance(
                    forKey: binding.key,
                    usedDefault: usedDefault,
                    reporter: provenanceReporter
                )

                // Track successfully resolved value for snapshot
                let resolvedValue = ResolvedValue(
                    key: binding.key,
                    stringifiedValue: stringifiedValue ?? "<nil>",
                    provenance: provenance,
                    isSecret: binding.isSecret
                )
                resolvedValues.append(resolvedValue)

            } catch let error as ConfigError {
                bindingDurations[binding.key] = clock.now - bindingStart
                // Convert ConfigError to diagnostic
                let diagnostic = diagnosticFromConfigError(error, key: binding.key)
                diagnostics.add(diagnostic)

                // Mode-specific error handling
                switch errorHandlingMode {
                case .failFast:
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                case .collectAll:
                    continue
                }

            } catch {
                bindingDurations[binding.key] = clock.now - bindingStart
                // Wrap decode errors in ConfigError for better diagnostics
                let configError = ConfigError.decodeFailed(
                    key: binding.key,
                    underlyingError: error.localizedDescription
                )
                let diagnostic = diagnosticFromConfigError(configError, key: binding.key)
                diagnostics.add(diagnostic)

                // Mode-specific error handling
                switch errorHandlingMode {
                case .failFast:
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                case .collectAll:
                    continue
                }
            }
        }

        for decisionBinding in profile.decisionBindings {
            let decisionStart = clock.now
            switch decisionBinding.apply(to: &draft) {
            case .skipped:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                continue
            case let .applied(trace, stringifiedValue):
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                decisionTraces.append(trace)
                let resolved = ResolvedValue(
                    key: decisionBinding.key,
                    stringifiedValue: stringifiedValue,
                    provenance: .decisionFallback,
                    isSecret: decisionBinding.isSecret
                )
                if let index = resolvedValues.firstIndex(where: { $0.key == decisionBinding.key }) {
                    resolvedValues[index] = resolved
                } else {
                    resolvedValues.append(resolved)
                }
            case .noMatch:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                let diagnostic = diagnosticFromConfigError(
                    .decisionFallbackFailed(key: decisionBinding.key),
                    key: decisionBinding.key
                )
                diagnostics.add(diagnostic)
                if errorHandlingMode == .failFast {
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                }
            }
        }

        // Check if we have any errors before finalizing
        if diagnostics.hasErrors {
            return .failure(diagnostics: diagnostics, snapshot: snapshot())
        }

        // Finalize draft
        let final: Final
        let finalizeStart = clock.now
        do {
            final = try profile.finalizeDraft(draft)
            finalizationDuration = clock.now - finalizeStart
        } catch let error as ConfigError {
            finalizationDuration = clock.now - finalizeStart
            let diagnostic = diagnosticFromConfigError(error, key: nil)
            diagnostics.add(diagnostic)
            return .failure(diagnostics: diagnostics, snapshot: snapshot())

        } catch {
            finalizationDuration = clock.now - finalizeStart
            diagnostics.add(
                severity: .error,
                message: "Finalization failed: \(error.localizedDescription)"
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot())
        }

        return .success(final: final, snapshot: snapshot())
    }

    /// Builds a configuration using the profile and reader, awaiting async specs.
    ///
    /// This mirrors `build` but additionally evaluates async value specs, async
    /// decision bindings, and async final specs using async/await. Async specs
    /// are evaluated sequentially (not concurrently).
    ///
    /// Use this method when your profile includes:
    /// - Bindings with `asyncValueSpecs` (e.g., network validation)
    /// - `asyncDecisionBindings` (e.g., remote feature flag lookups)
    /// - `asyncFinalSpecs` (e.g., cross-field async validation)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let result = await ConfigPipeline.buildAsync(
    ///     profile: myProfile,
    ///     reader: configReader
    /// )
    /// switch result {
    /// case let .success(config, snapshot):
    ///     print("Config: \(config)")
    ///     if let metrics = snapshot.performanceMetrics {
    ///         print("Build took \(metrics.totalDuration)")
    ///     }
    /// case let .failure(diagnostics, _):
    ///     for item in diagnostics.diagnostics {
    ///         print(item.formattedDescription())
    ///     }
    /// }
    /// ```
    public static func buildAsync<Final>(
        profile: SpecProfile<some Any, Final>,
        reader: Configuration.ConfigReader,
        provenanceReporter: ResolvedValueProvenanceReporter? = nil,
        errorHandlingMode: ErrorHandlingMode = .collectAll
    ) async -> BuildResult<Final> {
        let clock = ContinuousClock()
        let totalStart = clock.now
        var bindingDurations: [String: Duration] = [:]
        var decisionBindingDurations: [String: Duration] = [:]
        var finalizationDuration: Duration = .zero

        var diagnostics = DiagnosticsReport()
        var resolvedValues: [ResolvedValue] = []
        var decisionTraces: [DecisionTrace] = []

        func snapshot() -> Snapshot {
            Snapshot(
                resolvedValues: resolvedValues,
                decisionTraces: decisionTraces,
                diagnostics: diagnostics,
                performanceMetrics: PerformanceMetrics(
                    bindingDurations: bindingDurations,
                    decisionBindingDurations: decisionBindingDurations,
                    finalizationDuration: finalizationDuration,
                    totalDuration: clock.now - totalStart
                )
            )
        }

        provenanceReporter?.reset()

        // Create draft
        var draft = profile.makeDraft()

        // Apply bindings, collecting resolved values and diagnostics
        for binding in profile.bindings {
            let bindingStart = clock.now
            do {
                let (stringifiedValue, usedDefault) = try await binding.applyAndCaptureAsync(
                    to: &draft,
                    reader: reader,
                    contextProvider: profile.contextProvider
                )
                bindingDurations[binding.key] = clock.now - bindingStart

                let provenance = Self.provenance(
                    forKey: binding.key,
                    usedDefault: usedDefault,
                    reporter: provenanceReporter
                )

                // Track successfully resolved value for snapshot
                let resolvedValue = ResolvedValue(
                    key: binding.key,
                    stringifiedValue: stringifiedValue ?? "<nil>",
                    provenance: provenance,
                    isSecret: binding.isSecret
                )
                resolvedValues.append(resolvedValue)

            } catch let error as ConfigError {
                bindingDurations[binding.key] = clock.now - bindingStart
                let diagnostic = diagnosticFromConfigError(error, key: binding.key)
                diagnostics.add(diagnostic)

                switch errorHandlingMode {
                case .failFast:
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                case .collectAll:
                    continue
                }

            } catch {
                bindingDurations[binding.key] = clock.now - bindingStart
                let configError = ConfigError.decodeFailed(
                    key: binding.key,
                    underlyingError: error.localizedDescription
                )
                let diagnostic = diagnosticFromConfigError(configError, key: binding.key)
                diagnostics.add(diagnostic)

                switch errorHandlingMode {
                case .failFast:
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                case .collectAll:
                    continue
                }
            }
        }

        for decisionBinding in profile.decisionBindings {
            let decisionStart = clock.now
            switch decisionBinding.apply(to: &draft) {
            case .skipped:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                continue
            case let .applied(trace, stringifiedValue):
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                decisionTraces.append(trace)
                let resolved = ResolvedValue(
                    key: decisionBinding.key,
                    stringifiedValue: stringifiedValue,
                    provenance: .decisionFallback,
                    isSecret: decisionBinding.isSecret
                )
                if let index = resolvedValues.firstIndex(where: { $0.key == decisionBinding.key }) {
                    resolvedValues[index] = resolved
                } else {
                    resolvedValues.append(resolved)
                }
            case .noMatch:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                let diagnostic = diagnosticFromConfigError(
                    .decisionFallbackFailed(key: decisionBinding.key),
                    key: decisionBinding.key
                )
                diagnostics.add(diagnostic)
                if errorHandlingMode == .failFast {
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                }
            }
        }

        // Apply async decision bindings
        for decisionBinding in profile.asyncDecisionBindings {
            let decisionStart = clock.now
            switch await decisionBinding.applyAsync(to: &draft) {
            case .skipped:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                continue
            case let .applied(trace, stringifiedValue):
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                decisionTraces.append(trace)
                let resolved = ResolvedValue(
                    key: decisionBinding.key,
                    stringifiedValue: stringifiedValue,
                    provenance: .decisionFallback,
                    isSecret: decisionBinding.isSecret
                )
                if let index = resolvedValues.firstIndex(where: { $0.key == decisionBinding.key }) {
                    resolvedValues[index] = resolved
                } else {
                    resolvedValues.append(resolved)
                }
            case .noMatch:
                decisionBindingDurations[decisionBinding.key] = clock.now - decisionStart
                let diagnostic = diagnosticFromConfigError(
                    .asyncDecisionFallbackFailed(key: decisionBinding.key),
                    key: decisionBinding.key
                )
                diagnostics.add(diagnostic)
                if errorHandlingMode == .failFast {
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                }
            }
        }

        // Check if we have any errors before finalizing
        if diagnostics.hasErrors {
            return .failure(diagnostics: diagnostics, snapshot: snapshot())
        }

        // Finalize draft
        let final: Final
        let finalizeStart = clock.now
        do {
            final = try profile.finalizeDraft(draft)
            finalizationDuration = clock.now - finalizeStart
        } catch let error as ConfigError {
            finalizationDuration = clock.now - finalizeStart
            let diagnostic = diagnosticFromConfigError(error, key: nil)
            diagnostics.add(diagnostic)
            return .failure(diagnostics: diagnostics, snapshot: snapshot())

        } catch {
            finalizationDuration = clock.now - finalizeStart
            diagnostics.add(
                severity: .error,
                message: "Finalization failed: \(error.localizedDescription)"
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot())
        }

        for spec in profile.asyncFinalSpecs {
            do {
                let isSatisfied = try await spec.isSatisfiedBy(final)
                if !isSatisfied {
                    let diagnostic = diagnosticFromConfigError(
                        .asyncFinalSpecFailed(spec: spec.metadata),
                        key: nil
                    )
                    diagnostics.add(diagnostic)
                    return .failure(diagnostics: diagnostics, snapshot: snapshot())
                }
            } catch {
                diagnostics.add(
                    severity: .error,
                    message: "Async specification failed: \(error.localizedDescription)",
                    context: specContext(spec.metadata)
                )
                return .failure(diagnostics: diagnostics, snapshot: snapshot())
            }
        }

        return .success(final: final, snapshot: snapshot())
    }

    /// Converts a ConfigError into a DiagnosticItem.
    ///
    /// - Parameters:
    ///   - error: The configuration error to convert.
    ///   - key: Optional configuration key associated with the error.
    /// - Returns: A diagnostic item representing the error.
    private static func diagnosticFromConfigError(
        _ error: ConfigError,
        key: String?
    ) -> DiagnosticItem {
        switch error {
        case let .specFailed(specKey, spec):
            DiagnosticItem(
                key: key ?? specKey,
                severity: .error,
                message: "Value specification failed for key '\(specKey)'",
                context: specContext(spec)
            )
        case let .finalSpecFailed(spec):
            DiagnosticItem(
                key: key,
                severity: .error,
                message: "Post-finalization specification failed",
                context: specContext(spec)
            )
        case let .asyncSpecFailed(specKey, spec):
            DiagnosticItem(
                key: key ?? specKey,
                severity: .error,
                message: "Async specification failed for key '\(specKey)'",
                context: specContext(spec)
            )
        case let .asyncFinalSpecFailed(spec):
            DiagnosticItem(
                key: key,
                severity: .error,
                message: "Async post-finalization specification failed",
                context: specContext(spec)
            )
        case let .decisionFallbackFailed(decisionKey):
            DiagnosticItem(
                key: key ?? decisionKey,
                severity: .error,
                message: "Decision fallback did not match for key '\(decisionKey)'"
            )
        case let .asyncDecisionFallbackFailed(decisionKey):
            DiagnosticItem(
                key: key ?? decisionKey,
                severity: .error,
                message: "Async decision fallback did not match for key '\(decisionKey)'"
            )
        case let .contextProviderMissing(missingKey):
            DiagnosticItem(
                key: key ?? missingKey,
                severity: .error,
                message: "Context provider required for contextual spec evaluation"
            )
        case let .decodeFailed(decodeKey, underlyingError):
            DiagnosticItem(
                key: key ?? decodeKey,
                severity: .error,
                message: "Failed to decode configuration value for key '\(decodeKey)': \(underlyingError)",
                context: [
                    "errorType": DiagnosticContextValue("Decode Error"),
                    "underlyingError": DiagnosticContextValue(underlyingError),
                ]
            )
        }
    }

    private static func specContext(_ metadata: SpecMetadata) -> [String: DiagnosticContextValue] {
        [
            "spec": DiagnosticContextValue(metadata.displayName),
            "specType": DiagnosticContextValue(metadata.typeName),
        ]
    }

    private static func provenance(
        forKey key: String,
        usedDefault: Bool,
        reporter: ResolvedValueProvenanceReporter?
    ) -> Provenance {
        if usedDefault {
            return .defaultValue
        }
        if let reporter {
            if let recorded = reporter.provenance(forKey: key) {
                return recorded
            }
        }
        return .unknown
    }
}
