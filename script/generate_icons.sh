#!/usr/bin/env bash
# Builds the app and input-menu icons from support/IconSource (see generate_icons.swift).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
/usr/bin/swift "$ROOT/script/generate_icons.swift"
