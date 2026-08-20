#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Akshara.app"
APP_PROCESS="Akshara"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_APP="$HOME/Library/Input Methods/$APP_NAME"
SYSTEM_APP="/Library/Input Methods/$APP_NAME"

usage() {
  cat <<'EOF'
Usage: ./script/uninstall.sh [--system]

Removes Akshara from the current user's Input Methods folder. Pass --system to
also remove the system-wide installation (administrator credentials required).
EOF
}

remove_app() {
  local app_path="$1"
  local needs_sudo="$2"

  [[ -d "$app_path" ]] || return 0

  "$LSREGISTER" -u "$app_path" >/dev/null 2>&1 || true
  if [[ "$needs_sudo" == "yes" ]]; then
    sudo /bin/rm -rf "$app_path"
  else
    /bin/rm -rf "$app_path"
  fi
  echo "Removed $app_path"
}

remove_system=false
case "${1:-}" in
  "") ;;
  --system) remove_system=true ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

/usr/bin/swift "$SCRIPT_DIR/cleanup_akshara_sources.swift" >/dev/null 2>&1 || true
remove_app "$USER_APP" no
if [[ "$remove_system" == true ]]; then
  remove_app "$SYSTEM_APP" yes
fi

/usr/bin/killall "$APP_PROCESS" >/dev/null 2>&1 || true
/usr/bin/killall TextInputMenuAgent >/dev/null 2>&1 || true
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true

if [[ "$remove_system" == true ]]; then
  echo "Akshara has been uninstalled."
else
  echo "Removed the user installation. Run with --system to also remove /Library/Input Methods/Akshara.app."
fi
echo "If Akshara is still listed in Input Sources, log out and back in."
