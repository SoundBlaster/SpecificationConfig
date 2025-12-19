import Configuration
import SpecificationConfig

func loadConfig() {
    do {
        let loader = ConfigFileLoader.findConfigFile() ?? ConfigFileLoader()
        let reporter = ResolvedValueProvenanceReporter()
        let newReader = try loader.createReader(accessReporter: reporter)
        reader = newReader
        provenanceReporter = reporter
        build(with: newReader, provenanceReporter: reporter)
        loadError = nil
    } catch {
        reader = nil
        buildResult = nil
        config = nil
        loadError = error
        provenanceReporter = nil
    }
}
