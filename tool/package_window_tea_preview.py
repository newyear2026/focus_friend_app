#!/usr/bin/env python3
"""Encode Flutter-rendered frames at their original visual-clock speed."""
from pathlib import Path
import subprocess, json
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/fennec-squirrel-window-tea-v1'
FFMPEG = '/opt/homebrew/bin/ffmpeg'
manifest = []
for friend in ['fennec', 'squirrel']:
    frames = OUT / 'frames' / friend
    assert len(list(frames.glob('*.png'))) == 264
    subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y',
        '-framerate', '12', '-i', str(frames / '%04d.png'), '-c:v', 'libx264',
        '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
        str(OUT / f'{friend}-window-tea.mp4')], check=True)
    manifest.append({'friend': friend, 'frames': 264, 'fps': 12,
        'durationSeconds': 22, 'source': 'production Flutter painters',
        'file': f'{friend}-window-tea.mp4', 'speedMultiplier': 1})
    subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y',
        '-i', str(OUT / f'{friend}-window-tea.mp4'),
        '-vf', 'fps=1/2,scale=245:231,tile=6x2', '-frames:v', '1',
        str(OUT / f'{friend}-video-contact.jpg')], check=True)
(OUT / 'preview-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest))
