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
    ///   - errorHandlingMode: Strategy for handling binding errors. Default is `.collectAll`,
    ///     which collects all binding errors before failing. Use `.failFast` to stop at
    ///     the first error (useful for development/debugging).
    /// - Returns: Build result containing either success (final config + snapshot) or
    ///            failure (diagnostics + partial snapshot).
    public static func build<Final>(
        profile: SpecProfile<some Any, Final>,
        reader: Configuration.ConfigReader,
        errorHandlingMode: ErrorHandlingMode = .collectAll
    ) -> BuildResult<Final> {
        var diagnostics = DiagnosticsReport()
        var resolvedValues: [ResolvedValue] = []
        var decisionTraces: [DecisionTrace] = []

        // Create draft
        var draft = profile.makeDraft()

        // Apply bindings, collecting resolved values and diagnostics
        for binding in profile.bindings {
            do {
                let (stringifiedValue, usedDefault) = try binding.applyAndCapture(
                    to: &draft,
                    reader: reader
                )

                // Determine provenance based on whether default was used
                let provenance: Provenance = usedDefault ? .defaultValue : .unknown

                // Track successfully resolved value for snapshot
                let resolvedValue = ResolvedValue(
                    key: binding.key,
                    stringifiedValue: stringifiedValue ?? "<nil>",
                    provenance: provenance,
                    isSecret: binding.isSecret
                )
                resolvedValues.append(resolvedValue)

            } catch let error as ConfigError {
                // Convert ConfigError to diagnostic
                let diagnostic = diagnosticFromConfigError(error, key: binding.key)
                diagnostics.add(diagnostic)

                // Mode-specific error handling
                switch errorHandlingMode {
                case .failFast:
                    // Stop immediately and return failure
                    let snapshot = Snapshot(
                        resolvedValues: resolvedValues,
                        decisionTraces: decisionTraces,
                        diagnostics: DiagnosticsReport()
                    )
                    return .failure(diagnostics: diagnostics, snapshot: snapshot)
                case .collectAll:
                    // Continue to next binding
                    continue
                }

            } catch {
                // Handle other errors (decode errors, etc.)
                diagnostics.add(
                    key: binding.key,
                    severity: .error,
                    message: "Binding application failed: \(error.localizedDescription)"
                )

                // Mode-specific error handling
                switch errorHandlingMode {
                case .failFast:
                    // Stop immediately and return failure
                    let snapshot = Snapshot(
                        resolvedValues: resolvedValues,
                        decisionTraces: decisionTraces,
                        diagnostics: DiagnosticsReport()
                    )
                    return .failure(diagnostics: diagnostics, snapshot: snapshot)
                case .collectAll:
                    // Continue to next binding
                    continue
                }
            }
        }

        for decisionBinding in profile.decisionBindings {
            switch decisionBinding.apply(to: &draft) {
            case .skipped:
                continue
            case let .applied(trace, stringifiedValue):
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
                let diagnostic = diagnosticFromConfigError(
                    .decisionFallbackFailed(key: decisionBinding.key),
                    key: decisionBinding.key
                )
                diagnostics.add(diagnostic)
                if errorHandlingMode == .failFast {
                    let snapshot = Snapshot(
                        resolvedValues: resolvedValues,
                        decisionTraces: decisionTraces,
                        diagnostics: DiagnosticsReport()
                    )
                    return .failure(diagnostics: diagnostics, snapshot: snapshot)
                }
            }
        }

        // Check if we have any errors before finalizing
        if diagnostics.hasErrors {
            let snapshot = Snapshot(
                resolvedValues: resolvedValues,
                decisionTraces: decisionTraces,
                diagnostics: DiagnosticsReport()
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot)
        }

        // Finalize draft
        let final: Final
        do {
            final = try profile.finalizeDraft(draft)
        } catch let error as ConfigError {
            let diagnostic = diagnosticFromConfigError(error, key: nil)
            diagnostics.add(diagnostic)

            let snapshot = Snapshot(
                resolvedValues: resolvedValues,
                decisionTraces: decisionTraces,
                diagnostics: DiagnosticsReport()
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot)

        } catch {
            diagnostics.add(
                severity: .error,
                message: "Finalization failed: \(error.localizedDescription)"
            )

            let snapshot = Snapshot(
                resolvedValues: resolvedValues,
                decisionTraces: decisionTraces,
                diagnostics: DiagnosticsReport()
            )
            return .failure(diagnostics: diagnostics, snapshot: snapshot)
        }

        // Success - build final snapshot
        let snapshot = Snapshot(
            resolvedValues: resolvedValues,
            decisionTraces: decisionTraces,
            diagnostics: diagnostics
        )

        return .success(final: final, snapshot: snapshot)
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
        case let .decisionFallbackFailed(decisionKey):
            DiagnosticItem(
                key: key ?? decisionKey,
                severity: .error,
                message: "Decision fallback did not match for key '\(decisionKey)'"
            )
        }
    }

    private static func specContext(_ metadata: SpecMetadata) -> [String: DiagnosticContextValue] {
        [
            "spec": DiagnosticContextValue(metadata.displayName),
            "specType": DiagnosticContextValue(metadata.typeName),
        ]
    }
}
