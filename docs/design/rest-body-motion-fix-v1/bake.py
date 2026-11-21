#!/usr/bin/env python3
"""The proposed rest action for the fennec and squirrel.

1. Drawings: lift only through drawings that sit where the resting drawing
   sits, and sip without the drawings that move the cup sideways or down.
2. Moving area: paint a drawing only where it acts. The area is measured, not
   hand drawn: the pixels that differ from cel 0 by more than an outline
   wobble, grown by a margin. Everything else stays the resting drawing.
3. Register: a sip drawing whose head sits a pixel or two off the resting
   head is slid back first, so the face it contributes lines up with the head
   that stays."""
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import analyze as A
import measure as M
import scene as S

THRESHOLD = 30  # RGB difference that counts as a changed pixel
OPEN = 9        # a change thinner than this is an outline wobble, not a move
NEAR = 29       # ...unless it lies this close to a move: a mouth, a cup rim
GROW = 15       # margin around a moving part, covers its soft shading
CLOSE = 21      # bridges gaps so a seam never runs through a paw or the cup
FEATHER = 1.5

LIFT = {'fennec': [4, 6, 8, 9, 10], 'squirrel': [4, 6, 7, 9, 10]}
# The same 22 ticks as today, eyes closed for the same 14.
SIP = {
    'fennec': [(3, 2), (27, 2), (17, 2), (16, 10), (17, 2), (27, 2), (3, 2)],
    'squirrel': [(3, 2), (27, 2), (16, 14), (27, 2), (3, 2)],
}
BLINK = [1, 2]
# Things that are one object are painted from one drawing: the fennec's
# glasses (both lenses, bridge and temple) and each of the squirrel's eyes,
# so a rim or an eye is never half one drawing, half another.
WHOLE = {
    'fennec': {'sip': [(232, 170, 392, 238)], 'blink': []},
    'squirrel': {'sip': [(234, 212, 300, 268), (324, 202, 356, 254)], 'blink': [(234, 212, 300, 268), (324, 202, 356, 254)]},
}# From this row of the 384px atlas down, every drawing already is cel 0: the
# closed book and the body behind it.
FLOOR = {'fennec': 264, 'squirrel': 274}


def timeline(friend):
    return S.action(LIFT[friend], SIP[friend])


def used(friend):
    return BLINK + LIFT[friend] + [cel for cel, _ in SIP[friend]]


def offsets(friend, cels):
    """{cel: how far it is slid back}, in stage pixels. A sip drawing
    contributes a face, so it is slid by how far its head sits from cel 0's.
    The top of the lift is slid exactly as the first sip drawing, so the cup
    they hand over does not dip between them."""
    rest = A.on_grey(cels[0]).convert('L')
    out = {}
    for index, _ in SIP[friend]:
        _, dx, dy = M.match(rest, A.on_grey(cels[index]).convert('L'), M.HEAD[friend])
        if dx or dy:
            out[index] = (dx, dy)
    first = SIP[friend][0][0]
    if first in out:
        out[LIFT[friend][-1]] = out[first]
    return out


def slid(cel, dx, dy):
    """cel moved by (-dx, -dy); whole pixels are copied, fractions resampled."""
    if dx == int(dx) and dy == int(dy):
        out = Image.new('RGBA', cel.size, (0, 0, 0, 0))
        out.paste(cel, (-int(dx), -int(dy)))
        return out
    # Premultiplied, so a see-through pixel's colour never bleeds into an edge.
    return cel.convert('RGBa').transform(cel.size, Image.AFFINE, (1, 0, dx, 0, 1, dy), resample=Image.BICUBIC).convert('RGBA')


def registered(friend, cels):
    out = list(cels)
    for index, (dx, dy) in offsets(friend, cels).items():
        out[index] = slid(cels[index], dx, dy)
    return out


def changed(cel, rest):
    """(every changed pixel, the changed pixels that are a real move)."""
    grey = (128, 128, 128)
    diff = ImageChops.difference(A.on_grey(cel, grey), A.on_grey(rest, grey))
    r, g, b = diff.split()
    most = ImageChops.lighter(ImageChops.lighter(r, g), b)
    alpha = ImageChops.difference(cel.getchannel('A'), rest.getchannel('A'))
    hard = ImageChops.lighter(most, alpha).point(lambda v: 255 if v > THRESHOLD else 0)
    return hard, hard.filter(ImageFilter.MinFilter(OPEN)).filter(ImageFilter.MaxFilter(OPEN))


