# Task PRD: E2 — Add config file loader

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** E2
**Priority:** High
**Effort:** Medium
**Dependencies:** E1 (App scaffolding), D1 (ConfigReader helpers)

---

## 1. Objective

Add configuration file loading infrastructure to ConfigPetApp using Swift Configuration's FileProvider. This includes creating a config.json file and setting up the ConfigReader to read from it.

**Current State:**
- ConfigPetApp has placeholder UI
- No configuration file exists
- No ConfigReader instance

**Target State:**
- config.json file in app's working directory
- FileProvider configured to read from config.json
- ConfigReader instance available to app
- Infrastructure ready for E3 (AppConfig integration)

**Source:** PRD §9 Phase E, Task E2

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. config.json file with pet configuration (name + isSleeping)
2. ConfigFileLoader utility class/struct
3. FileProvider setup to read config.json
4. ConfigReader instance creation
5. Location strategy for finding config.json
6. Error handling for missing/invalid config files
7. Documentation of config file format

### 2.2 What this task does NOT deliver

- AppConfig or Draft types (E3)
- SpecProfile or bindings (E3)
- UI for displaying config (E4)
- Actual configuration loading into types (E3)
- Reload functionality (E4)

### 2.3 Success Criteria

- [x] ⏳ config.json exists with sample pet data
- [x] ⏳ Can create FileProvider pointing to config.json
- [x] ⏳ Can create ConfigReader from FileProvider
- [x] ⏳ ConfigReader successfully reads values from config.json
- [x] ⏳ Error handling for missing config file
- [x] ⏳ Location resolution works (finds config.json in working directory)
- [x] ⏳ Tests verify file reading works
- [x] ⏳ Documentation explains config file format
- [x] ⏳ App builds and runs with config infrastructure
- [x] ⏳ Library tests still pass

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Configuration file creation**
- Create config.json with pet configuration structure
- Location: config.json in app working directory
- Format: JSON with nested pet object
- Fields: name (String), isSleeping (Bool)

**Acceptance Criteria:**
```json
{
  "pet": {
    "name": "Egorchi",
    "isSleeping": true
  }
}
```
- File exists and is valid JSON
- Contains expected structure

**FR-2: File location resolution**
- Determine where to look for config.json
- Options: current directory, app bundle, specific path
- Make location configurable for testing

**Acceptance Criteria:**
- App finds config.json when run from Xcode
- Can override location for tests
- Clear error when file not found

**FR-3: FileProvider creation**
- Use Swift Configuration's FileProvider
- Point to resolved config.json path
- Handle file not found gracefully

**Acceptance Criteria:**
- FileProvider initialized successfully
- Can read from config.json
- Error thrown if file missing

**FR-4: ConfigReader creation**
- Create ConfigReader instance from FileProvider
- Make ConfigReader available to app
- Encapsulate in utility class/struct

**Acceptance Criteria:**
- ConfigReader instance created
- Can read values using ConfigReader helpers (from D1)
- Available to SwiftUI views via environment or @State

**FR-5: Value reading verification**
- Verify can read "pet.name" as String
- Verify can read "pet.isSleeping" as Bool
- Use ConfigReader helper extensions from D1

**Acceptance Criteria:**
- `reader.string(forKey: ConfigKey("pet.name"))` returns "Egorchi"
- `reader.bool(forKey: ConfigKey("pet.isSleeping"))` returns true
- No runtime errors

### 3.2 Non-Functional Requirements

**NFR-1: Error handling**
- Clear error messages for missing file
- Clear error messages for invalid JSON
- Don't crash app if config unavailable

**NFR-2: Testability**
- Can create ConfigReader with test config
- Can inject different file paths
- Can verify file reading in tests

**NFR-3: Maintainability**
- ConfigFileLoader is reusable
- Clear separation of concerns
- Easy to extend for ENV overrides (F3)

**NFR-4: Documentation**
- config.json format documented
- Expected file location documented
- Error conditions documented

---

## 4. Technical Design

### 4.1 Directory Structure

```
Demo/ConfigPetApp/
├── ConfigPetApp/
│   ├── ConfigPetApp.swift
│   ├── ContentView.swift
│   ├── ConfigFileLoader.swift     # New: Config loading utility
│   └── config.json                # New: Config file (or in Resources/)
└── ConfigPetAppTests/              # Optional: tests for config loading
```

### 4.2 ConfigFileLoader Implementation

