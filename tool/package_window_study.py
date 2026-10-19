"""Slice, register and pack authored study cels; never paint or warp parts."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw, ImageChops, ImageStat, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/squirrel-fennec-study-v1'
POINTS = {
    'squirrel': {
        'writing': [(160,300),(193,289),(235,298),(263,320),(277,350),(277,383),(196,381),(153,348)],
        'page': [(151,303),(198,291),(258,306),(287,312),(328,320),(360,326),(388,365),(388,397),(123,397),(124,351)],
    },
    'fennec': {
        'writing': [(110,315),(153,302),(176,292),(227,300),(259,328),(271,360),(270,387),(196,391),(112,377),(106,345)],
        'page': [(111,320),(151,309),(177,295),(199,296),(239,322),(299,321),(338,315),(364,334),(389,370),(390,397),(121,397),(108,351)],
    },
}
FIXED = {'squirrel': [(362,320,470,450),(110,270,160,356)],
         'fennec': [(360,340,480,450)]}
FEATURES = {'squirrel': [(215,90,300,170),(185,185,300,275),(50,170,100,270)],
            'fennec': [(130,60,190,160),(325,145,390,185),(170,220,270,280)]}


def opaque(image):
    canvas = Image.new('RGBA', image.size, (128,128,128,255))
    canvas.alpha_composite(image)
    return canvas.convert('RGB')


def register(source, target, friend):
    source = source.resize((512,512), Image.Resampling.LANCZOS)
    reference = opaque(target)
    best = None
    def search(scales, offsets):
        nonlocal best
        for scale in scales:
            size = round(512 * scale)
            scaled = source.resize((size,size), Image.Resampling.LANCZOS)
            for x,y in offsets:
                stage = Image.new('RGBA',(512,512))
                stage.alpha_composite(scaled,(x,y))
                rgb = opaque(stage)
                score = sum(sum(ImageStat.Stat(ImageChops.difference(
                    reference.crop(rect),rgb.crop(rect))).mean) for rect in FEATURES[friend])
                if best is None or score < best[0]:
                    best = score,stage,scale,x,y
    search([.98,.99,1,1.01,1.02],[(x,y) for x in range(-6,7,3) for y in range(-6,7,3)])
    _,_,scale,x,y = best
    search([scale*.9975,scale,scale*1.0025],[(x+dx,y+dy) for dx in range(-2,3) for dy in range(-2,3)])
    score,stage,scale,x,y = best
    return stage,{'scale':scale,'offset':[x,y],'featureDifference':score}


def mask(friend, phase, cel=0):
    result = Image.new('L',(512,512))
    d = ImageDraw.Draw(result)
    d.polygon(POINTS[friend][phase], fill=255)
    if phase == 'page' and 14 <= cel <= 20:
        d.rectangle((245,280,360,380) if friend == 'squirrel' else (214,290,350,380), fill=255)
    for rect in FIXED[friend]:
        d.rectangle(rect, fill=0)
    return result


def slices(path):
    image = Image.open(path).convert('RGBA')
    assert image.width % 3 == 0 and image.height % 2 == 0
    assert image.width // 3 == image.height // 2
    assert image.getchannel('A').getextrema()[0] == 0, f'No transparency: {path}'
    n = image.width // 3
    return [image.crop((i%3*n,i//3*n,(i%3+1)*n,(i//3+1)*n)) for i in range(6)]


def package(friend, publish=False):
    base = Image.open(OUT/'reference'/f'{friend}-canonical.png').convert('RGBA')
    sources = []
    for section in ['writing','page-a','page-b','page-c']:
        sources.extend(slices(OUT/'raw'/f'{friend}-{section}.png'))
    assert len(sources) == 24
    cels = [base]
    report = []
    (OUT/'cels').mkdir(exist_ok=True)
    for i,source in enumerate(sources[1:],1):
        if i == 23:
            cels.append(base.copy())
            report.append({'cel':i,'phase':'page','source':'canonical loop closing pose'})
            continue
        if i == 22:
            source = sources[1]
        phase = 'writing' if i < 6 else 'page'
        registered, registration = register(source,base,friend)
        region = mask(friend,phase,i)
        # A narrow guard preserves the canonical boundary; no artwork blur.
        blend = region.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(.6))
        blend = ImageChops.multiply(blend,region)
        cel = Image.composite(registered,base,blend)
        cels.append(cel)
        source_name = 'writing cel 1 return bridge' if i == 22 else f'authored cel {i}'
        report.append({'cel':i,'phase':phase,'source':source_name,**registration})
    atlas = Image.new('RGBA',(1536,2304))
    for i,cel in enumerate(cels):
        cel.save(OUT/'cels'/f'{friend}-{i:02d}.png')
        atlas.paste(cel.resize((384,384),Image.Resampling.LANCZOS),(i%4*384,i//4*384))
    atlas.save(OUT/f'{friend}-study.png')
    if publish:
        atlas.save(ROOT/f'assets/images/friends/motion/{friend}/study.png')
    background = Image.open(OUT/'reference'/f'{friend}-room-stage.png').convert('RGBA')
    contact = Image.new('RGB',(1536,1080),'#fff5e2')
    draw = ImageDraw.Draw(contact)
    for slot,i in enumerate([0,5,9,15,20,23]):
        preview = background.copy();preview.alpha_composite(cels[i])
        x,y = slot%3*512,slot//3*540
        contact.paste(preview.convert('RGB'),(x,y))
        draw.text((x+10,y+516),f'{friend} cel {i}',fill='#382b26')
    contact.save(OUT/f'{friend}-contact.jpg',quality=95)
    (OUT/f'{friend}-registration.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'{friend}: packed 24 authored study cels')


if __name__ == '__main__':
    for friend in ['squirrel','fennec']:
        package(friend,'--publish' in sys.argv)
