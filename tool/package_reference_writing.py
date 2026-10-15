#!/usr/bin/env python3
"""Pack whole authored cels with translation-only registration and previews.

Run with the bundled Python/Pillow/NumPy runtime. Artwork is created by
image_gen; this script does not redraw, deform, blend or isolate body parts.
"""
from collections import deque
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/connected-writing-24'
DETAIL = OUT / 'detail'
CELL = 512
TIMELINE = [0] * 6 + list(range(24)) + [23] * 6


def forehead_anchor(cel):
    """Locate the round cream forehead spot, excluding ears and face patches."""
    rgba = np.array(cel)
    red, green, blue, alpha = [rgba[:, :, i] for i in range(4)]
    yy, xx = np.indices(alpha.shape)
    mask = ((red > 220) & (green > 180) & (blue > 140) & (alpha > 128)
            & (xx >= 230) & (xx <= 355) & (yy >= 100) & (yy <= 265))
    candidates = []
    for y, x in zip(*np.where(mask)):
        if not mask[y, x]:
            continue
        queue = deque([(int(y), int(x))])
        mask[y, x] = False
        pixels = []
        while queue:
            py, px = queue.popleft()
            pixels.append((py, px))
            for cy, cx in ((py - 1, px), (py + 1, px),
                           (py, px - 1), (py, px + 1)):
                if 0 <= cy < CELL and 0 <= cx < CELL and mask[cy, cx]:
                    mask[cy, cx] = False
                    queue.append((cy, cx))
        if not 250 <= len(pixels) <= 1000:
            continue
        points = np.array(pixels)
        width = int(np.ptp(points[:, 1])) + 1
        height = int(np.ptp(points[:, 0])) + 1
        if not (18 <= width <= 42 and 18 <= height <= 42):
            continue
        center_y, center_x = np.mean(points, axis=0)
        candidates.append((float(center_x), float(center_y), width, height))
    assert candidates, 'Cannot locate the held forehead anchor'
    return min(candidates, key=lambda a: (a[0] - 290) ** 2 + (a[1] - 202) ** 2)


def extract_connected_cels(sheet):
    """Find the six complete drawings; generated gutters can vary in width."""
    mask = np.array(sheet)[:, :, 3] > 128
    height, width = mask.shape
    components = []
    for sy, sx in zip(*np.where(mask)):
        if not mask[sy, sx]:
            continue
        queue = deque([(int(sy), int(sx))])
        mask[sy, sx] = False
        count = 0
        left = right = int(sx)
        top = bottom = int(sy)
        while queue:
            y, x = queue.popleft()
            count += 1
            left, right = min(left, x), max(right, x)
            top, bottom = min(top, y), max(bottom, y)
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < height and 0 <= nx < width and mask[ny, nx]:
                    mask[ny, nx] = False
                    queue.append((ny, nx))
        if count > 50000:
            components.append((left, top, right + 1, bottom + 1))
    assert len(components) == 6, components
    components.sort(key=lambda r: (int((r[1] + r[3]) / 2 >= height / 2), r[0]))
    result = []
    for left, top, right, bottom in components:
        assert right - left <= 488 and bottom - top <= 470
        # Eight pixels of transparent edge preserve antialiasing. This crop
        # includes the entire connected panda AND notebook, including the tail.
        sprite = sheet.crop((left - 8, top - 8, right + 8, bottom + 8))
        cel = Image.new('RGBA', (CELL, CELL))
        cel.paste(sprite, (3, 25))
        result.append(cel)
    return result


def head_geometry(cel, anchor):
    alpha = np.array(cel)[:, :, 3] > 128
    yy, _ = np.indices(alpha.shape)
    ys, xs = np.where(alpha & (yy < anchor[1] + 8))
    return float(xs.max() - xs.min() + 1), float(anchor[1] - ys.min())


