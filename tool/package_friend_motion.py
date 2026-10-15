#!/usr/bin/env python3
"""Mechanically register and pack authored ImageGen cels; never redraw artwork."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/design/penguin-otter-motion-v1'
DESTINATION = ROOT / 'assets/images/friends/motion'
CELL = 384
# Whole-cel affine registration in the common 512px stage, not limb transforms.
REGISTRATION = {
    'penguin': {'study-a': (1, 50, 55)},
    'otter': {'study-a': (1.15, 0, 40)},
}


def head_box(cel):
    pixels = np.asarray(cel)
    rgb = pixels[:, :, :3].astype(int)
    mask = (pixels[:, :, 3] > 220) & (rgb.max(axis=2) < 240)
    mask[:24] = False  # atlas gutter; discard neighbouring-cell bleed
    top = int(np.where(mask)[0].min())
    band = mask[top + 25:top + 140]
    xx = np.where(band)[1]
    return float(xx.min()), float(xx.max()), top


def book_anchor(cel):
    pixels = np.asarray(cel).astype(int)
    r, g, b, alpha = (pixels[:, :, i] for i in range(4))
    cover = (alpha > 220) & (g > r + 4) & (b > r + 3)
    cover[:270] = False
    cover[:, :45] = False
    cover[:, 295:] = False
    yy, xx = np.where(cover)
    return float(xx.min()), float(yy.max())


def cells(animal, section):
    source = Image.open(SOURCE / f'{animal}-{section}-raw.png').convert('RGBA')
    width, height = source.size
    assert width % 4 == 0 and height % 3 == 0
    assert width // 4 == height // 3, 'Sprite cells must be square'
    base = Image.open(SOURCE / f'{animal}-study-a-raw.png').convert('RGBA')
    base_size = base.width // 4
    reference = base.crop((0, 0, base_size, base_size))
    left, right, top = head_box(reference)
    base_scale, base_x, base_y = REGISTRATION[animal]['study-a']
    target_width = (right - left) * base_scale
    target_center = (right + left) / 2 * base_scale + base_x
    target_top = top * base_scale + base_y
    book_x, book_y = book_anchor(reference)
    target_book_x = book_x * base_scale + base_x
    target_book_y = book_y * base_scale + base_y
    result = []
    for index in range(12):
        size = width // 4
        cel = source.crop((index % 4 * size, index // 4 * size,
                           (index % 4 + 1) * size, (index // 4 + 1) * size))
        if section.startswith('study'):
            book_x, book_y = book_anchor(cel)
            scale = base_scale
            x = round(target_book_x - book_x * scale)
            y = round(target_book_y - book_y * scale)
        else:
            left, right, top = head_box(cel)
            scale = target_width / (right - left)
            x = round(target_center - (left + right) / 2 * scale)
            y = round(target_top - top * scale)
        # Mechanical atlas slicing: keep artwork, exclude only the cell gutter.
        inner = cel.crop((0, 24, size, size))
        cel = Image.new('RGBA', (size, size))
        cel.alpha_composite(inner, (0, 24))
        scaled = round(size * scale)
        cel = cel.resize((scaled, scaled), Image.Resampling.LANCZOS)
        stage = Image.new('RGBA', (512, 512))
        stage.alpha_composite(cel, (x, y))
        result.append(stage)
    return result


def main():
    for animal in REGISTRATION:
        target = DESTINATION / animal
        target.mkdir(parents=True, exist_ok=True)
        sets = {'study': cells(animal, 'study-a') + cells(animal, 'study-b'),
                'rest': cells(animal, 'rest')}
        for name, frames in sets.items():
            atlas = Image.new('RGBA', (CELL * 4, CELL * (len(frames) // 4)))
            for index, frame in enumerate(frames):
                tile = frame.resize((CELL, CELL), Image.Resampling.LANCZOS)
                atlas.alpha_composite(tile, (index % 4 * CELL, index // 4 * CELL))
            atlas.save(target / f'{name}.png')
            sheet = Image.new('RGB', (512 * 3, 540 * 2), '#f3eadb')
            draw = ImageDraw.Draw(sheet)
            selected = [0, 5, 8, 16, 20, 23] if name == 'study' else [0, 1, 4, 6, 9, 11]
            for slot, index in enumerate(selected):
                x, y = slot % 3 * 512, slot // 3 * 540
                sheet.paste(frames[index], (x, y), frames[index])
                draw.text((x + 12, y + 512), f'{animal} {name} cel {index}', fill='#352724')
            sheet.save(SOURCE / f'{animal}-{name}-registration.jpg', quality=93)
        report = {'stage': [512, 512], 'runtimeCell': CELL,
                  'studyCels': 24, 'teaCels': 12,
                  'baseStudyTransform': REGISTRATION[animal]['study-a'],
                  'studyRegistration': 'whole-cel translation by book left/bottom',
                  'restRegistration': 'uniform whole-cel scaling/translation by head width/top'}
        (SOURCE / f'{animal}-registration.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
