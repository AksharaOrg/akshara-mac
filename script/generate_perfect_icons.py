#!/usr/bin/env python3
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(ROOT, "support", "Resources")
FONT_PATH = "/System/Library/Fonts/Supplemental/Sinhala Sangam MN.ttc"

def render_pure_text_icon(text, scale):
    """
    Renders pure text without any background box (template image).
    Used across all macOS surfaces (Menu Bar and Cursor Indicator).
    """
    SS = 8
    canvas_w_pt = 22.0
    canvas_h_pt = 18.0
    
    canvas_w = canvas_w_pt * scale * SS
    canvas_h = canvas_h_pt * scale * SS
    
    im_hi = Image.new("RGBA", (int(canvas_w), int(canvas_h)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im_hi)
    
    font_size = (14.0 * scale) * SS
    font = ImageFont.truetype(FONT_PATH, int(font_size), index=1) # Bold
    bbox = draw.textbbox((0, 0), text, font=font)
    gw = bbox[2] - bbox[0]
    gh = bbox[3] - bbox[1]
    
    gx = round((canvas_w - gw) / 2 - bbox[0])
    gy = round((canvas_h - gh) / 2 - bbox[1] - (0.5 * scale * SS))
    
    draw.text((gx, gy), text, font=font, fill=(0, 0, 0, 255))
    
    target_w = int(canvas_w_pt * scale)
    target_h = int(canvas_h_pt * scale)
    return im_hi.resize((target_w, target_h), Image.Resampling.LANCZOS)

def export_tiff(im_1x, im_2x, base_name):
    path_1x = os.path.join(RES_DIR, f"{base_name}.tif")
    path_2x = os.path.join(RES_DIR, f"{base_name}@2x.tif")
    
    im_1x.save(path_1x, format="TIFF", dpi=(72, 72))
    im_2x.save(path_2x, format="TIFF", dpi=(144, 144))
    print(f"Exported {base_name}.tif ({im_1x.size}) and {base_name}@2x.tif ({im_2x.size})")

if __name__ == "__main__":
    im_16 = render_pure_text_icon("අක්", 1)
    im_32 = render_pure_text_icon("අක්", 2)
    
    export_tiff(im_16, im_32, "AksharaMenu")
    export_tiff(im_16, im_32, "AksharaMenuWhite")
    print("Done generating pure text 'අක්' template icons!")
