# Swift Tooling Setup (macOS + Linux)

## Purpose

Provide minimal, repo-accurate setup steps for building and testing **SpecificationConfig** locally.

CI reference: `.github/workflows/ci.yml`.

## macOS (Recommended)

### Install

- Install Xcode (CI runs on Xcode 15.4+ and 16.0).
- Select the active Xcode if you have multiple installed:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Verify

```bash
swift --version
swift build -v
swift test -v
```

### SwiftFormat (Optional Locally, Required In CI)

CI runs `swiftformat --lint .`. Install via Homebrew:

```bash
brew install swiftformat
swiftformat --lint .
```

## Linux

### Option A: Use Docker (Matches CI)

If you have Docker installed, this is the simplest way to match CI’s Swift toolchains:

```bash
docker run --rm -it -v "$PWD":/work -w /work swift:6.0 swift test -v
```

(CI also tests Swift 5.10; swap the tag if needed.)

### Option B: Install Swift Toolchain

Install Swift using the official instructions for your distribution:

- https://www.swift.org/install/

Then verify:

```bash
swift --version
swift build -v
swift test -v
```

## Troubleshooting

- `swift: command not found` → install Swift (macOS: Xcode; Linux: Docker or swift.org toolchain).
- Builds locally but fails in CI → re-run the exact CI commands from `.github/workflows/ci.yml`.
