"""Slice Image Gen thinking cels and package them with the existing study actions."""

import hashlib
import json
import shutil
import subprocess
import zipfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = Path('/Users/jaewook/.codex/generated_images/01a118d2-1fb9-7060-a354-23505d975c23/exec-7971abc7-2c0c-456e-9aaf-93bf4f630eed.png')
WRITING = ROOT.parent / 'writing-12-frames'
PAGE = ROOT.parent / 'page-turn-12-frames'
shutil.copy2(SOURCE, ROOT / 'thinking-generated-source.png')
original = Image.open(SOURCE).convert('RGB')
sheet = original if original.size == (1448, 1086) else original.resize((1448, 1086), Image.Resampling.LANCZOS)
sheet.save(ROOT / 'thinking-contact-sheet.png')
directories = {'thinking': ROOT / 'frames', 'writing': ROOT / 'writing-frames', 'page': ROOT / 'page-frames'}
for directory in directories.values():
    directory.mkdir(exist_ok=True)
frames = {kind: [] for kind in directories}
records = []
for i in range(12):
    name = f'frame-{i + 1:02d}.png'
    col, row = i % 4, i // 4
    box = (col * 362, row * 362, (col + 1) * 362, (row + 1) * 362)
    frame = sheet.crop(box)
    path = directories['thinking'] / name
    frame.save(path)
    frames['thinking'].append(frame)
    records.append({'index': i + 1, 'file': str(path.relative_to(ROOT)), 'crop': box,
                    'sha256': hashlib.sha256(frame.tobytes()).hexdigest()})
    for kind, source_dir in [('writing', WRITING), ('page', PAGE)]:
        source_file = source_dir / 'frames' / name
        shutil.copy2(source_file, directories[kind] / name)
        assert source_file.read_bytes() == (directories[kind] / name).read_bytes()
        frames[kind].append(Image.open(source_file).convert('RGB'))
assert len({r['sha256'] for r in records}) == 12

palette_source = Image.new('RGB', (1448, 3258))
for row, image in enumerate([sheet, Image.open(WRITING / 'writing-contact-sheet.png'), Image.open(PAGE / 'page-turn-contact-sheet.png')]):
    palette_source.paste(image, (0, row * 1086))
palette = palette_source.quantize(colors=256, method=Image.Quantize.MEDIANCUT)

labels = {'thinking': '생각하기', 'writing': '필기하기', 'page': '페이지 넘기기'}
def sequence(kind, hold_thinking=False):
    result = []
    for i in range(12):
        count = 7 if hold_thinking and i in [5, 6] else 1
        result.extend({'kind': kind, 'index': i, 'label': labels[kind]} for _ in range(count))
    return result

thinking = sequence('thinking', hold_thinking=True)
writing_thinking = sequence('writing') * 3 + thinking
routine = writing_thinking + sequence('writing') * 3 + sequence('page')
routine += [{'kind': 'page', 'index': 11, 'label': '다시 필기 준비'} for _ in range(4)]
assert len(thinking) == 24 and len(writing_thinking) == 60 and len(routine) == 112
timelines = {'thinking': thinking, 'writing_thinking': writing_thinking, 'routine': routine,
             'writing': sequence('writing'), 'page': sequence('page')}

def images_for(timeline):
    return [frames[item['kind']][item['index']] for item in timeline]

def save_gif(timeline, name):
    images = images_for(timeline)
    durations = [10 * (round((i + 1) * 100 / 12) - round(i * 100 / 12)) for i in range(len(images))]
    encoded = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in images]
    encoded[0].save(ROOT / name, save_all=True, append_images=encoded[1:],
                    duration=durations, loop=0, optimize=False, disposal=2)
    gif = Image.open(ROOT / name)
    actual_ms = 0
    for i in range(gif.n_frames):
        gif.seek(i)
        actual_ms += gif.info['duration']
    assert actual_ms == sum(durations)
    return {'encoded_frames': gif.n_frames, 'duration_ms': actual_ms}

gifs = {
    'thinking': save_gif(thinking, 'thinking-loop.gif'),
    'writing_thinking': save_gif(writing_thinking, 'writing-and-thinking.gif'),
    'routine': save_gif(routine, 'study-routine.gif')
}
assert gifs['thinking']['encoded_frames'] == 12 and gifs['thinking']['duration_ms'] == 2000

video = subprocess.Popen([
    'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error', '-f', 'rawvideo',
    '-pixel_format', 'rgb24', '-video_size', '362x362', '-framerate', '12', '-i', '-',
    '-an', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
    str(ROOT / 'study-routine.mp4')], stdin=subprocess.PIPE)
for im in images_for(routine) * 2:
    video.stdin.write(im.tobytes())
video.stdin.close()
assert video.wait() == 0

manifest = {
    'source': str(SOURCE), 'source_size': list(original.size), 'sheet_size': [1448, 1086],
    'grid': [4, 3], 'frame_size': [362, 362], 'new_thinking_frames': 12,
    'existing_writing_frames': 12, 'existing_page_frames': 12, 'fps': 12,
    'thinking_hold_frames': [6, 7], 'thinking_ticks': 24, 'writing_thinking_ticks': 60,
    'routine_ticks': 112, 'gifs': gifs, 'frames': records, 'timelines': timelines,
    'artwork_method': 'Built-in Image Gen; code only normalizes the grid when necessary, crops equal cells, copies existing PNGs unchanged, holds drawn cels, and encodes GIF/MP4. No procedural redraw, warping, crossfades, or synthesized in-betweens.'
}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

# Embed timing data in a classic script so the preview also works from local files.
(ROOT / 'timeline.js').write_text('window.studyTimelines = ' + json.dumps(timelines, ensure_ascii=False) + ';\n')
with zipfile.ZipFile(ROOT / 'thinking-12-frames.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for record in records:
        bundle.write(ROOT / record['file'], record['file'])
    bundle.write(ROOT / 'manifest.json', 'manifest.json')
with zipfile.ZipFile(ROOT / 'study-motion-assets.zip', 'w', zipfile.ZIP_DEFLATED) as bundle:
    for directory in directories.values():
        for path in sorted(directory.glob('*.png')):
            bundle.write(path, str(path.relative_to(ROOT)))
    for name in ['index.html', 'README.md', 'manifest.json', 'timeline.js', 'thinking-contact-sheet.png',
                 'thinking-loop.gif', 'writing-and-thinking.gif', 'study-routine.gif', 'study-routine.mp4']:
        if (ROOT / name).exists():
            bundle.write(ROOT / name, name)
print(json.dumps({'new_thinking_frames': 12, 'copied_existing_frames': 24, 'gifs': gifs,
                  'routine_ticks': 112, 'video_frames': 224}, ensure_ascii=False))
