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

If you have Docker installed, this is the simplest way to match CI's Swift toolchains:

```bash
docker run --rm -it -v "$PWD":/work -w /work swift:6.0 swift test -v
```

(CI also tests Swift 5.10; swap the tag if needed.)

### Option B: Install via swiftly (Recommended)

The simplest native installation uses swiftly, the official Swift version manager:

```bash
curl -L https://swift-server.github.io/swiftly/swiftly-install.sh | bash
source ~/.local/share/swiftly/env.sh
swiftly install 6.0.3
```

### Option C: Manual Install (Ubuntu 24.04)

```bash
# Install dependencies
sudo apt update && sudo apt install -y \
    binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
    libedit2 libgcc-9-dev libpython3-dev libsqlite3-0 \
    libstdc++-9-dev libxml2-dev libz3-dev pkg-config \
    tzdata unzip zlib1g-dev

# Download and extract Swift
cd /tmp
wget https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
tar -xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
sudo mv swift-6.0.3-RELEASE-ubuntu24.04 /usr/share/swift

# Add to PATH (add to ~/.bashrc for persistence)
export PATH="/usr/share/swift/usr/bin:$PATH"
```

For Ubuntu 22.04, replace `ubuntu2404` with `ubuntu2204` in the URL.

### Verify Installation

```bash
swift --version
swift build -v
swift test -v
```

## Troubleshooting

- `swift: command not found` → install Swift (macOS: Xcode; Linux: Docker or swift.org toolchain).
- Builds locally but fails in CI → re-run the exact CI commands from `.github/workflows/ci.yml`.
