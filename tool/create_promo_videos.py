#!/usr/bin/env python3
"""Rebuild three Korean social videos from the app's own artwork and renders.

Requires Python/Pillow, ffmpeg and ffprobe. Run capture_promo_footage_test.dart
first. No installed app, production database, network or third-party music is used.
"""
from __future__ import annotations

import argparse
from array import array
from functools import lru_cache
import json
import math
from pathlib import Path
import subprocess
import wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'deliverables/promo_videos'
TMP = Path('/private/tmp/focus-promo-2026-10-14')
W, H, FPS = 1080, 1920, 30
CREAM = '#fff7e6'
INK = '#30293c'
AMBER = '#ffca7b'
MUTED = '#cebece'
FONT = ROOT / 'assets/fonts/PretendardVariable.ttf'


def clamp(x):
    return max(0.0, min(1.0, x))


def ease(x):
    return 1 - (1 - clamp(x)) ** 3


@lru_cache(maxsize=100)
def font(size, weight=700):
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([weight])
    return f


@lru_cache(maxsize=100)
def asset(path):
    return Image.open(ROOT / path).convert('RGBA')


def fit(im, size, center=(.5, .5)):
    return ImageOps.fit(im, tuple(map(int, size)), Image.Resampling.LANCZOS,
                        centering=center)


def paste(im, layer, xy, opacity=1):
    if opacity < .999:
        layer = layer.copy()
        layer.putalpha(layer.getchannel('A').point(lambda x: round(x * opacity)))
    im.alpha_composite(layer, tuple(map(round, xy)))


@lru_cache(maxsize=256)
def text_image(text, size, color=CREAM, weight=750, spacing=10, align='left'):
    f = font(size, weight)
    bbox = ImageDraw.Draw(Image.new('RGBA', (1, 1))).multiline_textbbox(
        (0, 0), text, font=f, spacing=spacing, align=align)
    im = Image.new('RGBA', (math.ceil(bbox[2]) + 8, math.ceil(bbox[3]-bbox[1]) + 8))
    ImageDraw.Draw(im).multiline_text((2, 2-bbox[1]), text, font=f, fill=color,
                                     spacing=spacing, align=align,
                                     stroke_width=0)
    return im


def text(im, value, x, y, size, color=CREAM, weight=750, t=3, center=False,
         spacing=15):
    block = text_image(value, size, color, weight, spacing,
                       'center' if center else 'left')
    if center:
        x -= block.width / 2
    paste(im, block, (x, y + 30 * (1-ease(t/.65))), ease(t/.5))


def pill(im, value, center, y, size=32, light=False, alpha=1):
    block = text_image(value, size, INK if light else CREAM, 650)
    layer = Image.new('RGBA', (block.width+60, block.height+36))
    ImageDraw.Draw(layer).rounded_rectangle((0,0,layer.width-1,layer.height-1),
        radius=layer.height/2, fill=AMBER if light else '#4c4059',
        outline=None if light else '#75627e', width=1)
    paste(layer,block,(30,18))
    paste(im,layer,(center-layer.width/2,y),alpha)


@lru_cache(maxsize=12)
def background(kind):
    if kind in ('warm', 'light'):
        top = (255, 247, 230) if kind == 'light' else (250, 234, 210)
        bottom = (247, 226, 195) if kind == 'light' else (231, 202, 174)
        im = Image.new('RGBA', (W,H))
        d = ImageDraw.Draw(im)
        for y in range(H):
            a = y/H
            color = tuple(round(top[c]*(1-a)+bottom[c]*a) for c in range(3))
            d.line((0,y,W,y),fill=color)
        glow = Image.new('RGBA', (W,H))
        gd = ImageDraw.Draw(glow)
        gd.ellipse((-180,550,1150,1880),fill=(255,255,240,115))
        im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(130)))
    else:
        name = 'room-night' if kind == 'night' else 'room-evening'
        im = fit(asset(f'assets/images/immersive/{name}.png'),(W,H)).filter(
            ImageFilter.GaussianBlur(22))
        shade = Image.new('RGBA',(W,H))
        sd = ImageDraw.Draw(shade)
        for y in range(H):
            # Smooth dark-to-clear-to-dark vignette, without a visible band.
            a = round(150 + 52 * math.exp(-((y/680)**2)) + 39*(y/H)**3)
            sd.line((0,y,W,y),fill=(31,24,44,a))
        im.alpha_composite(shade)
    return im


