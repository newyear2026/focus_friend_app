"""Package generated page-turn drawings and connect the existing writing sequence."""

import hashlib
import json
import shutil
import subprocess
import zipfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
WRITING = ROOT.parent / 'writing-12-frames'
SOURCE = Path('/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-6bd494fd-8c00-4409-9827-29234a06b716.png')
shutil.copy2(SOURCE, ROOT / 'page-turn-generated-source.png')
original = Image.open(SOURCE).convert('RGB')
# Normalize the generator's one-pixel size deviation to the existing 4x3 grid.
sheet = original.resize((1448, 1086), Image.Resampling.LANCZOS)
sheet.save(ROOT / 'page-turn-contact-sheet.png')
frame_dir = ROOT / 'frames'
writing_dir = ROOT / 'writing-frames'
frame_dir.mkdir(exist_ok=True)
writing_dir.mkdir(exist_ok=True)
frames, writing_frames, records = [], [], []
for i in range(12):
    col, row = i % 4, i // 4
    box = (col * 362, row * 362, (col + 1) * 362, (row + 1) * 362)
    frame = sheet.crop(box)
    path = frame_dir / f'frame-{i + 1:02d}.png'
    frame.save(path)
    frames.append(frame)
    source_writing = WRITING / 'frames' / path.name
    shutil.copy2(source_writing, writing_dir / path.name)
    writing_frames.append(Image.open(source_writing).convert('RGB'))
    records.append({'index': i + 1, 'file': str(path.relative_to(ROOT)), 'crop': box,
                    'sha256': hashlib.sha256(frame.tobytes()).hexdigest()})
assert len({r['sha256'] for r in records}) == 12

# Share a palette across both actions. This is media packaging, not artwork edits.
palette_source = Image.new('RGB', (1448, 2172))
palette_source.paste(sheet, (0, 0))
palette_source.paste(Image.open(WRITING / 'writing-contact-sheet.png'), (0, 1086))
palette = palette_source.quantize(colors=256, method=Image.Quantize.MEDIANCUT)

def save_gif(images, name):
    duration = [10 * (round((i + 1) * 100 / 12) - round(i * 100 / 12)) for i in range(len(images))]
    encoded = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in images]
    encoded[0].save(ROOT / name, save_all=True, append_images=encoded[1:],
                    duration=duration, loop=0, optimize=False, disposal=2)
    out = Image.open(ROOT / name)
    actual_ms = 0
    for i in range(out.n_frames):
        out.seek(i)
        actual_ms += out.info['duration']
    assert actual_ms == sum(duration)
    return {'encoded_frames': out.n_frames, 'duration_ms': actual_ms}

page_gif = save_gif(frames, 'page-turn-loop-12fps.gif')
assert page_gif['encoded_frames'] == 12
assert page_gif['duration_ms'] == 1000

# 4 writing loops, a brief pencil pause, a single turn, and a brief settling hold.
timeline = []
for _ in range(4):
    timeline.extend({'action': 'writing', 'index': i, 'label': '필기하기'} for i in range(12))
timeline.extend({'action': 'writing', 'index': 11, 'label': '잠깐 멈춤'} for _ in range(4))
timeline.extend({'action': 'page', 'index': i, 'label': '페이지 넘기기'} for i in range(12))
timeline.extend({'action': 'page', 'index': 11, 'label': '다시 필기 준비'} for _ in range(4))
combined = [(writing_frames if item['action'] == 'writing' else frames)[item['index']] for item in timeline]
combined_gif = save_gif(combined, 'writing-and-page-turn.gif')

# Encode two cycles without interpolation; every video frame is an existing cel.
video = subprocess.Popen([
    'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-f', 'rawvideo',
    '-pixel_format', 'rgb24', '-video_size', '362x362', '-framerate', '12', '-i', '-',
    '-an', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
    str(ROOT / 'writing-and-page-turn.mp4')], stdin=subprocess.PIPE)
for im in combined * 2:
    video.stdin.write(im.tobytes())
video.stdin.close()
assert video.wait() == 0

manifest = {
    'source': str(SOURCE), 'source_size': list(original.size),
    'normalized_sheet_size': [1448, 1086], 'grid': [4, 3], 'frame_size': [362, 362],
    'new_page_frames': 12, 'existing_writing_frames': 12, 'fps': 12,
    'page_gif': page_gif, 'combined_gif': combined_gif,
    'combined_ticks': len(timeline), 'combined_seconds': len(timeline) / 12,
    'timeline': timeline, 'frames': records,
    'artwork_method': 'Built-in Image Gen; packaging only normalizes the sheet by one pixel, crops equal cells, copies existing writing PNGs, and encodes GIF/MP4. No interpolation, warping, crossfades or procedural redraws.'
}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
with zipfile.ZipFile(ROOT / 'page-turn-12-frames.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for record in records:
        bundle.write(ROOT / record['file'], record['file'])
    bundle.write(ROOT / 'manifest.json', 'manifest.json')
with zipfile.ZipFile(ROOT / 'writing-and-page-turn-assets.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for directory in [frame_dir, writing_dir]:
        for path in sorted(directory.glob('*.png')):
            bundle.write(path, str(path.relative_to(ROOT)))
    for name in ['index.html', 'README.md', 'manifest.json', 'page-turn-contact-sheet.png',
                 'page-turn-loop-12fps.gif', 'writing-and-page-turn.gif', 'writing-and-page-turn.mp4']:
        path = ROOT / name
        if path.exists():
            bundle.write(path, name)
print(json.dumps({'new_page_frames': 12, 'frame_size': [362, 362], 'page_gif': page_gif,
                  'combined_gif': combined_gif, 'combined_ticks': len(timeline)}, ensure_ascii=False))
