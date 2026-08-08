#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES="$ROOT/support/Resources"
GLYPH="$RESOURCES/AksharaGlyph.png"
WORK="$ROOT/build/icon-generation"
ICONSET="$WORK/Akshara.iconset"

if [[ ! -f "$GLYPH" ]]; then
  echo "Missing icon glyph: $GLYPH" >&2
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

magick "$GLYPH" -trim +repage -resize '31x31>' \
  -gravity center -background none -extent 32x32 \
  -channel A -morphology Dilate Diamond:1 +channel \
  -depth 8 -define png:color-type=6 \
  "$WORK/AksharaMenuBlack.png"
magick "$WORK/AksharaMenuBlack.png" \
  -channel RGB -fill white -colorize 100 \
  -depth 8 -define png:color-type=6 \
  "$WORK/AksharaMenuWhite.png"

/usr/bin/sips -s format tiff -z 16 16 "$WORK/AksharaMenuBlack.png" \
  --out "$RESOURCES/AksharaMenu.tif" >/dev/null
/usr/bin/sips -s format tiff "$WORK/AksharaMenuBlack.png" \
  --out "$RESOURCES/AksharaMenu@2x.tif" >/dev/null
/usr/bin/sips -s format tiff -z 16 16 "$WORK/AksharaMenuWhite.png" \
  --out "$RESOURCES/AksharaMenuWhite.tif" >/dev/null
/usr/bin/sips -s format tiff "$WORK/AksharaMenuWhite.png" \
  --out "$RESOURCES/AksharaMenuWhite@2x.tif" >/dev/null

echo "Generated Akshara app and menu icons"