def sparkles(im, t, light=False):
    d = ImageDraw.Draw(im)
    for i,(x,y) in enumerate([(930,570),(130,1340),(900,1550),(165,650)]):
        y += math.sin(t*.6+i*1.8)*14
        r = 8 + math.sin(t*.8+i)*2
        color = '#cb9261' if light else '#eac28b'
        d.line((x-r,y,x+r,y),fill=color,width=2)
        d.line((x,y-r,x,y+r),fill=color,width=2)


def brand(im, label, light=False, t=0):
    color=INK if light else CREAM
    text(im,'작은 집중방',88,116,32,color,800)
    block=text_image(label,26,'#8d7262' if light else MUTED,550)
    paste(im,block,(W-96-block.width,121))
    # A quiet editorial rule; all copy sits inside the vertical social safe area.
    ImageDraw.Draw(im).line((88,181,992,181),fill='#ceb79f' if light else '#66536d',width=1)


@lru_cache(maxsize=48)
def rounded_mask(size, radius):
    mask=Image.new('L',size)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,size[0]-1,size[1]-1),radius=radius,fill=255)
    return mask


@lru_cache(maxsize=20)
def shadow(size, radius):
    layer=Image.new('RGBA',(size[0]+100,size[1]+100))
    ImageDraw.Draw(layer).rounded_rectangle((50,50,size[0]+50,size[1]+50),
        radius=radius,fill=(5,2,13,140))
    return layer.filter(ImageFilter.GaussianBlur(25))


def framed(im, src, x, y, width, height=None, radius=40, border=True):
    width=int(width)
    height=int(height or width*src.height/src.width)
    src=fit(src,(width,height))
    src.putalpha(rounded_mask((width,height),radius))
    paste(im,shadow((width,height),radius),(x-50,y-25))
    paste(im,src,(x,y))
    if border:
        layer=Image.new('RGBA',(width,height))
        ImageDraw.Draw(layer).rounded_rectangle((1,1,width-2,height-2),radius=radius,
                                               outline=(255,243,224,140),width=2)
        paste(im,layer,(x,y))


@lru_cache(maxsize=240)
def footage(kind, index):
    count=192 if kind=='focus' else 120
    return Image.open(TMP/kind/f'frame-{index % count:03}.png').convert('RGBA')


def clip(kind,t):
    return footage(kind,int(t*12))


@lru_cache(maxsize=96)
def companion(index):
    # Original 12 fps footage comes from the exact Flutter companion painter.
    return Image.open(TMP/'companion'/f'frame-{index%72:03}.png').convert('RGBA')


def phone(im,source,t,width=532,y=548,x=None):
    enter=ease(t/.75)
    x=(W-width)/2 if x is None else x
    framed(im,source,x,y+70*(1-enter)+math.sin(t*.9)*5,width,radius=42)


def line_tag(im,value,y,light=False):
    text(im,value,540,y,32,'#7d6757' if light else MUTED,550,center=True)


def end_card(t,light=False,subtitle='혼자보다 포근한, 나의 집중 시간',
             cta='오늘, 같이 시작해요'):
    im=background('light' if light else 'night').copy()
    brand(im,'FOCUS FRIEND',light)
    sparkles(im,t,light)
    portrait=asset('assets/images/companion-portrait.png')
    s=round(560*(.92+.08*ease(t/.9)))
    portrait=ImageOps.contain(portrait,(s,s),Image.Resampling.LANCZOS)
    paste(im,portrait,((W-portrait.width)/2,410+math.sin(t*.8)*6),ease(t/.5))
    text(im,'작은 집중방',540,1060,112,INK if light else CREAM,850,t=t-.1,center=True)
    text(im,subtitle,540,1240,40,'#7d6757' if light else MUTED,550,t=t-.25,center=True)
    layer=Image.new('RGBA',(800,124))
    ImageDraw.Draw(layer).rounded_rectangle((0,0,799,123),radius=62,fill=AMBER)
    text(layer,cta+'  →',400,39,43,INK,800,center=True)
    paste(im,layer,(140,1435+24*(1-ease((t-.35)/.6))),ease((t-.35)/.5))
    line_tag(im,'나의 속도로, 차곡차곡.',1640,light)
    return im


