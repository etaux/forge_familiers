#!/usr/bin/env python3
"""Génère une planche dynamique pour une rareté donnée."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,math,sys
ROOT=Path(__file__).resolve().parents[1]
rarity=sys.argv[1] if len(sys.argv)>1 else 'rare'
labels={'common':'COMMUNES','rare':'RARES','epic':'ÉPIQUES','legendary':'LÉGENDAIRES','unique':'UNIQUES','ultimate':'ULTIME'}
colors={'common':(85,217,130),'rare':(59,140,255),'epic':(172,85,255),'legendary':(255,148,31),'unique':(220,228,238),'ultimate':(255,224,138)}
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def ft(n,b=False):return ImageFont.truetype(BOLD if b else FONT,n)
cards=[c for c in json.loads((ROOT/'data/card_catalog.json').read_text()) if c['rarity']==rarity]
cols=6;thumb=240;cell_h=302;header=120;rows=max(1,math.ceil(len(cards)/cols));W=cols*thumb;H=header+rows*cell_h;accent=colors[rarity]
out=Image.new('RGB',(W,H),(6,10,26));d=ImageDraw.Draw(out);title=f"COLLECTION {labels[rarity]} · {len(cards)} / {100 if rarity!='ultimate' else 1}";b=d.textbbox((0,0),title,font=ft(34,True));d.text(((W-(b[2]-b[0]))/2,20),title,font=ft(34,True),fill=accent);sub='Illustrations originales · taux réparti entre les cartes du rang';b=d.textbbox((0,0),sub,font=ft(15));d.text(((W-(b[2]-b[0]))/2,67),sub,font=ft(15),fill=(165,177,207))
for i,c in enumerate(cards):
 p=ROOT/c['art'].replace('res://','');im=ImageOps.fit(Image.open(p).convert('RGB'),(thumb,thumb),Image.Resampling.LANCZOS);x=(i%cols)*thumb;y=header+(i//cols)*cell_h;out.paste(im,(x,y));d.rectangle((x,y,x+thumb-1,y+thumb-1),outline=accent,width=2);name=c['name'];b=d.textbbox((0,0),name,font=ft(15,True));d.text((x+(thumb-(b[2]-b[0]))/2,y+248),name,font=ft(15,True),fill=(242,246,255));title2=c['title'];b=d.textbbox((0,0),title2,font=ft(10));d.text((x+(thumb-(b[2]-b[0]))/2,y+274),title2,font=ft(10),fill=(172,184,211))
outpath=ROOT/f"apercu_{rarity}s_{len(cards)}.jpg";out.save(outpath,quality=92);print(outpath)
