#!/usr/bin/env python3
"""Mechanically pack whole Image Gen drawings and the stationary notebook.

No body parts are cut apart, redrawn, blended or warped. Uniform registration
is baked into each COMPLETE drawing so runtime book placement never changes.
"""
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


def main():
    frames = OUT / 'frames'
    frames.mkdir(exist_ok=True)
    canonical = Image.open(ROOT / 'docs/design/connected-writing-24/frames/frame-01.png').convert('RGBA')
    target = forehead_anchor(canonical)
    target_width, target_height = head_geometry(canonical, target)
    atlas = Image.new('RGBA', (2560, 3072))
    entries = []
    for batch, name in enumerate(('writing-body', 'turn-body-clean-1',
                                  'turn-body-clean-2', 'arm-bridges', 'page-inbetweens')):
        source = OUT / f'{name}-source.png'
        for local, cel in enumerate(complete_drawings(Image.open(source).convert('RGBA'))):
            index = batch * 6 + local
            anchor = forehead_anchor(cel)
            width, height = head_geometry(cel, anchor)
            scale = ((target_width / width) * (target_height / height)) ** .5
            assert .85 <= scale <= 1.2
            resized = cel.resize((round(CELL * scale), round(CELL * scale)),
                                 Image.Resampling.LANCZOS)
            packed = Image.new('RGBA', (CELL, CELL))
            dx = round(target[0] - anchor[0] * scale)
            dy = round(target[1] - anchor[1] * scale)
            packed.paste(resized, (dx, dy))
            ys, xs = np.where(np.asarray(packed)[:, :, 3] > 128)
            assert xs.min() > 0 and xs.max() < CELL - 1
            assert ys.min() > 0 and ys.max() < CELL - 1
            packed.save(frames / f'body-{index:02}.png')
            atlas.paste(packed, (index % 5 * CELL, index // 5 * CELL))
            entries.append({'cel': index, 'source': source.name, 'sourceCel': local,
                            'uniformScale': scale, 'translation': [dx, dy],
                            'sha256': hashlib.sha256(packed.tobytes()).hexdigest()})
    atlas.save(OUT / 'body-atlas.png')
    shutil.copy2(OUT / 'body-atlas.png', ROOT / 'assets/images/immersive/redpanda-calm-connected-body-30.png')
    book = Image.open(OUT / 'fixed-book-source.png').convert('RGBA')
    ys, xs = np.where(np.asarray(book)[:, :, 3] > 128)
    book = book.crop((int(xs.min()) - 4, int(ys.min()) - 4,
                      int(xs.max()) + 5, int(ys.max()) + 5))
    book.save(OUT / 'fixed-notebook.png')
    shutil.copy2(OUT / 'fixed-notebook.png', ROOT / 'assets/images/immersive/redpanda-fixed-notebook.png')
    manifest = {'mode': 'built-in image_gen', 'columns': 5, 'rows': 6,
                'cellSize': CELL, 'registrationIn580Canvas': [64, 35, 500, 500],
                'fixedNotebookInCel': [172, 403, 320, 76],
                'frames': entries}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'drawings': len(entries), 'bookSize': book.size,
                      'scales': [round(e['uniformScale'], 4) for e in entries]}))


if __name__ == '__main__':
    main()