```swift
import Foundation
import Configuration

/// Loads configuration from config.json file.
struct ConfigFileLoader {
    /// Errors that can occur during config loading.
    enum LoadError: Error, LocalizedError {
        case fileNotFound(path: String)
        case invalidJSON(underlying: Error)
        case readerCreationFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Configuration file not found at: \(path)"
            case .invalidJSON(let error):
                return "Invalid JSON in config file: \(error.localizedDescription)"
            case .readerCreationFailed(let error):
                return "Failed to create config reader: \(error.localizedDescription)"
            }
        }
    }

    /// The path to the configuration file.
    let configFilePath: String

    /// Creates a loader with the default config file path.
    init() {
        // Default: config.json in current working directory
        self.configFilePath = FileManager.default.currentDirectoryPath + "/config.json"
    }

    /// Creates a loader with a specific config file path.
    init(configFilePath: String) {
        self.configFilePath = configFilePath
    }

    /// Creates a ConfigReader from the config file.
    ///
    /// - Returns: A ConfigReader instance ready to read configuration values.
    /// - Throws: LoadError if the file cannot be found or read.
    func createReader() throws -> Configuration.ConfigReader {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: configFilePath) else {
            throw LoadError.fileNotFound(path: configFilePath)
        }

        // Create file URL
        let fileURL = URL(fileURLWithPath: configFilePath)

        // Create FileProvider
        do {
            let provider = try FileProvider(url: fileURL)
            return ConfigReader(provider: provider)
        } catch {
            throw LoadError.readerCreationFailed(underlying: error)
        }
    }

    /// Attempts to find config.json in common locations.
    ///
    /// Search order:
    /// 1. Current working directory
    /// 2. App bundle resources (if running as app)
    ///
    /// - Returns: ConfigFileLoader with resolved path, or nil if not found.
    static func findConfigFile() -> ConfigFileLoader? {
        let fileManager = FileManager.default

        // Try current directory
        let currentDirPath = fileManager.currentDirectoryPath + "/config.json"
        if fileManager.fileExists(atPath: currentDirPath) {
            return ConfigFileLoader(configFilePath: currentDirPath)
        }

        // Try app bundle
        if let bundlePath = Bundle.main.path(forResource: "config", ofType: "json") {
            return ConfigFileLoader(configFilePath: bundlePath)
        }

        return nil
    }
}
```

### 4.3 config.json Format

```json
{
  "pet": {
    "name": "Egorchi",
    "isSleeping": true
  }
}
```

**Field Specifications:**
- `pet.name`: String, required, pet's display name
- `pet.isSleeping`: Boolean, required, whether pet is asleep

### 4.4 Integration with App

Option 1: App-level state (simple, for now):

```swift
import SwiftUI
import Configuration

@main
struct ConfigPetApp: App {
    @State private var configReader: Configuration.ConfigReader?
    @State private var configError: Error?

    init() {
        loadConfig()
    }

    private func loadConfig() {
        do {
            let loader = ConfigFileLoader.findConfigFile() ?? ConfigFileLoader()
            _configReader = State(initialValue: try loader.createReader())
        } catch {
            _configError = State(initialValue: error)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ConfigManager(reader: configReader, error: configError))
        }
        .defaultSize(width: 800, height: 600)
    }
}

// Simple holder for config state
class ConfigManager: ObservableObject {
    let reader: Configuration.ConfigReader?
    let error: Error?

    init(reader: Configuration.ConfigReader?, error: Error?) {
        self.reader = reader
        self.error = error
    }
}
```

Option 2: Observable object (more structured):

```swift
@MainActor
class ConfigManager: ObservableObject {
    @Published var reader: Configuration.ConfigReader?
    @Published var error: Error?

    init() {
        loadConfig()
    }

    func loadConfig() {
        do {
            let loader = ConfigFileLoader.findConfigFile() ?? ConfigFileLoader()
            self.reader = try loader.createReader()
            self.error = nil
        } catch {
            self.reader = nil
            self.error = error
        }
    }
}
```

### 4.5 Config File Location

For development/testing:
- Place config.json in project root (next to Project.swift)
- Xcode will use this as working directory when running app

For production (future):
- Bundle config.json as resource
- Or use application support directory

### 4.6 Key Design Decisions

**1. File location strategy**
- **Decision:** Check current directory first, then app bundle
- **Rationale:** Easier for development; works in Xcode; can override for tests

**2. Error handling approach**
- **Decision:** Capture errors but don't crash app
- **Rationale:** Can show error UI in E5; app remains functional

**3. ConfigReader lifecycle**
- **Decision:** Create once at app launch, store in @State or ObservableObject
- **Rationale:** Simple for MVP; can reload later (E4)

**4. config.json location for E2**
- **Decision:** Put in Demo/ConfigPetApp/ (project root)
- **Rationale:** Xcode uses this as working directory; easy to edit

**5. Use ConfigFileLoader struct**
- **Decision:** Separate utility struct rather than inline code
- **Rationale:** Testable, reusable, clear responsibility

---

## 5. Implementation Plan

