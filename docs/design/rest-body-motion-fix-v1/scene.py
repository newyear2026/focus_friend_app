#!/usr/bin/env python3
"""The app's rest scene for the fennec and squirrel, reproduced with Pillow so
proposed timelines and masks can be previewed without rebuilding the app.

Mirrors lib/friend_motion_scene.dart: the room plate, the actor on its 704px
stage (cel 0 outside the moving region, the timeline cel inside it), the
evening light modulate, then the room's left book stack over the actor."""
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import analyze as A

ROOT = A.ROOT
STAGE = (100, 570, 704)  # left, top, size in the 853x1844 scene
EVENING = ((0xE6, 0xCB, 0xD3), (0xFF, 0xE9, 0xCA))
BOOKS = {
    'squirrel': [(0, 1021), (165, 1013), (270, 1019), (282, 1024), (283, 1066), (296, 1068), (293, 1098), (315, 1114), (318, 1150), (330, 1164), (330, 1198), (0, 1210)],
    'fennec': [(0, 1058), (25, 1056), (110, 1051), (200, 1053), (289, 1060), (294, 1064), (295, 1095), (318, 1098), (320, 1132), (334, 1136), (335, 1172), (330, 1200), (0, 1210)],
}
# What the previews show: the friend and the desk in front of it.
VIEW = {'fennec': (150, 600, 720, 1170), 'squirrel': (120, 640, 690, 1210)}

_rooms, _lights, _books = {}, {}, {}


def room(friend):
    if friend not in _rooms:
        _rooms[friend] = Image.open(ROOT / f'assets/images/friends/motion/{friend}/rooms/evening.png').convert('RGB')
    return _rooms[friend]


def _light():
    if 'evening' not in _lights:
        size = STAGE[2]
        ramp = Image.new('RGB', (size, 1))
        for x in range(size):
            t = x / (size - 1)
            ramp.putpixel((x, 0), tuple(round(a + (b - a) * t) for a, b in zip(*EVENING)))
        _lights['evening'] = ramp.resize((size, size))
    return _lights['evening']


def _book_mask(friend):
    if friend not in _books:
        mask = Image.new('L', room(friend).size, 0)
        ImageDraw.Draw(mask).polygon(BOOKS[friend], fill=255)
        _books[friend] = mask
    return _books[friend]


def render(friend, actor, view=None):
    """actor: the 512px RGBA drawing the app would paint on the stage."""
    left, top, size = STAGE
    plate = room(friend).copy()
    scaled = actor.resize((size, size), Image.BICUBIC)
    lit = ImageChops.multiply(scaled.convert('RGB'), _light())
    plate.paste(lit, (left, top), scaled.getchannel('A'))
    plate.paste(room(friend), (0, 0), _book_mask(friend))
    return plate.crop(view or VIEW[friend])


def to_view(friend, x, y, view=None):
    """512px stage coordinates to preview pixels."""
    v = view or VIEW[friend]
    scale = STAGE[2] / 512
    return (STAGE[0] + x * scale - v[0], STAGE[1] + y * scale - v[1])


def exposures(holds):
    return [cel for cel, ticks in holds for _ in range(ticks)]


def action(lift, sip):
    up = list(zip(lift, (4, 4, 2, 2, 3)))
    return exposures(up + sip + list(reversed(up)))


CURRENT_SIP = [(3, 2), (27, 2), (17, 2), (18, 2), (16, 6), (18, 2), (17, 2), (27, 2), (3, 2)]
CURRENT = {
    'fennec': action([20, 6, 23, 9, 10], CURRENT_SIP),
    'squirrel': action([4, 5, 22, 8, 10], CURRENT_SIP),
}
