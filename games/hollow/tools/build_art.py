"""Deterministic high-detail pixel masonry and isometric room source art."""
from PIL import Image,ImageDraw
import numpy as np,random,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
W,H=1760,1200
ORIGIN=(790,300)
def iso(x,y,z=0):return(round(790+(x-y)*.8),round(300+(x+y)*.4-z))
def tint(c,n):return tuple(max(0,min(255,v+n)) for v in c)
def poly(d,pts,c):d.polygon(pts,fill=c)
def tile(d,x,y,x2,y2,c):poly(d,[iso(x,y),iso(x2,y),iso(x2,y2),iso(x,y2)],c)
def face(d,side,a,b,z1,z2,c):
 def p(q,z):return iso(0,q,z) if side=='left' else iso(q,0,z)
 poly(d,[p(a,z1),p(b,z1),p(b,z2),p(a,z2)],c)
def wall(d,side,end,r):
 base=(79,80,101) if side=='left' else (93,88,106)
 face(d,side,0,end,0,228,(30,35,52))
 unit=68
 for row in range(9):
  z=row*25
  for pos in range(-unit,int(end)+unit,unit):
   a=max(0,pos+(unit//2 if row%2 else 0));b=min(end,pos+unit-2+(unit//2 if row%2 else 0))
   if a>=b:continue
   c=tint(base,r.randrange(-12,13));face(d,side,a,b,z+2,z+24,c)
   face(d,side,a+1,b-1,z+22,z+24,tint(c,22));face(d,side,a,b,z+2,z+4,tint(c,-20))
   for i in range(15):
    q=r.uniform(a,b);zz=r.uniform(z+4,z+21)
    xx,yy=iso(0,q,zz) if side=='left' else iso(q,0,zz)
    d.line((xx,yy,xx+r.randrange(1,4),yy),fill=tint(c,r.choice([-17,-9,11,18])))
   if r.random()<.35:
    q=(a+b)/2;zz=z+18
    pts=[iso(0,q,zz),iso(0,q+4,zz-6),iso(0,q+1,zz-12)] if side=='left' else [iso(q,0,zz),iso(q+4,0,zz-6),iso(q+1,0,zz-12)]
    d.line(pts,fill=tint(c,-26))
 # Damp staining sinks down from the joints.
 for i in range(100):
  q=r.uniform(0,end);z=r.uniform(10,205);xx,yy=iso(0,q,z) if side=='left' else iso(q,0,z)
  d.line((xx,yy,xx,yy+r.randrange(5,20)),fill=r.choice(['#3b4957','#3e4859','#4d5365']))
 for z1,z2,c in [(0,8,'#343d54'),(8,14,'#777a8c'),(212,218,'#353e56'),(218,228,'#767488'),(228,233,'#aaa0ad')]:face(d,side,0,end,z1,z2,c)
 # Rounded ribs / engaged piers create architectural depth.
 for q in ([0,255,550,800] if side=='left' else [0,300,650,960]):
  a=max(0,q-14);b=min(end,q+14)
  face(d,side,a,b,10,216,'#727488' if side=='right' else '#565f77')
  face(d,side,a+3,min(b,a+8),10,216,'#9190a0')
  for z in range(18,214,29):face(d,side,a,b,z,z+2,'#384158')
  face(d,side,max(0,a-6),min(end,b+6),202,214,'#93909f')
  face(d,side,max(0,a-6),min(end,b+6),12,25,'#686d84')

def arch(d,side,a,b,window=False):
 def p(q,z):return iso(0,q,z) if side=='left' else iso(q,0,z)
 mid=(a+b)/2;half=(b-a)/2;base=25 if window else 0;top=175 if window else 145
 path=[p(a,base),p(a,top-43)]
 for i in range(25):
  ang=math.pi-math.pi*i/24;path.append(p(mid+half*math.cos(ang),top-43+43*math.sin(ang)))
 path.append(p(b,base))
 poly(d,path,'#5c739d' if window else '#111827')
 d.line(path[1:-1],fill='#9692a4',width=8)
 d.line([p(a,base),p(a,top-43)],fill='#828599',width=6);d.line([p(b,base),p(b,top-43)],fill='#4d5970',width=7)
 # Keystone seams and chipped highlights around the arch ring.
 for i in range(1,12):
  ang=math.pi-math.pi*i/12
  pa=p(mid+half*math.cos(ang),top-43+43*math.sin(ang));pb=p(mid+(half+7)*math.cos(ang),top-43+50*math.sin(ang))
  d.line([pa,pb],fill='#353e52',width=2)
 if window:
  for q in np.linspace(a+8,b-8,5):d.line([p(q,base),p(q,top-33)],fill='#27354f',width=3)
  for z in [64,100]:d.line([p(a,z),p(b,z)],fill='#29344b',width=4)
  d.line([p(a,base),p(b,base)],fill='#a1a7bd',width=4)
 else:
  # Faint recessed sidewall catches reflected light.
  d.line([p(a+6,base),p(a+6,top-46)],fill='#252c41',width=2)
  d.line([p(a,base),p(b,base)],fill='#9994a4',width=3)

for room in [1,2]:
 r=random.Random(360+room)
 im=Image.new('RGB',(W,H),'#101524');d=ImageDraw.Draw(im)
 # Floor foundation and layered dropoff.
 poly(d,[iso(0,800),iso(960,800),iso(960,800,-28),iso(0,800,-28)],'#293046')
 poly(d,[iso(960,0),iso(960,800),iso(960,800,-28),iso(960,0,-28)],'#222a3e')
 for x in range(0,961,40):d.line([iso(x,800),iso(x,800,-27)],fill='#1c2437')
 for y in range(0,801,40):d.line([iso(960,y),iso(960,y,-27)],fill='#192135')
 # Hand-weathered slate. Each tile has distinct bevels, inclusions and fissures.
 for yy in range(0,800,40):
  for xx in range(0,960,48):
   c=tint((73,79,95),r.randrange(-10,14))
   tile(d,xx,yy,xx+48,yy+40,c)
   d.line([iso(xx,yy+40),iso(xx,yy),iso(xx+48,yy)],fill=tint(c,21),width=2)
   d.line([iso(xx+48,yy),iso(xx+48,yy+40),iso(xx,yy+40)],fill=tint(c,-22),width=2)
   for i in range(32):
    x=r.uniform(xx+4,xx+44);y=r.uniform(yy+4,yy+36);px,py=iso(x,y)
    d.point((px,py),fill=tint(c,r.randrange(-18,20)))
    if i%4==0:d.line([iso(x,y),iso(x+3,y+1)],fill=tint(c,-12))
   if r.random()<.36:
    x=xx+r.uniform(9,28);y=yy+r.uniform(5,15)
    d.line([iso(x,y),iso(x+6,y+9),iso(x+3,y+17),iso(x+14,y+23)],fill=tint(c,-29),width=1)
    d.line([iso(x+1,y),iso(x+7,y+9),iso(x+4,y+17)],fill=tint(c,10),width=1)
 # Geometric worn floor border.
 for inset,col in [(18,'#777989'),(23,'#373f55'),(28,'#92909b'),(32,'#424a60')]:
  d.line([iso(inset,inset),iso(960-inset,inset),iso(960-inset,800-inset),iso(inset,800-inset),iso(inset,inset)],fill=col,width=2)
 # Fine floor grain is quantized to keep readable pixels.
 arr=np.array(im);nr=np.random.default_rng(100+room)
 noise=nr.integers(-3,4,(H,W,1));arr=np.clip(arr.astype('int16')+noise,0,255).astype('uint8');im=Image.fromarray(arr);d=ImageDraw.Draw(im)
 # Large stone mosaic, subtly visible through wear.
 if room!=1:
  cx,cy=480,430
  for rad,col in [(170,'#3b4359'),(166,'#80818f'),(155,'#40475e'),(140,'#62687a'),(137,'#454c62')]:
   pts=[iso(cx+rad*math.cos(a),cy+rad*math.sin(a)) for a in np.linspace(0,2*math.pi,100)]
   d.line(pts,fill=col,width=2)
  for angle in np.linspace(0,2*math.pi,17)[:-1]:
   d.line([iso(cx+142*math.cos(angle),cy+142*math.sin(angle)),iso(cx+164*math.cos(angle),cy+164*math.sin(angle))],fill='#747887',width=2)
  star=[iso(cx+(100 if i%2==0 else 42)*math.cos(i*math.pi/4),cy+(100 if i%2==0 else 42)*math.sin(i*math.pi/4)) for i in range(8)]
  d.line(star+[star[0]],fill='#7c7e8c',width=2)
 # Wet patches with small edge reflections.
 for k in range(18):
  cx=r.uniform(70,900);cy=r.uniform(70,750);rad=r.uniform(12,37)
  pts=[iso(cx+rad*r.uniform(.6,1)*math.cos(a),cy+rad*r.uniform(.6,1)*math.sin(a)) for a in np.linspace(0,2*math.pi,18)]
  poly(d,pts,r.choice(['#293b4e','#354353','#2c3c50']))
 # Deep soft, baked ambient contact shading under the tall masonry.
 for width,col in [(27,'#30394f'),(18,'#252f46'),(9,'#1b253b')]:
  tile(d,0,0,960,width,col);tile(d,0,0,width,800,col)
 wall(d,'left',800,r);wall(d,'right',960,r)
 arch(d,'left',95,185);arch(d,'left',615,710)
 arch(d,'right',100,220);arch(d,'right',745,870)
 if room==1:
  arch(d,'left',350,470);arch(d,'right',430,530)
  for i in range(5):tile(d,430,i*8,530,i*8+7,'#767887' if i%2==0 else '#464e64')
 else:
  arch(d,'right',395,545,True)
 if room==1:
  # Cistern basin, deeply recessed with an inset stone rim.
  tile(d,315,270,650,580,'#91909d');tile(d,322,277,643,573,'#454d67');tile(d,331,286,634,564,'#162c40')
  d.line([iso(315,580),iso(650,580),iso(650,270)],fill='#b2a9ae',width=3)
  # Drain outlets and rust stains on the back wall.
  for y in [320,490]:
   px,py=iso(0,y,30);d.ellipse((px-8,py-10,px+8,py+10),fill='#111a2a',outline='#726d79',width=3)
 # Front cutaway trim leaves the traversable thresholds clearly visible.
 segments=[(0,440),(520,960)] if room==2 else [(0,960)]
 for a,b in segments:d.line([iso(a,800),iso(b,800)],fill='#8c8d9c',width=3)
 segments=[(0,360),(460,800)] if room==0 else [(0,800)]
 for a,b in segments:d.line([iso(960,a),iso(960,b)],fill='#6f7c91',width=3)
 if room==0:
  for k in range(5):tile(d,960+k*9,360,969+k*9,460,'#6b7185' if k%2==0 else '#3e4960')
 if room==2:
  for k in range(5):tile(d,440,800+k*9,520,809+k*9,'#6b7185' if k%2==0 else '#3e4960')
 # Moss in mortar joints, scattered stone chips, tiny signs of decay.
 for i in range(650):
  x=r.uniform(15,945);y=r.choice([r.uniform(12,45),r.uniform(760,788)])
  px,py=iso(x,y);d.rectangle((px,py,px+r.randrange(1,4),py+1),fill=r.choice(['#3e5b56','#465b60','#53635f','#63756a']))
 for i in range(90):
  x=r.uniform(45,915);y=r.uniform(50,750);px,py=iso(x,y)
  d.polygon([(px,py),(px+3,py-2),(px+6,py),(px+2,py+2)],fill='#858493');d.line((px,py+2,px+5,py+1),fill='#2a344b')
 # Limited but nuanced palette; no blurred upscaling.
 im.quantize(colors=112,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).save(ROOT/'assets'/('room%d.png'%room),optimize=True)

