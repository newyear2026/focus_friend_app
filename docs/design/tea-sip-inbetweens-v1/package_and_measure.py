#!/usr/bin/env python3
"""Mechanical whole-cel registration, user-authorized canonical compositing and QA.
No semantic painting, deformation, or per-part repositioning is performed.
"""
from pathlib import Path
import sys,json,math
from PIL import Image,ImageDraw,ImageChops,ImageFilter
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tool'))
from package_mouth_tea import fit
POINTS={
'squirrel':[(232,198),(231,215),(223,223),(214,225),(213,245),(207,247),(207,268),(210,275),(206,277),(206,308),(196,314),(192,325),(186,329),(187,512),(512,512),(512,198),(285,200),(284,195),(252,193)],
'fennec':[(133,138),(133,223),(175,227),(188,237),(188,321),(183,336),(183,512),(512,512),(512,142),(368,142),(355,150),(293,148),(288,142),(260,141),(256,137),(197,135),(196,132)]}
SLOTS={'A':3,'B':27,'17':17,'18':18,'16':16}

def load_cels(friend):
    p=ROOT/f'assets/images/friends/motion/{friend}/rest.png'
    atlas=Image.open(p).convert('RGBA')
    return [atlas.crop((i%4*384,i//4*384,i%4*384+384,i//4*384+384)) for i in range(28)]

def mask(friend,size=512):
    m=Image.new('L',(size,size));ImageDraw.Draw(m).polygon([(round(x*size/512),round(y*size/512)) for x,y in POINTS[friend]],fill=255)
    return m

def rgb_gray(im):
    bg=Image.new('RGBA',im.size,(128,128,128,255));bg.alpha_composite(im);return bg.convert('RGB')

def package(friend,publish=False):
    old=load_cels(friend);(OUT/'before').mkdir(exist_ok=True)
    atlas_old=ROOT/f'assets/images/friends/motion/{friend}/rest.png'
    backup=OUT/'before'/f'{friend}-rest.png'
    if not backup.exists(): backup.write_bytes(atlas_old.read_bytes())
    else:
        a=Image.open(backup).convert('RGBA');old=[a.crop((i%4*384,i//4*384,i%4*384+384,i//4*384+384)) for i in range(28)]
    target=old[10].resize((512,512),Image.Resampling.LANCZOS)
    m=mask(friend,384)
    # Preserve cel 10 along the existing tested cut, blend only the edited
    # interior. Four-stage-pixel feather is an alpha transition, not image blur.
    inset=m.filter(ImageFilter.MinFilter(17))
    feather=inset.filter(ImageFilter.GaussianBlur(1.5))
    feather=ImageChops.multiply(feather,m)
    # Keep canonical fixed foreground book, pencil and lower torso below desk.
    ImageDraw.Draw(feather).rectangle((0,260 if friend=='fennec' else 271,383,383),fill=0)
    cels=[c.copy() for c in old];transforms=[]
    for key,slot in SLOTS.items():
        raw=Image.open(OUT/'raw'/f'{friend}-{key}.png').convert('RGBA')
        registered,transform=fit(raw,target,friend)
        registered.save(OUT/'cels'/f'{friend}-{key}-registered.png')
        packed=registered.resize((384,384),Image.Resampling.LANCZOS)
        edited=Image.composite(packed,old[10],feather)
        final=Image.composite(edited,old[0],m)
        final.save(OUT/'cels'/f'{friend}-{key}.png')
        cels[slot]=final
        transforms.append({'key':key,'slot':slot,**transform})
    atlas=Image.new('RGBA',(1536,2688))
    for i,cel in enumerate(cels):atlas.paste(cel,(i%4*384,i//4*384))
    atlas.save(OUT/f'{friend}-rest-candidate.png')
    if publish:atlas.save(atlas_old)
    (OUT/f'{friend}-registration.json').write_text(json.dumps(transforms,indent=2)+'\n')
    contact=Image.new('RGB',(384*6,416),(128,128,128));d=ImageDraw.Draw(contact)
    for j,(key,slot) in enumerate([('10',10),*SLOTS.items()]):
        cel=cels[slot];contact.paste(rgb_gray(cel),(j*384,32));d.text((j*384+10,8),f'{friend} {key} / {slot}',fill='white')
    contact.save(OUT/f'{friend}-candidate-contact.jpg',quality=95)
    return cels

from collections import deque

def cup_measure(im,friend):
 pix=im.load();left,top,right,bottom=240,205,375,350;w=right-left;h=bottom-top
 mask=bytearray(w*h);marks=[]
 for y in range(top,bottom):
  for x in range(left,right):
   r,g,b,a=pix[x,y]
   if a>200 and 30<g<140 and g>r*1.07 and g>b*1.2:marks.append((x,y))
   if a>200 and r>180 and g>155 and b>100 and r-g<55 and g-b<65:mask[(y-top)*w+x-left]=1
 if not marks:return None
 mx,my=[sum(p[k] for p in marks)/len(marks) for k in range(2)]
 components=[]
 for start in range(w*h):
  if not mask[start]:continue
  q=deque([start]);mask[start]=0;pts=[]
  while q:
   i=q.popleft();x,y=i%w,i//w;pts.append((x+left,y+top))
   for j in [i-1 if x else -1,i+1 if x+1<w else -1,i-w if y else -1,i+w if y+1<h else -1]:
    if j>=0 and mask[j]:mask[j]=0;q.append(j)
  if len(pts)>250:
   xs=[p[0] for p in pts];ys=[p[1] for p in pts];box=[min(xs),min(ys),max(xs)+1,max(ys)+1]
   if box[0]<=mx<=box[2] and box[1]<=my<=box[3] and box[2]-box[0]<105:components.append((len(pts),box))
 if not components:return {'emblem':[mx,my]}
 area,box=max(components)
 return {'emblem':[mx,my],'cupBox':box,'cupCenter':[(box[0]+box[2])/2,(box[1]+box[3])/2],'width':box[2]-box[0],'height':box[3]-box[1]}

def measure(friend):
    atlas=Image.open(OUT/f'{friend}-rest-candidate.png').convert('RGBA')
    cells=[atlas.crop((i%4*384,i//4*384,i%4*384+384,i//4*384+384)).resize((512,512),Image.Resampling.LANCZOS) for i in range(28)]
    base=rgb_gray(cells[0]);m=mask(friend)
    boundary=Image.new('L',(512,512));ImageDraw.Draw(boundary).line(POINTS[friend]+[POINTS[friend][0]],fill=255,width=1)
    edge=[i for i,v in enumerate(boundary.getdata()) if v]
    rect=(124,52,374,167) if friend=='fennec' else (170,90,370,200)
    def dark(im):return sum(1 for r,g,b in rgb_gray(im).crop(rect).getdata() if .299*r+.587*g+.114*b<55)
    capture=json.loads((OUT/'after-capture-manifest.json').read_text())
    entry=next(e for e in capture if e['friend']==friend and e['mode']=='rest')
    used=sorted({s['from'] for s in entry['samples']})
    rows=[];union=set()
    for i in used:
        rgb=rgb_gray(cells[i]);dif=list(ImageChops.difference(base,rgb).getdata());bad={p for p in edge if max(dif[p])>40};union|=bad
        rows.append({'cel':i,'boundaryOver40':len(bad),'darkPixels':dark(cells[i]),'darkRatioVs10':dark(cells[i])/dark(cells[10])})
    cup_path=[{'cel':i,**cup_measure(cells[i],friend)} for i in [0,10,3,27,17,18,16]]
    result={'cupPath':cup_path,'friend':friend,'boundaryUnionOver40':len(union),'boundaryLimit':60 if friend=='fennec' else 30,'darkBaseline10':dark(cells[10]),'rows':rows}
    (OUT/f'{friend}-art-measurements.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))

if __name__=='__main__':
    for f in ('fennec','squirrel'):
        if '--measure-only' not in sys.argv:package(f,'--publish' in sys.argv)
        measure(f)