def filled(mask):
    """mask with its enclosed holes painted in."""
    padded = Image.new('L', (mask.width + 2, mask.height + 2), 0)
    padded.paste(mask, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    return padded.point(lambda v: 0 if v == 128 else 255).crop((1, 1, mask.width + 1, mask.height + 1))


def main_parts(mask, least=600):
    """mask without its specks: stray patches far from anything that moves."""
    work, out = mask.copy(), Image.new('L', mask.size, 0)
    while True:
        box = work.point(lambda v: 255 if v == 255 else 0).getbbox()
        if box is None:
            return out
        row = list(work.crop((box[0], box[1], box[2], box[1] + 1)).getdata())
        ImageDraw.floodfill(work, (box[0] + row.index(255), box[1]), 100)
        part = work.point(lambda v: 255 if v == 100 else 0)
        if part.histogram()[255] >= least:
            out = ImageChops.lighter(out, part)
        work = work.point(lambda v: 0 if v == 100 else v)


def moving_area(friend, cels, indexes, whole=()):
    union = Image.new('L', cels[0].size, 0)
    for index in indexes:
        every, moved = changed(cels[index], cels[0])
        beside = ImageChops.darker(every, moved.filter(ImageFilter.MaxFilter(NEAR)))
        union = ImageChops.lighter(union, ImageChops.lighter(moved, beside))
    union = union.filter(ImageFilter.MaxFilter(GROW))
    union = filled(union.filter(ImageFilter.MaxFilter(CLOSE)).filter(ImageFilter.MinFilter(CLOSE)))
    draw = ImageDraw.Draw(union)
    for box in whole:
        draw.rectangle(box, fill=255)
    # Never paint more than the app does today, and never the closed book.
    draw.rectangle((0, -(-FLOOR[friend] * A.STAGE // A.CELL), A.STAGE, A.STAGE), fill=0)
    return main_parts(ImageChops.darker(union, A.mask(friend)))


def masks(friend, cels):
    sip = [cel for cel, _ in SIP[friend]]
    return {
        'lift': moving_area(friend, cels, LIFT[friend]),
        'sip': moving_area(friend, cels, LIFT[friend] + sip, WHOLE[friend]['sip']),
        'blink': moving_area(friend, cels, BLINK, WHOLE[friend]['blink']),
    }


def sealed(friend, drawing, rest, scale=1.0):
    """drawing with the strip where the body sits on the book no more
    see-through than it is in rest (cel 0): a pixel that is takes cel 0's
    opacity and, if it had no colour of its own, the body colour above it.
    scale is the drawing's size relative to the 512px stage."""
    left, top, right, _ = (round(v * scale) for v in M.CONTACT[friend])
    bottom = round(FLOOR[friend] * A.STAGE / A.CELL * scale)
    out = drawing.copy()
    px, solid = out.load(), rest.load()
    for x in range(left, right):
        for y in range(top, bottom):
            alpha = px[x, y][3]
            if alpha < solid[x, y][3] and px[x, y - 1][3] >= 128:
                colour = px[x, y] if alpha >= 128 else px[x, y - 1]
                px[x, y] = colour[:3] + (solid[x, y][3],)
    return out


def stages(friend):
    """{cel: the moving area it is painted through}."""
    return {
        **{cel: 'blink' for cel in BLINK},
        **{cel: 'lift' for cel in LIFT[friend]},
        **{cel: 'sip' for cel, _ in SIP[friend]},
    }


def baked(friend, cels=None):
    """{cel: 512px RGBA} with everything outside the moving area from cel 0."""
    cels = registered(friend, cels or A.cels(friend))
    m = masks(friend, cels)
    soft = {name: mask.filter(ImageFilter.GaussianBlur(FEATHER)) for name, mask in m.items()}
    out = {0: cels[0]}
    for index, name in stages(friend).items():
        out[index] = sealed(friend, Image.composite(cels[index], cels[0], soft[name]), cels[0])
    return out, m


def publish(friend):
    """Writes the baked drawings into their slots of the app's atlas, at the
    atlas's own 384px. The areas are measured on the 512px stage, where they
    were reviewed. Drawings the rest no longer uses are left as drawn."""
    kept = A.BEFORE / f'{friend}-rest.png'
    if not kept.exists():
        A.BEFORE.mkdir(exist_ok=True)
        kept.write_bytes(A.asset(friend).read_bytes())
    native, cels = A.native(friend), A.cels(friend)
    moves = offsets(friend, cels)
    scale = A.CELL / A.STAGE
    soft = {}
    for name, mask in masks(friend, registered(friend, cels)).items():
        soft[name] = mask.filter(ImageFilter.GaussianBlur(FEATHER)).resize((A.CELL, A.CELL), Image.BILINEAR)
        ImageDraw.Draw(soft[name]).rectangle((0, FLOOR[friend], A.CELL, A.CELL), fill=0)
    atlas = Image.open(kept).convert('RGBA')
    rest = native[0]
    for index, name in stages(friend).items():
        dx, dy = moves.get(index, (0, 0))
        cel = slid(native[index], dx * scale, dy * scale)
        area = soft[name]
        # Premultiplied along the feather, so a see-through pixel's colour
        # never tints the seam; to the bit the cel inside and cel 0 outside.
        packed = Image.composite(cel.convert('RGBa'), rest.convert('RGBa'), area).convert('RGBA')
        packed = Image.composite(cel, packed, area.point(lambda v: 255 if v == 255 else 0))
        packed = Image.composite(rest, packed, area.point(lambda v: 255 if v == 0 else 0))
        atlas.paste(sealed(friend, packed, rest, scale), (index % 4 * A.CELL, index // 4 * A.CELL))
    atlas.save(A.asset(friend), optimize=True)


def variants(friend):
    """The three things the proposal compares, as the app would paint them."""
    cels = A.cels(friend)
    today = {i: A.painted(friend, cels, i) for i in set(S.CURRENT[friend]) | {0, 1, 2}}
    reordered = {i: A.painted(friend, cels, i) for i in set(timeline(friend)) | {0, 1, 2}}
    held, _ = baked(friend, cels)
    return {
        'current': {'timeline': S.CURRENT[friend], 'drawings': today},
        'drawings': {'timeline': timeline(friend), 'drawings': reordered},
        'drawings+area': {'timeline': timeline(friend), 'drawings': held},
    }


if __name__ == '__main__':
    for friend in LIFT:
        publish(friend)
        print(friend, 'published', sorted(stages(friend)), 'slid', offsets(friend, A.cels(friend)))
