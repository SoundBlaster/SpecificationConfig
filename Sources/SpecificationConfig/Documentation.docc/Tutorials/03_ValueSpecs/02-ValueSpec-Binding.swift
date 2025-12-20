import Configuration
import SpecificationConfig

let petNameBinding = Binding(
    key: "pet.name",
    keyPath: \AppConfigDraft.petName,
    decoder: ConfigReader.string,
    valueSpecs: [nonEmptyNameSpec]
)
