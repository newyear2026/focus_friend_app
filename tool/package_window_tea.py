#!/usr/bin/env python3
"""Register whole authored cels and pack them; do not repaint or split limbs."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/design/fennec-squirrel-window-tea-v1'
DEST = ROOT / 'assets/images/friends/motion'
TRANSFORMS = {'fennec': (1.08, 45, 35), 'squirrel': (1.02, 24, 66)}


def head_anchor(cel, friend):
    # Only head/ears/hat; exclude the tail, book and held cup.
    edge = 65 if friend == 'fennec' else 140
    mask = cel.getchannel('A').point(lambda alpha: 255 if alpha > 220 else 0)
    left, top, right, _ = mask.crop((edge, 0, cel.width, 160)).getbbox()
    return float(left + edge), float(right - 1 + edge), float(top)


def main():
    for friend, (base_scale, base_x, base_y) in TRANSFORMS.items():
        raw = Image.open(SOURCE / f'{friend}-rest-raw.png').convert('RGBA')
        cell = raw.width // 4
        assert raw.size == (cell * 4, cell * 3)
        cels = [raw.crop((i % 4 * cell, i // 4 * cell,
                         (i % 4 + 1) * cell, (i // 4 + 1) * cell)) for i in range(12)]
        left, right, top = head_anchor(cels[0], friend)
        target_width = (right - left) * base_scale
        target_right = right * base_scale + base_x
        target_top = top * base_scale + base_y
        atlas = Image.new('RGBA', (1536, 1152))
        contact = Image.new('RGB', (512 * 3, 540 * 2), '#fff4df')
        draw = ImageDraw.Draw(contact)
        registrations = []
        for i, cel in enumerate(cels):
            left, right, top = head_anchor(cel, friend)
            scale = target_width / (right - left)
            x, y = round(target_right - right * scale), round(target_top - top * scale)
            stage = Image.new('RGBA', (512, 512))
            side = round(cell * scale)
            stage.alpha_composite(cel.resize((side, side), Image.Resampling.LANCZOS), (x, y))
            atlas.alpha_composite(stage.resize((384, 384), Image.Resampling.LANCZOS),
                                  (i % 4 * 384, i // 4 * 384))
            registrations.append({'cel': i, 'scale': scale, 'x': x, 'y': y})
            if i in [0, 1, 3, 5, 6, 7]:
                slot = [0, 1, 3, 5, 6, 7].index(i)
                contact.paste(stage, (slot % 3 * 512, slot // 3 * 540), stage)
                draw.text((slot % 3 * 512 + 12, slot // 3 * 540 + 516),
                          f'{friend} cel {i}', fill='#352724')
            if i in [0, 7]:
                stage.save(SOURCE / f'{friend}-cel-{i}.png')
        target = DEST / friend
        target.mkdir(parents=True, exist_ok=True)
        atlas.save(target / 'rest.png')
        contact.save(SOURCE / f'{friend}-registered.jpg', quality=92)
        (SOURCE / f'{friend}-registration.json').write_text(
            json.dumps({'method': 'uniform whole-cel head registration',
                        'stage': [512, 512], 'runtimeCel': [384, 384],
                        'transforms': registrations}, indent=2) + '\n')


if __name__ == '__main__':
    main()
