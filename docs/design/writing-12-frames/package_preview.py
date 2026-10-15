"""Package Image Gen artwork; only crop grid cells and encode a GIF preview."""

import hashlib
import json
import shutil
import zipfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = Path('/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-358835bd-b475-4bdd-9bfc-eeec6c6a1a59.png')
shutil.copy2(SOURCE, ROOT / 'writing-contact-sheet.png')
sheet = Image.open(SOURCE).convert('RGB')
assert sheet.width % 4 == 0 and sheet.height % 3 == 0
width, height = sheet.width // 4, sheet.height // 3
frame_dir = ROOT / 'frames'
frame_dir.mkdir(exist_ok=True)
frames = []
frame_records = []
for index in range(12):
    col, row = index % 4, index // 4
    box = (col * width, row * height, (col + 1) * width, (row + 1) * height)
    frame = sheet.crop(box)
    path = frame_dir / f'frame-{index + 1:02d}.png'
    frame.save(path)
    frames.append(frame)
    frame_records.append({'index': index + 1, 'file': str(path.relative_to(ROOT)), 'crop': box, 'sha256': hashlib.sha256(frame.tobytes()).hexdigest()})
assert len({f['sha256'] for f in frame_records}) == 12

# A shared palette avoids per-frame color palette flicker. GIF units are 10 ms.
palette = sheet.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
gif_frames = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
durations = [80, 90, 80] * 4  # 12 frames total exactly 1000 ms.
gif_frames[0].save(ROOT / 'writing-loop-12fps.gif', save_all=True,
                   append_images=gif_frames[1:], duration=durations,
                   loop=0, optimize=False, disposal=2)
gif = Image.open(ROOT / 'writing-loop-12fps.gif')
assert gif.n_frames == 12
actual_durations = []
for i in range(gif.n_frames):
    gif.seek(i)
    actual_durations.append(gif.info['duration'])
assert sum(actual_durations) == 1000
manifest = {'source': str(SOURCE), 'sheet_size': sheet.size, 'grid': [4, 3],
            'frame_size': [width, height], 'frame_count': 12, 'fps': 12,
            'gif_durations_ms': actual_durations,
            'artwork_method': 'Built-in Image Gen. Equal-cell extraction only; no redraw, morphing, interpolation or warping in packaging.',
            'frames': frame_records}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
with zipfile.ZipFile(ROOT / 'writing-12-frames.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for record in frame_records:
        bundle.write(ROOT / record['file'], record['file'])
    bundle.write(ROOT / 'manifest.json', 'manifest.json')
print(json.dumps({'frames': len(frames), 'size': [width, height], 'unique_frames': 12,
                  'gif_frames': gif.n_frames, 'loop_ms': sum(actual_durations)}, ensure_ascii=False))
