#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES="$ROOT/support/Resources"
GLYPH="$RESOURCES/AksharaGlyph.png"
MENU_FONT="/System/Library/Fonts/Supplemental/Sinhala Sangam MN.ttc"
WORK="$ROOT/build/icon-generation"
ICONSET="$WORK/Akshara.iconset"

if [[ ! -f "$GLYPH" ]]; then
  echo "Missing icon glyph: $GLYPH" >&2
  exit 1
fi

if [[ ! -f "$MENU_FONT" ]]; then
  echo "Missing Sinhala menu-icon font: $MENU_FONT" >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required (brew install imagemagick)." >&2
  exit 1
fi

rm -rf "$WORK"
mkdir -p "$ICONSET"

# Keep the detailed mark large, but give the app icon an opaque visual tile.
magick -size 1024x1024 xc:none \
  -fill white -draw "roundrectangle 24,24 1000,1000 210,210" \
  \( "$GLYPH" -trim +repage -resize '900x900>' \) \
  -gravity center -geometry +0+2 -composite \
  -depth 8 -define png:color-type=6 \
  "$RESOURCES/AksharaIconMaster.png"

for size in 16 32 128 256 512; do
  /usr/bin/sips -s format png -z "$size" "$size" \
    "$RESOURCES/AksharaIconMaster.png" \
    --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  /usr/bin/sips -s format png -z "$double" "$double" \
    "$RESOURCES/AksharaIconMaster.png" \
    --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
/usr/bin/iconutil -c icns "$ICONSET" -o "$RESOURCES/Akshara.icns"

# Generate multi-resolution template TIFF menu icons with optical centering
PYTHON_BIN=""
if [[ -f "$ROOT/graphify-out/.graphify_python" ]]; then
  PYTHON_BIN="$(cat "$ROOT/graphify-out/.graphify_python")"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
fi

if [[ -n "$PYTHON_BIN" ]]; then
  "$PYTHON_BIN" "$ROOT/script/generate_perfect_icons.py"
fi

echo "Generated Akshara app and menu icons"

