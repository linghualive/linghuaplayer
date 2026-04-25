#!/usr/bin/env python3
"""Generate app icon in Apple Music style — single eighth note on red-pink gradient."""

import math
import os
from PIL import Image, ImageDraw


def draw_gradient(img, color_top, color_bot):
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        t = y / (h - 1)
        r = int(color_top[0] + (color_bot[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_bot[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_bot[2] - color_top[2]) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))


def draw_note(draw, s):
    """Draw a single eighth note (♪) — Apple Music style."""
    # Note head: tilted ellipse at bottom-center
    head_cx = s * 0.46
    head_cy = s * 0.66
    head_rx = s * 0.115
    head_ry = s * 0.08
    head_tilt = -30

    # Stem: from right side of note head up
    stem_x = head_cx + head_rx * math.cos(math.radians(-head_tilt)) * 0.65
    stem_bottom = head_cy - head_ry * 0.2
    stem_top = s * 0.22
    stem_w = s * 0.028

    # Draw stem
    draw.rectangle(
        [stem_x - stem_w / 2, stem_top, stem_x + stem_w / 2, stem_bottom],
        fill='white',
    )

    # Flag — a graceful curved flag from stem top
    flag_pts = []
    n = 40
    for i in range(n + 1):
        t = i / n
        # Bezier-like curve for the flag
        x0 = stem_x + stem_w / 2
        y0 = stem_top
        # Control points for a flowing S-curve flag
        cx1 = stem_x + s * 0.18
        cy1 = stem_top + s * 0.04
        cx2 = stem_x + s * 0.14
        cy2 = stem_top + s * 0.22
        x3 = stem_x + s * 0.02
        y3 = stem_top + s * 0.28

        # Cubic bezier
        mt = 1 - t
        x = mt**3 * x0 + 3 * mt**2 * t * cx1 + 3 * mt * t**2 * cx2 + t**3 * x3
        y = mt**3 * y0 + 3 * mt**2 * t * cy1 + 3 * mt * t**2 * cy2 + t**3 * y3
        flag_pts.append((x, y))

    # Inner curve (thinner at the tip)
    for i in range(n, -1, -1):
        t = i / n
        x0 = stem_x + stem_w / 2
        y0 = stem_top
        cx1 = stem_x + s * 0.12
        cy1 = stem_top + s * 0.06
        cx2 = stem_x + s * 0.09
        cy2 = stem_top + s * 0.18
        x3 = stem_x + s * 0.01
        y3 = stem_top + s * 0.24

        mt = 1 - t
        x = mt**3 * x0 + 3 * mt**2 * t * cx1 + 3 * mt * t**2 * cx2 + t**3 * x3
        y = mt**3 * y0 + 3 * mt**2 * t * cy1 + 3 * mt * t**2 * cy2 + t**3 * y3
        flag_pts.append((x, y))

    draw.polygon(flag_pts, fill='white')

    # Note head (tilted ellipse)
    pts = []
    for i in range(72):
        a = 2 * math.pi * i / 72
        px = head_rx * math.cos(a)
        py = head_ry * math.sin(a)
        tilt = math.radians(head_tilt)
        x = head_cx + px * math.cos(tilt) - py * math.sin(tilt)
        y = head_cy + px * math.sin(tilt) + py * math.cos(tilt)
        pts.append((x, y))
    draw.polygon(pts, fill='white')


def generate(size, path, rounded=False):
    ss = 4
    r = size * ss
    img = Image.new('RGBA', (r, r), (0, 0, 0, 0))

    # Apple Music-like gradient: vivid red top → deep magenta/pink bottom
    color_top = (252, 60, 68)
    color_bot = (214, 36, 82)

    if rounded:
        grad = Image.new('RGBA', (r, r))
        draw_gradient(grad, color_top, color_bot)
        mask = Image.new('L', (r, r), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, r - 1, r - 1], radius=int(r * 0.22), fill=255
        )
        img.paste(grad, mask=mask)
    else:
        draw_gradient(img, color_top, color_bot)

    draw_note(ImageDraw.Draw(img), r)
    img = img.resize((size, size), Image.LANCZOS)
    img.save(path, 'PNG')
    print(f"  {path}  ({size}x{size})")


def main():
    base = '/Users/linghua/linghuaplayer'
    res = f'{base}/android/app/src/main/res'
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    print("Generating Android mipmap icons…")
    for folder, sz in sizes.items():
        generate(sz, f'{res}/{folder}/ic_launcher.png', rounded=False)

    # Master icons for flutter_launcher_icons
    print("Generating master icons…")
    generate(1024, f'{base}/logo.png', rounded=False)
    generate(1024, f'{base}/logo_adaptive_fg.png', rounded=False)
    generate(1024, f'{base}/logo_adaptive_bg.png', rounded=False)
    generate(1024, f'{base}/assets/icon/app_icon.png', rounded=True)
    print("Done!")


if __name__ == '__main__':
    main()