### Phase 1: Create Config File
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Create Demo/ConfigPetApp/config.json
2. [x] Add sample pet data (name: "Egorchi", isSleeping: true)
3. [x] Verify JSON is valid
4. [x] Document format in comments

**Verification:**
- JSON validates (use `jq . config.json` or online validator)
- File readable

### Phase 2: Implement ConfigFileLoader
**Estimated time:** 30-40 minutes

**Subtasks:**
1. [x] Create ConfigPetApp/ConfigFileLoader.swift
2. [x] Implement init methods (default + custom path)
3. [x] Implement createReader() method
4. [x] Implement LoadError enum with descriptions
5. [x] Implement findConfigFile() static method
6. [x] Add documentation comments

**Verification:**
- Code compiles
- Can import Configuration module

### Phase 3: Integrate with App
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [x] Choose integration approach (State vs ObservableObject)
2. [x] Update ConfigPetApp.swift to load config
3. [x] Create ConfigManager if using ObservableObject approach
4. [x] Handle errors gracefully (store error, don't crash)
5. [x] Test app launches without config file (error handling)
6. [x] Test app launches with config file (success path)

**Verification:**
- App builds
- App runs (even without config.json)
- App loads config when file present

### Phase 4: Add Basic Verification
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] Add temporary debug output in ContentView
2. [x] Read "pet.name" from ConfigReader
3. [x] Read "pet.isSleeping" from ConfigReader
4. [x] Display values in ContentView (temporary)
5. [x] Verify correct values appear

**Verification:**
- UI shows "Egorchi" and "true" (or similar debug info)
- No runtime errors

### Phase 5: Testing (Optional but Recommended)
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [x] Create ConfigPetAppTests/ directory if needed
2. [x] Write test for ConfigFileLoader with valid file
3. [x] Write test for ConfigFileLoader with missing file
4. [x] Write test for ConfigFileLoader.findConfigFile()
5. [x] Run tests to verify

**Verification:**
- Tests pass
- Coverage for happy path and error cases

### Phase 6: Documentation and Cleanup
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] Add config.json format to Demo/README.md
2. [x] Document config file location
3. [x] Remove debug output from ContentView (if added)
4. [x] Add comments explaining config loading flow
5. [x] Update Project.swift if needed (resources)

**Verification:**
- Documentation clear
- Code clean

### Phase 7: Final Verification
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Clean build in Tuist
2. [x] Run app and verify config loads
3. [x] Verify library still builds: `swift build`
4. [x] Verify library tests pass: `swift test`
5. [x] Check git status

**Verification:**
- App runs successfully
- Config values available to app
- Library unaffected
- Ready for E3

---

## 6. Test Plan

### 6.1 Manual Testing

| Test | Steps | Expected Result |
|------|-------|-----------------|
| Config file present | Place valid config.json, run app | App loads, no errors |
| Config file missing | Remove config.json, run app | App shows error (or handles gracefully) |
| Invalid JSON | Add syntax error to config.json, run app | Error captured, app doesn't crash |
| Read pet.name | Load config, read "pet.name" | Returns "Egorchi" |
| Read pet.isSleeping | Load config, read "pet.isSleeping" | Returns true |

### 6.2 Unit Tests (if implemented)

```swift
import XCTest
@testable import ConfigPetApp
import Configuration

final class ConfigFileLoaderTests: XCTestCase {
    func testLoadValidConfigFile() throws {
        // Create temp config file
        let tempConfig = createTempConfigFile(content: validJSON)
        let loader = ConfigFileLoader(configFilePath: tempConfig.path)

        // Should create reader successfully
        let reader = try loader.createReader()
        XCTAssertNotNil(reader)

        // Should read values
        let name = reader.string(forKey: ConfigKey("pet.name"))
        XCTAssertEqual(name, "Egorchi")
    }

    func testLoadMissingConfigFile() {
        let loader = ConfigFileLoader(configFilePath: "/nonexistent/config.json")

        // Should throw file not found
        XCTAssertThrowsError(try loader.createReader()) { error in
            XCTAssertTrue(error is ConfigFileLoader.LoadError)
        }
    }
}
```

---

## 7. Verification Commands

Execute these commands to verify the implementation:

```bash
# 1. Navigate to demo app
cd Demo/ConfigPetApp

# 2. Verify config file exists and is valid JSON
cat config.json
jq . config.json  # Or python3 -m json.tool config.json

# 3. Generate Tuist project
tuist generate

# 4. Build app
xcodebuild -workspace ConfigPetApp.xcworkspace -scheme ConfigPetApp build

# 5. Verify root library still works
cd ../..
swift build -v
swift test -v

# 6. Run app in Xcode
# Open ConfigPetApp.xcworkspace
# Product > Run (⌘R)
# Verify no crashes, config loads
```

