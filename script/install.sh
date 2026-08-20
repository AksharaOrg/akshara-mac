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

# ── Design System ────────────────────────────────────────────────────────────
GREEN='\033[32m'
CYAN='\033[36m'
RED='\033[31m'
YELLOW='\033[33m'
DIM='\033[2m'
RESET='\033[0m'

spin() {
    local pid=$1
    local msg="$2"
    local delay=0.08
    local spin_frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    tput civis 2>/dev/null || true
    while kill -0 $pid 2>/dev/null; do
        for frame in "${spin_frames[@]}"; do
            printf "\r \e[36m%s\e[0m %s" "$frame" "$msg"
            sleep $delay
            kill -0 $pid 2>/dev/null || break
        done
    done
    wait $pid
    local status=$?
    printf "\r\033[K"
    if [ $status -eq 0 ]; then
        echo -e "\033[32m✔\033[0m $msg"
    else
        echo -e "\033[31m✖\033[0m $msg"
    fi
    tput cnorm 2>/dev/null || true
    return $status
}

section() {
    echo -e "\n${YELLOW}▸ $1${RESET}"
}

# ── Build if needed ──────────────────────────────────────────────────────────
if [[ "${1:-}" != "--no-build" ]]; then
  "$ROOT/script/build_and_run.sh" build
elif [[ ! -d "$SRC" ]]; then
  echo -e "${RED}✖ Missing built app at $SRC${RESET}" >&2
  exit 1
fi

# ── Install ──────────────────────────────────────────────────────────────────
section "Cleaning up duplicates"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
(
    "$LSREGISTER" -dump | grep -oE "path:.*?Akshara\.app" | sed 's/path:[ \t]*//' | sed 's/ (.*//' | sort -u | while read app_path; do
        if [ "$app_path" != "$DST" ]; then
            "$LSREGISTER" -u "$app_path" >/dev/null 2>&1 || true
        fi
    done
    "$LSREGISTER" -u "$LEGACY_DST" >/dev/null 2>&1 || true
    rm -rf "$DST" "$LEGACY_DST"
    killall "$APP_PROCESS" 2>/dev/null || true
    killall "$LEGACY_APP_PROCESS" 2>/dev/null || true
) &
spin $! "Removing previous installation"

section "Installing"
mkdir -p "$DST_DIR"

( cp -R "$SRC" "$DST" ) &
spin $! "Copying app to Input Methods"

(
    /usr/bin/xattr -cr "$DST" 2>/dev/null || true
    /usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
    /usr/bin/codesign --force --sign - "$DST" >/dev/null 2>&1
    /usr/bin/xattr -r -d com.apple.provenance "$DST" 2>/dev/null || true
) &
spin $! "Signing app bundle"

( "$LSREGISTER" -f "$DST" >/dev/null 2>&1 || true ) &
spin $! "Registering with LaunchServices"

( /usr/bin/swift "$ROOT/script/enable_akshara.swift" "$DST" >/dev/null 2>&1 ) &
spin $! "Enabling input sources"

section "Restarting services"
(
    killall cfprefsd 2>/dev/null || true
    killall "System Settings" 2>/dev/null || true
    USER_ID=$(id -u)
    launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputMenuAgent" 2>/dev/null || true
    launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputUI.xpc.CursorUIViewService" 2>/dev/null || true
    launchctl kickstart -k "gui/$USER_ID/com.apple.TextInputSwitcher" 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
    rm -rf ~/Library/Caches/com.apple.IntlDataCache* 2>/dev/null || true
) &
spin $! "Restarting input method services"

echo -e "\n${GREEN}✔ Akshara installed successfully${RESET}"
echo -e "${DIM}Location: $DST${RESET}\n"

# Show a native glassy restart dialog if running interactively (not in CI)
if [[ -t 1 ]]; then
  /usr/bin/swift "$ROOT/script/restart_dialog.swift" || true
fi
