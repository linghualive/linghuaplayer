#!/usr/bin/env python3
"""Generate a Material 3 style music player icon — mint/teal theme."""

from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024


def create_m3_background(size):
    """Create a clean M3-style background with subtle radial tonal shift."""
    img = Image.new('RGBA', (size, size))
    pixels = img.load()
    cx, cy = size / 2, size / 2
    max_dist = math.sqrt(cx * cx + cy * cy)

    # Center: bright mint #00E5A0 → Edge: teal #00897B
    c_center = (0, 229, 160)
    c_edge = (0, 137, 123)

    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_dist
            dist = min(dist * 1.2, 1.0)  # push gradient outward
            t = dist ** 0.8  # ease
            r = int(c_center[0] * (1 - t) + c_edge[0] * t)
            g = int(c_center[1] * (1 - t) + c_edge[1] * t)
            b = int(c_center[2] * (1 - t) + c_edge[2] * t)
            pixels[x, y] = (r, g, b, 255)

    return img


def draw_m3_music_note(img, size):
    """Draw a clean Material 3 style music note — rounded, modern, centered."""
    # We'll draw on a larger canvas for anti-aliasing, then downscale
    AA = 4
    big = size * AA
    canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    s = big / 1024
    cx, cy = big // 2, big // 2

    # Shift note slightly up-left to visually center
    ox = int(-10 * s)
    oy = int(-10 * s)

    # ── Single eighth note (♪) — cleaner and more iconic than double ──
    head_rx = int(80 * s)
    head_ry = int(58 * s)
    stem_w = int(20 * s)
    stem_h = int(320 * s)
    flag_w = int(90 * s)
    flag_h = int(140 * s)

    # Note head center
    hx = cx + ox
    hy = cy + oy + int(130 * s)

    # Stem
    stem_x = hx + int(head_rx * 0.6)
    stem_top = hy - stem_h
    stem_bot = hy - int(10 * s)

    white = (255, 255, 255, 255)

    # Draw note head (tilted ellipse)
    tilt = math.radians(-20)
    for dy in range(-head_ry - 4, head_ry + 4):
        for dx in range(-head_rx - 4, head_rx + 4):
            rx = dx * math.cos(-tilt) - dy * math.sin(-tilt)
            ry = dx * math.sin(-tilt) + dy * math.cos(-tilt)
            if (rx / head_rx) ** 2 + (ry / head_ry) ** 2 <= 1.0:
                px, py = hx + dx, hy + dy
                if 0 <= px < big and 0 <= py < big:
                    draw.point((px, py), fill=white)

    # Draw stem (rectangle with rounded top)
    draw.rounded_rectangle(
        [stem_x, stem_top, stem_x + stem_w, stem_bot],
        radius=int(stem_w * 0.4),
        fill=white
    )

    # Draw flag (curved) — use a series of ellipse arcs
    flag_top = stem_top
    for i in range(int(flag_h)):
        t = i / flag_h
        curve_x = int(flag_w * math.sin(t * math.pi * 0.7) * (1 - t * 0.3))
        y_pos = flag_top + i
        thickness = int(stem_w * (1 - t * 0.6))
        x_start = stem_x + stem_w
        draw.rectangle(
            [x_start, y_pos, x_start + curve_x, y_pos + max(thickness, 1)],
            fill=white
        )

    # Downscale with anti-aliasing
    note_layer = canvas.resize((size, size), Image.LANCZOS)
    return Image.alpha_composite(img, note_layer)


