# SpecificationConfig

[![CI](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/ci.yml/badge.svg)](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/ci.yml)
[![Deploy DocC](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/deploy-docs.yml/badge.svg)](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/deploy-docs.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)](https://github.com/SoundBlaster/SpecificationConfig)

A Swift Configuration wrapper powered by SpecificationCore. It builds typed config values from key-path bindings, validates with specs, and emits deterministic diagnostics.

## Why this wrapper

- Explicit injection: app code owns Draft/Final types, bindings, and specs.
- Typed mapping from keys to Draft via `WritableKeyPath`.
- Value-level and final specs powered by SpecificationCore.
- Deterministic diagnostics and snapshots for UI-friendly reporting.

## Quickstart

Minimal end-to-end usage with an in-memory provider:

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

## Demo app (Config Pet)

The demo app lives under `Demo/ConfigPetApp` and bundles `config.json`.

```bash
cd Demo/ConfigPetApp

tuist install

tuist generate

open ConfigPetApp.xcworkspace
```

Run the `ConfigPetApp` scheme and update `Demo/ConfigPetApp/config.json` to test reloads.

## Documentation

DocC tutorials live under `Sources/SpecificationConfig/Documentation.docc/Tutorials/`.
Start with `01_MVP.tutorial` for the v0 walkthrough.

## Requirements

- Swift 6.0 or later
- Xcode 16.2 (Xcode 26.0) or later (for development on macOS)

## Building and Testing

```bash
swift build -v
swift test -v
swiftformat --lint .
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
