#!/usr/bin/env python3
"""Pack complete authored cels; no limb edits, morphing or alpha repainting."""
from pathlib import Path
import hashlib
import json
import shutil

import numpy as np
from PIL import Image

from package_reference_page_turn import complete_drawings
from package_reference_writing import forehead_anchor, head_geometry

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/calm-connected-motion'
CELL = 512


def register(cel, canonical):
    target = forehead_anchor(canonical)
    anchor = forehead_anchor(cel)
    base_width, base_height = head_geometry(canonical, target)
    width, height = head_geometry(cel, anchor)
    scale = ((base_width / width) * (base_height / height)) ** .5
    assert .8 < scale < 1.2, scale
    resized = cel.resize((round(CELL * scale), round(CELL * scale)),
                         Image.Resampling.LANCZOS)
    dx = round(target[0] - anchor[0] * scale)
    dy = round(target[1] - anchor[1] * scale)
    packed = Image.new('RGBA', (CELL, CELL))
    packed.paste(resized, (dx, dy))
    ys, xs = np.where(np.asarray(packed)[:, :, 3] > 128)
    assert 0 < xs.min() <= xs.max() < CELL - 1
    assert 0 < ys.min() <= ys.max() < CELL - 1
    return packed, {'uniformScale': scale, 'translation': [dx, dy]}


def main():
    cels = [Image.open(OUT / f'frames/body-{i:02}.png').convert('RGBA')
            for i in range(30)]
    canonical = cels[0]
    changes = {}
    source = Image.open(OUT / 'alpha-cleanup-source.png').convert('RGBA')
    for half, index in enumerate((4,)):
        cut = source.crop((half * source.width // 2, 0,
                           (half + 1) * source.width // 2, source.height))
        ys, xs = np.where(np.asarray(cut)[:, :, 3] > 128)
        # Crop and register the ENTIRE connected character, preserving alpha.
        bounds = (int(xs.min()) - 8, int(ys.min()) - 8,
                  int(xs.max()) + 9, int(ys.max()) + 9)
        cut = cut.crop(bounds)
        scale = min(480 / cut.width, 470 / cut.height)
        cut = cut.resize((round(cut.width * scale), round(cut.height * scale)),
                         Image.Resampling.LANCZOS)
        cel = Image.new('RGBA', (CELL, CELL))
        cel.paste(cut, (16, 24))
        cels[index], geometry = register(cel, canonical)
        changes[index] = {'source': 'alpha-cleanup-source.png',
                          'sourceCel': half, **geometry}
    pairs = [(9, 8), (28, 12), (12, 13), (13, 21), (14, 15), (15, 29)]
    source = Image.open(OUT / 'slow-inbetweens-source.png').convert('RGBA')
    for local, cel in enumerate(complete_drawings(source)):
        index = 30 + local
        packed, geometry = register(cel, canonical)
        cels.append(packed)
        changes[index] = {'source': 'slow-inbetweens-source.png',
                          'sourceCel': local, 'requestedBetween': pairs[local], **geometry}
    for name, index, between in [
        ('lift-cleanup', 25, None), ('settling-bridge', 36, [13, 21]),
    ]:
        cut = Image.open(OUT / f'{name}-source.png').convert('RGBA')
        ys, xs = np.where(np.asarray(cut)[:, :, 3] > 128)
        cut = cut.crop((int(xs.min()) - 8, int(ys.min()) - 8,
                        int(xs.max()) + 9, int(ys.max()) + 9))
        scale = min(480 / cut.width, 470 / cut.height)
        cut = cut.resize((round(cut.width * scale), round(cut.height * scale)),
                         Image.Resampling.LANCZOS)
        cel = Image.new('RGBA', (CELL, CELL))
        cel.paste(cut, (16, 24))
        packed, geometry = register(cel, canonical)
        if index == len(cels):
            cels.append(packed)
        else:
            cels[index] = packed
        changes[index] = {'source': f'{name}-source.png', **geometry}
        if between:
            changes[index]['between'] = between
    # The same complete bridge is also used after the paper has settled.
    # A separate atlas index lets page geometry exist only on its first visit.
    cels.append(cels[36].copy())
    changes[37] = {'sameWholeDrawingAs': 36, 'paper': 'already settled'}
    atlas = Image.new('RGBA', (CELL * 6, CELL * 7))
    folder = OUT / 'slow-frames'
    folder.mkdir(exist_ok=True)
    entries = []
    for index, cel in enumerate(cels):
        cel.save(folder / f'body-{index:02}.png')
        atlas.paste(cel, (index % 6 * CELL, index // 6 * CELL))
        entries.append({'cel': index,
                        **changes.get(index, {'source': f'frames/body-{index:02}.png'}),
                        'sha256': hashlib.sha256(cel.tobytes()).hexdigest()})
    atlas.save(OUT / 'body-atlas-slow.png')
    shutil.copy2(OUT / 'body-atlas-slow.png',
                 ROOT / 'assets/images/immersive/redpanda-slow-connected-body-38.png')
    manifest = {'mode': 'built-in image_gen', 'columns': 6, 'rows': 7,
                'cellSize': CELL, 'writingStrokeSeconds': 4,
                'writingSeconds': 36, 'pageTurnSeconds': 5.5,
                'cycleSeconds': 41.5, 'frames': entries}
    (OUT / 'slow-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'drawings': len(cels), 'changes': changes}))


if __name__ == '__main__':
    main()
