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

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
# Unregister ALL known instances of Akshara to prevent duplicates in System Settings
"$LSREGISTER" -dump | grep -oE "path:.*?Akshara\.app" | sed 's/path:[ \t]*//' | sort | uniq | while read app_path; do
    if [ "$app_path" != "$DST" ]; then
        "$LSREGISTER" -u "$app_path" >/dev/null 2>&1 || true
    fi
done

"$LSREGISTER" -u "$LEGACY_DST" >/dev/null 2>&1 || true
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
killall cfprefsd 2>/dev/null || true

killall "System Settings" 2>/dev/null || true

USER_ID=$(id -u)
launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputMenuAgent" 2>/dev/null || true
launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputUI.xpc.CursorUIViewService" 2>/dev/null || true
launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputSwitcher" 2>/dev/null || true

killall SystemUIServer 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.IntlDataCache* 2>/dev/null || true

echo "Enabled Akshara input sources"
echo "Keyboard has been reloaded. It should now work without restarting."

# Show a native glassy restart dialog if running interactively (not in CI)
if [[ -t 1 ]]; then
  /usr/bin/swift "$ROOT/script/restart_dialog.swift" || true
fi

