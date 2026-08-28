#!/usr/bin/env python3
"""Maquette visuelle de l’interface mobile HD V6."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps,ImageFilter
ROOT=Path(__file__).resolve().parents[1]
FONT=str(ROOT/'assets/fonts/Nunito-Variable.ttf')
def ft(n): return ImageFont.truetype(FONT,n)
def center(d,x,y,t,f,fill):
 b=d.textbbox((0,0),t,font=f);d.text((x-(b[2]-b[0])/2,y),t,font=f,fill=fill)
def rr(d,box,r,fill,outline=None,w=1): d.rounded_rectangle(box,r,fill=fill,outline=outline,width=w)
def phone_background(size):
 w,h=size;im=Image.new('RGB',size,(6,9,24));p=im.load()
 for y in range(h):
  t=y/(h-1);c=(int(17*(1-t)+5*t),int(22*(1-t)+7*t),int(58*(1-t)+20*t))
  for x in range(w): p[x,y]=c
 return im.convert('RGBA')
def label(d,xy,text,size,color=(247,249,255,255),bold=False): d.text(xy,text,font=ft(size),fill=color,stroke_width=0)
def chip(d,box,text,accent): rr(d,box,13,(*tuple(int(v*.30) for v in accent),235),(*accent,180),1);center(d,(box[0]+box[2])/2,box[1]+7,text,ft(12),(*accent,255))
def stat(d,x,title,value,accent):
 rr(d,(x,18,x+102,72),17,(18,26,62,250),(*accent,145),1);center(d,x+51,26,title,ft(10),(170,180,205,255));center(d,x+51,43,value,ft(18),(*accent,255))
def draw_nav_icon(d,i,cx,cy,color):
 if i==0:
  d.line((cx-8,cy,cx,cy-7,cx+8,cy),fill=color,width=2);d.rectangle((cx-6,cy,cx+6,cy+8),outline=color,width=2)
 elif i==1:
  d.rounded_rectangle((cx-7,cy-8,cx+7,cy+9),3,outline=color,width=2);d.line((cx-3,cy-3,cx+3,cy-3),fill=color,width=2)
 elif i==2:
  d.line((cx,cy-7,cx,cy+9),fill=color,width=2);d.arc((cx-9,cy-8,cx,cy+9),90,270,fill=color,width=2);d.arc((cx,cy-8,cx+9,cy+9),270,90,fill=color,width=2)
 elif i==3:
  d.line((cx,cy-9,cx,cy+9),fill=color,width=2);d.line((cx-9,cy,cx+9,cy),fill=color,width=2);d.line((cx-6,cy-6,cx+6,cy+6),fill=color,width=1);d.line((cx+6,cy-6,cx-6,cy+6),fill=color,width=1)
 else:
  d.rectangle((cx-8,cy-1,cx+8,cy+9),outline=color,width=2);d.line((cx-10,cy-2,cx-7,cy-8,cx+7,cy-8,cx+10,cy-2),fill=color,width=2)
def nav(d,active):
 entries=[('FERME',(98,228,255)),('CARTES',(111,168,255)),('ALBUMS',(255,211,106)),('FUSION',(185,131,255)),('MARCHÉ',(255,181,99))]
 rr(d,(14,804,486,886),24,(12,18,48,252),(90,80,150,130),1)
 for i,(tx,c) in enumerate(entries):
  x=21+i*92; act=i==active
  if act: rr(d,(x,812,x+86,878),15,(*tuple(int(v*.28) for v in c),245),(*c,190),1);d.rectangle((x+10,874,x+76,878),fill=(*c,255))
  icon_color=(*c,255) if act else (160,170,195,255);draw_nav_icon(d,i,x+43,828,icon_color);center(d,x+43,846,tx,ft(10),(255,255,255,255) if act else (160,170,195,255))
def chest(d,cx,cy):
 # glow
 for r,a in [(105,20),(78,28),(55,38)]: d.ellipse((cx-r,cy-r,cx+r,cy+r),fill=(122,86,255,a))
 rr(d,(cx-120,cy-20,cx+120,cy+92),20,(35,24,74,255),(164,126,255,255),4);rr(d,(cx-128,cy-72,cx+128,cy-10),18,(65,42,119,255),(220,194,255,255),4)
 for x in (cx-85,cx+85): rr(d,(x-10,cy-65,x+10,cy+84),5,(183,124,52,255),(255,221,151,255),2)
 pts=[(cx,cy-45),(cx+34,cy-8),(cx,cy+38),(cx-34,cy-8)];d.polygon(pts,fill=(118,92,255,255));d.line(pts+[pts[0]],fill=(235,222,255,255),width=4,joint='curve')
 center(d,cx,cy+55,'ORIGINE',ft(16),(244,239,255,255))
def art_thumb(path,size):
 im=Image.open(path).convert('RGB');im=ImageOps.fit(im,(size,size),Image.Resampling.LANCZOS);m=Image.new('L',(size,size),0);ImageDraw.Draw(m).rounded_rectangle((0,0,size-1,size-1),12,fill=255);out=Image.new('RGBA',(size,size));out.putalpha(0);out.paste(im,(0,0),m);return out

canvas=Image.new('RGB',(1500,1080),(4,6,18));d=ImageDraw.Draw(canvas,'RGBA');center(d,750,28,'INTERFACE MOBILE HD V6',ft(46),(247,249,255,255));center(d,750,82,'TYPOGRAPHIE NETTE · MENUS MODERNES · CONTRASTE RENFORCÉ',ft(16),(166,179,211,255))
# phone shadows
for x in (170,830):
 sh=Image.new('RGBA',canvas.size,(0,0,0,0));sd=ImageDraw.Draw(sh);sd.rounded_rectangle((x-12,132,x+512,1042),42,fill=(0,0,0,180));sh=sh.filter(ImageFilter.GaussianBlur(22));canvas=Image.alpha_composite(canvas.convert('RGBA'),sh)
# Phone 1 farm
p=phone_background((500,900));pd=ImageDraw.Draw(p,'RGBA');label(pd,(20,18),'FORGE',11,(98,228,255,255));label(pd,(20,34),'DES FAMILIERS',23,(247,249,255,255));stat(pd,272,'ESSENCE','200',(210,196,255));stat(pd,382,'CARTES','64',(98,228,255))
rr(pd,(14,88,486,792),28,(11,18,49,247),(104,88,180,120),1);chip(pd,(29,105,260,135),'SÉRIE 01 · CAISSE ORIGINE',(141,112,255));chip(pd,(370,105,470,135),'+1 / 10 SEC',(98,228,255))
rr(pd,(29,148,244,198),16,(17,28,58,250),(255,211,106,150),1);center(pd,136,157,'MISSIONS  ·  DU JOUR',ft(12),(255,225,145,255));rr(pd,(256,148,471,198),16,(15,35,49,250),(118,229,172,150),1);center(pd,363,157,'EXPÉDITIONS',ft(12),(145,242,188,255))
chest(pd,250,330);center(pd,250,445,'CAISSE ORIGINE · PETITE',ft(20),(247,249,255,255));center(pd,250,473,'6 cartes · 150 essences',ft(13),(170,180,205,255))
opts=[('PETITE','6 · 150'),('MOYENNE','15 · 330'),('GRANDE','25 · 500'),('TRÈS GRANDE','50 · 850')]
for i,(a,b) in enumerate(opts):
 x=29+(i%2)*224;y=510+(i//2)*66;sel=i==0;rr(pd,(x,y,x+212,y+56),15,(49,35,100,250) if sel else (18,26,62,245),(202,180,255,220) if sel else (80,89,125,120),2 if sel else 1);center(pd,x+106,y+8,a,ft(12),(247,249,255,255));center(pd,x+106,y+29,b,ft(11),(189,198,222,255))
rr(pd,(29,656,241,716),18,(14,39,61,250),(98,228,255,220),2);center(pd,135,668,'RÉCOLTER  +2',ft(14),(247,249,255,255));rr(pd,(253,656,471,716),18,(50,35,108,250),(163,130,255,230),2);center(pd,362,668,'OUVRIR 6 CARTES',ft(14),(247,249,255,255));center(pd,250,738,'Récolte disponible toutes les 10 secondes',ft(11),(170,180,205,255));nav(pd,0)
canvas.alpha_composite(p,(170,135))
# Phone 2 albums
p=phone_background((500,900));pd=ImageDraw.Draw(p,'RGBA');label(pd,(20,18),'FORGE',11,(98,228,255,255));label(pd,(20,34),'DES FAMILIERS',23,(247,249,255,255));stat(pd,272,'ESSENCE','850',(210,196,255));stat(pd,382,'CARTES','64',(98,228,255))
rr(pd,(14,88,486,792),28,(11,18,49,247),(104,88,180,120),1);label(pd,(30,108),'HABITATS & ALBUMS',23,(247,249,255,255));rr(pd,(354,101,470,155),17,(16,43,45,250),(118,229,172,170),1);center(pd,412,108,'POUSSIÈRES',ft(10),(170,180,205,255));center(pd,412,128,'2 650',ft(17),(118,229,172,255))
rr(pd,(29,172,471,216),14,(14,40,45,248),(118,229,172,120),1);center(pd,250,184,'BONUS D’EXPÉDITION ACTIF  +15 %',ft(12),(145,242,188,255));rr(pd,(29,230,471,282),16,(22,48,58,250),(118,229,172,190),2);center(pd,250,244,'INVOQUER UNE COMMUNE MANQUANTE  ·  100',ft(12),(247,249,255,255))
label(pd,(29,301),'HABITATS',16,(145,242,188,255));habs=[('FORÊT ÉVEILLÉE','10 / 10','+5 %',(85,217,130)),('ARCHIVE CHROMATIQUE','4 / 11','5 000 P',(220,231,241))]
for i,(n,prog,reward,c) in enumerate(habs):
 y=332+i*108;rr(pd,(29,y,471,y+96),17,(17,26,60,250),(*c,140),1);label(pd,(44,y+13),n,14,(*c,255));label(pd,(44,y+40),prog+' CRÉATURES',11,(170,180,205,255));pd.rounded_rectangle((44,y+67,355,y+76),5,fill=(20,29,60,255));fill=1 if i==0 else .36;pd.rounded_rectangle((44,y+67,44+int(311*fill),y+76),5,fill=(*c,220));rr(pd,(371,y+20,455,y+73),13,(22,39,70,250),(*c,170),1);center(pd,413,y+30,reward,ft(11),(247,249,255,255))
label(pd,(29,557),'ALBUMS',16,(255,211,106,255));# album row with thumbs
rr(pd,(29,588,471,743),17,(25,22,58,250),(255,190,90,130),1);label(pd,(44,602),'GENÈSE CHROMATIQUE',14,(255,220,150,255));label(pd,(44,627),'4 / 6 CARTES DÉCOUVERTES',11,(170,180,205,255))
paths=[ROOT/'assets/art/chroma_zero.png',ROOT/'assets/art/unique/prismara.webp',ROOT/'assets/art/unique/mercurel.webp',ROOT/'assets/art/unique/abyssalis.webp']
for i,path in enumerate(paths): p.alpha_composite(art_thumb(path,64),(44+i*74,656));rr(pd,(354,650,455,718),14,(44,32,86,250),(255,211,106,180),1);center(pd,404,660,'CONSULTER',ft(11),(247,249,255,255));center(pd,404,681,'LES CARTES',ft(10),(202,190,220,255));nav(pd,2)
canvas.alpha_composite(p,(830,135))
# captions
d=ImageDraw.Draw(canvas,'RGBA');center(d,420,1048,'ÉCRAN FERME',ft(15),(130,218,245,255));center(d,1080,1048,'ÉCRAN ALBUMS',ft(15),(255,215,125,255))
canvas.convert('RGB').save(ROOT/'apercu_interface_v6.png')
print(ROOT/'apercu_interface_v6.png')
