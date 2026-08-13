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
rm -rf "$DST"
rm -rf "$LEGACY_DST"
cp -R "$SRC" "$DST"

/usr/bin/xattr -cr "$DST" 2>/dev/null || true
/usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
/usr/bin/codesign --force --sign - "$DST" >/dev/null
/usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DST" >/dev/null 2>&1 || true
/usr/bin/swift "$ROOT/script/enable_akshara.swift" "$DST"
killall "$APP_PROCESS" 2>/dev/null || true
killall "$LEGACY_APP_PROCESS" 2>/dev/null || true
killall TextInputMenuAgent 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo "Installed $DST"
echo "Log out/in if it does not appear immediately in System Settings > Keyboard > Input Sources."

/usr/bin/osascript -e '
tell application "System Events"
    activate
    set dialogResult to display dialog "Akshara keyboard has been installed successfully.\n\nYou need to restart your Mac to apply the changes." with title "Restart Required" buttons {"Not now", "Restart"} default button "Restart" cancel button "Not now" with icon caution
    if button returned of dialogResult is "Restart" then
        restart
    end if
end tell
' || true