def emotion(scene,t):
    if scene==3:
        return end_card(t)
    light=scene==1
    im=background('light' if light else 'evening').copy()
    brand(im,'함께하는 집중',light)
    if scene==0:
        text(im,'미루고 있던 일,\n같이 시작할까요?',88,265,86,t=t)
        phone(im,clip('focus',t),t,width=526,y=560)
        pill(im,'오늘은, 딱 25분만.',540,1750,30,True,ease((t-.35)/.6))
    elif scene==1:
        text(im,'당신의 옆자리엔\n작은 친구가 있어요.',88,270,80,INK,t=t)
        sparkles(im,t,True)
        src=companion(int(t*12))
        size=880
        # The card matches the source's warm paper so the drawing stays intact.
        framed(im,src,100,650+25*(1-ease(t/.7)),size,size,radius=70,border=False)
        line_tag(im,'사각사각, 함께 써 내려가는 시간.',1640,True)
    else:
        text(im,'딱 25분.\n시작은 작아도 괜찮아요.',88,270,75,t=t)
        phone(im,clip('focus',t+5),t,width=526,y=555)
        pill(im,'나의 속도로, 한 번 더.',540,1750,30,False)
    return im


def rewards(im,t):
    names=[('plant','화분','첫 집중 완료'),('mug','머그컵','누적 60분'),('lamp','조명','누적 120분')]
    for i,(key,name,rule) in enumerate(names):
        x=88+i*310
        y=750+65*(1-ease((t-i*.16)/.6))+math.sin(t*.9+i)*5
        layer=Image.new('RGBA',(284,550))
        d=ImageDraw.Draw(layer)
        d.rounded_rectangle((0,0,283,549),radius=38,fill='#fff7e6',outline='#d4b99c',width=2)
        obj=asset(f'assets/images/immersive/reward-{key}.png')
        # Remove transparent padding only; preserve all artwork and proportions.
        obj=obj.crop(obj.getbbox())
        obj=ImageOps.contain(obj,(235,330),Image.Resampling.LANCZOS)
        paste(layer,obj,((284-obj.width)/2,60+(330-obj.height)/2))
        text(layer,name,142,420,39,INK,800,center=True)
        text(layer,rule,142,486,28,'#816855',600,center=True)
        paste(im,layer,(x,y),ease((t-i*.16)/.5))


def features(scene,t):
    if scene==4:
        return end_card(t,True,'작은 시작이, 나만의 습관이 되도록')
    light=scene in (0,2)
    im=background('warm' if scene==2 else 'light' if light else 'evening').copy()
    brand(im,'차곡차곡 쌓이는 하루',light)
    if scene==0:
        text(im,'오늘의 25분이\n내일의 습관으로.',88,270,88,INK,t=t)
        framed(im,companion(int(t*12)),100,650,880,880,radius=70,border=False)
        pill(im,'집중 → 소품 → 기록',540,1640,34,True)
    elif scene==1:
        text(im,'25분 또는 50분.\n내 리듬대로.',88,270,84,t=t)
        phone(im,asset('docs/design/immersive-room/home-day.png'),t,width=520,y=560)
        line_tag(im,'오늘의 집중을 시작하는 작은 버튼.',1740)
    elif scene==2:
        text(im,'집중한 시간만큼,\n방에 작은 기쁨이.',88,270,82,INK,t=t)
        rewards(im,t)
        text(im,'화분 · 머그컵 · 조명',540,1430,46,INK,750,t=t-.4,center=True)
        line_tag(im,'완료한 집중이 소품으로 남아요.',1550,True)
    elif scene==3:
        text(im,'쌓이는 건 시간,\n남는 건 나의 기록.',88,270,80,t=t)
        phone(im,asset('docs/design/immersive-room/records.png'),t,width=520,y=560)
        line_tag(im,'달력에 남기는, 차곡차곡 집중의 흔적.',1740)
    return im


