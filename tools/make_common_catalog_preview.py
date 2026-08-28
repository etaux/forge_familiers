#!/usr/bin/env python3
"""Génère une planche dynamique de toutes les communes du catalogue."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,math
ROOT=Path(__file__).resolve().parents[1]
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def ft(n,b=False):return ImageFont.truetype(BOLD if b else FONT,n)
cards=[c for c in json.loads((ROOT/'data/card_catalog.json').read_text()) if c['rarity']=='common']
cols=10;thumb=180;label_h=34;header=105;rows=math.ceil(len(cards)/cols);W=cols*thumb;H=header+rows*(thumb+label_h)
out=Image.new('RGB',(W,H),(7,10,28));d=ImageDraw.Draw(out)
title=f"COLLECTION COMMUNE · {len(cards)} / 100";b=d.textbbox((0,0),title,font=ft(34,True));d.text(((W-(b[2]-b[0]))/2,20),title,font=ft(34,True),fill=(240,244,255));sub='Illustrations originales · catalogue paginé · cible finale 501 cartes';b=d.textbbox((0,0),sub,font=ft(15));d.text(((W-(b[2]-b[0]))/2,65),sub,font=ft(15),fill=(159,172,204))
for i,c in enumerate(cards):
 p=ROOT/c['art'].replace('res://','');im=ImageOps.fit(Image.open(p).convert('RGB'),(thumb,thumb),Image.Resampling.LANCZOS);x=(i%cols)*thumb;y=header+(i//cols)*(thumb+label_h);out.paste(im,(x,y));name=c['name'];b=d.textbbox((0,0),name,font=ft(13,True));d.text((x+(thumb-(b[2]-b[0]))/2,y+184),name,font=ft(13,True),fill=(236,240,252))
output=ROOT/f"apercu_communes_{len(cards)}.jpg"
out.save(output,quality=92)
print(output)
