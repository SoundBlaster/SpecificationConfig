# Task PRD: E1 — Create macOS SwiftUI app target

**Version:** 1.0.0
**Status:** PLAN Complete
**Task ID:** E1
**Priority:** High
**Effort:** Medium
**Dependencies:** A1 (Repository exists)

---

## 1. Objective

Create a buildable macOS SwiftUI application target named "ConfigPetApp" to serve as the demo for the SpecificationConfig library. This is the foundation for the "Config Pet" demo that will showcase configuration-driven UI updates.

**Current State:**
- No demo app exists
- SpecificationConfig library is complete through Phase D
- Package.swift only defines library target

**Target State:**
- Xcode project at `Demo/ConfigPetApp/ConfigPetApp.xcodeproj`
- Minimal working SwiftUI app that builds and runs
- App depends on SpecificationConfig library
- Clean project structure ready for E2-E5 implementation

**Source:** PRD §9 Phase E, Task E1

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Xcode project structure in `Demo/ConfigPetApp/`
2. Minimal SwiftUI app with App delegate and ContentView
3. Project configured to depend on SpecificationConfig
4. App builds and launches successfully
5. Placeholder UI showing app is ready for config integration
6. .gitignore updates for Xcode-specific files

### 2.2 What this task does NOT deliver

- Configuration loading logic (E2)
- AppConfig types or SpecProfile (E3)
- Actual UI layout (E4, E5)
- Tutorial documentation (F1)
- Any config.json files yet

### 2.3 Success Criteria

- [x] ⏳ Xcode project exists at `Demo/ConfigPetApp/ConfigPetApp.xcodeproj`
- [x] ⏳ App builds without errors
- [x] ⏳ App launches and displays window with placeholder content
- [x] ⏳ Project depends on SpecificationConfig library
- [x] ⏳ Project structure follows macOS SwiftUI conventions
- [x] ⏳ Clean separation between app code and library code
- [x] ⏳ Git ignores Xcode user-specific files
- [x] ⏳ Documentation explains how to open and run the app

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Xcode project creation**
- Create new macOS SwiftUI app project
- Name: ConfigPetApp
- Bundle identifier: com.example.ConfigPetApp (or similar)
- Minimum deployment target: macOS 15.0 (matches Package.swift)
- SwiftUI lifecycle

**Acceptance Criteria:**
- Project file is valid and opens in Xcode
- Project settings match macOS 15.0 minimum
- SwiftUI app lifecycle enabled

**FR-2: Library dependency**
- Project depends on SpecificationConfig SPM library
- Uses local package path (../.. from Demo/ConfigPetApp)
- Can import SpecificationConfig in source files

**Acceptance Criteria:**
- Xcode resolves SpecificationConfig package
- Can write `import SpecificationConfig` without errors
- Library types are available in app code

**FR-3: Minimal app structure**
- App entry point (@main App struct)
- ContentView with placeholder UI
- Window configuration appropriate for demo

**Acceptance Criteria:**
- App launches and shows window
- Window has reasonable default size
- Placeholder text visible

**FR-4: Project organization**
- Clean file structure
- Separate groups for Views, Models (for future use)
- Assets catalog for future resources

**Acceptance Criteria:**
- Xcode navigator shows logical organization
- Easy to locate files
- Standard macOS app structure

### 3.2 Non-Functional Requirements

**NFR-1: Build performance**
- Debug builds complete in reasonable time
- No unnecessary compilation flags or complex build phases

**NFR-2: Developer experience**
- Opening project in Xcode is straightforward
- Standard Xcode shortcuts and features work
- No custom build scripts or complex setup needed (yet)

**NFR-3: Maintainability**
- Standard Xcode project structure
- Follows Swift package conventions for local dependencies
- Easy to add new files and features

**NFR-4: Documentation**
- README in Demo/ directory explaining how to build and run
- Comments in code where needed
- Clear naming conventions

---

## 4. Technical Design

### 4.1 Directory Structure

```
Demo/
  ConfigPetApp/
    ConfigPetApp.xcodeproj
    ConfigPetApp/
      ConfigPetApp.swift          # @main App entry point
      ContentView.swift            # Main view (placeholder)
      Assets.xcassets/             # Asset catalog
      ConfigPetApp.entitlements    # Sandbox/capabilities
      Info.plist (if needed)
    ConfigPetApp.xcodeproj/
      project.pbxproj              # Xcode project file
      xcshareddata/
        xcschemes/
          ConfigPetApp.xcscheme    # Build scheme
  README.md                        # How to build and run
```

### 4.2 App Entry Point

```swift
import SwiftUI

@main
struct ConfigPetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 800, height: 600)
    }
}
```

### 4.3 ContentView (Placeholder)

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Config Pet")
                .font(.largeTitle)
            Text("Demo application for SpecificationConfig")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("Configuration loading will be added in task E2")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
