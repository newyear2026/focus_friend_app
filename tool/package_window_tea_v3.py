#!/usr/bin/env python3
"""Register the approved connected cels at a constant scale; no repainting."""
from pathlib import Path
import json
from PIL import Image, ImageChops, ImageStat, ImageDraw
from package_connected_window_tea import head_anchor, remove_detached_edge_fragments

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/rest-motion-audit-v3/art'
SOURCE = ROOT / 'docs/design/window-tea-connected-v2'
PREVIOUS = ROOT / 'docs/design/fennec-squirrel-window-tea-v1'
DEST = ROOT / 'assets/images/friends/motion'
FEATURES = {
    'fennec': [(135, 40, 230, 170), (330, 55, 390, 170), (235, 115, 325, 170)],
    'squirrel': [(198, 90, 308, 165), (180, 140, 245, 196)],
}
PAIRS = {'fennec': [(0, 4), (4, 5), (7, 8), (8, 9)],
         'squirrel': [(4, 5), (5, 6), (6, 7), (11, 14)]}


def slice_sheet(path, columns, rows):
    raw = Image.open(path).convert('RGBA')
    width, height = raw.width / columns, raw.height / rows
    assert abs(width - height) < 2, raw.size
    return [remove_detached_edge_fragments(raw.crop(tuple(round(v) for v in (
        index % columns * width, index // columns * height,
        (index % columns + 1) * width, (index // columns + 1) * height))))
        for index in range(columns * rows)]


def placed(cel, scale, offset):
    stage = Image.new('RGBA', (512, 512))
    stage.alpha_composite(cel.resize((round(cel.width * scale),
                                     round(cel.height * scale)),
                                    Image.Resampling.LANCZOS), offset)
    return stage


def opaque(image):
    background = Image.new('RGBA', image.size, '#fff4df')
    background.alpha_composite(image)
    return background.convert('RGB')


def register(cels, friend, target, base_scale):
    fixed_left, fixed_top, fixed_right = head_anchor(target, friend, reference=True)
    target_rgb = opaque(target)
    stages, transforms = [], []
    for index, cel in enumerate(cels):
        left, top, right = head_anchor(cel, friend)
        initial = (round(fixed_right - right * base_scale),
                   round(fixed_top - top * base_scale))
        best = None
        resized = cel.resize((round(cel.width * base_scale), round(cel.height * base_scale)), Image.Resampling.LANCZOS)
        for dy in range(-8, 9):
            for dx in range(-8, 9):
                offset = (initial[0] + dx, initial[1] + dy)
                stage = Image.new('RGBA', (512, 512))
                stage.alpha_composite(resized, offset)
                rgb = opaque(stage)
                score = sum(sum(ImageStat.Stat(ImageChops.difference(
                    target_rgb.crop(region), rgb.crop(region))).mean)
                    for region in FEATURES[friend])
                if best is None or score < best[0]:
                    best = (score, stage, offset)
        stages.append(best[1])
        transforms.append({'frame': index, 'scale': base_scale,
                           'offset': best[2], 'registrationError': best[0]})
    return stages, transforms


def package(friend, prepare_only=False):
    OUT.mkdir(parents=True, exist_ok=True)
    reference = Image.open(PREVIOUS / f'{friend}-cel-0.png').convert('RGBA')
    base_cels = slice_sheet(SOURCE / f'{friend}-rest-raw.png', 4, 4)
    left, _, right = head_anchor(base_cels[0], friend)
    ref_left, _, ref_right = head_anchor(reference, friend, reference=True)
    scale = (ref_right - ref_left) / (right - left)
    # The same scale for every original cel prevents cap/ear bbox noise from
    # making the complete animal grow and shrink from one pose to the next.
    canonical = placed(base_cels[0], scale, (
        round(ref_right - right * scale),
        round(head_anchor(reference, friend, reference=True)[1] -
              head_anchor(base_cels[0], friend)[1] * scale)))
    stages, transforms = register(base_cels, friend, canonical, scale)
    for index, stage in enumerate(stages):
        stage.save(OUT / f'{friend}-base-{index:02}.png')
    board = Image.new('RGBA', (1024, 2048))
    for row, (start, end) in enumerate(PAIRS[friend]):
        board.alpha_composite(stages[start], (0, row * 512))
        board.alpha_composite(stages[end], (512, row * 512))
    board.save(OUT / f'{friend}-bridge-reference.png')
    (OUT / f'{friend}-base-registration.json').write_text(json.dumps(transforms, indent=2) + '\n')
    if prepare_only:
        return

    fixed_y = 348 if friend == 'fennec' else 362
    props = Image.new('RGBA', (512, 512))
    props.alpha_composite(reference.crop((90, fixed_y + 6, 430, 440)), (90, fixed_y + 6))
    props.alpha_composite(reference.crop((150, fixed_y, 410, fixed_y + 6)), (150, fixed_y))
    rows = (len(stages) + 3) // 4
    atlas = Image.new('RGBA', (1536, rows * 384))
    contact = Image.new('RGB', (1536, rows * 400), '#fff4df')
    draw = ImageDraw.Draw(contact)
    for index, stage in enumerate(stages):
        stage.paste((0, 0, 0, 0), (0, fixed_y, 512, 512))
        stage.alpha_composite(props)
        stage.save(OUT / f'{friend}-cel-{index:02}.png')
        packed = stage.resize((384, 384), Image.Resampling.LANCZOS)
        atlas.alpha_composite(packed, (index % 4 * 384, index // 4 * 384))
        contact.paste(packed, (index % 4 * 384, index // 4 * 400), packed)
        draw.text((index % 4 * 384 + 12, index // 4 * 400 + 384),
                  f'{friend} cel {index}', fill='#352724')
    atlas.save(OUT / f'{friend}-rest-packed.png')
    atlas.save(DEST / friend / 'rest.png')
    contact.save(OUT / f'{friend}-contact.jpg', quality=93)
    (OUT / f'{friend}-registration.json').write_text(json.dumps({
        'method': 'one fixed scale per source sheet and rigid whole-cel translation',
        'originals': transforms, 'inbetweens': [],
        'bridgePairs': PAIRS[friend], 'stage': [512, 512],
        'runtimeCel': [384, 384], 'runtimeGrid': [4, rows]}, indent=2) + '\n')


if __name__ == '__main__':
    import sys
    prepare_only = '--prepare-only' in sys.argv
    friends = [v for v in sys.argv[1:] if not v.startswith('--')]
    for friend in friends or ['fennec', 'squirrel']:
        package(friend, prepare_only)
