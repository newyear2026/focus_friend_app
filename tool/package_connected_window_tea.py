#!/usr/bin/env python3
"""Crop/register whole generated drawings and pack them; never warp body parts."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from collections import deque

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/window-tea-connected-v2'
PREVIOUS = ROOT / 'docs/design/fennec-squirrel-window-tea-v1'
DEST = ROOT / 'assets/images/friends/motion'


def remove_detached_edge_fragments(image):
    """Discard isolated pieces spilling over from neighbouring source cells."""
    alpha = image.getchannel('A')
    width, height = image.size
    opaque = bytearray(1 if a > 128 else 0 for a in alpha.tobytes())
    largest = []
    for start in range(len(opaque)):
        if not opaque[start]:
            continue
        queue, component = deque([start]), []
        opaque[start] = 0
        while queue:
            i = queue.popleft()
            component.append(i)
            x, y = i % width, i // width
            for j in (i - 1 if x else -1, i + 1 if x + 1 < width else -1,
                      i - width if y else -1, i + width if y + 1 < height else -1):
                if j >= 0 and opaque[j]:
                    opaque[j] = 0
                    queue.append(j)
        if len(component) > len(largest):
            largest = component
    connected = bytearray(width * height)
    for i in largest:
        connected[i] = 255
    # Retain the generated antialiased fringe; do not repaint any artwork.
    mask = Image.frombytes('L', image.size, bytes(connected)).filter(ImageFilter.MaxFilter(7))
    image.putalpha(ImageChops.multiply(alpha, mask))
    return image


def head_anchor(image, friend, reference=False):
    # Fixed head/ear silhouette only, with cup and tail excluded.
    x = round(image.width * (0.18 if friend == 'fennec' else 0.43))
    bottom = round(image.height * (0.49 if friend == 'fennec' else 0.52))
    if friend == 'squirrel':
        x, bottom = (140, 130) if reference else (round(image.width * .32), round(image.height * .223))
    elif reference:
        x, bottom = 65, 160
    mask = image.getchannel('A').point(lambda a: 255 if a > 220 else 0)
    bounds = mask.crop((x, 0, image.width, bottom)).getbbox()
    if bounds is None:
        raise ValueError('Missing head silhouette')
    left, top, right, _ = bounds
    return left + x, top, right - 1 + x


def package(friend):
    raw = Image.open(OUT / f'{friend}-rest-raw.png').convert('RGBA')
    assert raw.width == raw.height, raw.size
    cell = raw.width / 4
    reference = Image.open(PREVIOUS / f'{friend}-cel-0.png').convert('RGBA')
    target_left, target_top, target_right = head_anchor(reference, friend, reference=True)
    fixed_y = 348 if friend == 'fennec' else 362
    props = Image.new('RGBA', (512, 512))
    props.alpha_composite(reference.crop((90, fixed_y + 6, 430, 440)), (90, fixed_y + 6))
    props.alpha_composite(reference.crop((150, fixed_y, 410, fixed_y + 6)), (150, fixed_y))
    atlas = Image.new('RGBA', (1536, 1536))
    contact = Image.new('RGB', (1536, 1600), '#fff4df')
    draw = ImageDraw.Draw(contact)
    manifest = []
    for frame in range(16):
        source = raw.crop(tuple(round(value) for value in (
            frame % 4 * cell, frame // 4 * cell,
            (frame % 4 + 1) * cell, (frame // 4 + 1) * cell)))
        source = remove_detached_edge_fragments(source)
        left, top, right = head_anchor(source, friend)
        scale = (target_right - target_left) / (right - left)
        offset = (round(target_right - right * scale),
                  round(target_top - top * scale))
        width, height = round(source.width * scale), round(source.height * scale)
        stage = Image.new('RGBA', (512, 512))
        stage.alpha_composite(source.resize((width, height), Image.Resampling.LANCZOS), offset)
        # Old props are a fixed foreground plate. The entire new connected
        # character above this desk boundary is preserved as a single drawing.
        stage.paste((0, 0, 0, 0), (0, fixed_y, 512, 512))
        stage.alpha_composite(props)
        packed = stage.resize((384, 384), Image.Resampling.LANCZOS)
        atlas.alpha_composite(packed, (frame % 4 * 384, frame // 4 * 384))
        contact.paste(packed, (frame % 4 * 384, frame // 4 * 400), packed)
        draw.text((frame % 4 * 384 + 12, frame // 4 * 400 + 384),
                  f'{friend} cel {frame}', fill='#352724')
        stage.save(OUT / f'{friend}-cel-{frame:02}.png')
        manifest.append({'frame': frame, 'scale': scale, 'offset': offset})
    atlas.save(DEST / friend / 'rest.png')
    atlas.save(OUT / f'{friend}-rest-packed.png')
    contact.save(OUT / f'{friend}-contact.jpg', quality=93)
    (OUT / f'{friend}-registration.json').write_text(json.dumps({
        'method': 'one uniform scale and translation per connected cel',
        'sourceSize': raw.size, 'sourceGrid': [4, 4],
        'stage': [512, 512], 'runtimeCel': [384, 384],
        'fixedPropsFrom': str(PREVIOUS.relative_to(ROOT) / f'{friend}-cel-0.png'),
        'fixedPropsTop': fixed_y, 'frames': manifest}, indent=2) + '\n')


if __name__ == '__main__':
    import sys
    for friend in sys.argv[1:] or ['fennec', 'squirrel']:
        package(friend)
