#!/usr/bin/env python3
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(ROOT, "support", "Resources")
FONT_PATH = "/System/Library/Fonts/Supplemental/Sinhala Sangam MN.ttc"

def render_native_badge(scale):
    """
    Renders an 8x supersampled, pixel-perfect macOS input source squircle badge.
    Exact proportions matching Apple's native [A] ABC badge.
    Downsampled with Lanczos filter for silky smooth subpixel anti-aliasing.
    """
    SS = 8
    canvas_w_pt = 22.0
    canvas_h_pt = 18.0
    
    canvas_w = canvas_w_pt * scale * SS
    canvas_h = canvas_h_pt * scale * SS
    
    badge_w = 21.0 * scale * SS
    badge_h = 16.2 * scale * SS
    radius = 5.6 * scale * SS
    
    im_hi = Image.new("RGBA", (int(canvas_w), int(canvas_h)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im_hi)
    
    bx0 = (canvas_w - badge_w) / 2
    by0 = (canvas_h - badge_h) / 2
    bx1 = bx0 + badge_w
    by1 = by0 + badge_h
    
    # Draw solid black badge at 8x resolution with exact continuous curvature
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=radius, fill=(0, 0, 0, 255))
    
    # Font size increased by exactly 1 point (10.8pt at 1x)
    font_size = (10.8 * scale) * SS
    font = ImageFont.truetype(FONT_PATH, int(font_size), index=1) # Bold
    bbox = draw.textbbox((0, 0), "අක", font=font)
    gw = bbox[2] - bbox[0]
    gh = bbox[3] - bbox[1]
    
    gx = round((canvas_w - gw) / 2 - bbox[0])
    gy = round((canvas_h - gh) / 2 - bbox[1] - (0.3 * scale * SS))
    
    # High-resolution cutout mask
    mask_hi = Image.new("L", (int(canvas_w), int(canvas_h)), 0)
    mask_draw = ImageDraw.Draw(mask_hi)
    mask_draw.text((gx, gy), "අක", font=font, fill=255)
    
    arr_hi = np.array(im_hi)
    m_arr_hi = np.array(mask_hi)
    arr_hi[:, :, 3] = np.clip(arr_hi[:, :, 3].astype(int) - m_arr_hi.astype(int), 0, 255).astype(np.uint8)
    
    im_final_hi = Image.fromarray(arr_hi)
    # Downsample smoothly with high-quality Lanczos filter
    target_w = int(canvas_w_pt * scale)
    target_h = int(canvas_h_pt * scale)
    im_down = im_final_hi.resize((target_w, target_h), Image.Resampling.LANCZOS)
    return im_down

def export_tiff(im_1x, im_2x, base_name):
    path_1x = os.path.join(RES_DIR, f"{base_name}.tif")
    path_2x = os.path.join(RES_DIR, f"{base_name}@2x.tif")
    
    im_1x.save(path_1x, format="TIFF", dpi=(72, 72))
    im_2x.save(path_2x, format="TIFF", dpi=(144, 144))
    print(f"Exported {base_name}.tif ({im_1x.size}) and {base_name}@2x.tif ({im_2x.size})")

if __name__ == "__main__":
    im_16 = render_native_badge(1)
    im_32 = render_native_badge(2)
    
    export_tiff(im_16, im_32, "AksharaMenu")
    export_tiff(im_16, im_32, "AksharaMenuWhite")
    print("Done generating smooth native squircle badge icons!")
