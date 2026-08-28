#!/usr/bin/env python3
"""Planche de présentation dynamique des habitats et albums."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter
import json, math

ROOT=Path(__file__).resolve().parents[1]
W=2200
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def ft(n,b=False): return ImageFont.truetype(BOLD if b else FONT,n)
def col(s):
 s=s.lstrip('#'); return tuple(int(s[i:i+2],16) for i in (0,2,4))
def text_center(d,x,y,t,f,fill):
 b=d.textbbox((0,0),t,font=f); d.text((x-(b[2]-b[0])/2,y),t,font=f,fill=fill)
def thumb(card,size=72):
 p=ROOT/card['art'].replace('res://',''); im=Image.open(p).convert('RGB'); im=ImageOps.fit(im,(size,size),Image.Resampling.LANCZOS)
 m=Image.new('L',(size,size),0); ImageDraw.Draw(m).rounded_rectangle((0,0,size-1,size-1),12,fill=255)
 out=Image.new('RGBA',(size,size),(0,0,0,0)); out.paste(im,(0,0),m); return out

cards={c['id']:c for c in json.loads((ROOT/'data/card_catalog.json').read_text())}
sets=json.loads((ROOT/'data/collections.json').read_text())
habitat_rows=math.ceil(len(sets['habitats'])/4)
album_rows=math.ceil(len(sets['albums'])/5)
album_title_y=210+habitat_rows*325+20
album_start_y=album_title_y+65
footer_y=album_start_y+album_rows*380+30
H=footer_y+185
img=Image.new('RGB',(W,H),(7,10,28)); d=ImageDraw.Draw(img,'RGBA')
for cx,cy,c in [(280,350,(70,170,125)),(1800,400,(90,130,230)),(1100,1500,(160,90,230))]:
 layer=Image.new('RGBA',(W,H),(0,0,0,0)); ld=ImageDraw.Draw(layer); ld.ellipse((cx-520,cy-520,cx+520,cy+520),fill=(*c,55)); layer=layer.filter(ImageFilter.GaussianBlur(180)); img=Image.alpha_composite(img.convert('RGBA'),layer); d=ImageDraw.Draw(img,'RGBA')
text_center(d,W/2,38,'HABITATS & ALBUMS',ft(56,True),(247,248,255,255))
text_center(d,W/2,108,f"{len(sets['habitats'])} HABITATS · {len(sets['albums'])} ALBUMS · {len(cards)} CARTES",ft(19,True),(174,156,232,255))
text_center(d,W/2,147,'Recycler les doublons · restaurer les habitats · compléter les pages',ft(18),(145,157,187,255))

# Habitats : grille 4 x 2.
hw,hh,hcols=500,300,4
for i,h in enumerate(sets['habitats']):
 x=55+(i%hcols)*535; y=210+(i//hcols)*325; accent=col(h['color'])
 d.rounded_rectangle((x,y,x+hw,y+hh),28,fill=(15,22,48,240),outline=(*accent,210),width=3)
 d.text((x+20,y+17),h['label'],font=ft(21,True),fill=(*accent,255))
 d.text((x+20,y+50),f"{len(h['card_ids'])} CRÉATURES · +{h['expedition_bonus_percent']} % EXPÉDITION",font=ft(12,True),fill=(188,198,222,255))
 for j,cid in enumerate(h['card_ids']):
  size=58; t=thumb(cards[cid],size); tx=x+18+(j%7)*68; ty=y+88+(j//7)*76; img.alpha_composite(t,(tx,ty)); ImageDraw.Draw(img,'RGBA').rounded_rectangle((tx-1,ty-1,tx+size,ty+size),11,outline=(*accent,150),width=2)
 d=ImageDraw.Draw(img,'RGBA')

text_center(d,W/2,album_title_y,f"{len(sets['albums'])} ALBUMS THÉMATIQUES",ft(32,True),(255,213,112,255))
# Albums : grille dynamique de 5 colonnes.
aw,ah,acols=410,350,5
for i,a in enumerate(sets['albums']):
 x=45+(i%acols)*425; y=album_start_y+(i//acols)*380
 d.rounded_rectangle((x,y,x+aw,y+ah),24,fill=(20,20,53,245),outline=(212,160,74,170),width=2)
 text_center(d,x+aw/2,y+17,a['label'],ft(17,True),(255,218,145,255))
 text_center(d,x+aw/2,y+47,a['description'],ft(9),(160,169,195,255))
 for j,cid in enumerate(a['card_ids']):
  size=82; t=thumb(cards[cid],size); tx=x+58+(j%3)*105; ty=y+82+(j//3)*106; img.alpha_composite(t,(tx,ty)); ImageDraw.Draw(img,'RGBA').rounded_rectangle((tx-1,ty-1,tx+size+1,ty+size+1),13,outline=(220,172,93,150),width=2)
 d=ImageDraw.Draw(img,'RGBA')
 reward=f"{a['reward_essence']} ESS. · {a['reward_coins']} JETONS · {a['reward_dust']} POUSSIÈRES"
 text_center(d,x+aw/2,y+318,reward,ft(9,True),(208,192,156,255))

d.rounded_rectangle((145,footer_y,W-145,footer_y+105),28,fill=(15,40,43,245),outline=(105,220,160,180),width=2)
text_center(d,W/2,footer_y+20,'RECYCLAGE DES DOUBLONS',ft(21,True),(125,237,175,255))
text_center(d,W/2,footer_y+59,'1 exemplaire protégé · poussières : 1 / 25 / 250 / 2 500 / 10 000 · commune manquante : 100',ft(15),(200,222,214,255))
img.convert('RGB').save(ROOT/'apercu_habitats_albums.jpg',quality=91)
print(ROOT/'apercu_habitats_albums.jpg')
