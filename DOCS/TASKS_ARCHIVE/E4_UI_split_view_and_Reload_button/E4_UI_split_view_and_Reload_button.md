# Task PRD: E4 — UI split view + Reload button

**Version:** 1.0.0
**Status:** Complete
**Task ID:** E4
**Priority:** High
**Effort:** M
**Dependencies:** E3 (AppConfig + SpecProfile)

---

## 1. Objective

Refactor the ConfigPetApp UI into a split view with configuration inputs/status on the left and pet display on the right, and add a Reload button that rebuilds configuration on demand.

**Current State:**
- Single-column VStack layout
- No reload control
- Displays AppConfig values in a single block

**Target State:**
- Split view layout: left panel for config status/values, right panel for pet visualization
- Reload button triggers ConfigManager reload
- Layout is simple and clear for the v0 MVP

**Source:** PRD §9 Phase E, Task E4

---

## 2. Scope and Intent

### 2.1 What this task delivers

1. Split view UI layout in ContentView
2. Left panel with config status + values + reload button
3. Right panel with pet name and sleeping state visualization
4. Reload button wired to ConfigManager.loadConfig()

### 2.2 What this task does NOT deliver

- Error list panel (E5)
- Advanced pet animation or assets
- Additional config fields beyond pet.name/isSleeping

### 2.3 Success Criteria

- [x] ContentView uses split view layout (left/right)
- [x] Reload button triggers config reload
- [x] Left panel shows status and current AppConfig values
- [x] Right panel shows pet name and state
- [x] Manual run shows values updating after config.json edits + reload
- [x] `swift build -v`, `swift test -v`, `swiftformat --lint .` succeed

---

## 3. Requirements

### 3.1 Functional Requirements

**FR-1: Split view layout**
- Use a two-pane layout (HStack with panels or NavigationSplitView)
- Left: configuration status + values
- Right: pet display (name + sleeping indicator)

**Acceptance Criteria:**
- Panels are visually distinct
- Layout adapts to window resizing

**FR-2: Reload button**
- Add a Reload button in the left panel
- Button triggers ConfigManager.loadConfig()

**Acceptance Criteria:**
- Button updates AppConfig after config.json changes

**FR-3: Pet visualization**
- Show pet name prominently
- Show sleeping state in a simple visual (text + icon)

**Acceptance Criteria:**
- Pet name and status are visible without scrolling

### 3.2 Non-Functional Requirements

**NFR-1: Maintainability**
- Keep UI changes localized to ContentView
- Avoid adding new assets or dependencies

**NFR-2: Accessibility**
- Use system colors and text styles where possible

---

## 4. Technical Design

### 4.1 ContentView Structure

- Root HStack with two VStack panels
- Left panel:
  - App title + subtitle
  - Status line
  - Config values
  - Reload button
- Right panel:
  - Pet name
  - Sleeping state indicator

---

## 5. Execution Plan (Checklist)

- [x] Update ContentView layout to split view
- [x] Add Reload button and hook to ConfigManager.loadConfig()
- [x] Add basic pet display panel
- [x] Run `swift build -v`
- [x] Run `swift test -v`
- [x] Run `swiftformat --lint .`

---

## 6. Acceptance Criteria

- Split view layout implemented with left config panel and right pet panel
- Reload button rebuilds configuration and updates UI
- All validation commands pass

---

## 7. Definition of Done

- All checklist items complete
- Task documentation updated with completed checklist
- `DOCS/Workplan.md` marks E4 as complete

**Archived:** 2025-12-18
