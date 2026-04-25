#!/usr/bin/env python3
"""Generate an Apple-style music player icon — bright, luminous, clean."""

from PIL import Image, ImageDraw
import math

SIZE = 1024


def create_apple_gradient(size):
    """Apple Music-inspired gradient: bright, luminous, warm-to-cool.

    Apple icons use bright, saturated colors that feel lit from within.
    Key principles: high luminosity, smooth transitions, slightly warm bias.
    """
    img = Image.new('RGBA', (size, size))
    pixels = img.load()

    # Apple-style: bright red-pink top → vivid magenta-coral bottom-left → warm orange accent
    # Reference: Apple Music icon uses red→pink→coral
    tl = (255, 45, 85)    # Apple red (systemRed)
    tr = (255, 55, 95)    # slightly pinker
    bl = (255, 100, 130)  # soft coral-pink
    br = (255, 59, 48)    # warm red

    for y in range(size):
        for x in range(size):
            fx = x / (size - 1)
            fy = y / (size - 1)

            top = tuple(int(tl[i] * (1 - fx) + tr[i] * fx) for i in range(3))
            bot = tuple(int(bl[i] * (1 - fx) + br[i] * fx) for i in range(3))
            color = tuple(int(top[i] * (1 - fy) + bot[i] * fy) for i in range(3))

            pixels[x, y] = (*color, 255)

    return img


def add_apple_glow(img, size):
    """Add Apple-style inner luminosity — subtle highlight at top-center."""
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Soft white glow at upper-center (Apple icons feel "lit from above")
    glow_cx, glow_cy = size // 2, size * 2 // 7
    max_r = int(size * 0.45)

    for r in range(max_r, 0, -2):
        t = 1 - r / max_r
        alpha = int(40 * t ** 2.5)
        draw.ellipse(
            [glow_cx - r, glow_cy - r, glow_cx + r, glow_cy + r],
            fill=(255, 255, 255, alpha)
        )

    return Image.alpha_composite(img, overlay)


def draw_apple_note(img, size):
    """Draw Apple Music-style note — clean, bold, perfectly centered."""
    AA = 4
    big = size * AA
    canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    s = big / 1024
    cx, cy = big // 2, big // 2

    # Apple Music uses a bold double eighth note, slightly larger proportion
    ox = int(-12 * s)
    oy = int(5 * s)

    head_rx = int(72 * s)
    head_ry = int(52 * s)
    stem_w = int(20 * s)
    stem_h = int(320 * s)
    note_gap = int(220 * s)
    beam_h = int(28 * s)
    beam_gap = int(48 * s)
    tilt = math.radians(-18)

    h1_cx = cx + ox - note_gap // 2
    h1_cy = cy + oy + int(140 * s)
    h2_cx = cx + ox + note_gap // 2
    h2_cy = cy + oy + int(108 * s)

    s1_x = h1_cx + int(head_rx * 0.65)
    s2_x = h2_cx + int(head_rx * 0.65)
    s1_top = h1_cy - stem_h
    s2_top = h2_cy - stem_h

    white = (255, 255, 255, 255)

    # Note heads
    for hcx, hcy in [(h1_cx, h1_cy), (h2_cx, h2_cy)]:
        for dy in range(-head_ry - 3, head_ry + 3):
            for dx in range(-head_rx - 3, head_rx + 3):
                rx = dx * math.cos(-tilt) - dy * math.sin(-tilt)
                ry = dx * math.sin(-tilt) + dy * math.cos(-tilt)
                if (rx / head_rx) ** 2 + (ry / head_ry) ** 2 <= 1.0:
                    px, py = hcx + dx, hcy + dy
                    if 0 <= px < big and 0 <= py < big:
                        draw.point((px, py), fill=white)

    # Stems
    r = int(stem_w * 0.35)
    draw.rounded_rectangle([s1_x, s1_top, s1_x + stem_w, h1_cy - int(8 * s)], radius=r, fill=white)
    draw.rounded_rectangle([s2_x, s2_top, s2_x + stem_w, h2_cy - int(8 * s)], radius=r, fill=white)

    # Beams
    for i in range(2):
        offset = i * beam_gap
        pts = [
            (s1_x - int(1 * s), s1_top + offset),
            (s2_x + stem_w + int(1 * s), s2_top + offset),
            (s2_x + stem_w + int(1 * s), s2_top + offset + beam_h),
            (s1_x - int(1 * s), s1_top + offset + beam_h),
        ]
        draw.polygon(pts, fill=white)

    note_layer = canvas.resize((size, size), Image.LANCZOS)
    return Image.alpha_composite(img, note_layer)


def apple_round_corners(img, size):
    """Apple-style continuous corners (squircle) — approximated with large radius."""
    # Apple uses ~22% corner radius for app icons
    radius = int(size * 0.22)
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def main():
    print("Generating Apple-style icon...")

    # Main logo
    bg = create_apple_gradient(SIZE)
    bg = add_apple_glow(bg, SIZE)
    img = draw_apple_note(bg, SIZE)
    rounded = apple_round_corners(img, SIZE)
    rounded.save('logo.png', 'PNG')
    print("Saved logo.png")

    # Android adaptive foreground (note on transparent)
    fg_canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    fg = draw_apple_note(fg_canvas, SIZE)
    fg.save('logo_adaptive_fg.png', 'PNG')
    print("Saved logo_adaptive_fg.png")

    # Android adaptive background (gradient only)
    bg_only = create_apple_gradient(SIZE)
    bg_only = add_apple_glow(bg_only, SIZE)
    bg_only.save('logo_adaptive_bg.png', 'PNG')
    print("Saved logo_adaptive_bg.png")


if __name__ == '__main__':
    main()
