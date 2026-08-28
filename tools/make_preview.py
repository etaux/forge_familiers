#!/usr/bin/env python3
"""Génère une planche visuelle autonome des cinq raretés."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
import math
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "apercu_collection.png"
W, H = 2200, 1300
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

CARDS = [
    ("mousselet.png", "MOUSSELET", "Esprit des sous-bois", "COMMUNE", "89,39 %", (85, 217, 130), 1),
    ("cristaloup.png", "CRISTALOUP", "Gardien du lac gelé", "RARE", "10 %", (59, 140, 255), 2),
    ("noctilux.png", "NOCTILUX", "Félin des nébuleuses", "ÉPIQUE", "0,5 %", (172, 85, 255), 3),
    ("solgriffon.png", "SOLGRIFFON", "Souverain de l’aurore", "LÉGENDAIRE", "0,1 %", (255, 148, 31), 4),
    ("chroma_zero.png", "CHRØMA–ZÉRO", "Anomalie prismatique", "UNIQUE", "0,01 %", (220, 228, 238), 5),
]


def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def fit_crop(img, size):
    return ImageOps.fit(img.convert("RGB"), size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def rounded_paste(base, img, box, radius):
    x0, y0, x1, y1 = box
    img = img.resize((x1-x0, y1-y0), Image.Resampling.LANCZOS)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width-1, img.height-1), radius=radius, fill=255)
    base.paste(img, (x0, y0), mask)


def centered(draw, xy, text, ft, fill, stroke=0, stroke_fill=None):
    x, y = xy
    box = draw.textbbox((0, 0), text, font=ft, stroke_width=stroke)
    draw.text((x-(box[2]-box[0])/2, y), text, font=ft, fill=fill,
              stroke_width=stroke, stroke_fill=stroke_fill)


# Radial/vertical background.
img = Image.new("RGB", (W, H), (7, 10, 28))
pix = img.load()
for y in range(H):
    for x in range(W):
        dx, dy = (x-W*0.5)/(W*0.65), (y-H*0.42)/(H*0.8)
        glow = max(0.0, 1.0-math.sqrt(dx*dx+dy*dy))
        violet = max(0.0, 1.0-math.sqrt(((x-W*0.22)/(W*0.42))**2+((y-H*0.35)/(H*0.8))**2))
        pix[x, y] = (
            int(7 + glow*10 + violet*8),
            int(10 + glow*12 + violet*3),
            int(28 + glow*28 + violet*38),
        )

# Ambient stars.
draw = ImageDraw.Draw(img, "RGBA")
rng = random.Random(42026)
for _ in range(135):
    x, y = rng.randrange(W), rng.randrange(H)
    r = rng.choice([1, 1, 1, 2, 2, 3])
    a = rng.randrange(35, 125)
    draw.ellipse((x-r, y-r, x+r, y+r), fill=(178, 190, 255, a))

centered(draw, (W/2, 64), "FORGE DES FAMILIERS", font(65, True), (246, 247, 255, 255), 2, (69, 44, 145, 255))
centered(draw, (W/2, 144), "SÉRIE ORIGINE  ·  LES CINQ RARETÉS FONDATRICES", font(22, True), (175, 157, 232, 255))
centered(draw, (W/2, 188), "Plus la créature est belle et spectaculaire, plus elle est rare.", font(21), (149, 158, 190, 255))

cw, ch, gap = 360, 650, 34
start_x = (W - (cw*5 + gap*4)) // 2
y0 = 280

for idx, (file_name, name, subtitle, rarity, rate, color, stars) in enumerate(CARDS):
    x0 = start_x + idx*(cw+gap)
    # Glow.
    glow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer, "RGBA")
    gd.rounded_rectangle((x0-12, y0-12, x0+cw+12, y0+ch+12), radius=42, fill=(*color, 110 if idx < 4 else 150))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(34 if idx < 4 else 46))
    img = Image.alpha_composite(img.convert("RGBA"), glow_layer)
    draw = ImageDraw.Draw(img, "RGBA")

    # Shadow and frame.
    draw.rounded_rectangle((x0+7, y0+14, x0+cw+7, y0+ch+14), radius=37, fill=(0, 0, 0, 145))
    if idx == 4:
        # Chrome spectral outer frame.
        frame = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        fp = frame.load()
        spectrum = [(102,231,255), (169,118,255), (255,136,202), (255,224,116), (122,245,211), (220,228,238)]
        for yy in range(ch):
            for xx in range(cw):
                t = ((xx/cw)*1.3 + (yy/ch)*0.35) % 1
                pos = t*(len(spectrum)-1)
                a = int(pos); b = min(a+1, len(spectrum)-1); f = pos-a
                c = tuple(int(spectrum[a][k]*(1-f)+spectrum[b][k]*f) for k in range(3))
                fp[xx, yy] = (*c, 255)
        mask = Image.new("L", (cw, ch), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle((0,0,cw-1,ch-1), radius=36, fill=255)
        md.rounded_rectangle((8,8,cw-9,ch-9), radius=30, fill=0)
        img.paste(frame, (x0,y0), Image.composite(mask, Image.new("L", mask.size, 0), mask))
    else:
        draw.rounded_rectangle((x0, y0, x0+cw, y0+ch), radius=36, fill=(*color, 255))
    draw.rounded_rectangle((x0+8, y0+8, x0+cw-8, y0+ch-8), radius=30, fill=(10, 15, 39, 255))

    # Top badge.
    badge_w = 238
    draw.rounded_rectangle((x0+(cw-badge_w)//2, y0+18, x0+(cw+badge_w)//2, y0+65), radius=22,
                           fill=(*[max(10, int(c*.25)) for c in color], 245), outline=(*color, 220), width=2)
    centered(draw, (x0+cw/2, y0+28), "◆"*stars + "  " + rarity, font(17, True), (*color, 255), 1, (5,8,22,255))

    # Art.
    art = Image.open(ROOT / "assets" / "art" / file_name)
    art = fit_crop(art, (cw-34, 355))
    rounded_paste(img, art, (x0+17, y0+78, x0+cw-17, y0+433), 18)
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((x0+16, y0+77, x0+cw-16, y0+434), radius=19, outline=(*color, 225), width=3)

    # Rarity-dependent embellishments.
    if idx >= 1:
        count = 7 + idx*4
        for s in range(count):
            sx = x0 + 25 + ((s*79 + idx*17) % (cw-50))
            sy = y0 + 91 + ((s*53 + idx*31) % 315)
            rr = 1 + s % 3
            draw.line((sx-rr*2, sy, sx+rr*2, sy), fill=(*color, 170), width=1)
            draw.line((sx, sy-rr*2, sx, sy+rr*2), fill=(255,255,255,150), width=1)
    if idx == 4:
        # Holographic diagonal foil stripe, fusionnée avec l’art.
        foil = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(foil).polygon(((x0+62,y0+78),(x0+117,y0+78),(x0+277,y0+433),(x0+222,y0+433)), fill=(255,255,255,42))
        img = Image.alpha_composite(img, foil)
        draw = ImageDraw.Draw(img, "RGBA")

    # Information panel.
    draw.rounded_rectangle((x0+17, y0+447, x0+cw-17, y0+ch-18), radius=20,
                           fill=(13, 19, 47, 250), outline=(*color, 90), width=2)
    centered(draw, (x0+cw/2, y0+466), name, font(28, True), (247,248,255,255), 2, (2,5,18,255))
    centered(draw, (x0+cw/2, y0+509), subtitle, font(16), (183,192,216,255))
    draw.line((x0+42, y0+546, x0+cw-42, y0+546), fill=(*color, 65), width=2)
    draw.text((x0+32, y0+568), "TAUX DE CAISSE", font=font(13, True), fill=(132,143,172,255))
    rate_box = draw.textbbox((0,0), rate, font=font(24, True))
    draw.text((x0+cw-30-(rate_box[2]-rate_box[0]), y0+559), rate, font=font(24, True), fill=(*color,255))
    draw.text((x0+32, y0+613), f"OR-00{idx+1}", font=font(12, True), fill=(111,122,151,255))
    rank = "PREMIÈRE ÉDITION"
    rb = draw.textbbox((0,0), rank, font=font(12, True))
    draw.text((x0+cw-30-(rb[2]-rb[0]), y0+613), rank, font=font(12, True), fill=(*color,190))

# Bottom gameplay summary.
draw = ImageDraw.Draw(img, "RGBA")
bar = (215, 1012, W-215, 1205)
draw.rounded_rectangle(bar, radius=35, fill=(14, 19, 48, 235), outline=(119, 91, 211, 100), width=2)
centered(draw, (W/2, 1040), "UNE CAISSE ORIGINE · QUATRE TAILLES", font(23, True), (225,219,255,255))
items = [("PETITE", "6 CARTES · 150 ESS."), ("MOYENNE", "15 CARTES · 330 ESS."), ("GRANDE", "25 CARTES · 500 ESS."), ("TRÈS GRANDE", "50 CARTES · 850 ESS.")]
for i, (label, detail) in enumerate(items):
    cx = 430 + i*445
    draw.rounded_rectangle((cx-155,1100,cx+155,1172), radius=22, fill=(30,25,72,225), outline=(141,104,255,135), width=2)
    centered(draw, (cx, 1111), label, font(14, True), (166,151,215,255))
    centered(draw, (cx, 1136), detail, font(18, True), (246,247,255,255))
centered(draw, (W/2, 1235), "FUSION IDENTIQUE  ·  COMMUNE ×10  ·  RARE ×500  ·  ÉPIQUE ×1 000  ·  LÉGENDAIRE ×10 000", font(18, True), (111,218,255,255))

img.convert("RGB").save(OUT, quality=95)
print(OUT)
