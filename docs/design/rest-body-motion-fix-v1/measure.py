#!/usr/bin/env python3
"""Per-drawing measurements used by the proposal: where the head, the parts
that should hold still and the cup sit compared with the resting drawing
(cel 0), and how much room shows through between the body and the book.
All in the 512px stage the app paints."""
from pathlib import Path
import json
import sys
from PIL import ImageChops, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parent))
import analyze as A

# Patches of cel 0 that the cup and paws never cover.
HEAD = {'fennec': (250, 142, 340, 182), 'squirrel': (250, 198, 350, 214)}
# Parts that have no reason to move while the friend drinks or blinks.
STILL = {
    'fennec': {'left ear edge': (136, 140, 196, 200), 'cheek fluff': (150, 196, 214, 240)},
    'squirrel': {'head edge': (356, 222, 392, 262)},
}
# The cup's printed emblem in cel 0.
EMBLEM = {'fennec': (288, 294, 322, 332), 'squirrel': (286, 306, 320, 352)}
# The strip where the body meets the closed book, under the middle of the body.
CONTACT = {'fennec': (215, 326, 345, 348), 'squirrel': (215, 344, 345, 364)}


def match(reference, target, box, xs=range(-7, 8), ys=range(-7, 8)):
    patch = reference.crop(box)
    best = None
    for dy in ys:
        for dx in xs:
            score = ImageStat.Stat(ImageChops.difference(
                patch, target.crop((box[0] + dx, box[1] + dy, box[2] + dx, box[3] + dy)))).mean[0]
            if best is None or score < best[0]:
                best = (score, dx, dy)
    return best


def measure(friend, drawings):
    """drawings: {cel: 512px RGBA as painted}, including cel 0."""
    rest = A.on_grey(drawings[0]).convert('L')
    out = {}
    for index, drawing in drawings.items():
        grey = A.on_grey(drawing).convert('L')
        head = match(rest, grey, HEAD[friend])
        still = {name: match(rest, grey, box) for name, box in STILL[friend].items()}
        cup = match(rest, grey, EMBLEM[friend], range(-16, 40), range(-80, 8))
        slit = sum(1 for v in drawing.getchannel('A').crop(CONTACT[friend]).getdata() if v < 128)
        out[index] = {
            'head': (head[1], head[2]),
            'still': {name: (m[1], m[2]) for name, m in still.items()},
            'cup': (cup[1], cup[2]),
            'slit_px': slit,
        }
    return out


if __name__ == '__main__':
    import bake as B
    report = {}
    for friend in ('fennec', 'squirrel'):
        report[friend] = {}
        for name, variant in B.variants(friend).items():
            m = measure(friend, variant['drawings'])
            report[friend][name] = {'timeline': variant['timeline'], 'drawings': m}
            print(friend, name)
            seen = []
            for cel in [1, 2] + variant['timeline']:
                if cel in seen:
                    continue
                seen.append(cel)
                d = m[cel]
                print(f"  cel {cel:2d} head {d['head']} still {d['still']} cup {d['cup']} slit {d['slit_px']}")
    (Path(__file__).resolve().parent / 'measurements.json').write_text(json.dumps(report, indent=1))
