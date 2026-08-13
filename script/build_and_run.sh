#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara"
BUNDLE_ID="com.local.inputmethod.Akshara"
MODE="${1:-run}"
BUILD_DIR="$ROOT/build"
DIST_DIR="$ROOT/dist"
APP="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$BUILD_DIR" "$MACOS" "$RESOURCES"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swiftc \
  -emit-object \
  -wmo \
  -module-name Akshara \
  -emit-objc-header-path "$BUILD_DIR/Akshara-Swift.h" \
  -parse-as-library \
  -import-objc-header "$ROOT/src/Akshara-Bridging-Header.h" \
  -o "$BUILD_DIR/SwiftCode.o" \
  "$ROOT/src/WelcomeView.swift" \
  "$ROOT/src/WelcomeWindowManager.swift"



clang \
  -fobjc-arc \
  -Wall -Wextra -Werror=return-type \
  -I "$BUILD_DIR" \
  -framework Cocoa \
  -framework Carbon \
  -framework InputMethodKit \
  -framework UserNotifications \
  -framework SwiftUI \
  -L/usr/lib/swift \
  -Xlinker -rpath -Xlinker /usr/lib/swift \
  -o "$BUILD_DIR/$APP_NAME" \
  "$BUILD_DIR/SwiftCode.o" \
  "$ROOT/src/main.m" \
  "$ROOT/src/SinhalaInputController.m" \
  "$ROOT/src/SinhalaTransliterator.m" \
  "$ROOT/src/SmartPhoneticMaps.m" \
  "$ROOT/src/AutoUpdater.m"


cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"
cp "$ROOT/support/Info.plist" "$CONTENTS/Info.plist"
if [[ -d "$ROOT/support/Resources" ]]; then
  cp -R "$ROOT/support/Resources/." "$RESOURCES/"
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"

case "$MODE" in
  run)
    "$ROOT/script/install.sh" --no-build
    /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app"
    ;;
  --install|install)
    "$ROOT/script/install.sh" --no-build
    ;;
  --debug|debug)
    lldb -- "$MACOS/$APP_NAME"
    ;;
  --logs|logs)
    "$ROOT/script/install.sh" --no-build
    /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    "$ROOT/script/install.sh" --no-build
    /usr/bin/open -n "$HOME/Library/Input Methods/$APP_NAME.app"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    echo "Verified $APP_NAME is running"
    ;;
  build)
    echo "Built $APP"
    ;;
  *)
    echo "usage: $0 [run|build|install|--debug|--logs|--verify]" >&2
    exit 2
    ;;
esac
