#!/usr/bin/env python3
"""Planche finale des cartes de rareté Unique."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageFilter
import json,math
ROOT=Path(__file__).resolve().parents[1]
W,H=2100,1830; COLS=4; CW,CH=460,500
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'; BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def ft(n,b=False): return ImageFont.truetype(BOLD if b else FONT,n)
def center(d,x,y,t,f,fill):
 b=d.textbbox((0,0),t,font=f);d.text((x-(b[2]-b[0])/2,y),t,font=f,fill=fill)
cards=[c for c in json.loads((ROOT/'data/card_catalog.json').read_text()) if c['rarity']=='unique']
img=Image.new('RGB',(W,H),(4,7,18));d=ImageDraw.Draw(img,'RGBA')
for cx,cy,c in [(300,350,(80,190,220)),(1750,500,(190,90,210)),(1050,1450,(90,110,230))]:
 l=Image.new('RGBA',(W,H),(0,0,0,0));ld=ImageDraw.Draw(l);ld.ellipse((cx-600,cy-600,cx+600,cy+600),fill=(*c,45));l=l.filter(ImageFilter.GaussianBlur(190));img=Image.alpha_composite(img.convert('RGBA'),l)
d=ImageDraw.Draw(img,'RGBA');center(d,W/2,35,'ARCHIVE CHROMATIQUE',ft(58,True),(245,248,255,255));center(d,W/2,108,f'{len(cards)} CARTES UNIQUES · CHROME COSMIQUE',ft(20,True),(177,205,230,255));center(d,W/2,148,'Taux du rang : 0,01 % · taux par carte : environ 0,00091 %',ft(17),(148,164,193,255))
for i,c in enumerate(cards):
 row,col=divmod(i,COLS);x=80+col*500;y=210+row*525
 # glow and card
 accent=[(105,230,255),(177,123,255),(255,135,205),(255,225,125)][i%4]
 d.rounded_rectangle((x+7,y+10,x+CW+7,y+CH+10),28,fill=(0,0,0,150))
 d.rounded_rectangle((x,y,x+CW,y+CH),28,fill=(12,17,42,250),outline=(*accent,235),width=4)
 p=ROOT/c['art'].replace('res://','');art=ImageOps.fit(Image.open(p).convert('RGB'),(420,365),Image.Resampling.LANCZOS)
 m=Image.new('L',art.size,0);ImageDraw.Draw(m).rounded_rectangle((0,0,419,364),18,fill=255);img.paste(art,(x+20,y+20),m);d=ImageDraw.Draw(img,'RGBA');d.rounded_rectangle((x+19,y+19,x+441,y+386),19,outline=(*accent,190),width=3)
 center(d,x+CW/2,y+401,c['name'],ft(22,True),(247,248,255,255));center(d,x+CW/2,y+437,c['title'],ft(12),(182,193,216,255));center(d,x+CW/2,y+465,f"OR-{c['number']}  ·  UNIQUE",ft(11,True),(*accent,230))
img.convert('RGB').save(ROOT/'apercu_11_uniques.jpg',quality=93)
print(ROOT/'apercu_11_uniques.jpg')
