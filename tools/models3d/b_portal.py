from lib3d import *
b = Builder()
# ---- obsidian frame: 4 wide, 5 tall (hand-chiselled blocks, slight rotations)
BW, BH = .9, .9
import random; random.seed(2)
def blk(x, y, c="black", w=BW, h=BH, d=.55):
    b.box((w, h, d), (x, y, 0), c, base=True, rot=[("z", random.uniform(-1.6, 1.6))])
cols = ["black", "dark"]
# bottom + top rows
for i in range(6):
    x = -2.25 + i * BW
    blk(x, 0, cols[i % 2])
    blk(x, BH * 4, cols[(i + 1) % 2])
# sides
for j in range(1, 4):
    blk(-2.25, BH * j, cols[j % 2])
    blk(2.25, BH * j, cols[(j + 1) % 2])
# chiselled highlights
for i in range(14):
    x = random.uniform(-2.6, 2.6); y = random.uniform(.1, BH * 5 - .3)
    if abs(x) < 1.9 and BH < y < BH * 4: continue
    b.box((random.uniform(.15, .3), random.uniform(.1, .22), .6), (x, y, 0), "purple2",
          rot=[("z", random.uniform(-20, 20))])
# ---- glowing lapis-blue portal surface
b.box((3.6, BH * 3, .22), (0, BH, 0), "deepblue", base=True)
b.box((3.3, BH * 3 - .2, .3), (0, BH + .1, 0), "mosaic", base=True)
b.box((2.8, BH * 3 - .6, .36), (0, BH + .3, 0), "blue2", base=True)
for i in range(10):                              # swirling lighter motes
    x = random.uniform(-1.5, 1.5); y = random.uniform(BH + .3, BH * 4 - .4)
    b.ball(random.uniform(.08, .18), (x, y, random.choice([-.2, .2])), "blue", sub=0)
b.box((3.8, .16, .66), (0, BH - .08, 0), "mosaic")      # glow spill on frame
b.box((3.8, .16, .66), (0, BH * 4 - .06, 0), "mosaic")
b.box((.16, BH * 3, .66), (-1.85, BH, 0), "mosaic", base=True)
b.box((.16, BH * 3, .66), (1.85, BH, 0), "mosaic", base=True)
b.box((4.6, .1, 1.8), (0, .02, 0), "mosaic")            # light pooling on the ground
# ---- lever beside the portal
LX = 2.9
b.box((1.0, .3, 1.0), (LX, 0, .1), "grey4", base=True)
b.box((.3, 1.1, .3), (LX, .3, .1), "wood2", base=True)
b.box((.5, .3, .5), (LX, 1.4, .1), "grey3", base=True)
b.box((.12, .9, .12), (LX, 1.9, .35), "wood", rot=[("x", -26)])
b.ball(.16, (LX, 2.3, .62), "red2", sub=1)
b.cyl(.1, .36, (LX, 1.55, .1), "grey4", sections=8, axis="x")
# ---- obsidian step in front
b.box((4.4, .22, 1.0), (0, 0, 1.1), "dark", base=True)
b.box((4.0, .1, .8), (0, .22, 1.1), "black")
finish(b, "out/lapisovy_portal.glb", "LapisovyPortal")
