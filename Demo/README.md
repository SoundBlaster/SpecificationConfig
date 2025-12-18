# Config Pet Demo App

Demonstration application for the SpecificationConfig library.

## Current Status

- **E1 Complete:** App scaffolding created
- **E2 Pending:** Configuration file loading
- **E3 Pending:** AppConfig types and SpecProfile
- **E4 Pending:** Split-view UI with reload button
- **E5 Pending:** Error display panel

## Building and Running

### Option 1: Using Xcode (Recommended for macOS App)

1. Navigate to the demo directory:
   ```bash
   cd Demo/ConfigPetApp
   ```

2. Open the package in Xcode:
   ```bash
   open Package.swift
   ```

3. In Xcode:
   - Select "ConfigPetApp" scheme
   - Product > Run (⌘R)

The app will launch as a macOS SwiftUI application.

### Option 2: Using Swift Package Manager

From the demo directory:

```bash
cd Demo/ConfigPetApp
swift run ConfigPetApp
```

Note: This runs as a command-line executable with SwiftUI. For full macOS app experience, use Option 1.

## Project Structure

```
ConfigPetApp/
├── Package.swift              # SPM package definition
└── ConfigPetApp/
    ├── ConfigPetApp.swift     # App entry point (@main)
    └── ContentView.swift      # Main view (currently placeholder)
```

## Dependencies

The app depends on the SpecificationConfig library via local package reference:

```swift
.package(path: "../..")
```

This ensures the demo always uses the latest library code from the repository.

## Development Workflow

When working on the demo app:

1. Make changes to library code in `Sources/SpecificationConfig/`
2. Library changes are immediately available to the demo app
3. Build and run the demo to test integration

## Future Features

### Task E2: Configuration Loading
- Add config.json file support
- Create FileProvider for reading config
- Integrate with library's ConfigReader

### Task E3: AppConfig Types
- Define AppConfigDraft and AppConfig structs
- Create bindings for name and isSleeping
- Set up SpecProfile for pet configuration

### Task E4: UI Layout
- Split view: config values (left) + pet display (right)
- Reload button to refresh configuration
- Pet state visualization

### Task E5: Error Display
- Error list panel for validation failures
- Diagnostic message formatting
- Error highlighting

## Troubleshooting

### Package Dependency Not Resolving

If Xcode shows "Missing package product 'SpecificationConfig'":

1. File > Packages > Reset Package Caches
2. File > Packages > Resolve Package Versions

### Build Errors

Ensure the root SpecificationConfig library builds successfully:

```bash
cd ../..
swift build
swift test
```

## Notes

- Minimum macOS version: 15.0
- SwiftUI lifecycle
- Uses local package dependency for development
- Ready for E2-E5 implementation