def draw_m3_double_note(img, size):
    """Draw Material 3 double eighth note (♫) — clean, geometric, centered."""
    AA = 4
    big = size * AA
    canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    s = big / 1024
    cx, cy = big // 2, big // 2

    ox = int(-15 * s)
    oy = int(0 * s)

    head_rx = int(68 * s)
    head_ry = int(50 * s)
    stem_w = int(18 * s)
    stem_h = int(310 * s)
    note_gap = int(210 * s)
    beam_h = int(26 * s)
    beam_gap = int(46 * s)
    tilt = math.radians(-18)

    # Head positions
    h1_cx = cx + ox - note_gap // 2
    h1_cy = cy + oy + int(135 * s)
    h2_cx = cx + ox + note_gap // 2
    h2_cy = cy + oy + int(105 * s)

    # Stem attachment (right side of head)
    s1_x = h1_cx + int(head_rx * 0.65)
    s2_x = h2_cx + int(head_rx * 0.65)
    s1_top = h1_cy - stem_h
    s2_top = h2_cy - stem_h

    white = (255, 255, 255, 255)

    # Draw note heads
    for hcx, hcy in [(h1_cx, h1_cy), (h2_cx, h2_cy)]:
        for dy in range(-head_ry - 3, head_ry + 3):
            for dx in range(-head_rx - 3, head_rx + 3):
                rx = dx * math.cos(-tilt) - dy * math.sin(-tilt)
                ry = dx * math.sin(-tilt) + dy * math.cos(-tilt)
                if (rx / head_rx) ** 2 + (ry / head_ry) ** 2 <= 1.0:
                    px, py = hcx + dx, hcy + dy
                    if 0 <= px < big and 0 <= py < big:
                        draw.point((px, py), fill=white)

    # Draw stems with rounded ends
    r = int(stem_w * 0.4)
    draw.rounded_rectangle([s1_x, s1_top, s1_x + stem_w, h1_cy - int(10 * s)], radius=r, fill=white)
    draw.rounded_rectangle([s2_x, s2_top, s2_x + stem_w, h2_cy - int(10 * s)], radius=r, fill=white)

    # Draw beams with rounded corners
    for i in range(2):
        offset = i * beam_gap
        # Beam is a parallelogram — approximate with polygon
        pts = [
            (s1_x - int(2 * s), s1_top + offset),
            (s2_x + stem_w + int(2 * s), s2_top + offset),
            (s2_x + stem_w + int(2 * s), s2_top + offset + beam_h),
            (s1_x - int(2 * s), s1_top + offset + beam_h),
        ]
        draw.polygon(pts, fill=white)

    note_layer = canvas.resize((size, size), Image.LANCZOS)
    return Image.alpha_composite(img, note_layer)


def round_corners(img, radius):
    size = img.size[0]
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def main():
    print("Generating Material 3 mint/teal icon...")

    # Main logo
    bg = create_m3_background(SIZE)
    img = draw_m3_double_note(bg, SIZE)
    rounded = round_corners(img, SIZE // 4)  # M3 uses larger corner radius
    rounded.save('logo.png', 'PNG')
    print("Saved logo.png")

    # Android adaptive foreground (note on transparent)
    AA = 4
    big = SIZE * AA
    canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    s = big / 1024
    cx, cy = big // 2, big // 2
    ox = int(-15 * s)
    head_rx = int(68 * s)
    head_ry = int(50 * s)
    stem_w = int(18 * s)
    stem_h = int(310 * s)
    note_gap = int(210 * s)
    beam_h = int(26 * s)
    beam_gap = int(46 * s)
    tilt = math.radians(-18)
    white = (255, 255, 255, 255)

    h1_cx = cx + ox - note_gap // 2
    h1_cy = cy + int(135 * s)
    h2_cx = cx + ox + note_gap // 2
    h2_cy = cy + int(105 * s)
    s1_x = h1_cx + int(head_rx * 0.65)
    s2_x = h2_cx + int(head_rx * 0.65)
    s1_top = h1_cy - stem_h
    s2_top = h2_cy - stem_h

    for hcx, hcy in [(h1_cx, h1_cy), (h2_cx, h2_cy)]:
        for dy in range(-head_ry - 3, head_ry + 3):
            for dx in range(-head_rx - 3, head_rx + 3):
                rx = dx * math.cos(-tilt) - dy * math.sin(-tilt)
                ry = dx * math.sin(-tilt) + dy * math.cos(-tilt)
                if (rx / head_rx) ** 2 + (ry / head_ry) ** 2 <= 1.0:
                    px, py = hcx + dx, hcy + dy
                    if 0 <= px < big and 0 <= py < big:
                        draw.point((px, py), fill=white)

    r = int(stem_w * 0.4)
    draw.rounded_rectangle([s1_x, s1_top, s1_x + stem_w, h1_cy - int(10 * s)], radius=r, fill=white)
    draw.rounded_rectangle([s2_x, s2_top, s2_x + stem_w, h2_cy - int(10 * s)], radius=r, fill=white)

    for i in range(2):
        offset = i * beam_gap
        pts = [
            (s1_x - int(2 * s), s1_top + offset),
            (s2_x + stem_w + int(2 * s), s2_top + offset),
            (s2_x + stem_w + int(2 * s), s2_top + offset + beam_h),
            (s1_x - int(2 * s), s1_top + offset + beam_h),
        ]
        draw.polygon(pts, fill=white)

    fg = canvas.resize((SIZE, SIZE), Image.LANCZOS)
    fg.save('logo_adaptive_fg.png', 'PNG')
    print("Saved logo_adaptive_fg.png")

    # Android adaptive background (gradient only)
    bg_only = create_m3_background(SIZE)
    bg_only.save('logo_adaptive_bg.png', 'PNG')
    print("Saved logo_adaptive_bg.png")


if __name__ == '__main__':
    main()
