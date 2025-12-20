# ``SpecificationConfig``

A Swift Configuration wrapper powered by SpecificationCore. Build typed config values from key-path bindings, validate with specs, and surface deterministic diagnostics.

## Overview

SpecificationConfig gives you a small, explicit pipeline for configuration:

1. Define Draft and Final types for your app config.
2. Bind config keys into the draft with `Binding` and `SpecProfile`.
3. Validate with `SpecEntry` and `ContextualSpecEntry`.
4. Apply decision fallbacks when data is missing.
5. Build with `ConfigPipeline` and inspect diagnostics and snapshots.

### Key Features

- Typed bindings from config keys to draft properties using key paths.
- Value specs, final specs, and contextual specs for validation.
- Decision bindings for deterministic fallbacks and traceability.
- Deterministic diagnostics and snapshots for UI-friendly reporting.
- Provenance tracking (file, environment, default, decision) for every resolved value.

## Quick Start

### Basic Pipeline
```swift
import Configuration
import SpecificationConfig

struct AppDraft {
    var petName: String?
}

struct AppConfig {
    let petName: String
}

enum AppConfigError: Error {
    case missingName
}

let profile = SpecProfile<AppDraft, AppConfig>(
    bindings: [
        AnyBinding(
            Binding(
                key: "pet.name",
                keyPath: \AppDraft.petName,
                decoder: ConfigReader.string
            )
        ),
    ],
    finalize: { draft in
        guard let petName = draft.petName else {
            throw AppConfigError.missingName
        }
        return AppConfig(petName: petName)
    },
    makeDraft: AppDraft.init
)

let provider = InMemoryProvider(values: [
    AbsoluteConfigKey(stringLiteral: "pet.name"): ConfigValue(stringLiteral: "Egorchi"),
])
let reader = ConfigReader(provider: provider)

let result = ConfigPipeline.build(profile: profile, reader: reader)
```

### Inspect Diagnostics and Snapshot
```swift
switch result {
case let .success(config, snapshot):
    print("Config loaded: \(config.petName)")
    print("Resolved values: \(snapshot.resolvedValues.count)")
case let .failure(diagnostics, snapshot):
    print("Errors: \(diagnostics.errorCount)")
    for item in diagnostics.diagnostics {
        print(item.formattedDescription())
    }
    print("Resolved values before failure: \(snapshot.resolvedValues.count)")
}
```

### Context and Decision Fallbacks
```swift
import Foundation
import SpecificationConfig

struct AppDraft {
    var petName: String?
    var isSleeping: Bool?
}

struct AppConfig {
    let petName: String
    let isSleeping: Bool
}

struct NightContextProvider: ContextProviding {
    func currentContext() -> EvaluationContext {
        EvaluationContext(
            currentDate: Date(),
            launchDate: Date(),
            userData: [:],
            counters: [:],
            events: [:],
            flags: ["nightTime": true],
            segments: []
        )
    }
}

let profile = SpecProfile<AppDraft, AppConfig>(
    bindings: [
        AnyBinding(
            Binding(
                key: "pet.isSleeping",
                keyPath: \AppDraft.isSleeping,
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
    ],
    decisionBindings: [
        AnyDecisionBinding(
            DecisionBinding(
                key: "pet.name",
                keyPath: \AppDraft.petName,
                decisions: [
                    DecisionEntry(
                        description: "Sleeping pet",
                        predicate: { draft in draft.isSleeping == true },
                        result: "Sleepy"
                    ),
                ]
            )
        ),
    ],
    contextProvider: AnyContextProvider(NightContextProvider()),
    finalize: { draft in
        AppConfig(
            petName: draft.petName ?? "Unknown",
            isSleeping: draft.isSleeping ?? false
        )
    },
    makeDraft: AppDraft.init
)
```

## Tutorials

Start with the Config Pet walkthroughs:

- <doc:Tutorials> - Tutorial map and entry point
- <doc:01_MVP> - Build the MVP with bindings, pipeline, and diagnostics
- <doc:02_EnvOverrides> - Environment overrides and provider precedence
- <doc:03_ValueSpecs> - Value specs and diagnostics
- <doc:04_Decisions> - Decision bindings for fallbacks
- <doc:05_Watching> - Optional hot reload wiring
- <doc:06_ContextSpecs> - Contextual specs and UI feedback

## Getting Started

Add SpecificationConfig with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/SoundBlaster/SpecificationConfig.git", branch: "main")
]
```

## Topics

### Core Pipeline

- ``SpecProfile``
- ``Binding``
- ``AnyBinding``
- ``ConfigPipeline``
- ``BuildResult``
- ``ErrorHandlingMode``

### Validation and Diagnostics

- ``SpecEntry``
- ``ContextualSpecEntry``
- ``DiagnosticsReport``
- ``DiagnosticItem``
- ``DiagnosticSeverity``

### Decisions and Fallbacks

- ``DecisionEntry``
- ``DecisionBinding``
- ``AnyDecisionBinding``
- ``DecisionTrace``

### Context and Evaluation

- ``EvaluationContext``
- ``ContextProviding``
- ``AnyContextProvider``

### Snapshot and Provenance

- ``Snapshot``
- ``ResolvedValue``
- ``Provenance``
- ``ResolvedValueProvenanceReporter``
