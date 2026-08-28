#!/usr/bin/env python3
"""Planche de présentation de l’objectif et de la carte Ultime."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageFilter
ROOT=Path(__file__).resolve().parents[1]
W,H=1500,1000
FONT=str(ROOT/'assets/fonts/Nunito-Variable.ttf')
def ft(n): return ImageFont.truetype(FONT,n)
def center(d,x,y,t,f,fill):
 b=d.textbbox((0,0),t,font=f);d.text((x-(b[2]-b[0])/2,y),t,font=f,fill=fill)
img=Image.new('RGB',(W,H),(4,6,16));d=ImageDraw.Draw(img,'RGBA')
for cx,cy,c in [(350,400,(190,120,35)),(1150,420,(75,130,220)),(750,850,(170,90,210))]:
 l=Image.new('RGBA',(W,H),(0,0,0,0));ld=ImageDraw.Draw(l);ld.ellipse((cx-520,cy-520,cx+520,cy+520),fill=(*c,45));l=l.filter(ImageFilter.GaussianBlur(170));img=Image.alpha_composite(img.convert('RGBA'),l)
d=ImageDraw.Draw(img,'RGBA');center(d,W/2,30,'OBJECTIF ULTIME',ft(54),(255,241,188,255));center(d,W/2,96,'DÉCOUVRIR LES 11 UNIQUES · FORGER AETERNUM · LA CONSERVER À VIE',ft(17),(183,192,216,255))
# card
x,y,cw,ch=120,165,600,760
d.rounded_rectangle((x+10,y+14,x+cw+10,y+ch+14),34,fill=(0,0,0,170));d.rounded_rectangle((x,y,x+cw,y+ch),34,fill=(18,14,30,255),outline=(255,224,138,255),width=6)
for i,c in enumerate([(255,244,199),(216,155,50),(255,255,255)]):d.line((x+42,y+10+i*4,x+cw-42,y+10+i*4),fill=(*c,210),width=2)
art=ImageOps.fit(Image.open(ROOT/'assets/art/ultimate/aeternum.webp').convert('RGB'),(540,540),Image.Resampling.LANCZOS);m=Image.new('L',art.size,0);ImageDraw.Draw(m).rounded_rectangle((0,0,539,539),24,fill=255);img.paste(art,(x+30,y+40),m);d=ImageDraw.Draw(img,'RGBA');d.rounded_rectangle((x+29,y+39,x+571,y+581),25,outline=(255,224,138,230),width=4);center(d,x+cw/2,y+610,'AETERNUM',ft(38),(255,247,218,255));center(d,x+cw/2,y+662,'Souverain de l’Origine',ft(18),(204,190,160,255));center(d,x+cw/2,y+707,'OR-065  ·  ULTIME  ·  LIÉE AU COMPTE',ft(13),(255,224,138,255))
# objective panel
px,py,pw,ph=785,210,590,620
d.rounded_rectangle((px,py,px+pw,py+ph),30,fill=(16,20,48,245),outline=(255,224,138,175),width=3);center(d,px+pw/2,py+30,'LE DERNIER OBJECTIF',ft(28),(255,241,188,255));center(d,px+pw/2,py+82,'Compléter l’Archive chromatique',ft(17),(177,187,214,255))
steps=[('1','Découvrir les 11 cartes Uniques'),('2','Ouvrir l’objectif dans Albums'),('3','Forger gratuitement AETERNUM'),('4','Carte invendable et non recyclable')]
for i,(n,t) in enumerate(steps):
 sy=py+145+i*92;d.ellipse((px+45,sy,px+95,sy+50),fill=(74,52,22,255),outline=(255,224,138,220),width=2);center(d,px+70,sy+10,n,ft(20),(255,244,199,255));d.text((px+120,sy+13),t,font=ft(17),fill=(230,234,247,255))
# progress
center(d,px+pw/2,py+530,'11 / 11 UNIQUES DÉCOUVERTES',ft(17),(255,224,138,255));d.rounded_rectangle((px+65,py+570,px+pw-65,py+590),10,fill=(35,39,67,255));d.rounded_rectangle((px+65,py+570,px+pw-65,py+590),10,fill=(255,206,89,255));d.rounded_rectangle((px+115,py+610,px+pw-115,py+675),20,fill=(92,59,18,255),outline=(255,224,138,255),width=3);center(d,px+pw/2,py+628,'FORGER AETERNUM',ft(20),(255,249,225,255))
img.convert('RGB').save(ROOT/'apercu_carte_ultime.jpg',quality=94)
print(ROOT/'apercu_carte_ultime.jpg')
