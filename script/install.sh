#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara.app"
APP_PROCESS="Akshara"
LEGACY_APP_NAME="$(printf 'Sinhala%s.app' 'CleanIME')"
LEGACY_APP_PROCESS="$(printf 'Sinhala%s' 'CleanIME')"
SRC="$ROOT/dist/$APP_NAME"
DST_DIR="$HOME/Library/Input Methods"
DST="$DST_DIR/$APP_NAME"
LEGACY_DST="$DST_DIR/$LEGACY_APP_NAME"

if [[ "${1:-}" != "--no-build" ]]; then
  "$ROOT/script/build_and_run.sh" build
elif [[ ! -d "$SRC" ]]; then
  echo "Missing built app at $SRC" >&2
  exit 1
fi

mkdir -p "$DST_DIR"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$DST" >/dev/null 2>&1 || true
if [[ -d "/Library/Input Methods/$APP_NAME" ]]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "/Library/Input Methods/$APP_NAME" >/dev/null 2>&1 || true
  sudo rm -rf "/Library/Input Methods/$APP_NAME" 2>/dev/null || true
fi
rm -rf "$DST"
rm -rf "$LEGACY_DST"
cp -R "$SRC" "$DST"

/usr/bin/xattr -cr "$DST" 2>/dev/null || true
/usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
/usr/bin/codesign --force --sign - "$DST" >/dev/null
/usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DST" >/dev/null 2>&1 || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc >/dev/null 2>&1 || true
/usr/bin/swift "$ROOT/script/enable_akshara.swift" "$DST"

# Force restart macOS text-input services and CursorUIViewService using launchctl
UID_VAL=$(id -u)
launchctl kickstart -k "gui/$UID_VAL/com.apple.TextInputUI.xpc.CursorUIViewService" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$UID_VAL/com.apple.TextInputSwitcher" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$UID_VAL/com.apple.TextInputMenuAgent" >/dev/null 2>&1 || true

killall -9 "$APP_PROCESS" 2>/dev/null || true
killall -9 "$LEGACY_APP_PROCESS" 2>/dev/null || true
killall -9 CursorUIViewService 2>/dev/null || true
killall -9 TextInputSwitcher 2>/dev/null || true
killall -9 TextInputMenuAgent 2>/dev/null || true
killall ControlCenter 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

sleep 0.5
/usr/bin/open -n "$DST"

echo "✓ Successfully installed and launched $DST"

