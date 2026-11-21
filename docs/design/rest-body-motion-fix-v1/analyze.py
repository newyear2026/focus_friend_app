#!/usr/bin/env python3
"""Renders the fennec and squirrel rest cels the way the app paints them
(cel 0 outside windowTeaRegion, the timeline cel inside) and measures how far
each part of the body moves between consecutive drawings."""
from pathlib import Path
import json
from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent / 'analysis'
BEFORE = Path(__file__).resolve().parent / 'before'
STAGE = 512
CELL = 384
REGION = {
    'squirrel': [(232, 198), (231, 215), (223, 223), (214, 225), (213, 245), (207, 247), (207, 268), (210, 275), (206, 277), (206, 308), (196, 314), (192, 325), (186, 329), (187, 512), (512, 512), (512, 198), (285, 200), (284, 195), (252, 193)],
    'fennec': [(133, 138), (133, 223), (175, 227), (188, 237), (188, 321), (183, 336), (183, 512), (512, 512), (512, 142), (368, 142), (355, 150), (293, 148), (288, 142), (260, 141), (256, 137), (197, 135), (196, 132)],
}
LIFT = {'fennec': [20, 6, 23, 9, 10], 'squirrel': [4, 5, 22, 8, 10]}


def action(friend):
    lift = LIFT[friend]
    return [lift[0], lift[1], lift[2], lift[3], lift[4], 3, 27, 17, 18, 16]


def asset(friend):
    return ROOT / f'assets/images/friends/motion/{friend}/rest.png'


def source(friend):
    """The atlas as drawn: the copy kept before bake.py published over it."""
    kept = BEFORE / f'{friend}-rest.png'
    return kept if kept.exists() else asset(friend)


def native(friend, path=None):
    """The 28 cels at the atlas's own 384px."""
    atlas = Image.open(path or source(friend)).convert('RGBA')
    return [atlas.crop((i % 4 * CELL, i // 4 * CELL, i % 4 * CELL + CELL, i // 4 * CELL + CELL)) for i in range(28)]


def cels(friend, path=None):
    """The 28 cels enlarged to the 512px stage the app paints them on."""
    return [cel.resize((STAGE, STAGE), Image.LANCZOS) for cel in native(friend, path)]


def mask(friend):
    m = Image.new('L', (STAGE, STAGE), 0)
    ImageDraw.Draw(m).polygon(REGION[friend], fill=255)
    return m


def painted(friend, all_cels, index):
    if index == 0:
        return all_cels[0]
    return Image.composite(all_cels[index], all_cels[0], mask(friend))


def on_grey(image, grey=(236, 226, 214)):
    base = Image.new('RGB', image.size, grey)
    base.paste(image, (0, 0), image)
    return base


def diff_mask(a, b, threshold=24):
    d = ImageChops.difference(on_grey(a), on_grey(b)).convert('L')
    return d.point(lambda v: 255 if v > threshold else 0)


def bbox_of_dark(image, box):
    """Bounding box of line art (dark, opaque) inside box."""
    crop = image.crop(box)
    dark = on_grey(crop).convert('L').point(lambda v: 255 if v < 70 else 0)
    alpha = crop.getchannel('A').point(lambda v: 255 if v > 128 else 0)
    b = ImageChops.multiply(dark, alpha).getbbox()
    return None if b is None else (b[0] + box[0], b[1] + box[1], b[2] + box[0], b[3] + box[1])


def silhouette_bbox(image):
    return image.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()


def main():
    OUT.mkdir(exist_ok=True)
    report = {}
    for friend in REGION:
        all_cels = cels(friend)
        order = [0, 1, 2] + action(friend)
        frames = {i: painted(friend, all_cels, i) for i in order}
        # Contact sheet of what the app paints, in timeline order.
        cols = 5
        seq = [0] + action(friend)
        rows = (len(seq) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * STAGE, rows * (STAGE + 36)), (250, 246, 240))
        draw = ImageDraw.Draw(sheet)
        for n, index in enumerate(seq):
            x, y = n % cols * STAGE, n // cols * (STAGE + 36)
            sheet.paste(on_grey(frames[index]), (x, y + 36))
            draw.text((x + 10, y + 10), f'cel {index}', fill=(40, 30, 20))
        sheet.save(OUT / f'{friend}-painted-sequence.png')
        # Consecutive change maps: red where the drawing changed.
        steps = []
        change_sheet = Image.new('RGB', (cols * STAGE, rows * (STAGE + 36)), (250, 246, 240))
        cdraw = ImageDraw.Draw(change_sheet)
        for n in range(1, len(seq)):
            a, b = frames[seq[n - 1]], frames[seq[n]]
            m = diff_mask(a, b)
            changed = sum(1 for v in m.getdata() if v)
            base = on_grey(b).convert('L').convert('RGB')
            red = Image.new('RGB', base.size, (230, 40, 40))
            overlay = Image.composite(red, base, m)
            x, y = n % cols * STAGE, n // cols * (STAGE + 36)
            change_sheet.paste(overlay, (x, y + 36))
            cdraw.text((x + 10, y + 10), f'{seq[n - 1]} -> {seq[n]}: {changed}px', fill=(40, 30, 20))
            steps.append({
                'from': seq[n - 1], 'to': seq[n], 'changed': changed,
                'bbox': m.getbbox(),
                'silhouette_from': silhouette_bbox(a), 'silhouette_to': silhouette_bbox(b),
            })
        change_sheet.save(OUT / f'{friend}-change-maps.png')
        # Raw (unmasked) cels, to see what each drawing does outside the region.
        raw_sheet = Image.new('RGB', (cols * STAGE, rows * (STAGE + 36)), (250, 246, 240))
        rdraw = ImageDraw.Draw(raw_sheet)
        raw = []
        for n, index in enumerate(seq):
            x, y = n % cols * STAGE, n // cols * (STAGE + 36)
            raw_sheet.paste(on_grey(all_cels[index]), (x, y + 36))
            m = diff_mask(all_cels[0], all_cels[index])
            rdraw.text((x + 10, y + 10), f'raw cel {index}', fill=(40, 30, 20))
            raw.append({'cel': index, 'silhouette': silhouette_bbox(all_cels[index]), 'diff_bbox_vs_0': m.getbbox()})
        raw_sheet.save(OUT / f'{friend}-raw-sequence.png')
        report[friend] = {'steps': steps, 'raw': raw}
    (OUT / 'report.json').write_text(json.dumps(report, indent=1))
    for friend, data in report.items():
        print(friend)
        for s in data['steps']:
            print('  ', s)
        for r in data['raw']:
            print('  raw', r)


if __name__ == '__main__':
    main()
