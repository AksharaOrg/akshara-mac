#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara"
BUNDLE_ID="com.local.inputmethod.Akshara"
VERSION="${AKSHARA_VERSION:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT/support/Info.plist")}"
ARCH="${AKSHARA_ARCH:-universal}"
APP_SIGN_IDENTITY="${AKSHARA_APP_SIGN_IDENTITY:--}"
PKG_SIGN_IDENTITY="${AKSHARA_PKG_SIGN_IDENTITY:-}"
NOTARY_PROFILE="${AKSHARA_NOTARY_PROFILE:-}"
NOTARY_KEY="${AKSHARA_NOTARY_KEY:-}"
NOTARY_KEY_ID="${AKSHARA_NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${AKSHARA_NOTARY_ISSUER_ID:-}"
DIST_DIR="$ROOT/dist"
APP="$DIST_DIR/$APP_NAME.app"
LAUNCHER_NAME="Akshara Settings"
LAUNCHER="$DIST_DIR/$LAUNCHER_NAME.app"
PKG_ROOT="$ROOT/build/pkg-root"
PKG_SCRIPTS="$ROOT/build/pkg-scripts"
PKG_RESOURCES="$ROOT/build/pkg-resources"
PKG_DISTRIBUTION="$ROOT/build/Distribution.xml"
COMPONENT_PKG="$ROOT/build/$APP_NAME-component.pkg"
COMPONENT_PLIST="$ROOT/build/$APP_NAME-component.plist"
case "$ARCH" in
  universal|arm64|x86_64) ;;
  *) echo "Unknown architecture: $ARCH" >&2; exit 2 ;;
esac
FINAL_PKG="$DIST_DIR/$APP_NAME-$VERSION-$ARCH.pkg"

export COPYFILE_DISABLE=1

# ── Design System ────────────────────────────────────────────────────────────
# Only use colors/animations when stdout is a real terminal
if [ -t 1 ]; then
    GREEN='\033[32m'; CYAN='\033[36m'; RED='\033[31m'
    YELLOW='\033[33m'; DIM='\033[2m'; RESET='\033[0m'
else
    GREEN=''; CYAN=''; RED=''; YELLOW=''; DIM=''; RESET=''
fi

spin() {
    local pid=$1
    local msg="$2"
    if [ -t 1 ]; then
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
        wait $pid; local status=$?
        printf "\r\033[K"
        tput cnorm 2>/dev/null || true
    else
        printf "  → %s ... " "$msg"
        wait $pid; local status=$?
    fi
    if [ $status -eq 0 ]; then
        echo -e "\033[32m✔\033[0m $msg"
    else
        echo -e "\033[31m✖\033[0m $msg" >&2
    fi
    return $status
}

print_header() {
    [ -t 1 ] && clear || true
    echo -e "${GREEN}"
    echo "    _    _        _                   "
    echo "   / \  | | _____| |__   __ _ _ __ __ _ "
    echo "  / _ \ | |/ / __| '_ \ / \`| '__/ _\` |"
    echo " / ___ \|   <\__ \ | | | (_| | | | (_| |"
    echo "/_/   \_\_|\_\___/_| |_|\__,_|_|  \__,_|"
    echo -e "${RESET}"
    echo -e "${CYAN}අක්ෂර (Akshara) Mac Packager${RESET}"
    echo "----------------------------------------"
    echo ""
}

