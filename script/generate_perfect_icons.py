#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(ROOT, "support", "Resources")
FONT_PATH = "/System/Library/Fonts/Supplemental/Sinhala Sangam MN.ttc"

def make_template_icon(text, w_canvas, h_canvas, font_size, y_offset=0):
    im = Image.new("RGBA", (w_canvas, h_canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT_PATH, int(font_size), index=1) # Bold
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    
    x = round((w_canvas - w) / 2 - bbox[0])
    y = round((h_canvas - h) / 2 - bbox[1] + y_offset)
    
    draw.text((x, y), text, font=font, fill=(0, 0, 0, 255))
    return im

def export_tiff(im_1x, im_2x, base_name):
    path_1x = os.path.join(RES_DIR, f"{base_name}.tif")
    path_2x = os.path.join(RES_DIR, f"{base_name}@2x.tif")
    
    im_1x.save(path_1x, format="TIFF", dpi=(72, 72))
    im_2x.save(path_2x, format="TIFF", dpi=(144, 144))
    print(f"Exported {base_name}.tif ({im_1x.size}) and {base_name}@2x.tif ({im_2x.size})")

if __name__ == "__main__":
    # Proportional width for 'අක' so the glyph height matches native menu bar items:
    # 1x: 22x16 pt, font 14
    # 2x: 44x32 px, font 28
    im_16 = make_template_icon("අක", 22, 16, 14, y_offset=0)
    im_32 = make_template_icon("අක", 44, 32, 28, y_offset=-1)
    
    export_tiff(im_16, im_32, "AksharaMenu")
    export_tiff(im_16, im_32, "AksharaMenuWhite")
    print("Done generating bold scaled-up 'අක' template menu icons!")
