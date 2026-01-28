# SpecificationConfig

[![CI](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/ci.yml/badge.svg)](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/ci.yml)
[![Deploy DocC](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/deploy-docs.yml/badge.svg)](https://github.com/SoundBlaster/SpecificationConfig/actions/workflows/deploy-docs.yml)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-lightgrey.svg)](https://github.com/SoundBlaster/SpecificationConfig)

A Swift Configuration wrapper powered by SpecificationCore. It builds typed config values from key-path bindings and emits diagnostics plus snapshots.

## Manifest

- Product: `SpecificationConfig` (Swift Package)
- Platforms: macOS 15+, iOS 18+
- Dependencies: `swift-configuration`, `SpecificationCore`, `swift-docc-plugin`

## Features

- Typed bindings from config keys to Draft via `WritableKeyPath`
- Value and final specs with diagnostics and deterministic ordering
- Provenance-aware snapshots (file/env/default/decision)
- Decision bindings with trace metadata
- Redaction support for secret values

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

## Configuration Sources

SpecificationConfig works with any provider from [swift-configuration](https://github.com/apple/swift-configuration). The examples below show common patterns.

### JSON File

JSON support is enabled by default via the `JSON` trait:

```swift
import Configuration
import SpecificationConfig
import SystemPackage

let provider = try await FileProvider<JSONSnapshot>(
    filePath: FilePath("/path/to/config.json")
)
let reader = ConfigReader(provider: provider)
let result = ConfigPipeline.build(profile: profile, reader: reader)
```

### YAML File

Enable the `YAML` trait in your `Package.swift` dependency:

```swift
.package(url: "https://github.com/apple/swift-configuration", from: "1.0.0", traits: ["YAML"])
```

Then use `YAMLSnapshot`:

```swift
let provider = try await FileProvider<YAMLSnapshot>(
    filePath: FilePath("/path/to/config.yaml")
)
let reader = ConfigReader(provider: provider)
let result = ConfigPipeline.build(profile: profile, reader: reader)
```

### Stacking Providers

Use multiple providers with precedence (first match wins):

```swift
let reader = ConfigReader(providers: [
    EnvironmentVariablesProvider(),                                    // highest priority
    try await FileProvider<JSONSnapshot>(filePath: FilePath("config.json")), // file values
    InMemoryProvider(values: ["app.timeout": 30]),                    // defaults
])
```

> **Note:** TOML is not currently supported by swift-configuration.

## Documentation

All details live in DocC under `Sources/SpecificationConfig/Documentation.docc/`.

## Building and Testing

```bash
swift build -v
swift test -v
swiftformat --lint . # if installed
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
