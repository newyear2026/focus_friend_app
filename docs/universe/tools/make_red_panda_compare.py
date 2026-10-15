"""랫서팬더 픽셀·2D 비교판을 만든다.

원본은 읽기만 하고, 결과는 docs/universe/refs/ 에 쓴다.
실행: python3 docs/universe/tools/make_red_panda_compare.py (focus_friend_app 루트에서)
"""

import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

DEV = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parents[1] / "refs" / "red-panda-pixel-vs-2d.png"
FONT = DEV / "focus_friend_app/assets/fonts/PretendardVariable.ttf"

ROUTINE = "routine_app/flutter_app/assets/characters/redpanda_teashop/v1/approved"
FOCUS = "focus_friend_app/assets/images"

# (행 제목, [(라벨, 경로, 자르기 영역 또는 None, 픽셀 여부)])
ROWS = [
    ("픽셀 · LOOPET 찻집", [
        ("대기 idle", f"{ROUTINE}/idle.png", None, True),
        ("집중 focus", f"{ROUTINE}/focus.png", None, True),
        ("휴식 rest", f"{ROUTINE}/rest.png", None, True),
    ]),
    ("2D · 작은 집중방", [
        ("필기 시트 0번", f"{FOCUS}/redpanda-study-sheet.png", (0, 0, 443, 443), False),
        ("현재 홈 기준", f"{FOCUS}/immersive/redpanda-reference.png", None, False),
        ("휴식 차 시트 0번", f"{FOCUS}/rest/redpanda-tea-sheet.png", (0, 0, 362, 362), False),
    ]),
]

TILE = 320
PAD = 24
HEAD = 44
LABEL = 54
BG = (250, 245, 236)
CARD = (255, 252, 246)
INK = (58, 40, 30)
SUB = (130, 110, 95)


def font(size, weight=500):
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([weight])
    except OSError:
        pass
    return f


def tile(path, crop, pixel):
    im = Image.open(DEV / path).convert("RGBA")
    if crop:
        im = im.crop(crop)
    box = im.getbbox()
    if box:
        im = im.crop(box)
    scale = (TILE - 32) / max(im.size)
    size = (round(im.width * scale), round(im.height * scale))
    im = im.resize(size, Image.NEAREST if pixel else Image.LANCZOS)
    card = Image.new("RGBA", (TILE, TILE), CARD + (255,))
    card.alpha_composite(im, ((TILE - size[0]) // 2, (TILE - size[1]) // 2))
    return card


def main():
    cols = max(len(items) for _, items in ROWS)
    width = PAD + cols * (TILE + PAD)
    row_h = HEAD + TILE + LABEL
    height = PAD + len(ROWS) * row_h + PAD
    sheet = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(sheet)
    title, label, small = font(24, 700), font(18, 600), font(13, 400)

    y = PAD
    for row_title, items in ROWS:
        draw.text((PAD, y + 6), row_title, font=title, fill=INK)
        ty = y + HEAD
        for i, (name, path, crop, pixel) in enumerate(items):
            x = PAD + i * (TILE + PAD)
            sheet.alpha_composite(tile(path, crop, pixel), (x, ty))
            draw.text((x, ty + TILE + 6), name, font=label, fill=INK)
            draw.text((x, ty + TILE + 30), path.split("/")[-1], font=small, fill=SUB)
        y += row_h

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(OUT, optimize=True)
    print(f"wrote {OUT.relative_to(DEV)}")
    for _, items in ROWS:
        for _, path, _, _ in items:
            digest = hashlib.sha256((DEV / path).read_bytes()).hexdigest()
            print(f"{digest}  {path}")


if __name__ == "__main__":
    main()
