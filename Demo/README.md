# Config Pet Demo App

Demonstration application for the SpecificationConfig library.

## Current Status

- **E1 Complete:** App scaffolding created
- **E2 Complete:** Configuration file loading
- **E3 Pending:** AppConfig types and SpecProfile
- **E4 Pending:** Split-view UI with reload button
- **E5 Pending:** Error display panel

## Building and Running

### Prerequisites

- Tuist must be installed
- macOS 15.0 or later

### Using Tuist + Xcode (Required)

1. Navigate to the demo directory:
   ```bash
   cd Demo/ConfigPetApp
   ```

2. Install dependencies:
   ```bash
   tuist install
   ```

3. Generate the Xcode project:
   ```bash
   tuist generate
   ```

4. Open the workspace:
   ```bash
   open ConfigPetApp.xcworkspace
   ```

5. In Xcode:
   - Select "ConfigPetApp" scheme
   - Product > Run (⌘R)

The app will launch as a macOS SwiftUI application.

### Quick Regeneration

After making changes to Project.swift or dependencies:

```bash
tuist generate
```

## Project Structure

```
ConfigPetApp/
├── Project.swift              # Tuist project manifest
├── Tuist/
│   └── Package.swift         # External dependencies (SPM)
└── ConfigPetApp/
    ├── ConfigPetApp.swift     # App entry point (@main)
    └── ContentView.swift      # Main view (currently placeholder)
```

## Dependencies

The app is managed by Tuist and depends on the SpecificationConfig library via local package reference:

```swift
// In Tuist/Package.swift
.package(path: "../../..")

// In Project.swift
.external(name: "SpecificationConfig")
```

This ensures the demo always uses the latest library code from the repository.

## Development Workflow

When working on the demo app:

1. Make changes to library code in `Sources/SpecificationConfig/`
2. Regenerate the project if needed: `tuist generate`
3. Library changes are immediately available to the demo app
4. Build and run the demo to test integration

## Configuration File

The app reads configuration from `config.json` in the project root.

### Format

```json
{
  "pet": {
    "name": "Egorchi",
    "isSleeping": true
  }
}
```

### Fields

- `pet.name` (String): The pet's display name
- `pet.isSleeping` (Boolean): Whether the pet is currently asleep

To modify the configuration:
1. Edit `Demo/ConfigPetApp/config.json`
2. Reload the app (or use the Reload button when E4 is complete)

## Future Features

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

### Project Not Generating

If `tuist generate` fails:

1. Clean Tuist cache: `tuist clean`
2. Reinstall dependencies: `tuist install`
3. Try generating again: `tuist generate`

### Build Errors

Ensure the root SpecificationConfig library builds successfully:

```bash
cd ../..
swift build
swift test
```

### Tuist Installation

If Tuist is not installed, install it using:

```bash
curl -Ls https://install.tuist.io | bash
```

## Notes

- Minimum macOS version: 15.0
- SwiftUI lifecycle
- Uses local package dependency for development
- Ready for E2-E5 implementation
