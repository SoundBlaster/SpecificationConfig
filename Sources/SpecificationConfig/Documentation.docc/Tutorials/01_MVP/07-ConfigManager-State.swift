import Configuration
import SpecificationConfig

@MainActor
class ConfigManager: ObservableObject {
    @Published var reader: ConfigReader?
    @Published var buildResult: BuildResult<AppConfig>?
    @Published var config: AppConfig?
    @Published var loadError: Error?

    private var provenanceReporter: ResolvedValueProvenanceReporter?
}
