import Configuration
import SpecificationConfig

private func build(
    with reader: ConfigReader,
    provenanceReporter: ResolvedValueProvenanceReporter?
) {
    DemoContextProvider.shared.recordReload()
    let result = ConfigPipeline.build(
        profile: AppConfig.profile,
        reader: reader,
        provenanceReporter: provenanceReporter
    )
    buildResult = result
    if case let .success(config, _) = result {
        self.config = config
    } else {
        config = nil
    }
}
