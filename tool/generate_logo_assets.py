#!/usr/bin/env python3
"""Rasterize official Family Brain Logo 02 assets."""

from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageChops, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
BRAND = os.path.join(ROOT, 'assets/brand')
RES = os.path.join(ROOT, 'android/app/src/main/res')

CHARCOAL = (26, 28, 30, 255)
VIOLET = (99, 91, 255, 255)
NAVY = (10, 0, 51, 255)


def tile_mask(canvas: int, tile: float, radius: float, cx: float, cy: float, angle: float) -> Image.Image:
    work = Image.new('L', (canvas * 2, canvas * 2), 0)
    draw = ImageDraw.Draw(work)
    origin = canvas
    draw.rounded_rectangle(
        [origin - tile / 2, origin - tile / 2, origin + tile / 2, origin + tile / 2],
        radius=radius,
        fill=255,
    )
    work = work.rotate(-angle, resample=Image.Resampling.BICUBIC, center=(origin, origin))
    left = origin - cx
    top = origin - cy
    return work.crop((left, top, left + canvas, top + canvas))


def logo_masks(canvas: int) -> tuple[Image.Image, Image.Image, Image.Image]:
    tile = canvas * 0.62
    radius = tile * 0.18
    offset = canvas * 0.07
    cx = canvas / 2
    cy = canvas / 2
    left = tile_mask(canvas, tile, radius, cx - offset, cy, -40)
    right = tile_mask(canvas, tile, radius, cx + offset, cy, 40)
    hole = ImageChops.multiply(left, right)
    return left, right, hole


def apply_fill(mask: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    layer = Image.new('RGBA', mask.size, color)
    layer.putalpha(mask)
    return layer


def punch(base: Image.Image, hole: Image.Image) -> Image.Image:
    empty = Image.new('RGBA', base.size, (0, 0, 0, 0))
    return Image.composite(empty, base, hole)


def render_mark(canvas: int) -> Image.Image:
    left, right, hole = logo_masks(canvas)
    img = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    img = Image.alpha_composite(img, apply_fill(left, CHARCOAL))
    img = Image.alpha_composite(img, apply_fill(right, VIOLET))
    return punch(img, hole)


def rounded_rect_mask(canvas: int, radius: float) -> Image.Image:
    mask = Image.new('L', (canvas, canvas), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, canvas - 1, canvas - 1],
        radius=radius,
        fill=255,
    )
    return mask


def render_app_icon(canvas: int) -> Image.Image:
    left, right, hole = logo_masks(canvas)
    navy = Image.new('RGBA', (canvas, canvas), NAVY)
    white = Image.new('RGBA', (canvas, canvas), (255, 255, 255, 255))
    shapes = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    combined = ImageChops.lighter(left, right)
    shapes = Image.composite(white, shapes, combined)
    shapes = punch(shapes, hole)
    img = Image.alpha_composite(navy, shapes)
    squircle = rounded_rect_mask(canvas, canvas * 0.22)
    img.putalpha(squircle)
    return img.filter(ImageFilter.UnsharpMask(radius=0.4, percent=80, threshold=2))


def render_lockup(height: int = 256) -> Image.Image:
    mark = render_mark(height)
    width = int(height * 4.2)
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    img.paste(mark, (0, 0), mark)
    try:
        from PIL import ImageFont, ImageDraw as D
        draw = D.Draw(img)
        font = None
        for path in (
            '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
            '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
        ):
            if os.path.exists(path):
                font = ImageFont.truetype(path, int(height * 0.36))
                break
        if font is None:
            font = ImageFont.load_default()
        text = 'Family Brain'
        bbox = draw.textbbox((0, 0), text, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x = height + int(height * 0.08)
        y = (height - th) / 2 - bbox[1]
        draw.text((x, y), text, font=font, fill=CHARCOAL)
        cropped = width
        if x + tw + 16 < width:
            cropped = int(x + tw + height * 0.08)
        img = img.crop((0, 0, cropped, height))
    except Exception:
        pass
    return img


def save(image: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, 'PNG')
    print('wrote', path, image.size)


def main() -> None:
    os.makedirs(BRAND, exist_ok=True)
    save(render_mark(1024), os.path.join(BRAND, 'family_brain_mark.png'))
    save(render_app_icon(1024), os.path.join(BRAND, 'family_brain_app_icon.png'))
    save(render_mark(40), os.path.join(BRAND, 'family_brain_mark_40.png'))
    save(render_lockup(256), os.path.join(BRAND, 'family_brain_lockup.png'))
    mipmaps = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in mipmaps.items():
        save(render_app_icon(size), os.path.join(RES, folder, 'ic_launcher.png'))


if __name__ == '__main__':
    main()
