#!/usr/bin/env python3
"""Builds the proposal images and before/after clips for the fennec and
squirrel rest motion. Run from anywhere: python3 make_mockups.py"""
from pathlib import Path
import json
import shutil
import subprocess
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import analyze as A
import bake as B
import measure as M
import scene as S

FONT = A.ROOT / 'assets/fonts/PretendardVariable.ttf'
PAPER, INK, MUTED = (250, 247, 242), (38, 32, 28), (112, 102, 92)
RED, GREEN, LINE = (212, 58, 48), (26, 135, 90), (226, 218, 208)
NAMES = {'fennec': '사막여우', 'squirrel': '다람쥐'}
WIDTH, MARGIN = 1280, 40
CIRCLED = '①②③④⑤⑥'
# The top of the resting eye: where every drawing's eye should sit.
EYE_LINE = {'fennec': 174, 'squirrel': 225}
_fonts = {}


def font(size, weight='Regular'):
    key = (size, weight)
    if key not in _fonts:
        f = ImageFont.truetype(str(FONT), size)
        f.set_variation_by_name(weight)
        _fonts[key] = f
    return _fonts[key]


def wrapped(draw, xy, text, f, width, fill, leading=1.4):
    """Draws text broken at spaces to fit width; returns the y below it."""
    x, y = xy
    line = ''
    for word in text.split(' '):
        trial = f'{line} {word}'.strip()
        if line and draw.textlength(trial, font=f) > width:
            draw.text((x, y), line, font=f, fill=fill)
            y += round(f.size * leading)
            line = word
        else:
            line = trial
    draw.text((x, y), line, font=f, fill=fill)
    return y + round(f.size * leading)


def stage_view(box):
    left, top, size = S.STAGE
    scale = size / 512
    return tuple(round(v) for v in (left + box[0] * scale, top + box[1] * scale, left + box[2] * scale, top + box[3] * scale))


def tile(friend, drawing, size, box):
    return S.render(friend, drawing, view=stage_view(box)).resize((size, size), Image.LANCZOS)


def onion(before, after, size, box):
    """Red: the previous drawing's lines. Cyan: this drawing's. Black: both."""
    white = (255, 255, 255)
    a = A.on_grey(before, white).convert('L').crop(box).resize((size, size), Image.LANCZOS)
    b = A.on_grey(after, white).convert('L').crop(box).resize((size, size), Image.LANCZOS)
    return Image.merge('RGB', (b, a, a))