```

### 4.4 Package Dependency Setup

In Xcode:
1. File > Add Package Dependencies
2. Add local package: `../..` (relative path to root)
3. Select SpecificationConfig library
4. Add to ConfigPetApp target

This will create Package.swift-like dependency in project file.

### 4.5 Git Configuration

Update `.gitignore` with Xcode-specific entries:

```
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
*.xcworkspace/*
!*.xcworkspace/contents.xcworkspacedata
!*.xcworkspace/xcshareddata/

# User-specific files
xcuserdata/
*.xcuserstate

# Build artifacts
build/
DerivedData/
.build/
```

### 4.6 Key Design Decisions

**1. Xcode project vs SPM executable**
- **Decision:** Use Xcode project
- **Rationale:** macOS SwiftUI apps need proper app bundles, Info.plist, entitlements, etc. SPM executables can't provide full macOS app experience.

**2. Project location**
- **Decision:** `Demo/ConfigPetApp/` directory
- **Rationale:** Matches PRD §5.1 module layout, keeps demo separate from library

**3. Dependency approach**
- **Decision:** Local package dependency via relative path
- **Rationale:** Keeps library and demo in sync during development, standard SPM pattern

**4. Minimum macOS version**
- **Decision:** macOS 15.0
- **Rationale:** Matches Package.swift platforms setting, allows modern SwiftUI features

**5. Initial UI complexity**
- **Decision:** Minimal placeholder text
- **Rationale:** E1 is just scaffolding; UI comes in E4-E5

---

## 5. Implementation Plan

### Phase 1: Create Xcode Project
**Estimated time:** 20-30 minutes

**Subtasks:**
1. [x] Create `Demo/` directory
2. [x] Create `Demo/ConfigPetApp/` directory
3. [x] Open Xcode and create new macOS App project
   - Template: macOS > App
   - Name: ConfigPetApp
   - Save to: Demo/ConfigPetApp/
   - SwiftUI interface, Swift language
   - Minimum deployment: macOS 15.0
4. [x] Verify project structure created correctly

**Verification:**
- Project opens in Xcode
- Default app builds

### Phase 2: Add Library Dependency
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] In Xcode: File > Add Package Dependencies
2. [x] Choose "Add Local Package"
3. [x] Navigate to repository root (../..)
4. [x] Add SpecificationConfig product to ConfigPetApp target
5. [x] Test import in ContentView.swift

**Verification:**
- `import SpecificationConfig` compiles
- Can reference SpecificationConfig types (e.g., `ConfigLoader`)

### Phase 3: Customize Placeholder UI
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] Update ContentView to show placeholder content
2. [x] Add preview for ContentView
3. [x] Update App struct with default window size
4. [x] Build and run to verify appearance

**Verification:**
- App launches with window
- Placeholder text visible
- Window size appropriate

### Phase 4: Git Configuration
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Update root `.gitignore` with Xcode patterns
2. [x] Verify Xcode user files are ignored
3. [x] Ensure project.pbxproj and schemes are tracked
4. [x] Test with `git status`

**Verification:**
- Only essential Xcode files tracked
- xcuserdata/ ignored
- DerivedData/ ignored

### Phase 5: Documentation
**Estimated time:** 15-20 minutes

**Subtasks:**
1. [x] Create `Demo/README.md`
2. [x] Document how to open and build app
3. [x] Document current limitations (no config yet)
4. [x] Add note about future tasks (E2-E5)

**Verification:**
- README is clear
- Instructions work for new users

### Phase 6: Final Verification
**Estimated time:** 10-15 minutes

**Subtasks:**
1. [x] Clean build in Xcode (Product > Clean Build Folder)
2. [x] Rebuild and run
3. [x] Verify app launches
4. [x] Close Xcode, reopen project, verify dependency resolves
5. [x] Run from repository root: `swift build` (should still work)

**Verification:**
- Clean build succeeds
- App runs correctly
- Library still builds via SPM

---

## 6. Test Plan

### 6.1 Manual Testing

Since this is app scaffolding, testing is primarily manual:

| Test | Steps | Expected Result |
|------|-------|-----------------|
| Project opens | Double-click .xcodeproj | Xcode opens project |
| Dependency resolves | Wait for SPM resolution | SpecificationConfig appears in project navigator |
| Clean build | Product > Clean, Product > Build | Build succeeds |
| App launches | Product > Run | Window appears with placeholder UI |
| Window size | Check window dimensions | ~800x600 default size |
| UI content | Verify text displayed | Shows "Config Pet" and subtitle |
| Import library | Add `import SpecificationConfig` to file | No compile errors |

### 6.2 Integration Points

- Xcode project successfully links to local SPM package
- App target includes SpecificationConfig in frameworks
- Build phases configured correctly

---

## 7. Verification Commands

Execute these commands/actions to verify the implementation:

```bash
# 1. Verify directory structure
ls -la Demo/ConfigPetApp/

# 2. Verify Xcode project exists
file Demo/ConfigPetApp/ConfigPetApp.xcodeproj

# 3. Verify library still builds
swift build -v

# 4. Verify library tests still pass
swift test

# 5. Open Xcode project
open Demo/ConfigPetApp/ConfigPetApp.xcodeproj

# In Xcode:
# 6. Product > Build (⌘B)
# 7. Product > Run (⌘R)
# 8. Verify app window appears
```

**Success Criteria:**
- All commands succeed
- Xcode builds app without errors
- App runs and displays window

---

## 8. Dependencies and Risks

### 8.1 Dependencies

| Dependency | Type | Status | Notes |
|------------|------|--------|-------|
| A1 (Repository) | Required | ✅ Complete | Repository structure exists |
| Xcode | Required | System | Need Xcode installed (15.0+) |
| macOS 15.0+ | Required | System | For running the app |
| SpecificationConfig library | Required | ✅ Complete | Library code ready |

### 8.2 Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Xcode version incompatibility | Medium | Low | Document minimum Xcode version |
| SPM local package issues | Medium | Low | Use standard relative path pattern |
| Build configuration problems | Low | Low | Use default Xcode settings, minimal customization |
| Git ignore incomplete | Low | Medium | Test with `git status`, verify user files ignored |

---

## 9. Definition of Done

This task is complete when:

- [x] ⏳ Xcode project exists at `Demo/ConfigPetApp/ConfigPetApp.xcodeproj`
- [x] ⏳ Project depends on SpecificationConfig library
- [x] ⏳ App builds without errors in Xcode
- [x] ⏳ App launches and displays placeholder window
- [x] ⏳ Can import SpecificationConfig in app code
- [x] ⏳ `.gitignore` properly excludes Xcode user files
- [x] ⏳ `Demo/README.md` explains how to build and run
- [x] ⏳ Library still builds via `swift build`
- [x] ⏳ Library tests still pass via `swift test`
- [x] ⏳ All verification steps succeed
- [x] ⏳ Task PRD archived and Workplan updated (pending ARCHIVE phase)

---

## 10. Implementation Notes

### 10.1 Xcode Project Creation Steps

To create the project manually:

1. Open Xcode
2. File > New > Project
3. Choose macOS > App template
4. Configure:
   - Product Name: ConfigPetApp
   - Team: None (or personal team)
   - Organization Identifier: com.example
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None
   - Testing: Can add later
5. Save to: Demo/ConfigPetApp/

This creates the project structure automatically.

### 10.2 Adding Local Package Dependency

In Xcode (with project open):

1. Select project in navigator
2. Select ConfigPetApp target
3. Go to "General" tab
4. Scroll to "Frameworks, Libraries, and Embedded Content"
5. Click "+" button
6. Choose "Add Package Dependency"
7. Click "Add Local..."
8. Navigate two levels up (to repository root)
9. Select SpecificationConfig package
10. Choose SpecificationConfig product
11. Add to ConfigPetApp target

Alternative (using File menu):
1. File > Add Package Dependencies
2. Click "Add Local"
3. Navigate to repository root
4. Add SpecificationConfig

### 10.3 Window Configuration

Default window size is set in App struct:

```swift
.defaultSize(width: 800, height: 600)
```

This provides a reasonable canvas for the split-view UI that will be added in E4.

### 10.4 Git Ignore Patterns

Key patterns to add:

```
# Xcode user-specific
xcuserdata/
*.xcuserstate

# Build artifacts
build/
DerivedData/

# Keep project structure
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
```

---

## Appendix A: Expected File Structure After E1

```
Demo/
├── README.md
└── ConfigPetApp/
    ├── ConfigPetApp.xcodeproj/
    │   ├── project.pbxproj
    │   └── xcshareddata/
    │       └── xcschemes/
    │           └── ConfigPetApp.xcscheme
    └── ConfigPetApp/
        ├── ConfigPetApp.swift      # @main App
        ├── ContentView.swift        # Placeholder view
        ├── Assets.xcassets/
        └── ConfigPetApp.entitlements
```

---

## Appendix B: Related Files

| File | Purpose | Changes |
|------|---------|---------|
| `.gitignore` | Git exclusions | Add Xcode-specific patterns |
| `Demo/README.md` | New file | Instructions for building app |
| `Demo/ConfigPetApp/...` | New directory | Entire Xcode project |
| `Package.swift` | Existing | No changes (library unchanged) |

---

## Appendix C: Future Integration Points

This scaffolding prepares for:

- **E2:** Config file loading logic will be added to app
- **E3:** AppConfig types and SpecProfile will be defined
- **E4:** ContentView will be replaced with split-view UI
- **E5:** Error display panel will be added
- **F1:** Tutorial will reference this project structure

---

**End of PRD**
**Archived:** 2025-12-18
