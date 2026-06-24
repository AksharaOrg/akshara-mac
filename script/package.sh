#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Akshara"
BUNDLE_ID="com.local.inputmethod.Akshara"
VERSION="${AKSHARA_VERSION:-0.1.0}"
APP_SIGN_IDENTITY="${AKSHARA_APP_SIGN_IDENTITY:--}"
PKG_SIGN_IDENTITY="${AKSHARA_PKG_SIGN_IDENTITY:-}"
NOTARY_PROFILE="${AKSHARA_NOTARY_PROFILE:-}"
DIST_DIR="$ROOT/dist"
APP="$DIST_DIR/$APP_NAME.app"
PKG_ROOT="$ROOT/build/pkg-root"
PKG_SCRIPTS="$ROOT/build/pkg-scripts"
PKG_RESOURCES="$ROOT/build/pkg-resources"
PKG_DISTRIBUTION="$ROOT/build/Distribution.xml"
COMPONENT_PKG="$ROOT/build/$APP_NAME-component.pkg"
FINAL_PKG="$DIST_DIR/$APP_NAME-$VERSION.pkg"

export COPYFILE_DISABLE=1

"$ROOT/script/build_and_run.sh" build

rm -rf "$PKG_ROOT" "$PKG_SCRIPTS" "$PKG_RESOURCES" "$PKG_DISTRIBUTION" "$COMPONENT_PKG" "$FINAL_PKG"
mkdir -p "$PKG_ROOT/Library/Input Methods" "$PKG_SCRIPTS" "$PKG_RESOURCES" "$DIST_DIR"

cp -R "$APP" "$PKG_ROOT/Library/Input Methods/$APP_NAME.app"
/usr/bin/xattr -cr "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
/usr/bin/xattr -r -d com.apple.provenance "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
/usr/bin/find "$PKG_ROOT" -name '._*' -delete
if [[ "$APP_SIGN_IDENTITY" == "-" ]]; then
  /usr/bin/codesign --force --sign - "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" >/dev/null
else
  /usr/bin/codesign --force --options runtime --timestamp --sign "$APP_SIGN_IDENTITY" "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" >/dev/null
fi
/usr/bin/xattr -cr "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
/usr/bin/xattr -r -d com.apple.provenance "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" 2>/dev/null || true
/usr/bin/find "$PKG_ROOT" -name '._*' -delete
/usr/bin/codesign --verify --verbose=4 "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" >/dev/null

cat >"$PKG_SCRIPTS/postinstall" <<'SCRIPT'
#!/bin/sh
set -eu

APP="/Library/Input Methods/Akshara.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [ -d "$APP" ]; then
  /usr/bin/xattr -cr "$APP" 2>/dev/null || true
  /usr/bin/codesign --force --sign - "$APP" >/dev/null 2>&1 || true
  "$LSREGISTER" -f "$APP" >/dev/null 2>&1 || true
fi

/usr/bin/killall Akshara >/dev/null 2>&1 || true
/usr/bin/killall TextInputMenuAgent >/dev/null 2>&1 || true
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true

exit 0
SCRIPT
chmod +x "$PKG_SCRIPTS/postinstall"

/usr/bin/sips -s format png -z 160 160 "$ROOT/support/Resources/AksharaIconMaster.png" --out "$PKG_RESOURCES/installer-logo.png" >/dev/null
/usr/bin/sips -s format png -z 420 420 "$ROOT/support/Resources/AksharaIconMaster.png" --out "$PKG_RESOURCES/installer-background.png" >/dev/null
INSTALLER_LOGO_DATA="$(/usr/bin/base64 < "$PKG_RESOURCES/installer-logo.png" | /usr/bin/tr -d '\n')"

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
      img {
        width: 96px;
        height: 96px;
      }
      h1 {
        font-size: 22px;
        margin: 12px 0 8px;
      }
      p {
        font-size: 13px;
        margin: 0 0 8px;
      }
    </style>
  </head>
  <body>
    <img src="data:image/png;base64,$INSTALLER_LOGO_DATA" alt="Akshara">
    <h1>Install Akshara</h1>
    <p>Akshara adds Sinhala input methods for macOS, including Wijesekara/SLS1134 and phonetic typing.</p>
    <p>After installation, add Akshara from System Settings &gt; Keyboard &gt; Input Sources.</p>
    <p>Released under the MIT License.</p>
  </body>
</html>
HTML

/usr/bin/pkgbuild \
  --component "$PKG_ROOT/Library/Input Methods/$APP_NAME.app" \
  --scripts "$PKG_SCRIPTS" \
  --identifier "$BUNDLE_ID.pkg" \
  --version "$VERSION" \
  --install-location "/Library/Input Methods" \
  "$COMPONENT_PKG"

cat >"$PKG_DISTRIBUTION" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
  <title>Akshara</title>
  <welcome file="welcome.html"/>
  <background file="installer-background.png" mime-type="image/png" scaling="proportional"/>
  <options customize="never" require-scripts="true"/>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
  <choices-outline>
    <line choice="akshara"/>
  </choices-outline>
  <choice id="akshara" title="Akshara Sinhala Input Method">
    <pkg-ref id="$BUNDLE_ID.pkg"/>
  </choice>
  <pkg-ref id="$BUNDLE_ID.pkg" version="$VERSION" onConclusion="none">$(basename "$COMPONENT_PKG")</pkg-ref>
</installer-gui-script>
XML

PRODUCTBUILD_ARGS=(--distribution "$PKG_DISTRIBUTION" --resources "$PKG_RESOURCES" --package-path "$ROOT/build")
if [[ -n "$PKG_SIGN_IDENTITY" ]]; then
  PRODUCTBUILD_ARGS+=(--sign "$PKG_SIGN_IDENTITY")
fi
/usr/bin/productbuild "${PRODUCTBUILD_ARGS[@]}" "$FINAL_PKG"

if [[ -n "$NOTARY_PROFILE" ]]; then
  /usr/bin/xcrun notarytool submit "$FINAL_PKG" --keychain-profile "$NOTARY_PROFILE" --wait
  /usr/bin/xcrun stapler staple "$FINAL_PKG"
fi

/usr/sbin/pkgutil --check-signature "$FINAL_PKG" >/dev/null 2>&1 || true
echo "Built installer: $FINAL_PKG"
echo "Install with: open \"$FINAL_PKG\""