section() {
    echo -e "\n${YELLOW}▸ $1${RESET}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
print_header
echo -e "${DIM}Version: $VERSION${RESET}"

# Build first (build_and_run.sh has its own UI)
AKSHARA_ARCH="$ARCH" "$ROOT/script/build_and_run.sh" build

section "Preparing build environment"
(
    sudo chmod -R 755 "$PKG_ROOT" 2>/dev/null || true
    rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$PKG_RESOURCES" "$PKG_DISTRIBUTION" "$COMPONENT_PKG" "$COMPONENT_PLIST" "$FINAL_PKG"
    mkdir -p "$PKG_ROOT/Library/Input Methods" "$PKG_ROOT/Applications" "$PKG_SCRIPTS" "$PKG_RESOURCES" "$DIST_DIR"
) &
spin $! "Cleaning previous build artifacts"

section "Staging app bundle"
(
    cp -R "$APP" "$PKG_ROOT/Library/Input Methods/$APP_NAME.app"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$PKG_ROOT/Library/Input Methods/$APP_NAME.app/Contents/Info.plist" || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION#v}" "$PKG_ROOT/Library/Input Methods/$APP_NAME.app/Contents/Info.plist" || true
    /usr/bin/xattr -cr "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
    /usr/bin/xattr -r -d com.apple.provenance "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true

    # Akshara Settings, so Akshara is listed in Launchpad / Apps and Spotlight.
    cp -R "$LAUNCHER" "$PKG_ROOT/Applications/$LAUNCHER_NAME.app"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION#v}" "$PKG_ROOT/Applications/$LAUNCHER_NAME.app/Contents/Info.plist" || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION#v}" "$PKG_ROOT/Applications/$LAUNCHER_NAME.app/Contents/Info.plist" || true
    /usr/bin/xattr -cr "$PKG_ROOT/Applications/$LAUNCHER_NAME.app" 2>/dev/null || true
    /usr/bin/find "$PKG_ROOT" -name '._*' -delete
) &
spin $! "Staging app bundle v${VERSION#v}"

(
    for bundle in "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" "$PKG_ROOT/Applications/$LAUNCHER_NAME.app"; do
      if [[ "$APP_SIGN_IDENTITY" == "-" ]]; then
        /usr/bin/codesign --force --sign - "$bundle" >/dev/null
      else
        /usr/bin/codesign --force --options runtime --timestamp --sign "$APP_SIGN_IDENTITY" "$bundle" >/dev/null
      fi
    done
    /usr/bin/xattr -cr "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
    /usr/bin/xattr -r -d com.apple.provenance "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
    /usr/bin/find "$PKG_ROOT" -name '._*' -delete
    /usr/bin/codesign --verify --deep --strict "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" >/dev/null
    /usr/bin/codesign --verify --deep --strict "$PKG_ROOT/Applications/$LAUNCHER_NAME.app" >/dev/null
) &
spin $! "Signing app bundle"

section "Writing installer scripts"
(
cat >"$PKG_SCRIPTS/preinstall" <<'SCRIPT'
#!/bin/sh
# Remember whether Akshara was already installed: postinstall asks for a restart only after an update.
# A fresh install needs none (the input method registers its input sources when it starts).
MARKER="/private/tmp/com.local.inputmethod.Akshara.updating"
/bin/rm -f "$MARKER"
CONSOLE_USER="$(/usr/bin/stat -f%Su /dev/console)"
USER_HOME=""
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ] && [ "$CONSOLE_USER" != "loginwindow" ]; then
  USER_HOME="$(/usr/bin/dscl . -read /Users/"$CONSOLE_USER" NFSHomeDirectory | /usr/bin/awk '{print $2}')"
fi
if [ -d "/Library/Input Methods/Akshara.app" ] || { [ -n "$USER_HOME" ] && [ -d "$USER_HOME/Library/Input Methods/Akshara.app" ]; }; then
  /usr/bin/touch "$MARKER"
fi
exit 0
SCRIPT

cat >"$PKG_SCRIPTS/postinstall" <<'SCRIPT'
#!/bin/sh
set -eu

APP="/Library/Input Methods/Akshara.app"
USER_APP_NAME="Akshara.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# Remove the old per-user bundle so LaunchServices cannot expose two copies of
# the same input source after switching from the source installer to a pkg.
CONSOLE_USER="$(/usr/bin/stat -f%Su /dev/console)"
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ] && [ "$CONSOLE_USER" != "loginwindow" ]; then
  USER_HOME="$(/usr/bin/dscl . -read /Users/"$CONSOLE_USER" NFSHomeDirectory | /usr/bin/awk '{print $2}')"
  USER_APP="$USER_HOME/Library/Input Methods/$USER_APP_NAME"
  if [ -d "$USER_APP" ]; then
    "$LSREGISTER" -u "$USER_APP" >/dev/null 2>&1 || true
    /bin/rm -rf "$USER_APP"
  fi
  # Likewise the source installer's Akshara Settings in ~/Applications (the package puts it in /Applications).
  USER_LAUNCHER="$USER_HOME/Applications/Akshara Settings.app"
  if [ -d "$USER_LAUNCHER" ]; then
    "$LSREGISTER" -u "$USER_LAUNCHER" >/dev/null 2>&1 || true
    /bin/rm -rf "$USER_LAUNCHER"
  fi
fi

if [ -d "$APP" ]; then
  /usr/bin/xattr -cr "$APP" 2>/dev/null || true
fi

