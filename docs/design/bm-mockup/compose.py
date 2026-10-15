import sys, base64, io
from PIL import Image, ImageDraw, ImageEnhance, ImageChops
root = sys.argv[1]; out = sys.argv[2]
I = root + '/assets/images/immersive/'
def scene(amb, tint, rewards=('lamp','plant','mug')):
    plate = Image.open(I+f'room-{amb}.png').convert('RGBA')
    s = plate.copy()
    panda = Image.open(I+'redpanda-reference.png').convert('RGBA').resize((580,580), Image.LANCZOS)
    tl = Image.new('RGBA', panda.size, tint+(255,))
    panda = ImageChops.multiply(panda, tl); 
    a = Image.open(I+'redpanda-reference.png').convert('RGBA').resize((580,580), Image.LANCZOS).split()[3]
    panda.putalpha(a)
    s.alpha_composite(panda, (90,610))
    mask = Image.new('L', plate.size, 0)
    ImageDraw.Draw(mask).polygon([(0,1035),(294,1035),(345,1198),(0,1198)], fill=255)
    s.paste(plate, (0,0), mask)
    def put(name, box, fit='fill', t=True):
        im = Image.open(I+f'reward-{name}.png').convert('RGBA')
        l,tp,w,h = box
        if fit=='contain':
            r = min(w/im.width, h/im.height); im = im.resize((int(im.width*r), int(im.height*r)), Image.LANCZOS)
            l += (w-im.width)//2; tp += (h-im.height)//2
        else: im = im.resize((w,h), Image.LANCZOS)
        if t:
            al = im.split()[3]; im = ImageChops.multiply(im, Image.new('RGBA', im.size, tint+(255,))); im.putalpha(al)
        s.alpha_composite(im, (l,tp))
    if 'lamp' in rewards: put('lamp', (608,739,266,400), t=False)
    if 'plant' in rewards: put('plant', (648,957,115,138), 'contain')
    if 'mug' in rewards: put('mug', (613,1010,156,170))
    return s.convert('RGB')
def save(im, name, w=360, q=72):
    im = im.resize((w, int(im.height*w/im.width)), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, 'JPEG', quality=q, optimize=True)
    open(f'{out}/{name}.jpg','wb').write(b.getvalue())
    open(f'{out}/{name}.b64','w').write(base64.b64encode(b.getvalue()).decode())
    print(name, len(b.getvalue()))
ev = scene('evening', (255,221,202))
save(ev, 'home')
save(scene('night', (188,195,228)), 'night', 200)
save(scene('morning', (255,255,255)), 'morning', 200)
# placeholder scene variants (color only)
rain = ImageEnhance.Color(scene('day',(255,255,255))).enhance(0.45)
rain = ImageChops.multiply(rain, Image.new('RGB', rain.size, (170,190,215)))
save(rain, 'rain', 200)
snow = ImageEnhance.Color(scene('morning',(255,255,255))).enhance(0.35)
snow = ImageEnhance.Brightness(snow).enhance(1.08)
snow = ImageChops.multiply(snow, Image.new('RGB', snow.size, (215,228,245)))
save(snow, 'winter', 200)
