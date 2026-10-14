#!/usr/bin/env bash
# Local release build — mirrors CI to catch issues before pushing.
# Usage:
#   ./scripts/build-release.sh          # build everything
#   ./scripts/build-release.sh rust     # controller_server only
#   ./scripts/build-release.sh tauri    # desktop app only
#   ./scripts/build-release.sh flutter  # mobile client only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { echo -e "${GREEN}✓ $1${RESET}"; }
fail() { echo -e "${RED}✗ $1${RESET}"; exit 1; }
header() { echo -e "\n${BOLD}── $1 ──${RESET}"; }

build_rust() {
    header "Controller Server (release)"
    cd "$ROOT/controller_server"
    cargo build --release || fail "cargo build --release failed"
    pass "controller_server release build"

    cargo test --lib || fail "cargo test failed"
    pass "controller_server tests"
}

build_tauri() {
    header "Desktop App — Tauri (release)"
    cd "$ROOT/desktop_app"

    if ! command -v npx &>/dev/null; then
        fail "Node.js / npx not found — install Node 20+"
    fi

    npm ci --silent || fail "npm ci failed"
    npx tauri build 2>&1 || fail "tauri build failed"
    pass "tauri release build"
}

build_flutter() {
    header "Mobile Client — Flutter (release APK)"
    cd "$ROOT/mobile_client"

    if ! command -v flutter &>/dev/null; then
        fail "flutter not found — install Flutter SDK"
    fi

    local python_command
    if command -v python3 &>/dev/null; then
        python_command=python3
    elif command -v python &>/dev/null; then
        python_command=python
    else
        fail "Python 3 is required to check the pinned Flutter SDK"
    fi
    "$python_command" "$ROOT/scripts/check_flutter_version.py" || fail "Flutter SDK does not match the project pin"
    flutter pub get --enforce-lockfile || fail "Locked Flutter dependencies could not be resolved"
    flutter build apk --release --no-tree-shake-icons --no-pub || fail "flutter build apk --release failed"
    pass "flutter release APK"
}

case "$TARGET" in
    rust)    build_rust ;;
    tauri)   build_tauri ;;
    flutter) build_flutter ;;
    all)
        build_rust
        build_tauri
        build_flutter
        ;;
    *)
        echo "Usage: $0 {rust|tauri|flutter|all}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}All requested builds passed.${RESET}"
