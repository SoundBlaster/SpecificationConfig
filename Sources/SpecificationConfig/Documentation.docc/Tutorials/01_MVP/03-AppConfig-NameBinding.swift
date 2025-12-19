import Configuration
import SpecificationConfig

AnyBinding(
    Binding(
        key: "pet.name",
        keyPath: \AppConfigDraft.petName,
        decoder: ConfigReader.string,
        valueSpecs: [
            SpecEntry(description: "Non-empty pet name") { value in
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            },
        ]
    )
),
