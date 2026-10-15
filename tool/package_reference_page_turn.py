#!/usr/bin/env python3
"""Extract/register whole Image Gen cels; generate shared ink placement data."""
from collections import deque
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from package_reference_writing import forehead_anchor, head_geometry

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/connected-page-turn-12'
CELL = 512


def complete_drawings(sheet):
    mask = np.asarray(sheet)[:, :, 3] > 128
    height, width = mask.shape
    bounds = []
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
            bounds.append((left, top, right + 1, bottom + 1))
    assert len(bounds) == 6, bounds
    bounds.sort(key=lambda r: (int((r[1] + r[3]) / 2 >= height / 2), r[0]))
    for left, top, right, bottom in bounds:
        # The generator varies the gutters. Crop each COMPLETE connected drawing.
        cutout = sheet.crop((left - 8, top - 8, right + 8, bottom + 8))
        scale = min(480 / cutout.width, 470 / cutout.height, 1)
        cutout = cutout.resize((round(cutout.width * scale),
                                round(cutout.height * scale)), Image.Resampling.LANCZOS)
        cel = Image.new('RGBA', (CELL, CELL))
        cel.paste(cutout, (16, 24))
        yield cel


def paper_guide(cel):
    rgba = np.asarray(cel)
    yy, xx = np.indices(rgba.shape[:2])
    mask = ((rgba[:, :, 0] > 210) & (rgba[:, :, 1] > 190)
            & (rgba[:, :, 2] > 155) & (rgba[:, :, 3] > 128)
            & (yy > 410) & (xx >= 225) & (xx <= 280))
    ys, _ = np.where(mask)
    assert len(ys) > 100
    bottom = int(np.max(ys))
    # Three short lines stay in the exposed lower area of the LEFT page.
    return [207, bottom - 21, 80, -4, 9, 15]


def main():
    frames = OUT / 'frames'
    frames.mkdir(exist_ok=True)
    writing = ROOT / 'docs/design/connected-writing-24/frames'
    canonical = Image.open(writing / 'frame-01.png').convert('RGBA')
    anchor = forehead_anchor(canonical)
    base_width, base_height = head_geometry(canonical, anchor)
    atlas = Image.new('RGBA', (2048, 1536))
    scales, guides, provenance = [], [], []
    for batch in (1, 2):
        sheet = Image.open(OUT / f'source-{batch}.png').convert('RGBA')
        assert sheet.size == (1536, 1024)
        for local, cel in enumerate(complete_drawings(sheet)):
            index = (batch - 1) * 6 + local
            source_anchor = forehead_anchor(cel)
            width, height = head_geometry(cel, source_anchor)
            scale = round(((base_width / width) * (base_height / height)) ** .5, 6)
            dx, dy = round(anchor[0] - source_anchor[0]), round(anchor[1] - source_anchor[1])
            packed = Image.new('RGBA', (CELL, CELL))
            packed.paste(cel, (dx, dy))
            assert np.sum(np.asarray(cel)[:, :, 3] > 128) == np.sum(np.asarray(packed)[:, :, 3] > 128), 'Clipped artwork'
            assert .85 <= scale <= 1.2, scale
            packed.save(frames / f'frame-{index + 1:02}.png')
            atlas.paste(packed, (index % 4 * CELL, index // 4 * CELL))
            scales.append(scale)
            guides.append(paper_guide(packed))
            provenance.append({'drawing': index + 1, 'sourceSheet': batch,
                               'sourceCel': local + 1, 'translation': [dx, dy],
                               'displayScale': scale,
                               'pixelSha256': hashlib.sha256(packed.tobytes()).hexdigest()})
    assert len({entry['pixelSha256'] for entry in provenance}) == 12
    atlas.save(OUT / 'page-turn-atlas.png')
    shutil.copy2(OUT / 'page-turn-atlas.png',
                 ROOT / 'assets/images/immersive/redpanda-connected-page-turn-12.png')
    writing_guides = [paper_guide(Image.open(path).convert('RGBA'))
                      for path in sorted(writing.glob('frame-*.png'))]
    manifest = {'mode': 'built-in image_gen', 'drawings': 12, 'fps': 12,
                'writingSeconds': 18, 'pageTurnSeconds': 1.5, 'cycleSeconds': 19.5,
                'anchor': [anchor[0] / CELL, anchor[1] / CELL], 'scales': scales,
                'writingPaperGuides': writing_guides, 'pagePaperGuides': guides,
                'frames': provenance}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
    (OUT / 'registration.js').write_text('const pageRegistration = '+json.dumps(manifest)+';\n')
    dart = ('// Generated by tool/package_reference_page_turn.py.\n'
            '// Whole-cel registration and placement on the exposed paper.\n'
            'abstract final class ReferencePageRegistration {\n'
            '  static const scales = <double>['+', '.join(map(str, scales))+'];\n'
            '  static const writingPaper = <List<double>>[\n'
            + ''.join('    <double>['+', '.join(map(str, guide))+'],\n' for guide in writing_guides)
            + '  ];\n  static const turningPaper = <List<double>>[\n'
            + ''.join('    <double>['+', '.join(map(str, guide))+'],\n' for guide in guides)
            + '  ];\n}\n')
    (ROOT / 'lib/reference_page_registration.dart').write_text(dart)
    with zipfile.ZipFile(OUT / 'page-turn-12-frames.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(OUT / 'manifest.json', 'manifest.json')
        for path in sorted(frames.glob('*.png')):
            archive.write(path, 'frames/'+path.name)
    print(json.dumps({'drawings': 12, 'atlas': list(atlas.size), 'scales': scales,
                      'paperGuides': guides}))


if __name__ == '__main__':
    main()
