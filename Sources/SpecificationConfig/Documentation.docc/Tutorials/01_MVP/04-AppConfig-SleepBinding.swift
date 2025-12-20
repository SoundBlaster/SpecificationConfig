import Configuration
import SpecificationConfig

AnyBinding(
    Binding(
        key: "pet.isSleeping",
        keyPath: \AppConfigDraft.isSleeping,
        decoder: ConfigReader.bool,
        defaultValue: false,
        contextualValueSpecs: [
            ContextualSpecEntry(description: "Pets sleep at night") { context, isSleeping in
                if context.flag(for: "nightTime") {
                    return isSleeping
                }
                return !isSleeping
            },
        ]
    )
),
