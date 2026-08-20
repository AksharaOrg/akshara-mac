#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara"
APP_PATH="$ROOT/dist/$APP_NAME.app"

usage() {
  cat <<'EOF'
Usage: ./script/validate_install.sh

Checks the project layout and required tools before installing or packaging Akshara.
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "✖ Missing required command: $cmd" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

require_cmd /usr/bin/swift
require_cmd /usr/libexec/PlistBuddy
require_cmd /usr/bin/xattr
require_cmd /usr/bin/codesign
require_cmd /usr/bin/killall
require_cmd /usr/bin/open

if [[ ! -f "$ROOT/support/Info.plist" ]]; then
  echo "✖ Missing app metadata file: $ROOT/support/Info.plist" >&2
  exit 1
fi

if [[ ! -d "$ROOT/support/Resources" ]]; then
  echo "✖ Missing app resources directory: $ROOT/support/Resources" >&2
  exit 1
fi

if [[ ! -d "$ROOT/src" ]]; then
  echo "✖ Missing source directory: $ROOT/src" >&2
  exit 1
fi

if [[ ! -d "$ROOT/dist" ]]; then
  mkdir -p "$ROOT/dist"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "✖ Build output is missing: $APP_PATH" >&2
  echo "   Run: ./script/build_and_run.sh build" >&2
  exit 1
fi

if [[ ! -f "$APP_PATH/Contents/Info.plist" ]]; then
  echo "✖ App bundle is incomplete: $APP_PATH/Contents/Info.plist" >&2
  exit 1
fi

echo "✔ Akshara install validation passed"
echo "  Bundle: $APP_PATH"
