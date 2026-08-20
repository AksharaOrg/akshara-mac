#!/bin/bash

# කෝඩ් එකේ මොකක් හරි එරර් එකක් ආවොත් ස්ක්‍රිප්ට් එක නවතින්න
set -e 

echo "🧹 1. පරණ වර්ෂන් එක Uninstall කරමින්..."
sh ./script/uninstall.sh

echo "🗑️ 2. Keyboard Cache (HIToolbox) මකා දමමින්..."
rm -f ~/Library/Preferences/com.apple.HIToolbox.plist

echo "🔄 3. System UI Server එක Restart කරමින්..."
killall SystemUIServer || true

echo "🔨 4. අලුත් කීබෝර්ඩ් එක Build කරමින්..."

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara"
BUNDLE_ID="com.local.inputmethod.Akshara"
MODE="${1:-run}"
BUILD_DIR="$ROOT/build"
DIST_DIR="$ROOT/dist"
MODULE_CACHE="$BUILD_DIR/ModuleCache"
APP="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# ── Design System (CI-safe) ──────────────────────────────────────────────────
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
        printf "  → %s\n" "$msg"
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
    echo -e "${CYAN}අක්ෂර (Akshara) Mac Build Tool${RESET}"
    echo "----------------------------------------"
    echo ""
}

section() {
    echo -e "\n${YELLOW}▸ $1${RESET}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
print_header
echo -e "${DIM}Mode: $MODE${RESET}"

section "Preparing workspace"
( pkill -x "$APP_NAME" >/dev/null 2>&1 || true ) &
spin $! "Stopping existing Akshara process"
mkdir -p "$BUILD_DIR" "$MACOS" "$RESOURCES" "$MODULE_CACHE"

section "Compiling Universal Binary"
(
    build_arch() {
        local ARCH=$1
        local BUILD_DIR_ARCH="$BUILD_DIR/$ARCH"
        mkdir -p "$BUILD_DIR_ARCH"
        
        local SWIFT_TARGET=""
        if [ "$ARCH" == "x86_64" ]; then
            SWIFT_TARGET="x86_64-apple-macos14.0"
        else
            SWIFT_TARGET="arm64-apple-macos14.0"
        fi

        swiftc \
          -target $SWIFT_TARGET \
          -emit-object \
          -wmo \
          -module-name Akshara \
          -module-cache-path "$MODULE_CACHE" \
          -emit-objc-header-path "$ROOT/src/Akshara-Swift.h" \
          -parse-as-library \
          -import-objc-header "$ROOT/src/Akshara-Bridging-Header.h" \
          -o "$BUILD_DIR_ARCH/SwiftCode.o" \
          "$ROOT/src/WelcomeView.swift" \
          "$ROOT/src/PhoneticGuideView.swift" \
          "$ROOT/src/WelcomeWindowManager.swift" \
          "$ROOT/src/CapsLockHUD.swift" \
          2>&1

        clang \
          -arch $ARCH \
          -fobjc-arc \
          -fmodules \
          -fmodules-cache-path="$MODULE_CACHE" \
          -Wall -Wextra -Werror=return-type \
          -I "$BUILD_DIR" \
          -framework Cocoa \
          -framework Carbon \
          -framework InputMethodKit \
          -framework UserNotifications \
          -framework SwiftUI \
          -L/usr/lib/swift \
          -Xlinker -rpath -Xlinker /usr/lib/swift \
          -o "$BUILD_DIR_ARCH/$APP_NAME" \
          "$BUILD_DIR_ARCH/SwiftCode.o" \
          "$ROOT/src/main.m" \
          "$ROOT/src/SinhalaInputController.m" \
          "$ROOT/src/SinhalaTransliterator.m" \
          "$ROOT/src/SmartPhoneticMaps.m" \
          "$ROOT/src/AutoUpdater.m" \
          2>&1
    }

    build_arch "x86_64"
    build_arch "arm64"
    lipo -create "$BUILD_DIR/x86_64/$APP_NAME" "$BUILD_DIR/arm64/$APP_NAME" -output "$BUILD_DIR/$APP_NAME"
) &
spin $! "Compiling Universal Binary (x86_64 + arm64)"

section "Assembling app bundle"
(
    cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"
    cp "$ROOT/support/Info.plist" "$CONTENTS/Info.plist"
    if [[ -d "$ROOT/support/Resources" ]]; then
      cp -R "$ROOT/support/Resources/." "$RESOURCES/"
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$CONTENTS/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS/Info.plist"
    printf 'APPL????' > "$CONTENTS/PkgInfo"
) &
spin $! "Assembling app bundle"

# ── Mode dispatch ─────────────────────────────────────────────────────────────
case "$MODE" in
  run)
    echo ""
    "$ROOT/script/install.sh" --no-build
    ( /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app" >/dev/null 2>&1 ) &
    spin $! "Launching Akshara"
    echo -e "\n${GREEN}🎉 Akshara is running!${RESET}\n"
    ;;
  --install|install)
    echo ""
    "$ROOT/script/install.sh" --no-build
    echo -e "\n${GREEN}🎉 Install complete!${RESET}\n"
    ;;
  --debug|debug)
    echo -e "\n${CYAN}Starting lldb debugger...${RESET}\n"
    lldb -- "$MACOS/$APP_NAME"
    ;;
  --logs|logs)
    echo ""
    "$ROOT/script/install.sh" --no-build
    ( /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app" >/dev/null 2>&1 ) &
    spin $! "Launching Akshara"
    echo -e "\n${CYAN}Streaming logs (Ctrl+C to stop)...${RESET}\n"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    echo ""
    "$ROOT/script/install.sh" --no-build
    ( /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app" >/dev/null 2>&1 ) &
    spin $! "Launching Akshara"
    sleep 1
    if pgrep -x "$APP_NAME" >/dev/null; then
        echo -e "\n${GREEN}✔ Verified: $APP_NAME is running${RESET}\n"
    else
        echo -e "\n${RED}✖ $APP_NAME failed to start${RESET}\n"
        exit 1
    fi
    ;;
  build)
    echo ""
    LSR="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    ( "$LSR" -u "$APP" >/dev/null 2>&1 || true ) &
    spin $! "Unregistering build artifact from LaunchServices"
    echo -e "\n${GREEN}✔ Build complete → ${DIM}$APP${RESET}\n"
    ;;
  *)
    echo -e "\n${RED}✖ Unknown mode: $MODE${RESET}" >&2
    echo -e "${DIM}Usage: $0 [run|build|install|--debug|--logs|--verify]${RESET}\n" >&2
    exit 2
    ;;
esac

echo "✅ Build සහ Install කිරීම සාර්ථකයි!"

#echo "⚠️ 5. තත්පර 5කින් Mac එක Force Restart වෙනවා..."
#echo "කරුණාකර වැඩ කරමින් සිටි ෆයිල්ස් Save කරන්න!"
#sleep 5

# Mac එක Force Restart කිරීම
#sudo shutdown -r now