def calm(scene,t):
    if scene==3:
        return end_card(t,False,'집중도, 휴식도 다정하게.','나만의 리듬을 찾아요')
    im=background('night').copy()
    brand(im,'집중과 휴식 사이')
    if scene==0:
        text(im,'집중한 뒤엔,\n잠깐 쉬어가요.',88,270,90,t=t)
        phone(im,clip('rest',t),t,width=526,y=560)
        pill(im,'따뜻한 차와 5분의 쉼',540,1750,30,False)
    elif scene==1:
        text(im,'빗소리, 숲, 장작.\n내가 좋아하는 고요.',88,270,80,t=t)
        src=asset('docs/design/immersive-room/sound.png').crop((32,650,748,1650))
        framed(im,src,190,650+45*(1-ease(t/.6)),700,radius=38)
        # Ambient sound visualization responds gently; it isn't a fake app UI.
        d=ImageDraw.Draw(im)
        for i in range(33):
            h=12+38*(.5+.5*math.sin(t*2.4+i*.61))*math.sin((i+1)*math.pi/34)
            x=276+i*16
            d.rounded_rectangle((x,1710-h/2,x+6,1710+h/2),radius=3,fill=AMBER)
    else:
        text(im,'아침부터 밤까지,\n언제나 나의 작은 방.',88,270,79,t=t)
        paths=['home-morning.png','home-day.png','home-evening.png','home-night.png']
        k=min(3,int(t/1.15))
        source=asset('docs/design/immersive-room/'+paths[k])
        if k<3:
            a=clamp((t-k*1.15-.75)/.4)
            if a>0:
                source=Image.blend(source,asset('docs/design/immersive-room/'+paths[k+1]),a)
        phone(im,source,t,width=520,y=560)
        line_tag(im,'시간에 따라 달라지는 나의 방.',1740)
    return im


VIDEOS=[
    dict(slug='01_together',title='함께 집중하는 감성편',duration=18,
         starts=[0,4,8.5,13],render=emotion,ambience='rain',
         captions=[('미루고 있던 일, 같이 시작할까요?',0,4),
                   ('당신의 옆자리엔 작은 친구가 있어요.',4,8.5),
                   ('딱 25분. 시작은 작아도 괜찮아요.',8.5,13),
                   ('작은 집중방. 오늘, 같이 시작해요.',13,18)]),
    dict(slug='02_small_habits',title='타이머·소품·기록 기능편',duration=20,
         starts=[0,4,8,12,16],render=features,ambience='forest',
         captions=[('오늘의 25분이 내일의 습관으로.',0,4),
                   ('25분 또는 50분. 내 리듬대로.',4,8),
                   ('집중한 시간만큼, 방에 작은 기쁨이.',8,12),
                   ('쌓이는 건 시간, 남는 건 나의 기록.',12,16),
                   ('작은 집중방. 작은 시작이 나만의 습관이 되도록.',16,20)]),
    dict(slug='03_a_gentle_break',title='차와 자연 소리 힐링편',duration=18,
         starts=[0,4.5,9,13.5],render=calm,ambience='rain',
         captions=[('집중한 뒤엔, 잠깐 쉬어가요.',0,4.5),
                   ('빗소리, 숲, 장작. 내가 좋아하는 고요.',4.5,9),
                   ('아침부터 밤까지, 언제나 나의 작은 방.',9,13.5),
                   ('작은 집중방. 집중도, 휴식도 다정하게.',13.5,18)]),
]


