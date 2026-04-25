#!/usr/bin/env python3
"""Generate a modern, vibrant music player icon."""

from PIL import Image, ImageDraw
import math

SIZE = 1024


def create_gradient(size):
    """Create a vibrant gradient from coral/pink to deep purple."""
    img = Image.new('RGBA', (size, size))
    pixels = img.load()

    tl = (255, 107, 107)
    tr = (238, 90, 157)
    bl = (124, 77, 255)
    br = (101, 31, 255)

    for y in range(size):
        for x in range(size):
            fx = x / (size - 1)
            fy = y / (size - 1)
            top = tuple(int(tl[i] * (1 - fx) + tr[i] * fx) for i in range(3))
            bot = tuple(int(bl[i] * (1 - fx) + br[i] * fx) for i in range(3))
            color = tuple(int(top[i] * (1 - fy) + bot[i] * fy) for i in range(3))
            pixels[x, y] = (*color, 255)

    return img


def draw_music_note(draw, size, offset_x=0, offset_y=0):
    """Draw a clean, centered double eighth note."""
    cx, cy = size // 2, size // 2
    s = size / 1024

    ox = int((-30 + offset_x) * s)
    oy = int((10 + offset_y) * s)

    head_rx = int(62 * s)
    head_ry = int(45 * s)
    stem_w = int(16 * s)
    stem_h = int(300 * s)
    note_gap = int(200 * s)
    beam_h = int(22 * s)
    beam_gap = int(38 * s)
    tilt = -20

    h1_cx = cx + ox - note_gap // 2
    h1_cy = cy + oy + int(130 * s)
    h2_cx = cx + ox + note_gap // 2
    h2_cy = cy + oy + int(100 * s)

    s1_x = h1_cx + int(head_rx * 0.7)
    s2_x = h2_cx + int(head_rx * 0.7)

    s1_top = h1_cy - stem_h
    s2_top = h2_cy - stem_h

    angle = math.radians(tilt)
    white = (255, 255, 255, 255)

    for hcx, hcy in [(h1_cx, h1_cy), (h2_cx, h2_cy)]:
        for dy in range(-head_ry - 2, head_ry + 2):
            for dx in range(-head_rx - 2, head_rx + 2):
                rx = dx * math.cos(-angle) - dy * math.sin(-angle)
                ry = dx * math.sin(-angle) + dy * math.cos(-angle)
                if (rx / head_rx) ** 2 + (ry / head_ry) ** 2 <= 1.0:
                    px, py = hcx + dx, hcy + dy
                    if 0 <= px < size and 0 <= py < size:
                        draw.point((px, py), fill=white)

    draw.rectangle([s1_x, s1_top, s1_x + stem_w, h1_cy], fill=white)
    draw.rectangle([s2_x, s2_top, s2_x + stem_w, h2_cy], fill=white)

    for i in range(2):
        offset = i * beam_gap
        pts = [
            (s1_x, s1_top + offset),
            (s2_x + stem_w, s2_top + offset),
            (s2_x + stem_w, s2_top + offset + beam_h),
            (s1_x, s1_top + offset + beam_h),
        ]
        draw.polygon(pts, fill=white)


def add_glow(img, size):
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    glow_cx, glow_cy = size * 3 // 10, size * 3 // 10
    max_r = size // 3
    for r in range(max_r, 0, -2):
        alpha = int(25 * (1 - r / max_r) ** 2)
        draw.ellipse(
            [glow_cx - r, glow_cy - r, glow_cx + r, glow_cy + r],
            fill=(255, 255, 255, alpha)
        )
    return Image.alpha_composite(img, overlay)


def round_corners(img, radius):
    size = img.size[0]
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def main():
    print("Generating modern icon...")

    # Main logo (gradient + note + rounded corners)
    img = create_gradient(SIZE)
    img = add_glow(img, SIZE)
    draw = ImageDraw.Draw(img)
    draw_music_note(draw, SIZE)
    rounded = round_corners(img, SIZE // 5)
    rounded.save('logo.png', 'PNG')
    print("Saved logo.png")

    # Android adaptive icon foreground (white note on transparent)
    fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg)
    draw_music_note(fg_draw, SIZE)
    fg.save('logo_adaptive_fg.png', 'PNG')
    print("Saved logo_adaptive_fg.png")

    # Android adaptive icon background (gradient only)
    bg = create_gradient(SIZE)
    bg = add_glow(bg, SIZE)
    bg.save('logo_adaptive_bg.png', 'PNG')
    print("Saved logo_adaptive_bg.png")


if __name__ == '__main__':
    main()
