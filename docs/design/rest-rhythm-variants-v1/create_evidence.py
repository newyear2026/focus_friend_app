"""Build deterministic evidence from fresh app capture; never changes app assets."""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
CAPTURE = ROOT / 'capture'
BASELINE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/tmp/deskmate-motion-37cf920-baseline')
FRIENDS = ['penguin', 'otter', 'squirrel', 'fennec']
manifest = json.loads((CAPTURE / 'manifest.json').read_text())
baseline = json.loads((BASELINE / 'manifest.json').read_text())
by_key = {(m['friend'], m['mode']): m for m in manifest}
base_key = {(m['friend'], m['mode']): m for m in baseline}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def longest_hold(cells):
    longest = run = 0
    previous = None
    for cel in cells + cells:
        run = run + 1 if cel == previous else 1
        longest = max(longest, run)
        previous = cel
    return longest

report = {'baselineCommit': '37cf920', 'fps': 12, 'unchanged': [], 'restRhythms': []}
for key, actual in by_key.items():
    friend, mode = key
    if mode != 'study' and friend != 'redpanda':
        continue
    stem = f'{friend}-{mode}'
    old = base_key[key]
    assert old['frames'] == actual['frames'], stem
    mismatches = []
    baseline_hashes, actual_hashes = [], []
    for tick in range(actual['frames']):
        name = f'{tick:04d}.png'
        a, b = CAPTURE / 'frames' / stem / name, BASELINE / 'frames' / stem / name
        ah, bh = digest(a), digest(b)
        actual_hashes.append(ah)
        baseline_hashes.append(bh)
        if ah != bh:
            mismatches.append(tick)
    report['unchanged'].append({'clip': stem, 'frames': actual['frames'], 'changedFrames': mismatches, 'comparison': 'exact PNG SHA-256 for each frame', 'baselineSequenceSha256': hashlib.sha256(''.join(baseline_hashes).encode()).hexdigest(), 'actualSequenceSha256': hashlib.sha256(''.join(actual_hashes).encode()).hexdigest()})
    assert not mismatches, (stem, mismatches)

font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 21)
small = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 17)
bold = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 27)
image = Image.new('RGB', (1800, 850), '#f7f4ed')
draw = ImageDraw.Draw(image)
draw.text((50, 30), 'REST RHYTHM / 60 SECONDS / 12 FPS', fill='#272b30', font=bold)
draw.text((50, 77), 'Same authored cup action. Deterministic rest and blink variants only.', fill='#555b62', font=font)
colors = {'idle': '#c9ccc8', 'action': '#c38b43', 'blink': '#4c8c97'}
x0, plot_width = 235, 1500
for i, (label, color) in enumerate(colors.items()):
    x = 570 + i * 230
    draw.rounded_rectangle((x, 121, x + 24, 145), 4, fill=color)
    draw.text((x + 34, 121), label.title(), fill='#373d42', font=small)
for j in range(13):
    x = x0 + plot_width * j / 12
    draw.line((x, 178, x, 739), fill='#dedfd9', width=1)
    draw.text((x - 8, 153), str(j * 5), fill='#555b62', font=small)
for row, friend in enumerate(FRIENDS):
    m = by_key[friend, 'rest']
    cells = [s['from'] for s in m['samples']]
    idle = 3 if friend == 'penguin' else 0
    y = 203 + row * 133
    draw.text((50, y + 5), friend.title(), fill='#272b30', font=bold)
    variants = m['variants']
    lengths = [v['ticks'] for v in variants]
    draw.text((50, y + 44), f'Supercycle {len(cells)/12:.2f}s', fill='#555b62', font=small)
    draw.text((50, y + 67), f'Max hold {longest_hold(cells)}/60 ticks', fill='#555b62', font=small)
    for tick in range(720):
        sample = m['samples'][tick % len(cells)]
        cel = sample['from']
        label = 'action' if sample['action'] else 'idle'
        if label == 'idle' and cel != idle:
            label = 'blink'
        left = x0 + plot_width * tick / 720
        right = x0 + plot_width * (tick + 1) / 720
        draw.rectangle((left, y + 6, right + .3, y + 52), fill=colors[label])
    boundaries = []
    cycle_at = 0
    while cycle_at < 720:
        at = cycle_at
        for i, n in enumerate(lengths):
            if at >= 720:
                break
            boundaries.append(at)
            x = x0 + plot_width * at / 720
            draw.line((x, y - 10, x, y + 58), fill='#444c52', width=2)
            draw.text((x + 4, y + 67), f'V{i+1}', fill='#555b62', font=small)
            at += n
        cycle_at += len(cells)
    action_len = variants[0]['actionEndTick'] - variants[0]['actionStartTick']
    action_cells = cells[variants[0]['actionStartTick']:variants[0]['actionEndTick']]
    cursor = 0
    for v in variants:
        actual_action = cells[cursor+v['actionStartTick']:cursor+v['actionEndTick']]
        assert actual_action == action_cells, friend
        cursor += v['ticks']
    cursor = 0
    blink_counts = []
    for v in variants:
        rests = cells[cursor:cursor+v['actionStartTick']] + cells[cursor+v['actionEndTick']:cursor+v['ticks']]
        blink_counts.append(sum(cel != idle for cel in rests) // (4 if friend in ['squirrel', 'fennec'] else 2))
        cursor += v['ticks']
    oldcells = [s['from'] for s in base_key[friend, 'rest']['samples']]
    # The exact unchanged authored block must also occur in baseline capture.
    old_start = next(t for t in range(len(oldcells)-action_len+1) if oldcells[t:t+action_len] == action_cells)
    action_changed = []
    cursor = 0
    for i, v in enumerate(variants):
        for tick in range(action_len):
            a = CAPTURE / 'frames' / f'{friend}-rest' / f'{cursor+v["actionStartTick"]+tick:04d}.png'
            b = BASELINE / 'frames' / f'{friend}-rest' / f'{old_start+tick:04d}.png'
            if digest(a) != digest(b):
                action_changed.append({'variant': i, 'tick': tick})
        cursor += v['ticks']
    assert not action_changed, (friend, action_changed)
    assert longest_hold(cells) <= 60, friend
    report['restRhythms'].append({'friend': friend, 'variantTicks': lengths, 'variantSeconds': [n / 12 for n in lengths], 'supercycleTicks': len(cells), 'supercycleSeconds': len(cells) / 12, 'actionTicks': action_len, 'actionMatchesBaseline': True, 'blinkCounts': blink_counts, 'actionCaptureChangedFrames': action_changed, 'longestCyclicHoldTicks': longest_hold(cells), 'frameCount': m['frames']})
draw.text((50, 779), 'Penguin exception approved: 7-7.7s variants preserve the <=5s hold limit without blink artwork.', fill='#555b62', font=small)
image.save(ROOT / '60-second-rhythm.png')
(ROOT / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
