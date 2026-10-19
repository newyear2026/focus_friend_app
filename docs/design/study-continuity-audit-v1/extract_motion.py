"""Inspect the app clips served by the current V10 gallery, without editing art."""
from pathlib import Path
import json
import subprocess
from PIL import Image, ImageChops, ImageStat, ImageDraw

OUT = Path(__file__).resolve().parent
SOURCE = OUT.parent / 'all-character-motions-v10/capture'
records = json.loads((SOURCE / 'manifest.json').read_text())
report = {}
roi = (95, 240, 390, 405)


def sheet(friend, name, frames, ids):
    width, height = roi[2] - roi[0], roi[3] - roi[1]
    result = Image.new('RGB', (width * 6, (height + 30) * ((len(ids) + 5) // 6)), '#fff8eb')
    draw = ImageDraw.Draw(result)
    for i, frame in enumerate(ids):
        x, y = i % 6 * width, i // 6 * (height + 30)
        result.paste(frames[frame].crop(roi), (x, y))
        draw.text((x + 8, y + height + 7), f'{friend} {frame / 12:.3f}s / {frame}', fill='#382b26')
    result.save(OUT / f'{friend}-{name}.jpg', quality=96)


for friend in ['redpanda', 'squirrel', 'fennec']:
    entry = next(e for e in records if e['friend'] == friend and e['mode'] == 'study')
    clip = SOURCE / f'{friend}-study.mp4'
    pipe = subprocess.Popen(['/opt/homebrew/bin/ffmpeg', '-v', 'error', '-i', str(clip),
                             '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
    frames = []
    for _ in range(entry['frames']):
        data = pipe.stdout.read(490 * 462 * 3)
        assert len(data) == 490 * 462 * 3
        frames.append(Image.frombytes('RGB', (490, 462), data))
    assert pipe.wait() == 0
    changes = []
    last = None
    for sample in entry['samples']:
        frame = sample['frame']
        cel = sample.get('cel', sample.get('from'))
        if cel != last:
            before = frames[frame - 1] if frame else frames[-1]
            difference = ImageChops.difference(before.crop(roi), frames[frame].crop(roi))
            changes.append({'frame': frame, 'seconds': frame / 12, 'from': last, 'to': cel,
                            'phase': sample['phase'], 'roiMeanAbsoluteRgbDifference':
                            sum(ImageStat.Stat(difference).mean) / 3})
        last = cel
    writing = [c['frame'] for c in changes if c['frame'] < 24]
    turn = [c['frame'] for c in changes if c['frame'] >= 426]
    sheet(friend, 'writing', frames, writing)
    sheet(friend, 'page', frames, turn)
    # Isolate phase entry, late return and wrapped writing. The source images
    # remain full app crops, with no recoloring, interpolation or drawn motion.
    boundary = [426, 432, 433, 436, entry['frames'] - 8, entry['frames'] - 5,
                entry['frames'] - 1, 0, 6]
    sheet(friend, 'boundaries', frames, boundary)
    report[friend] = {'source': str(clip.relative_to(OUT.parent.parent.parent)),
                      'frames': entry['frames'], 'transitions': changes,
                      'largestPageChanges': sorted([c for c in changes if c['phase'] == 'pageTurn'],
                              key=lambda c: c['roiMeanAbsoluteRgbDifference'], reverse=True)[:7]}
(OUT / 'frame-inspection.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({f: r['largestPageChanges'] for f, r in report.items()}, indent=2))