# Remove stale Akshara/CleanIME entries from the logged-in user's HIToolbox
# preferences before the new bundle is registered.
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ] && [ "$CONSOLE_USER" != "loginwindow" ]; then
  CONSOLE_UID="$(/usr/bin/id -u "$CONSOLE_USER")"
  CLEANUP_SOURCE="$(/usr/bin/mktemp /tmp/akshara-cleanup.XXXXXX.swift)"
  /bin/cat >"$CLEANUP_SOURCE" <<'SWIFT'
import Foundation

let knownPrefixes = [
  "com.local.inputmethod.Akshara",
  "com.local.inputmethod.SinhalaCleanIME",
  "Akshara",
  "SinhalaCleanIME",
  "CleanIME"
]

func isStale(_ entry: [String: Any]) -> Bool {
  ["InputSourceID", "Bundle ID", "Input Mode"].contains { key in
    guard let value = entry[key] as? String else { return false }
    return knownPrefixes.contains { value == $0 || value.hasPrefix($0) || value.localizedCaseInsensitiveContains($0) }
  }
}

let defaults = UserDefaults.standard
var domain = defaults.persistentDomain(forName: "com.apple.HIToolbox") ?? [:]
for key in ["AppleEnabledInputSources", "AppleSelectedInputSources", "AppleInputSourceHistory"] {
  if let entries = domain[key] as? [Any] {
    domain[key] = entries.filter { entry in
      guard let dictionary = entry as? [String: Any] else { return true }
      return !isStale(dictionary)
    }
  }
}
defaults.setPersistentDomain(domain, forName: "com.apple.HIToolbox")
defaults.synchronize()
SWIFT
  # /usr/bin/swift is only a stub without the developer tools: on a fresh Mac it asks to install them.
  if /usr/bin/xcode-select -p >/dev/null 2>&1; then
    /bin/launchctl asuser "$CONSOLE_UID" /usr/bin/swift "$CLEANUP_SOURCE" >/dev/null 2>&1 || true
  fi
  /bin/rm -f "$CLEANUP_SOURCE"
fi

/usr/bin/killall Akshara >/dev/null 2>&1 || true
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true

# Show the setup guide to the logged-in user after a new installation.
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ] && [ "$CONSOLE_USER" != "loginwindow" ]; then
  CONSOLE_UID="$(/usr/bin/id -u "$CONSOLE_USER")"
  # Not -n: a second copy of the input method would run beside the one macOS manages.
  /bin/launchctl asuser "$CONSOLE_UID" /usr/bin/open "$APP" >/dev/null 2>&1 || true

  # After an update, ask for a restart so every app picks up the new input method. osascript is on
  # every Mac (/usr/bin/swift needs the developer tools). A fresh install needs no restart.
  if [ -f /private/tmp/com.local.inputmethod.Akshara.updating ]; then
    /bin/launchctl asuser "$CONSOLE_UID" /usr/bin/osascript \
      -e 'set answer to button returned of (display dialog "Akshara has been updated successfully. Restart your Mac to finish applying the update." with title "Akshara Updated" buttons {"Later", "Restart Now"} default button "Restart Now" with icon POSIX file "/Library/Input Methods/Akshara.app/Contents/Resources/Akshara.icns")' \
      -e 'if answer is "Restart Now" then tell application "System Events" to restart' >/dev/null 2>&1 || true
  fi
fi

/bin/rm -f /private/tmp/com.local.inputmethod.Akshara.updating
exit 0
SCRIPT
chmod +x "$PKG_SCRIPTS/preinstall" "$PKG_SCRIPTS/postinstall"
) &
spin $! "Writing postinstall script"

(
cat >"$PKG_RESOURCES/welcome.html" <<HTML
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
        line-height: 1.45;
        color: #1d1d1f;
      }
      h1 { font-size: 22px; margin: 12px 0 8px; }
      p  { font-size: 13px; margin: 0 0 8px; }
    </style>
  </head>
  <body>
    <h1>Install Akshara</h1>
    <p>Akshara adds Sinhala input methods for macOS, including Wijesekara/SLS1134 and phonetic typing.</p>
    <p>After installation, add Akshara from System Settings &gt; Keyboard &gt; Input Sources.</p>
    <p>Released under the MIT License.</p>
  </body>
</html>
HTML
) &
spin $! "Writing welcome page"

