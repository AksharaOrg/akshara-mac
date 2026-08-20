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

# Generate a standard macOS rounded-rectangle style input menu icon.
magick -size 630x450 xc:none \
  -fill black -draw "roundrectangle 0,0 629,449 140,140" \
  \( -size 630x450 xc:none -font "$MENU_FONT" -gravity center -pointsize 340 -fill black -annotate +0-15 'අක' -morphology Dilate Disk:3 \) \
  -compose DstOut -composite \
  -resize '42x30!' \
  "$WORK/AksharaMenuBlackCanvas.png"

magick "$WORK/AksharaMenuBlackCanvas.png" -fill white -colorize 100 "$WORK/AksharaMenuWhiteCanvas.png"

magick "$WORK/AksharaMenuBlackCanvas.png" -resize 28x22 \
  -colorspace sRGB -type TrueColorAlpha \
  -define tiff:photometric=RGB -define tiff:alpha=unassociated \
  -depth 8 "$RESOURCES/AksharaMenu.tif"
magick "$WORK/AksharaMenuBlackCanvas.png" \
  -colorspace sRGB -type TrueColorAlpha \
  -define tiff:photometric=RGB -define tiff:alpha=unassociated \
  -depth 8 "$RESOURCES/AksharaMenu@2x.tif"
magick "$WORK/AksharaMenuWhiteCanvas.png" -resize 28x22 \
  -colorspace sRGB -type TrueColorAlpha \
  -define tiff:photometric=RGB -define tiff:alpha=unassociated \
  -depth 8 "$RESOURCES/AksharaMenuWhite.tif"
magick "$WORK/AksharaMenuWhiteCanvas.png" \
  -colorspace sRGB -type TrueColorAlpha \
  -define tiff:photometric=RGB -define tiff:alpha=unassociated \
  -depth 8 "$RESOURCES/AksharaMenuWhite@2x.tif"

echo "Generated Akshara app and menu icons"
