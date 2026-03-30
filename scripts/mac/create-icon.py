#!/usr/bin/env python3
"""Generate app icon for Open Transcribe - a transcription/audio waveform icon."""
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size=1024):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background - rounded rectangle with gradient-like effect
    margin = size * 0.05
    corner_radius = size * 0.22
    
    # Draw rounded rectangle background (dark blue/teal gradient)
    # Outer bg
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=(30, 60, 90)
    )
    
    # Inner gradient effect - lighter center
    inner_margin = size * 0.08
    draw.rounded_rectangle(
        [inner_margin, inner_margin, size - inner_margin, size - inner_margin],
        radius=corner_radius * 0.9,
        fill=(20, 100, 130)
    )
    
    # Even lighter center circle
    center = size / 2
    circle_r = size * 0.30
    draw.ellipse(
        [center - circle_r, center - circle_r * 1.1, center + circle_r, center + circle_r * 0.9],
        fill=(25, 120, 155)
    )
    
    # Draw audio waveform bars
    bar_color = (255, 255, 255, 230)
    num_bars = 9
    bar_width = size * 0.045
    bar_gap = size * 0.02
    total_width = num_bars * bar_width + (num_bars - 1) * bar_gap
    start_x = (size - total_width) / 2
    
    # Waveform heights (symmetric pattern for audio wave)
    heights = [0.12, 0.22, 0.35, 0.28, 0.45, 0.28, 0.35, 0.22, 0.12]
    base_y = size * 0.55
    
    for i, h in enumerate(heights):
        x = start_x + i * (bar_width + bar_gap)
        bar_height = size * h
        y1 = base_y - bar_height / 2
        y2 = base_y + bar_height / 2
        
        # Draw rounded bars
        draw.rounded_rectangle(
            [x, y1, x + bar_width, y2],
            radius=bar_width / 2,
            fill=bar_color
        )
    
    # Draw a microphone icon above the waveform
    mic_x = center
    mic_y = size * 0.22
    mic_w = size * 0.07
    mic_h = size * 0.10
    
    # Microphone body (rounded rectangle)
    draw.rounded_rectangle(
        [mic_x - mic_w/2, mic_y, mic_x + mic_w/2, mic_y + mic_h],
        radius=mic_w / 2,
        fill=(255, 255, 255, 230)
    )
    
    # Microphone arc
    arc_box = [mic_x - mic_w * 1.3, mic_y - mic_h * 0.1, mic_x + mic_w * 1.3, mic_y + mic_h * 1.5]
    draw.arc(arc_box, 0, 180, fill=(255, 255, 255, 200), width=int(size * 0.02))
    
    # Microphone stand line
    draw.line(
        [mic_x, mic_y + mic_h, mic_x, mic_y + mic_h + size * 0.04],
        fill=(255, 255, 255, 200),
        width=int(size * 0.02)
    )
    
    # Microphone base line
    base_w = size * 0.06
    draw.line(
        [mic_x - base_w, mic_y + mic_h + size * 0.04, mic_x + base_w, mic_y + mic_h + size * 0.04],
        fill=(255, 255, 255, 200),
        width=int(size * 0.02)
    )
    
    # Draw "text lines" below waveform to suggest transcription
    line_color = (180, 220, 240, 160)
    line_y_start = size * 0.72
    line_height = size * 0.015
    line_gap = size * 0.035
    line_margin = size * 0.22
    line_widths = [0.56, 0.48, 0.40, 0.30]
    
    for i, w in enumerate(line_widths):
        y = line_y_start + i * line_gap
        lw = size * w
        draw.rounded_rectangle(
            [line_margin, y, line_margin + lw, y + line_height],
            radius=line_height / 2,
            fill=line_color
        )
    
    return img

def create_icns(output_path, iconset_dir="/tmp/opentranscribe.iconset"):
    """Create .icns file from the icon."""
    os.makedirs(iconset_dir, exist_ok=True)
    
    # Generate all required sizes
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    icon = create_icon(1024)
    
    for size in sizes:
        resized = icon.resize((size, size), Image.LANCZOS)
        resized.save(f"{iconset_dir}/icon_{size}x{size}.png")
        if size <= 512:
            # Retina variant
            resized2x = icon.resize((size * 2, size * 2), Image.LANCZOS)
            resized2x.save(f"{iconset_dir}/icon_{size}x{size}@2x.png")
    
    # Use iconutil to create .icns
    os.system(f"iconutil -c icns {iconset_dir} -o {output_path}")
    print(f"Created {output_path}")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(os.path.dirname(script_dir))
    icns_path = os.path.join(project_dir, "assets", "applet.icns")
    os.makedirs(os.path.dirname(icns_path), exist_ok=True)
    create_icns(icns_path)
    print(f"Icon saved to {icns_path}")