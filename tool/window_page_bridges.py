"""Compile study cels 24–29 from the registered 512px window-friend artwork."""
from PIL import Image, ImageDraw, ImageChops, ImageFilter

# The exposed sheet and the fingers on its upper edge. Keep these in front of
# the stationary drawing, even when the leaf passes the pencil or the chin.
FOREGROUND = {
    'squirrel': {
        15: [(248,356),(278,343),(285,308),(306,304),(329,292),(346,285),(356,286),(360,294),(360,310),(350,341),(310,397)],
        16: [(253,360),(277,350),(276,333),(271,309),(265,286),(281,300),(287,308),(292,303),(301,301),(310,301),(322,306),(333,319),(338,330),(338,339),(334,347),(326,351),(311,351),(312,368),(312,391),(309,400)],
    },
    'fennec': {
        15: [(248,361),(266,348),(272,314),(287,308),(305,308),(321,316),(329,328),(328,348),(314,371),(300,396)],
        16: [(246,364),(256,359),(248,350),(239,337),(233,321),(231,300),(243,312),(259,323),(265,311),(267,305),(281,305),(291,311),(299,318),(302,327),(301,336),(295,343),(288,346),(283,346),(298,396)],
    },
}


def polygon(points):
    result = Image.new('L', (512, 512))
    ImageDraw.Draw(result).polygon(points, fill=255)
    return result


def falling_leaf(squirrel):
    # Trace the two curved edges up to the gripping paw. The far half is
    # pinned to the gutter and the original fingers.
    segments = ([
        (180,310), (196,328,223,344,246,349), (254,355,266,361,277,366),
        (284,376,295,387,303,396), (275,384,253,386,234,384),
        (201,382,181,367,180,310),
    ] if squirrel else [
        (196,298), (212,318,246,337,263,345), (279,356,287,377,296,397),
        (279,383,248,374,230,362), (208,348,198,322,196,298),
    ])
    points = [segments[0]]
    for bx, by, cx, cy, dx, dy in segments[1:]:
        ax, ay = points[-1]
        for i in range(1, 21):
            t = i / 20
            def bezier(a, b, c, d):
                return (1-t)**3*a + 3*(1-t)**2*t*b + 3*(1-t)*t*t*c + t**3*d
            points.append((bezier(ax,bx,cx,dx), bezier(ay,by,cy,dy)))
    return polygon(points).filter(ImageFilter.MaxFilter(3))


def page_mesh(left, pivot, right, top, dx, dy):
    # Invert the displacement at each output corner. The source gutter
    # at y=395 stays fixed while the upper corner and fingers travel.
    def source_at(x, y):
        u, v = x, y
        for _ in range(10):
            across = max(0, min((u-left)/(pivot-left), (right-u)/(right-pivot)))
            down = max(0, min(1, (v-270)/(top-270), (395-v)/75))
            weight = across * down
            u = (u + x - dx*weight) / 2
            v = (v + y - dy*weight) / 2
        return u, v

    mesh = []
    for y in range(264, 400, 4):
        for x in range(140, 392, 4):
            corners = [(x, y), (x, y+4), (x+4, y+4), (x+4, y)]
            quad = tuple(v for px, py in corners for v in source_at(px, py))
            mesh.append(((x, y, x+4, y+4), quad))
    return mesh


def warp(image, mesh):
    region = (140, 264, 392, 400)
    transformed = image.transform(image.size, Image.Transform.MESH, mesh, Image.Resampling.BICUBIC)
    result = image.copy()
    result.paste(transformed.crop(region), region)
    return result


def bake_page_bridges(friend, cels):
    squirrel = friend == 'squirrel'
    # Each row moves one grip from the original lift, upright or release cel.
    poses = [(15, 348 if squirrel else 320, -24, -4),
             (16, 264 if squirrel else 231, 31, 1),
             (16, 264 if squirrel else 231, -24, 0),
             (17, 182 if squirrel else 193, 23, -5),
             (17, 182 if squirrel else 193, 4, 13),
             (17, 182 if squirrel else 193, 11, 28)]
    # Restore the fixed upper body and writing hand behind the moving sheet.
    fixed = polygon([(0,0),(512,0),(512,313 if squirrel else 322),
                     (299 if squirrel else 266,313 if squirrel else 322),
                     (286 if squirrel else 253,345),(281 if squirrel else 249,364),
                     (0,374)])
    # Keep the chest transition soft behind the moving hand. A hard cut here
    # creates a seam through the fur and the edge of the vest.
    fixed = fixed.filter(ImageFilter.GaussianBlur(5))
    bridges = []
    for cel, pivot, dx, dy in poses:
        right = (248 if squirrel else 261) if cel == 17 else (386 if squirrel else 363)
        left = 145 if cel == 17 else (226 if squirrel else 194)
        mesh = page_mesh(left, pivot, right, 285 if squirrel else 296, dx, dy)
        source = cels[cel]
        if cel == 17:
            # The sheet is already released. Let its free corner fall while
            # the writing hand and the hand at the spine keep their pose.
            sheet = falling_leaf(squirrel)
            moved = warp(sheet, mesh)
            exposed = sheet.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(1))
            plate = Image.composite(cels[0], source, exposed)
            turned = Image.composite(warp(source, mesh), plate, moved)
            # Beyond the contact point, use the actual paw and shadow again.
            left_half = polygon([(0,0),(right-1,0),(right-1,512),(0,512)])
            bridges.append(Image.composite(turned, source, left_half.filter(ImageFilter.GaussianBlur(2))))
        else:
            grip = polygon(FOREGROUND[friend][cel]).filter(ImageFilter.GaussianBlur(.55))
            moved = warp(grip, mesh)
            swept = ImageChops.lighter(grip, moved).filter(ImageFilter.MaxFilter(7))
            swept = swept.filter(ImageFilter.GaussianBlur(1))
            motion = Image.composite(warp(source, mesh), source, swept)
            exposed = ImageChops.multiply(swept, ImageChops.invert(moved))
            motion = Image.composite(cels[0], motion, ImageChops.multiply(fixed, exposed))
            # The registered room must show through where the lifted paw was.
            silhouette = ImageChops.lighter(cels[0].getchannel('A'),
                warp(ImageChops.multiply(grip, source.getchannel('A')), mesh))
            motion.putalpha(ImageChops.darker(motion.getchannel('A'), silhouette))
            bridges.append(motion)
    return bridges