def main():
    (OUT / 'frames').mkdir(exist_ok=True)
    (DETAIL / 'raw-frames').mkdir(exist_ok=True)
    cels = []
    sources = []
    for batch in range(1, 5):
        path = DETAIL / f'output-{batch}.png'
        sheet = Image.open(path).convert('RGBA')
        assert sheet.size == (CELL * 3, CELL * 2), sheet.size
        sources.append(str(path.relative_to(ROOT)))
        for cel in extract_connected_cels(sheet):
            alpha = np.array(cel)[:, :, 3]
            assert np.mean(alpha == 0) > .3, 'A cel lacks genuine transparency'
            cels.append(cel)
    anchors = [forehead_anchor(cel) for cel in cels]
    anchor_x, anchor_y, _, _ = anchors[0]
    base_width, base_height = head_geometry(cels[0], anchors[0])
    atlas = Image.new('RGBA', (CELL * 4, CELL * 6))
    info, registered = [], []
    for i, (cel, anchor) in enumerate(zip(cels, anchors)):
        dx, dy = round(anchor_x - anchor[0]), round(anchor_y - anchor[1])
        assert abs(dx) <= 60 and abs(dy) <= 60, (i, dx, dy)
        cel.save(DETAIL / 'raw-frames' / f'frame-{i + 1:02}.png')
        packed = Image.new('RGBA', (CELL, CELL))
        packed.paste(cel, (dx, dy))  # Copy complete RGBA pixels, no blending.
        before = np.array(cel)[:, :, 3] > 128
        after = np.array(packed)[:, :, 3] > 128
        assert before.sum() == after.sum(), 'Registration clipped visible artwork'
        packed.save(OUT / 'frames' / f'frame-{i + 1:02}.png')
        atlas.paste(packed, (i % 4 * CELL, i // 4 * CELL))
        registered.append(packed)
        width, height = head_geometry(cel, anchor)
        scale = round(((base_width / width) * (base_height / height)) ** .5, 6)
        assert .90 <= scale <= 1.10, scale
        ys, xs = np.where(after)
        info.append({'drawing': i + 1, 'file': f'frames/frame-{i + 1:02}.png',
                     'pixelSha256': hashlib.sha256(packed.tobytes()).hexdigest(),
                     'sourceSheet': sources[i // 6], 'sourceCell': i % 6,
                     'translation': [dx, dy], 'sourceAnchor': list(anchor),
                     'displayScale': scale,
                     'opaqueBounds': [int(xs.min()), int(ys.min()),
                                      int(xs.max()) + 1, int(ys.max()) + 1]})
    assert len({cel['pixelSha256'] for cel in info}) == 24
    previous = OUT / 'draft-24.png'
    if not previous.exists():
        shutil.copy2(OUT / 'final-atlas.png', previous)
    atlas.save(OUT / 'final-atlas.png')
    shutil.copy2(OUT / 'final-atlas.png',
                 ROOT / 'assets/images/immersive/redpanda-connected-writing-24.png')

    preview_frames = []
    for i in TIMELINE:
        matte = Image.new('RGBA', (CELL, CELL), (255, 247, 230, 255))
        scale = info[i]['displayScale']
        # Preview the same uniform whole-cel registration as Flutter/Canvas.
        scaled = registered[i].resize((round(CELL * scale), round(CELL * scale)),
                                      Image.Resampling.LANCZOS)
        matte.alpha_composite(scaled, (round((1 - scale) * anchor_x),
                                      round((1 - scale) * anchor_y)))
        preview_frames.append(matte.convert('RGB'))
    palette = preview_frames[0].quantize(colors=255)
    gifs = [frame.quantize(palette=palette, dither=Image.Dither.NONE)
            for frame in preview_frames]
    gifs[0].save(OUT / 'writing-loop.gif', save_all=True,
                 append_images=gifs[1:], duration=[80, 90, 80] * 12,
                 loop=0, optimize=False)
    gif = Image.open(OUT / 'writing-loop.gif')
    duration = 0
    for i in range(gif.n_frames):
        gif.seek(i)
        duration += gif.info['duration']
    assert duration == 3000
    manifest = {'mode': 'built-in image_gen', 'sourceSheets': sources,
                'asset': 'assets/images/immersive/redpanda-connected-writing-24.png',
                'atlasSize': list(atlas.size), 'columns': 4, 'rows': 6,
                'cellSize': [CELL, CELL], 'drawings': 24, 'fps': 12,
                'timeline': TIMELINE, 'loopMilliseconds': 3000,
                'registrationIn580Canvas': [64, 35, 500, 500],
                'registrationAnchor': [anchor_x, anchor_y], 'frames': info,
                'gifMilliseconds': duration}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    scales = [entry['displayScale'] for entry in info]
    registration = ('// Generated by tool/package_reference_writing.py.\n'
                    '// Uniform registration of each COMPLETE cel, not joint motion.\n'
                    'abstract final class ReferenceWritingRegistration {\n'
                    f'  static const anchorX = {anchor_x / CELL:.9f};\n'
                    f'  static const anchorY = {anchor_y / CELL:.9f};\n'
                    '  static const scales = <double>[\n'
                    + ''.join(f'    {scale:.6f},\n' for scale in scales)
                    + '  ];\n}\n')
    (ROOT / 'lib/reference_writing_registration.dart').write_text(registration)
    (OUT / 'registration.js').write_text(
        'const spriteRegistration = ' + json.dumps({
            'anchorX': anchor_x / CELL, 'anchorY': anchor_y / CELL, 'scales': scales}) + ';\n')
    with zipfile.ZipFile(OUT / 'writing-24-frames.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(OUT / 'manifest.json', 'manifest.json')
        for path in sorted((OUT / 'frames').glob('*.png')):
            archive.write(path, 'frames/' + path.name)
    print(json.dumps({'atlas': atlas.size, 'cell': CELL, 'uniqueDrawings': 24,
                      'loopMs': duration, 'translations': [i['translation'] for i in info]}))


if __name__ == '__main__':
    main()
