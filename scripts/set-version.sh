#!/usr/bin/env bash
#
# Single source of truth for the project version.
# Writes — or with --check, verifies — the given semantic version
# into every build manifest:
#
#   mobile_client/pubspec.yaml             (Flutter: build-name + build-number)
#   desktop_app/package.json               (npm/Tauri frontend)
#   desktop_app/src-tauri/tauri.conf.json  (drives desktop bundle/asset names)
#   desktop_app/src-tauri/Cargo.toml       ([package] version)
#
# Usage:
#   scripts/set-version.sh 1.2.3           # write 1.2.3 into all manifests
#   scripts/set-version.sh --check 1.2.3   # verify all manifests == 1.2.3 (CI)
#
# A leading 'v' is accepted for convenience, so a raw git tag works directly:
#   scripts/set-version.sh --check "$GITHUB_REF_NAME"
#
set -euo pipefail

CHECK=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK=1
  shift
fi

RAW="${1:-}"
VERSION="${RAW#v}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be MAJOR.MINOR.PATCH (got '${RAW}')" >&2
  echo "usage: $0 [--check] <version>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IFS=. read -r MAJOR MINOR PATCH <<<"$VERSION"
# Android versionCode must be a monotonically increasing integer. Derive it
# deterministically from the semver so it always grows as the version grows.
BUILD=$((MAJOR * 10000 + MINOR * 100 + PATCH))

PUBSPEC="$ROOT/mobile_client/pubspec.yaml"
PKG_JSON="$ROOT/desktop_app/package.json"
TAURI="$ROOT/desktop_app/src-tauri/tauri.conf.json"
CARGO="$ROOT/desktop_app/src-tauri/Cargo.toml"

for f in "$PUBSPEC" "$PKG_JSON" "$TAURI" "$CARGO"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing manifest: $f" >&2
    exit 1
  fi
done

# The versionCode formula packs minor/patch into two decimal digits each, so
# they must stay below 100 to keep the code monotonic and collision-free.
if (( MINOR > 99 || PATCH > 99 )); then
  echo "error: minor and patch must be <= 99 for the Android versionCode formula" >&2
  exit 1
fi

# --- portable readers (no GNU-only sed; runs on Linux/macOS/Git Bash) ---
read_pubspec() { awk -F'[ +]' '/^version:/{print $2; exit}' "$PUBSPEC"; }
read_json() {
  node -e '
    const fs = require("fs");
    process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).version || "");
  ' "$1"
}
read_cargo()   { awk -F'"' '/^version *= *"/{print $2; exit}' "$CARGO"; }

if [[ "$CHECK" == 1 ]]; then
  status=0
  while IFS='|' read -r label actual; do
    if [[ "$actual" != "$VERSION" ]]; then
      echo "MISMATCH: $label is '$actual', expected '$VERSION'" >&2
      status=1
    else
      echo "ok: $label = $actual"
    fi
  done <<EOF
pubspec.yaml|$(read_pubspec)
package.json|$(read_json "$PKG_JSON")
tauri.conf.json|$(read_json "$TAURI")
Cargo.toml|$(read_cargo)
EOF
  if [[ "$status" != 0 ]]; then
    echo "" >&2
    echo "Run 'scripts/set-version.sh $VERSION' and commit before tagging." >&2
  fi
  exit "$status"
fi

# --- writers ---
# pubspec.yaml: version: <name>+<code>
tmp="$(mktemp)"
awk -v v="$VERSION" -v b="$BUILD" \
  '/^version:/{print "version: " v "+" b; next} {print}' "$PUBSPEC" >"$tmp"
mv "$tmp" "$PUBSPEC"

# JSON manifests: set .version, preserving 2-space formatting.
for f in "$PKG_JSON" "$TAURI"; do
  node -e '
    const fs = require("fs");
    const file = process.argv[1];
    const j = JSON.parse(fs.readFileSync(file, "utf8"));
    j.version = process.argv[2];
    fs.writeFileSync(file, JSON.stringify(j, null, 2) + "\n");
  ' "$f" "$VERSION"
done

# Cargo.toml: only the first 'version = \"...\"' line (the [package] one).
tmp="$(mktemp)"
awk -v v="$VERSION" \
  'done!=1 && /^version *= *"/{print "version = \"" v "\""; done=1; next} {print}' \
  "$CARGO" >"$tmp"
mv "$tmp" "$CARGO"

echo "Set version $VERSION (Android versionCode $BUILD) across all manifests."
