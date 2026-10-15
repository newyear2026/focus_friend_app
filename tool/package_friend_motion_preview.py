#!/usr/bin/env python3
"""Encode actual Flutter-rendered frames without altering timing or artwork."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/penguin-otter-motion-v1'
FFMPEG = '/opt/homebrew/bin/ffmpeg'
videos = []
for animal in ['penguin', 'otter']:
    for action in ['study', 'rest']:
        frames = OUT / 'frames' / f'{animal}-{action}'
        expected = 162 if action == 'study' else 168
        assert len(list(frames.glob('*.png'))) == expected, frames
        subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y',
                        '-framerate', '12', '-i', str(frames / '%04d.png'),
                        '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2',
                        '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p',
                        '-movflags', '+faststart', str(OUT / f'{animal}-{action}.mp4')], check=True)
        subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y',
                        '-framerate', '12', '-i', str(frames / '%04d.png'),
                        '-filter_complex', '[0:v]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a',
                        '-loop', '0', str(OUT / f'{animal}-{action}.gif')], check=True)
        videos.append({'friend': animal, 'action': action, 'frames': expected, 'fps': 12, 'seconds': expected / 12, 'source': 'production Flutter painter'})
(OUT / 'preview-manifest.json').write_text(json.dumps(videos, indent=2) + '\n')
print(json.dumps(videos))