def render_frame(v,t):
    starts=v['starts']
    scene=max(i for i,s in enumerate(starts) if s<=t)
    frame=v['render'](scene,t-starts[scene])
    # Short dissolves retain the real app's unwarped artwork.
    if scene>0 and t-starts[scene]<.28:
        old=v['render'](scene-1,starts[scene]-starts[scene-1]+t-starts[scene])
        frame=Image.blend(old,frame,ease((t-starts[scene])/.28))
    return frame.convert('RGB')


def make_music(v,index):
    """An original, quiet felt-key and sine-pad score; no sampled music."""
    rate=22050
    n=round((v['duration']+.3)*rate)
    mono=array('f',[0])*n
    def note(start,length,midi,gain,bell=False):
        freq=440*2**((midi-69)/12)
        begin=round(start*rate)
        count=min(round(length*rate),n-begin)
        if count<=0:return
        for j in range(count):
            s=j/rate
            attack=min(1,s/(.012 if bell else .13))
            release=min(1,(length-s)/.5)
            decay=math.exp(-s/(.85 if bell else 4))
            tone=math.sin(math.tau*freq*s)
            tone+=.2*math.sin(math.tau*freq*2*s)+.065*math.sin(math.tau*freq*3*s)
            mono[begin+j]+=gain*attack*max(0,release)*decay*tone
    chords=[(48,55,60,64),(45,52,57,60),(41,48,53,57),(43,50,55,59)]
    for k in range(math.ceil(v['duration']/4)):
        for m in chords[(k+index)%4]:note(k*4,4.6,m,.024)
    melodies=[[72,76,79,76,74,72,67,72],[72,74,76,79,81,79,76,74],
              [79,76,74,72,67,72,74,76]]
    step=[.75,.625,1.125][index]
    for k in range(math.ceil(v['duration']/step)):
        note(.15+k*step,2.5,melodies[index][k%8],.085,True)
    for s in v['starts'][1:]:
        note(s+.08,1.8,84,.035,True)
        note(s+.25,1.8,88,.025,True)
    out=TMP/(v['slug']+'-original-score.wav')
    with wave.open(str(out),'wb') as wav:
        wav.setnchannels(2);wav.setsampwidth(2);wav.setframerate(rate)
        samples=array('h')
        for j,x in enumerate(mono):
            left=x+(mono[j-int(rate*.21)]*.15 if j>rate*.21 else 0)
            right=x+(mono[j-int(rate*.32)]*.15 if j>rate*.32 else 0)
            samples.extend((round(max(-.95,min(.95,left))*32767),
                            round(max(-.95,min(.95,right))*32767)))
        wav.writeframes(samples.tobytes())
    return out


def timestamp(t):
    ms=round(t*1000)
    return f'{ms//3600000:02}:{ms//60000%60:02}:{ms//1000%60:02},{ms%1000:03}'


def render_video(v,index):
    path=OUT/(v['slug']+'.mp4')
    music=make_music(v,index)
    log=TMP/(v['slug']+'-ffmpeg.log')
    command=['ffmpeg','-hide_banner','-y','-f','rawvideo','-pix_fmt','rgb24',
        '-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-i',str(music),
        '-stream_loop','-1','-i',str(ROOT/f"assets/audio/{v['ambience']}.mp3"),
        '-filter_complex',
        f"[1:a]volume=1.0[m];[2:a]volume={.20 if index==2 else .08}[a];"
        f"[m][a]amix=inputs=2:duration=first:normalize=0,"
        f"loudnorm=I=-18:TP=-1.5:LRA=9,afade=t=in:d=0.65,"
        f"afade=t=out:st={v['duration']-.9}:d=0.9[audio]",
        '-map','0:v','-map','[audio]','-t',str(v['duration']),
        '-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p',
        '-c:a','aac','-b:a','192k','-ar','48000','-movflags','+faststart',
        '-metadata','title=작은 집중방 — '+v['title'],
        '-metadata','comment=App artwork and isolated Flutter renders; original synthesized score; CC0 ambience.',
        str(path)]
    with log.open('w') as err:
        p=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=err)
        try:
            for f in range(v['duration']*FPS):
                p.stdin.write(render_frame(v,f/FPS).tobytes())
                if f%150==0:print(f"{v['slug']}: {f//FPS}/{v['duration']}s",flush=True)
        finally:
            p.stdin.close()
        if p.wait()!=0:raise RuntimeError(log.read_text()[-5000:])
    (OUT/(v['slug']+'.srt')).write_text('\n\n'.join(
        f'{i}\n{timestamp(s)} --> {timestamp(e)}\n{copy}'
        for i,(copy,s,e) in enumerate(v['captions'],1))+'\n')
    print(f'Finished {path.name}: {path.stat().st_size/1048576:.1f} MiB',flush=True)


