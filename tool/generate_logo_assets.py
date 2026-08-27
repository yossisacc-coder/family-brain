#!/usr/bin/env python3
"""Rasterize official Family Brain 08E two-tone assets from the chosen concept."""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
BRAND = os.path.join(ROOT, 'assets/brand')
RES = os.path.join(ROOT, 'android/app/src/main/res')
SOURCE = os.path.join(BRAND, 'family_brain_08e_source.png')


def save(image: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, 'PNG')
    print('wrote', path, image.size)


def extract_mark(source: Image.Image) -> Image.Image:
    sym = source.crop((80, 160, 944, 640)).convert('RGBA')
    pix = sym.load()
    width, height = sym.size
    for y in range(height):
        for x in range(width):
            red, green, blue, _alpha = pix[x, y]
            if red > 245 and green > 245 and blue > 245:
                pix[x, y] = (255, 255, 255, 0)
    bbox = sym.getbbox()
    if bbox is None:
        return sym
    sym = sym.crop(bbox)
    pad = int(max(sym.size) * 0.08)
    side = max(sym.size) + pad * 2
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(
        sym,
        ((side - sym.size[0]) // 2, (side - sym.size[1]) // 2),
        sym,
    )
    return canvas


def rounded_square(size: int, radius: int, fill: tuple[int, int, int, int]) -> Image.Image:
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(image).rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=radius,
        fill=fill,
    )
    return image


def render_app_icon(mark: Image.Image, size: int = 1024) -> Image.Image:
    background = rounded_square(size, int(size * 0.22), (255, 255, 255, 255))
    inset = int(size * 0.16)
    inner = mark.resize((size - 2 * inset, size - 2 * inset), Image.Resampling.LANCZOS)
    background.paste(inner, (inset, inset), inner)
    return background


def main() -> None:
    source = Image.open(SOURCE).convert('RGBA')
    mark = extract_mark(source)
    mark_1024 = mark.resize((1024, 1024), Image.Resampling.LANCZOS)
    save(mark_1024, os.path.join(BRAND, 'family_brain_mark.png'))
    save(mark.resize((40, 40), Image.Resampling.LANCZOS), os.path.join(BRAND, 'family_brain_mark_40.png'))
    save(source.crop((80, 160, 944, 860)), os.path.join(BRAND, 'family_brain_lockup.png'))
    icon = render_app_icon(mark_1024)
    save(icon, os.path.join(BRAND, 'family_brain_app_icon.png'))
    mipmaps = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in mipmaps.items():
        save(
            icon.resize((size, size), Image.Resampling.LANCZOS),
            os.path.join(RES, folder, 'ic_launcher.png'),
        )


if __name__ == '__main__':
    main()