section "Building installer package"
(
    # Input methods must stay in /Library/Input Methods, and Akshara Settings in /Applications.
    /usr/bin/pkgbuild --analyze --root "$PKG_ROOT" "$COMPONENT_PLIST"
    index=0
    while /usr/libexec/PlistBuddy -c "Print :$index" "$COMPONENT_PLIST" >/dev/null 2>&1; do
      if /usr/libexec/PlistBuddy -c "Print :$index:BundleIsRelocatable" "$COMPONENT_PLIST" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Set :$index:BundleIsRelocatable false" "$COMPONENT_PLIST"
      else
        /usr/libexec/PlistBuddy -c "Add :$index:BundleIsRelocatable bool false" "$COMPONENT_PLIST"
      fi
      index=$((index + 1))
    done

    /usr/bin/pkgbuild \
      --root "$PKG_ROOT" \
      --component-plist "$COMPONENT_PLIST" \
      --scripts "$PKG_SCRIPTS" \
      --identifier "$BUNDLE_ID.pkg" \
      --version "$VERSION" \
      --install-location "/" \
      "$COMPONENT_PKG" 2>&1

    cat >"$PKG_DISTRIBUTION" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
  <title>Akshara</title>
  <welcome file="welcome.html"/>
  <options customize="never" require-scripts="true"/>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
  <choices-outline>
    <line choice="akshara"/>
  </choices-outline>
  <choice id="akshara" title="Akshara Sinhala Input Method">
    <pkg-ref id="$BUNDLE_ID.pkg"/>
  </choice>
  <pkg-ref id="$BUNDLE_ID.pkg" version="$VERSION">$(basename "$COMPONENT_PKG")</pkg-ref>
</installer-gui-script>
XML

    PRODUCTBUILD_ARGS=(--distribution "$PKG_DISTRIBUTION" --resources "$PKG_RESOURCES" --package-path "$ROOT/build")
    if [[ -n "$PKG_SIGN_IDENTITY" ]]; then
      PRODUCTBUILD_ARGS+=(--sign "$PKG_SIGN_IDENTITY")
    fi
    /usr/bin/productbuild "${PRODUCTBUILD_ARGS[@]}" "$FINAL_PKG" 2>&1
) &
spin $! "Building .pkg installer"

# ── Notarization (optional) ──────────────────────────────────────────────────
if [[ -n "$NOTARY_KEY" || -n "$NOTARY_KEY_ID" || -n "$NOTARY_ISSUER_ID" ]]; then
    if [[ -z "$NOTARY_KEY" || -z "$NOTARY_KEY_ID" || -z "$NOTARY_ISSUER_ID" ]]; then
        echo -e "\n${RED}✖ AKSHARA_NOTARY_KEY, AKSHARA_NOTARY_KEY_ID, and AKSHARA_NOTARY_ISSUER_ID must all be set together${RESET}" >&2
        exit 2
    fi
    section "Notarizing"
    ( /usr/bin/xcrun notarytool submit "$FINAL_PKG" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID" --wait 2>&1 ) &
    spin $! "Submitting to Apple notary service"
    ( /usr/bin/xcrun stapler staple "$FINAL_PKG" 2>&1 ) &
    spin $! "Stapling notarization ticket"
elif [[ -n "$NOTARY_PROFILE" ]]; then
    section "Notarizing"
    ( /usr/bin/xcrun notarytool submit "$FINAL_PKG" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1 ) &
    spin $! "Submitting to Apple notary service"
    ( /usr/bin/xcrun stapler staple "$FINAL_PKG" 2>&1 ) &
    spin $! "Stapling notarization ticket"
fi

section "Verifying"
( /usr/sbin/pkgutil --check-signature "$FINAL_PKG" >/dev/null 2>&1 ) &
spin $! "Verifying package signature"

# ── Cleanup ──────────────────────────────────────────────────────────────────
section "Cleaning up"
(
    LSR="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    "$LSR" -u "$APP" 2>/dev/null || true
    "$LSR" -u "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
    "$LSR" -u "$LAUNCHER" 2>/dev/null || true
    "$LSR" -u "$PKG_ROOT/Applications/$LAUNCHER_NAME.app" 2>/dev/null || true
  "$LSR" -u "$PKG_ROOT" 2>/dev/null || true
    sudo chmod -R 755 "$PKG_ROOT" 2>/dev/null || true
    rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$PKG_RESOURCES" "$PKG_DISTRIBUTION" "$COMPONENT_PKG" "$COMPONENT_PLIST"
    rm -rf "$APP" "$LAUNCHER"
  "$LSR" -u "$PKG_ROOT" 2>/dev/null || true
) &
spin $! "Removing intermediate build files"

echo -e "\n${GREEN}🎉 Package ready!${RESET}"
echo -e "${DIM}Output: $FINAL_PKG${RESET}"
echo -e "${DIM}Install: open \"$FINAL_PKG\"${RESET}\n"