def previews():
    sheet=Image.new('RGB',(1440,1620),'#201c28')
    d=ImageDraw.Draw(sheet)
    for row,v in enumerate(VIDEOS):
        times=[s+.9 for s in v['starts']]
        # Four representative moments keep the overview readable.
        if len(times)>4:times=[times[i] for i in (0,1,2,4)]
        for col,t in enumerate(times):
            frame=render_frame(v,t)
            frame.thumbnail((260,462),Image.Resampling.LANCZOS)
            sheet.paste(frame,(55+col*350,row*540+48))
        d.text((55,row*540+12),v['title'],font=font(24,700),fill=CREAM)
        poster=render_frame(v,.95)
        poster.save(OUT/(v['slug']+'-poster.jpg'),quality=93)
    sheet.save(OUT/'storyboard.jpg',quality=94)


def manifest():
    result={'app':'작은 집중방','size':[W,H],'fps':FPS,'language':'ko',
        'date':'2026-10-14','videos':[{k:v[k] for k in ('slug','title','duration','captions')}
                                    for v in VIDEOS],
        'production':{'footage':'Real Flutter app widgets rendered with isolated in-memory fixtures. Focus and rest clocks progress normally. Calendar screen is example data.',
            'audio':'Original synthesized music plus the bundled CC0 nature recordings; no voiceover.',
            'availability':'No store availability or download URL is claimed; this is an Android prototype.',
            'rewards':{'plant':'First completed focus session','mug':'60 completed minutes','lamp':'120 completed minutes'},
            'safe_area':'Main copy is within x=88..992, y=116..1810. Platform UI overlays may vary.',
            'rebuild':['flutter test --no-pub tool/capture_promo_footage_test.dart',
                       'python3 tool/create_promo_videos.py']},
        'sources':{'font':'PretendardVariable.ttf, SIL OFL 1.1 (assets/fonts/OFL.txt)',
            'artwork':'Existing project illustrations and companion animation; no new generated artwork.',
            'rain':'rain against window 2 — bastipictures — CC0 — https://freesound.org/people/bastipictures/sounds/243781/',
            'forest':'forest ambience constant breeze.flac — kyles — CC0 — https://freesound.org/people/kyles/sounds/637559/'}}
    (OUT/'production.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')


def prepare_companion():
    folder=TMP/'companion';folder.mkdir(exist_ok=True,parents=True)
    if len(list(folder.glob('frame-*.png')))<72:
        subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y',
            '-i',str(ROOT/'docs/design/calm-connected-motion/stable-writing-full-cycle.mp4'),
            '-frames:v','72', '-start_number','0', str(folder/'frame-%03d.png')],check=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only',type=int,choices=[1,2,3])
    parser.add_argument('--previews-only',action='store_true')
    args=parser.parse_args()
    OUT.mkdir(exist_ok=True,parents=True)
    TMP.mkdir(exist_ok=True,parents=True)
    prepare_companion()
    for kind,count in [('focus',192),('rest',120)]:
        if len(list((TMP/kind).glob('frame-*.png')))!=count:
            raise RuntimeError(f'Render {kind} footage first using capture_promo_footage_test.dart')
    previews();manifest()
    if not args.previews_only:
        for index,v in enumerate(VIDEOS):
            if args.only is None or args.only==index+1:render_video(v,index)


if __name__=='__main__':main()