**Success Criteria:**
- All commands succeed
- App runs without errors
- Config values accessible

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| E1 (App scaffolding) | Required | ✅ Complete | App structure exists |
| D1 (ConfigReader helpers) | Required | ✅ Complete | Helper extensions available |
| Swift Configuration | Required | ✅ Available | FileProvider API |
| Tuist | Required | ✅ Available | Project generation |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Config file path issues | Medium | Medium | Use flexible path resolution; test both scenarios |
| FileProvider API unfamiliarity | Low | Low | Reference Swift Configuration docs; use D1 helpers |
| JSON format mismatches | Low | Low | Validate JSON; document format clearly |
| Working directory confusion | Medium | Medium | Document clearly; use findConfigFile() fallback |

---

## 9. Definition of Done

This task is complete when:

- [x] ⏳ config.json exists with pet configuration
- [x] ⏳ ConfigFileLoader.swift implemented and documented
- [x] ⏳ ConfigReader created successfully from config file
- [x] ⏳ Can read "pet.name" and "pet.isSleeping" values
- [x] ⏳ Error handling for missing/invalid files
- [x] ⏳ ConfigReader available to app (via State or ObservableObject)
- [x] ⏳ App builds and runs with Tuist
- [x] ⏳ Config loading tested manually (file present + absent)
- [x] ⏳ Documentation updated (Demo/README.md)
- [x] ⏳ Root library builds: `swift build`
- [x] ⏳ Root library tests pass: `swift test`
- [x] ⏳ Clean git status, ready for commit
- [x] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Swift Configuration FileProvider Usage

```swift
import Configuration

// Create file URL
let fileURL = URL(fileURLWithPath: "/path/to/config.json")

// Create FileProvider
let provider = try FileProvider(url: fileURL)

// Create ConfigReader
let reader = ConfigReader(provider: provider)

// Read values (using D1 helpers)
let name = reader.string(forKey: ConfigKey("pet.name"))
let isSleeping = reader.bool(forKey: ConfigKey("pet.isSleeping"))
```

### 10.2 Working Directory in Xcode

When running from Xcode:
- Working directory is the project directory (where Project.swift lives)
- `FileManager.default.currentDirectoryPath` returns this directory
- config.json should be placed here for easy access during development

### 10.3 Future Enhancements (Out of Scope for E2)

- Multiple config providers (F3: ENV overrides)
- Config file watching (F6)
- Config validation (E3 with SpecProfile)
- Config hot reload (E4)
- Bundling config as resource

---

## Appendix A: Example Usage

### Basic Config Loading

```swift
// In ConfigPetApp.swift
@main
struct ConfigPetApp: App {
    @StateObject private var configManager = ConfigManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
    }
}

// ConfigManager
@MainActor
class ConfigManager: ObservableObject {
    @Published var reader: Configuration.ConfigReader?
    @Published var loadError: Error?

    init() {
        loadConfig()
    }

    func loadConfig() {
        do {
            let loader = ConfigFileLoader.findConfigFile() ?? ConfigFileLoader()
            reader = try loader.createReader()
            loadError = nil
        } catch {
            reader = nil
            loadError = error
        }
    }
}

// In ContentView
struct ContentView: View {
    @EnvironmentObject var configManager: ConfigManager

    var body: some View {
        VStack {
            if let reader = configManager.reader {
                Text("Config loaded successfully")
                // In E3, we'll use this reader with SpecProfile
            } else if let error = configManager.loadError {
                Text("Config error: \(error.localizedDescription)")
            }
        }
    }
}
```

---

## Appendix B: config.json Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Config Pet Configuration",
  "type": "object",
  "required": ["pet"],
  "properties": {
    "pet": {
      "type": "object",
      "required": ["name", "isSleeping"],
      "properties": {
        "name": {
          "type": "string",
          "description": "The pet's display name",
          "minLength": 1
        },
        "isSleeping": {
          "type": "boolean",
          "description": "Whether the pet is currently asleep"
        }
      }
    }
  }
}
```

---

## Appendix C: Related Files

| File | Purpose | Changes |
|------|---------|---------|
| `Demo/ConfigPetApp/config.json` | New file | Configuration data |
| `Demo/ConfigPetApp/ConfigPetApp/ConfigFileLoader.swift` | New file | Config loading utility |
| `Demo/ConfigPetApp/ConfigPetApp/ConfigPetApp.swift` | Modify | Add config loading |
| `Demo/ConfigPetApp/ConfigPetApp/ContentView.swift` | Modify | Show config status (temporary) |
| `Demo/README.md` | Modify | Document config file format |

---

**End of PRD**
**Archived:** 2025-12-18