def badge(draw, xy, text, colour, size=20):
    f = font(size, 'SemiBold')
    width = draw.textlength(text, font=f)
    x, y = xy
    draw.rounded_rectangle((x, y, x + width + 20, y + size + 14), radius=(size + 14) // 2, fill=colour)
    draw.text((x + 10, y + 6), text, font=f, fill=(255, 255, 255))
    return width + 20


def dashes(draw, start, end, colour=(255, 255, 255)):
    (x0, y0), (x1, y1) = start, end
    length = max(abs(x1 - x0), abs(y1 - y0))
    for d in range(0, int(length), 14):
        t0, t1 = d / length, min(1, (d + 7) / length)
        draw.line((x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1), fill=colour, width=2)


def first_drawings(timeline, count):
    seen = []
    for cel in timeline:
        if cel not in seen:
            seen.append(cel)
        if len(seen) == count:
            break
    return seen


# ---------------------------------------------------------------- lift image
def lift_image(friend, variants, measured, out):
    box = {'fennec': (206, 160, 406, 360), 'squirrel': (202, 176, 402, 376)}[friend]
    size, gap = 232, 10
    scale = size / (box[2] - box[0])
    sheet = Image.new('RGB', (WIDTH, 1700), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((MARGIN, 30), f'{NAMES[friend]} · 컵을 들어 올리는 구간', font=font(46, 'Bold'), fill=INK)
    notes = {
        'current': {
            'fennec': '들어 올리는 그림 5장 중 ①③이 다른 그림보다 머리 3px, 몸통 4~5px 높게 그려져 있습니다. 그래서 머리와 몸이 위·아래·위·아래로 튀고, 그때마다 몸 아래에 틈이 열려 뒤 배경이 보입니다.',
            'squirrel': '들어 올리는 그림 5장 중 ③이 다른 그림보다 머리 2~3px, 몸통 4px 높게 그려져 있습니다. 올릴 때와 내릴 때 한 번씩 몸이 튀고, 그때 몸 아래에 틈이 열려 뒤 배경이 보입니다.',
        }[friend],
        'drawings+area': '쉬는 자세와 같은 자리에 그려진 그림 5장으로 바꾸고, 그 그림에서는 팔과 컵만 가져옵니다. 머리·귀·꼬리·몸통은 쉬는 자세 그림 그대로라 움직이지 않습니다.',
    }
    y = 112
    for key, title, colour in [('current', '현재', RED), ('drawings+area', '수정안', GREEN)]:
        variant = variants[key]
        lift = first_drawings(variant['timeline'], 5)
        draw.text((MARGIN, y), title, font=font(36, 'Bold'), fill=colour)
        y = wrapped(draw, (MARGIN, y + 52), notes[key], font(24), WIDTH - MARGIN * 2, INK)
        y += 10
        draw.text((MARGIN, y), '앱 화면 · 점선은 쉬는 자세의 눈 윗선', font=font(21, 'Medium'), fill=MUTED)
        y += 34
        for n, cel in enumerate(lift):
            x = MARGIN + n * (size + gap)
            sheet.paste(tile(friend, variant['drawings'][cel], size, box), (x, y))
            gy = y + (EYE_LINE[friend] - box[1]) * scale
            dashes(draw, (x, gy), (x + size, gy))
            m = measured[key][cel]
            if m['slit_px'] > 200:
                c = M.CONTACT[friend]
                draw.rounded_rectangle((x + (c[0] - box[0]) * scale - 8, y + (c[1] + 10 - box[1]) * scale - 7,
                                        x + (c[2] - box[0]) * scale + 8, y + (c[3] - 2 - box[1]) * scale + 7), radius=9, outline=RED, width=4)
            draw.text((x, y + size + 9), CIRCLED[n], font=font(26, 'Bold'), fill=INK)
            bx = x + 34
            dy = m['head'][1]
            if abs(dy) >= 2:
                bx += badge(draw, (bx, y + size + 8), f'머리 {abs(dy)}px 위', RED) + 6
                if m['slit_px'] > 200:
                    badge(draw, (bx, y + size + 8), '틈', RED)
            else:
                badge(draw, (bx, y + size + 8), '머리 그대로', GREEN if key != 'current' else MUTED)
        y += size + 58
        draw.text((MARGIN, y), '직전 그림과 겹쳐 보기 · 빨강/청록으로 번진 곳이 움직인 곳, 검정은 그대로인 곳', font=font(21, 'Medium'), fill=MUTED)
        y += 34
        previous = variant['drawings'][0]
        for n, cel in enumerate(lift):
            x = MARGIN + n * (size + gap)
            sheet.paste(onion(previous, variant['drawings'][cel], size, box), (x, y))
            draw.rectangle((x, y, x + size - 1, y + size - 1), outline=LINE)
            previous = variant['drawings'][cel]
        y += size + 44
    sheet.crop((0, 0, WIDTH, y)).save(out)


# ----------------------------------------------------------------- sip image
def sip_image(variants, measured, out):
    size, gap = 190, 12
    box = {'fennec': (236, 150, 416, 330), 'squirrel': (222, 196, 402, 376)}
    removed = {
        'fennec': {18: ('빼기', '컵이 5px 내려갔다 다시 올라옴')},
        'squirrel': {17: ('빼기', '컵이 옆으로 10px 튐'), 18: ('빼기', '눈두덩 색이 달라 깜빡임')},
    }
    sheet = Image.new('RGB', (WIDTH, 1700), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((MARGIN, 30), '입에 대고 마시는 구간', font=font(46, 'Bold'), fill=INK)
    y = wrapped(draw, (MARGIN, 100), '컵이 입에 닿은 뒤에는 눈만 감기면 됩니다. 지금은 사이 그림마다 컵 위치가 달라 컵이 출렁입니다. 점선은 머금고 있는 그림의 컵 문양 위치입니다.',
                font(24), WIDTH - MARGIN * 2, INK)
    y += 14
    for friend in ('fennec', 'squirrel'):
        draw.text((MARGIN, y), NAMES[friend], font=font(34, 'Bold'), fill=INK)
        y += 54
        scale = size / (box[friend][2] - box[friend][0])
        for key, title, colour in [('current', '현재', RED), ('drawings+area', '수정안', GREEN)]:
            variant = variants[friend][key]
            timeline = variant['timeline']
            order = [10]
            for cel in timeline[timeline.index(10):]:
                if cel != order[-1]:
                    order.append(cel)
                if cel == 16:
                    break
            draw.text((MARGIN, y), title, font=font(26, 'Bold'), fill=colour)
            y += 40
            cup = measured[friend][key][16]['cup']
            emblem = M.EMBLEM[friend]
            for n, cel in enumerate(order):
                x = MARGIN + n * (size + gap)
                sheet.paste(tile(friend, variant['drawings'][cel], size, box[friend]), (x, y))
                if n >= 1:
                    ex = x + ((emblem[0] + emblem[2]) / 2 + cup[0] - box[friend][0]) * scale
                    ey = y + ((emblem[1] + emblem[3]) / 2 + cup[1] - box[friend][1]) * scale
                    dashes(draw, (x, ey), (x + size, ey))
                    dashes(draw, (ex, y), (ex, y + size))
                note = removed[friend].get(cel) if key == 'current' else None
                if note:
                    draw.rectangle((x, y, x + size - 1, y + size - 1), outline=RED, width=6)
                    draw.text((x, y + size + 8), note[0], font=font(22, 'Bold'), fill=RED)
                    wrapped(draw, (x, y + size + 38), note[1], font(19, 'Medium'), size, RED, 1.3)
                elif cel == 16:
                    draw.text((x, y + size + 8), '머금고 있는 그림', font=font(21, 'SemiBold'), fill=INK)
                elif n == 0:
                    draw.text((x, y + size + 8), '다 든 그림', font=font(21, 'SemiBold'), fill=INK)
            y += size + (96 if key == 'current' else 60)
    sheet.crop((0, 0, WIDTH, y)).save(out)


# ---------------------------------------------------------- moving-area image
def area_image(out):
    size, gap = 290, 13
    box = {'fennec': (96, 36, 426, 366), 'squirrel': (80, 84, 410, 414)}
    sheet = Image.new('RGB', (WIDTH, 1300), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((MARGIN, 30), '그림을 갈아 끼우는 범위', font=font(46, 'Bold'), fill=INK)
    y = wrapped(draw, (MARGIN, 100), '색칠된 곳만 동작 그림으로 바뀌고 나머지는 쉬는 자세 그림 그대로입니다. 지금은 얼굴과 몸 전체가 범위에 들어 있어, 그림마다 1~3px씩 다른 귀·볼털·몸 테두리가 눈을 깜빡일 때마다 같이 떨립니다. 수정안은 실제로 움직이는 곳만 잡습니다.',
                font(24), WIDTH - MARGIN * 2, INK)
    y += 16
    for friend in ('fennec', 'squirrel'):
        cels = A.cels(friend)
        masks = B.masks(friend, cels)
        for n, (title, mask, colour) in enumerate([
            ('현재 · 항상 이 범위', A.mask(friend), RED),
            ('수정안 · 컵 드는 동안', masks['lift'], GREEN),
            ('수정안 · 마시는 동안', masks['sip'], GREEN),
            ('수정안 · 눈 깜빡일 때', masks['blink'], GREEN),
        ]):
            x = MARGIN + n * (size + gap)
            draw.text((x, y), title, font=font(22, 'SemiBold'), fill=colour)
            base = A.on_grey(cels[0], (255, 252, 247))
            tint = Image.composite(Image.new('RGB', base.size, colour), base, mask.point(lambda v: 125 if v else 0))
            sheet.paste(tint.crop(box[friend]).resize((size, size), Image.LANCZOS), (x, y + 38))
            draw.rectangle((x, y + 38, x + size - 1, y + 38 + size - 1), outline=LINE)
        y += 38 + size + 30
    sheet.crop((0, 0, WIDTH, y + 10)).save(out)


# --------------------------------------------------------------- graph image
def graph_image(variants, measured, out):
    plot_w, plot_h, gap = 580, 190, 40
    sheet = Image.new('RGB', (WIDTH, 1200), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((MARGIN, 30), '한 번 마시는 동안의 움직임', font=font(46, 'Bold'), fill=INK)
    draw.text((MARGIN, 96), '들기 → 마시기 → 내리기 약 4.3초를 그림 단위로 잰 값입니다 (쉬는 자세 = 0).', font=font(24), fill=INK)
    x, y = MARGIN, 150
    draw.line((x, y + 14, x + 50, y + 14), fill=RED, width=6)
    draw.text((x + 60, y), '현재', font=font(24, 'SemiBold'), fill=INK)
    draw.line((x + 150, y + 14, x + 200, y + 14), fill=GREEN, width=6)
    draw.text((x + 210, y), '수정안', font=font(24, 'SemiBold'), fill=INK)
    plots = [
        ('머리 높이', lambda m: -m['head'][1], (-1, 5)),
        ('컵 높이', lambda m: -m['cup'][1], (0, 72)),
        ('컵 좌우 위치', lambda m: m['cup'][0], (-2, 32)),
    ]
    top0 = 212
    for column, friend in enumerate(('fennec', 'squirrel')):
        left = MARGIN + column * (plot_w + gap)
        y = top0
        for title, value, (low, high) in plots:
            draw.text((left, y), f'{NAMES[friend]} · {title} (px)', font=font(24, 'SemiBold'), fill=INK)
            top = y + 40

            def py(v, top=top, low=low, high=high):
                return top + plot_h - (v - low) / (high - low) * plot_h

            draw.rectangle((left, top, left + plot_w, top + plot_h), fill=(255, 253, 249), outline=LINE)
            draw.line((left, py(0), left + plot_w, py(0)), fill=LINE, width=2)
            draw.text((left + 8, top + 6), f'{high:+d}', font=font(18), fill=MUTED)
            draw.text((left + 8, py(0) - 24), '0', font=font(18), fill=MUTED)
            for key, colour in [('current', RED), ('drawings+area', GREEN)]:
                timeline = [0] * 4 + variants[friend][key]['timeline'] + [0] * 4
                step = plot_w / len(timeline)
                points = []
                for tick, cel in enumerate(timeline):
                    v = value(measured[friend][key][cel])
                    points += [(left + tick * step, py(v)), (left + (tick + 1) * step, py(v))]
                draw.line(points, fill=colour, width=5 if key == 'current' else 4, joint='curve')
            y += plot_h + 78
    sheet.crop((0, 0, WIDTH, y)).save(out)


# ---------------------------------------------------------------------- clips
def clip(friend, variants, out_stem):
    # A blink, one drink and a blink: seven seconds of a rest.
    def ticks(action):
        return [0] * 8 + [1, 2, 2, 1] + [0] * 8 + action + [0] * 10 + [1, 2, 2, 1] + [0] * 8
    left, right = ticks(variants['current']['timeline']), ticks(variants['drawings+area']['timeline'])
    view = S.VIEW[friend]
    w, h = view[2] - view[0], view[3] - view[1]
    header, gap = 64, 8
    cache = {}

    def frame(key, cel):
        if (key, cel) not in cache:
            cache[key, cel] = S.render(friend, variants[key]['drawings'][cel])
        return cache[key, cel]

    work = Path(tempfile.mkdtemp(prefix='rest-clip-'))
    for tick, (a, b) in enumerate(zip(left, right)):
        canvas = Image.new('RGB', (w * 2 + gap, h + header), PAPER)
        draw = ImageDraw.Draw(canvas)
        draw.text((14, 10), '현재', font=font(36, 'Bold'), fill=RED)
        draw.text((w + gap + 14, 10), '수정안', font=font(36, 'Bold'), fill=GREEN)
        canvas.paste(frame('current', a), (0, header))
        canvas.paste(frame('drawings+area', b), (w + gap, header))
        canvas.save(work / f'{tick:04d}.png')
    quiet = ['ffmpeg', '-loglevel', 'error', '-y']
    subprocess.run(quiet + ['-stream_loop', '2', '-framerate', '12', '-i', str(work / '%04d.png'),
                            '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '16',
                            str(HERE / f'{out_stem}.mp4')], check=True)
    subprocess.run(quiet + ['-framerate', '12', '-i', str(work / '%04d.png'),
                            '-vf', 'scale=800:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=192[p];[b][p]paletteuse=dither=bayer:bayer_scale=4',
                            '-loop', '0', str(HERE / f'{out_stem}.gif')], check=True)
    shutil.rmtree(work)
    return len(left)


def main():
    variants = {friend: B.variants(friend) for friend in NAMES}
    measured = {friend: {key: M.measure(friend, v['drawings']) for key, v in variants[friend].items()} for friend in NAMES}
    (HERE / 'measurements.json').write_text(json.dumps({
        friend: {key: {'timeline': variants[friend][key]['timeline'], 'drawings': measured[friend][key]} for key in variants[friend]}
        for friend in NAMES}, indent=1))
    lift_image('fennec', variants['fennec'], measured['fennec'], HERE / '01-fennec-lift.png')
    lift_image('squirrel', variants['squirrel'], measured['squirrel'], HERE / '02-squirrel-lift.png')
    sip_image(variants, measured, HERE / '03-sip.png')
    area_image(HERE / '04-moving-area.png')
    graph_image(variants, measured, HERE / '05-motion-graph.png')
    for friend in NAMES:
        print(friend, 'clip', clip(friend, variants[friend], f'{friend}-before-after'), 'ticks')


if __name__ == '__main__':
    main()
