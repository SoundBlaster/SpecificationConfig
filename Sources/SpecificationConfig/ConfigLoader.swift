import Configuration

/// A stateful configuration loader that encapsulates a profile and reader
/// for convenient reloading without re-specifying parameters.
///
/// Use `ConfigLoader` when you need to reload configuration multiple times
/// (e.g., in response to a "Reload" button or file change event) without
/// manually passing the profile and reader each time.
///
/// ## Example
///
/// ```swift
/// let loader = ConfigLoader(
///     profile: myProfile,
///     reader: configReader,
///     errorHandlingMode: .collectAll
/// )
///
/// // Initial load
/// let result = loader.build()
///
/// // Later, reload after config file changes
/// let newResult = loader.reload()
/// ```
///
/// ## Thread Safety
///
/// `ConfigLoader` itself is a simple struct with no internal mutable state.
/// Thread safety depends on the thread safety of the stored `ConfigReader`.
/// If the reader is thread-safe, the loader can be used from multiple threads.
public struct ConfigLoader<Draft, Final> {
    private let profile: SpecProfile<Draft, Final>
    private let reader: Configuration.ConfigReader
    private let errorHandlingMode: ErrorHandlingMode

    /// Creates a configuration loader with the specified profile and reader.
    ///
    /// - Parameters:
    ///   - profile: The specification profile defining bindings and finalization.
    ///   - reader: The configuration reader supplying values.
    ///   - errorHandlingMode: Strategy for handling errors (default: `.collectAll`).
    public init(
        profile: SpecProfile<Draft, Final>,
        reader: Configuration.ConfigReader,
        errorHandlingMode: ErrorHandlingMode = .collectAll
    ) {
        self.profile = profile
        self.reader = reader
        self.errorHandlingMode = errorHandlingMode
    }

    /// Builds configuration using the stored profile and reader.
    ///
    /// Each call creates a fresh draft and re-reads from the configuration reader.
    /// No caching or state is maintained between calls.
    ///
    /// - Returns: Build result containing either success (final config + snapshot)
    ///            or failure (diagnostics + partial snapshot).
    public func build() -> BuildResult<Final> {
        ConfigPipeline.build(
            profile: profile,
            reader: reader,
            errorHandlingMode: errorHandlingMode
        )
    }

    /// Reloads configuration using the stored profile and reader.
    ///
    /// This is semantically equivalent to `build()` but more clearly conveys
    /// the intent of refreshing configuration from potentially changed sources.
    ///
    /// Each reload creates a fresh draft and re-reads all configuration values,
    /// producing updated diagnostics and snapshot.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // In a SwiftUI view model
    /// @MainActor
    /// class ConfigManager: ObservableObject {
    ///     @Published var config: AppConfig?
    ///     private let loader: ConfigLoader<AppConfigDraft, AppConfig>
    ///
    ///     func reloadConfig() {
    ///         let result = loader.reload()
    ///         switch result {
    ///         case let .success(newConfig, _):
    ///             config = newConfig
    ///         case let .failure(diagnostics, _):
    ///             // Handle errors
    ///             print(diagnostics.summary)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: Build result containing either success (final config + snapshot)
    ///            or failure (diagnostics + partial snapshot).
    public func reload() -> BuildResult<Final> {
        build()
    }
}
