#!/usr/bin/env python3
"""Register connected authored drawings as a whole; no limb deformation."""
from pathlib import Path
import json
from PIL import Image, ImageChops, ImageStat, ImageDraw
from package_connected_window_tea import remove_detached_edge_fragments

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/window-tea-mouth-v4/art'
BASE = ROOT / 'docs/design/rest-motion-audit-v3/art'
FEATURES = {
    'fennec': [(135, 40, 230, 170), (330, 55, 390, 170), (235, 115, 325, 170)],
    'squirrel': [(198, 90, 308, 165), (180, 140, 245, 196)],
}


def opaque(image):
    background = Image.new('RGBA', image.size, '#fff4df')
    background.alpha_composite(image)
    return background.convert('RGB')


def head_top(image, friend):
    alpha = image.getchannel('A').point(lambda a: 255 if a > 220 else 0)
    x = round(image.width * (.35 if friend == 'squirrel' else .2))
    bounds = alpha.crop((x, 0, image.width, round(image.height * .6))).getbbox()
    if bounds is None:
        raise ValueError('Missing head')
    return bounds[1]


def head_right(image, friend, top, height):
    alpha = image.getchannel('A').point(lambda a: 255 if a > 220 else 0)
    x = round(image.width * (.3 if friend == 'squirrel' else .2))
    bounds = alpha.crop((x, 0, image.width, min(image.height, round(top + height)))).getbbox()
    return bounds[2] + x


def fit(cel, target, friend):
    cel = remove_detached_edge_fragments(cel.copy())
    reference = opaque(target)
    source_top, target_top = head_top(cel, friend), head_top(target, friend)
    target_right = head_right(target, friend, target_top, 30 if friend == 'squirrel' else 80)
    nominal = 512 / cel.width
    best = None

    def search(scales, refine=False):
        nonlocal best
        for scale in scales:
            source_right = head_right(cel, friend, source_top,
                                     (30 if friend == 'squirrel' else 80) / scale)
            initial = (round(target_right - source_right * scale),
                       round(target_top - source_top * scale))
            resized = cel.resize((round(cel.width * scale), round(cel.height * scale)),
                                 Image.Resampling.LANCZOS)
            for dy in range(-6, 7, 1 if refine else 2):
                for dx in range(-10, 11, 1 if refine else 2):
                    offset = (initial[0] + dx, initial[1] + dy)
                    stage = Image.new('RGBA', (512, 512))
                    stage.alpha_composite(resized, offset)
                    rgb = opaque(stage)
                    score = sum(sum(ImageStat.Stat(ImageChops.difference(
                        reference.crop(region), rgb.crop(region))).mean)
                        for region in FEATURES[friend])
                    if best is None or score < best[0]:
                        best = (score, stage, scale, offset)

    search([nominal * (.70 + step * .025) for step in range(23)])
    scale = best[2]
    search([scale * (1 + step * .0025) for step in range(-2, 3)], refine=True)
    return best[1], {'scale': best[2], 'offset': best[3], 'featureError': best[0]}


def prepare(friend):
    target = Image.open(BASE / f'{friend}-base-00.png').convert('RGBA')
    source = Image.open(OUT / f'{friend}-sip-raw.png').convert('RGBA')
    stage, transform = fit(source, target, friend)
    stage.save(OUT / f'{friend}-sip-registered.png')
    (OUT / f'{friend}-sip-registration.json').write_text(json.dumps(transform, indent=2) + '\n')
    return stage


def strip_cells(path):
    image = Image.open(path).convert('RGBA')
    half = image.width / 2
    if abs(half - image.height) > 2:
        raise ValueError(f'Expected two square cels, got {image.size}')
    return [image.crop((round(i * half), 0, round((i + 1) * half), image.height))
            for i in range(2)]


def package(friend, publish=False):
    target = Image.open(BASE / f'{friend}-base-00.png').convert('RGBA')
    stages = [Image.open(BASE / f'{friend}-cel-{i:02}.png').convert('RGBA')
              for i in range(16)]
    stages.append(Image.open(OUT / f'{friend}-sip-registered.png').convert('RGBA'))
    manifest = []
    groups = [('tilt', OUT / f'{friend}-tilt-raw.png')]
    groups += [(f'lift-{i}', OUT / f'{friend}-lift-{i}-raw.png')
               for i in range(4 if friend == 'fennec' else 3)]
    if friend == 'squirrel':
        groups.append(('start', OUT / 'squirrel-start-raw.png'))
    for name, path in groups:
        for slot, source in enumerate(strip_cells(path)):
            stage, transform = fit(source, target, friend)
            manifest.append({'frame': len(stages), 'source': str(path.relative_to(ROOT)),
                             'stripSlot': slot, 'kind': name, **transform})
            stages.append(stage)
    fixed_y = 348 if friend == 'fennec' else 362
    # The fixed foreground is identical in every cel, and never follows hands.
    props = stages[0].crop((0, fixed_y, 512, 512))
    while len(stages) < 28:
        stages.append(stages[0].copy())
    atlas = Image.new('RGBA', (1536, 2688))
    contact = Image.new('RGB', (1536, 2800), '#fff4df')
    draw = ImageDraw.Draw(contact)
    for index, stage in enumerate(stages):
        stage.paste((0, 0, 0, 0), (0, fixed_y, 512, 512))
        stage.alpha_composite(props, (0, fixed_y))
        stage.save(OUT / f'{friend}-cel-{index:02}.png')
        packed = stage.resize((384, 384), Image.Resampling.LANCZOS)
        atlas.alpha_composite(packed, (index % 4 * 384, index // 4 * 384))
        contact.paste(packed, (index % 4 * 384, index // 4 * 400), packed)
        draw.text((index % 4 * 384 + 8, index // 4 * 400 + 384),
                  f'{friend} cel {index}', fill='#352724')
    atlas.save(OUT / f'{friend}-rest-packed.png')
    contact.save(OUT / f'{friend}-contact.jpg', quality=94)
    (OUT / f'{friend}-registration.json').write_text(json.dumps(manifest, indent=2) + '\n')
    if publish:
        atlas.save(ROOT / f'assets/images/friends/motion/{friend}/rest.png')


if __name__ == '__main__':
    import sys
    friends = [arg for arg in sys.argv[1:] if not arg.startswith('--')]
    for friend in friends or ['squirrel', 'fennec']:
        if '--package' in sys.argv:
            package(friend, '--publish' in sys.argv)
        else:
            prepare(friend)
