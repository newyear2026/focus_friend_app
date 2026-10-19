"""Encode fresh merged-app frames and verify deterministic rest integration."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from PIL import Image, ImageChops

OUT = Path(__file__).resolve().parent
CAPTURE = OUT / 'capture'
ORIGINAL = Path(sys.argv[1])
SIP = Path(sys.argv[2])
FFMPEG = '/opt/homebrew/bin/ffmpeg'
FFPROBE = '/opt/homebrew/bin/ffprobe'
manifest = json.loads((CAPTURE / 'manifest.json').read_text())
original = json.loads((ORIGINAL / 'manifest.json').read_text())
sip = json.loads((SIP / 'manifest.json').read_text())


def pose(sample):
    return (sample['phase'], sample.get('cel', sample.get('from')),
            sample.get('to'), sample.get('blend'), sample.get('ink'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def frame(folder, stem, tick):
    return folder / 'frames' / stem / f'{tick:04d}.png'


def longest_hold(cels):
    run = longest = 0
    previous = None
    for cel in cels + cels:
        run = run + 1 if cel == previous else 1
        longest = max(longest, run)
        previous = cel
    return longest


report = {'source': 'fresh merged FocusFriendApp capture', 'frames': 0,
          'videos': [], 'matchingPoses': [], 'rest': {}}
for entry in manifest:
    friend, mode = entry['friend'], entry['mode']
    stem = f'{friend}-{mode}'
    report['frames'] += entry['frames']
    if not entry['static']:
        target = CAPTURE / f'{stem}.mp4'
        subprocess.run([
            FFMPEG, '-y', '-v', 'error', '-framerate', str(entry['fps']),
            '-i', str(CAPTURE / 'frames' / stem / '%04d.png'), '-an',
            '-c:v', 'libx264', '-threads', '2', '-preset', 'fast', '-crf', '18',
            '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(target),
        ], check=True)
        metadata = json.loads(subprocess.check_output([
            FFPROBE, '-v', 'error', '-select_streams', 'v:0',
            '-show_entries', 'stream=width,height,nb_frames,avg_frame_rate',
            '-show_entries', 'format=duration', '-of', 'json', str(target),
        ]))
        stream = metadata['streams'][0]
        assert int(stream['nb_frames']) == entry['frames']
        assert stream['avg_frame_rate'] == '12/1'
        assert abs(float(metadata['format']['duration']) - entry['clipSeconds']) < .001
        report['videos'].append({'clip': stem, **metadata})

    source = SIP if friend in ('fennec', 'squirrel') and mode == 'rest' else ORIGINAL
    source_manifest = sip if source == SIP else original
    old = next(e for e in source_manifest if (e['friend'], e['mode']) == (friend, mode))
    expected = {pose(s): frame(source, stem, s['frame']) for s in old['samples']}
    verified, excluded = 0, 0
    for sample in entry['samples']:
        reference = expected.get(pose(sample))
        if reference is None:
            excluded += 1
            continue
        assert digest(frame(CAPTURE, stem, sample['frame'])) == digest(reference), (stem, sample)
        verified += 1
    # Full panda writing contains ink timings absent from the old excerpt.
    # Every rest, penguin/otter study cel and static study must match exactly.
    if friend != 'redpanda' or mode == 'rest':
        assert excluded == 0, (stem, excluded)
    report['matchingPoses'].append({'clip': stem, 'exactPngMatches': verified,
                                  'notInEarlierExcerpt': excluded,
                                  'reference': 'sip-inbetweens' if source == SIP else '37cf920'})
    if mode != 'rest':
        continue
    cels = [s.get('cel', s.get('from')) for s in entry['samples']]
    maximum = longest_hold(cels)
    if friend != 'redpanda':
        assert maximum <= 60
    transitions = []
    for i in range(len(cels)):
        j = (i + 1) % len(cels)
        if cels[i] == cels[j]:
            continue
        a = Image.open(frame(CAPTURE, stem, i)).convert('RGB')
        b = Image.open(frame(CAPTURE, stem, j)).convert('RGB')
        r, g, b = ImageChops.difference(a, b).split()
        hist = ImageChops.lighter(ImageChops.lighter(r, g), b).histogram()
        transitions.append({'from': cels[i], 'to': cels[j],
                            'changedAny': sum(hist[1:]), 'maxRgbGt15': sum(hist[16:])})
    report['rest'][friend] = {
        'supercycleTicks': len(cels), 'supercycleSeconds': entry['clipSeconds'],
        'variantTicks': [v['ticks'] for v in entry.get('variants', [])],
        'longestCyclicHoldTicks': maximum,
        'maximumChangedAny': max(t['changedAny'] for t in transitions),
        'maximumRgbGt15': max(t['maxRgbGt15'] for t in transitions),
    }
for friend in ('fennec', 'squirrel'):
    assert report['rest'][friend]['variantTicks'] == [216, 228, 240]
    assert report['rest'][friend]['maximumChangedAny'] <= report['rest']['redpanda']['maximumChangedAny']
    assert report['rest'][friend]['maximumRgbGt15'] <= report['rest']['redpanda']['maximumRgbGt15']
(OUT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
