"""Package fresh current-app captures and measure same-pose writing progress."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import subprocess
from PIL import Image, ImageChops, ImageDraw

OUT = Path(__file__).resolve().parent
CAP = OUT / 'capture'
records = json.loads((CAP / 'manifest.json').read_text())
report = {'sourceCommit': '3fa176e', 'captureDate': '2026-10-24',
          'frames': sum(r['frames'] for r in records), 'modes': [], 'writing': {}}


def encode(entry):
    stem = entry['friend'] + '-' + entry['mode']
    path = CAP / (stem + '.mp4')
    subprocess.run(['/opt/homebrew/bin/ffmpeg', '-v', 'error', '-y', '-framerate', '12',
                    '-i', str(CAP / 'frames' / stem / '%04d.png'), '-an', '-c:v', 'libx264',
                    '-threads', '2', '-crf', '18', '-preset', 'fast', '-pix_fmt', 'yuv420p',
                    '-movflags', '+faststart', str(path)], check=True)
    meta = json.loads(subprocess.check_output(['/opt/homebrew/bin/ffprobe', '-v', 'error',
                      '-show_entries', 'stream=nb_frames,avg_frame_rate',
                      '-show_entries', 'format=duration', '-of', 'json', str(path)]))
    assert int(meta['streams'][0]['nb_frames']) == entry['frames']
    assert meta['streams'][0]['avg_frame_rate'] == '12/1'
    assert abs(float(meta['format']['duration']) - entry['clipSeconds']) < .001
    return {'clip': stem, 'frames': entry['frames'], 'seconds': entry['clipSeconds'],
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


with ThreadPoolExecutor(max_workers=2) as pool:
    report['modes'] = list(pool.map(encode, records))

ink = Image.new('RGB', (700, 432), '#fff8eb')
draw = ImageDraw.Draw(ink)
for friend in ['redpanda', 'penguin', 'otter', 'squirrel', 'fennec']:
    frames = CAP / 'frames' / (friend + '-study')
    before, after = [Image.open(frames / f'{tick:04d}.png').convert('RGB')
                     for tick in [42, 426]]
    difference = ImageChops.difference(before, after)
    changed = sum(1 for pixel in difference.getdata() if max(pixel) > 0)
    report['writing'][friend] = {'beforeSeconds': 3.5, 'afterSeconds': 35.5,
                                'sameWritingCel': 1, 'changedPixels': changed,
                                'fullSceneIdentical': difference.getbbox() is None}
    if friend in ['redpanda', 'squirrel', 'fennec']:
        row = ['redpanda', 'squirrel', 'fennec'].index(friend)
        for col, image in enumerate([before, after]):
            crop = image.crop((60, 285, 410, 400))
            ink.paste(crop, (col * 350, row * 144))
            draw.text((col * 350 + 8, row * 144 + 120),
                      f'{friend}: {3.5 if col == 0 else 35.5}s', fill='#382b26')
ink.save(OUT / 'writing-progress-comparison.jpg', quality=96)

penguin = next(r for r in records if r['friend'] == 'penguin' and r['mode'] == 'rest')
ids = [next(s['frame'] for s in penguin['samples'] if s['from'] == cel)
       for cel in [3, 4, 5, 6]]
sheet = Image.new('RGB', (980, 260), '#fff8eb')
d = ImageDraw.Draw(sheet)
for slot, frame in enumerate(ids):
    image = Image.open(CAP / 'frames/penguin-rest' / f'{frame:04d}.png').convert('RGB')
    sheet.paste(image.resize((245, 231), Image.Resampling.LANCZOS), (slot * 245, 0))
    d.text((slot * 245 + 8, 239), f'penguin cel {[3,4,5,6][slot]} / {frame/12:.3f}s', fill='#382b26')
sheet.save(OUT / 'penguin-lift.jpg', quality=96)
report['penguinRestDistinctCels'] = sorted({s['from'] for s in penguin['samples']})
(OUT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
