from lib3d import *
import numpy as np
b = Builder()
N = 16
# ---- round basin: outer ring of stone blocks + rim + water
for i in range(N):
    a = 2 * np.pi * i / N; ang = np.degrees(a)
    x, z = np.cos(a) * 2.1, np.sin(a) * 2.1
    b.box((.45, .7, .55), (x, 0, z), "stone", base=True, rot=[("y", -ang)])
    b.box((.5, .14, .62), (x, .7, z), "stone2", rot=[("y", -ang)])
    if i % 2 == 0:                                   # blue mosaic inlay
        b.box((.42, .12, .1), (x * .9, .5, z * .9), "mosaic", rot=[("y", -ang)])
    else:
        b.box((.3, .1, .1), (x * .9, .32, z * .9), "blue2", rot=[("y", -ang)])
b.cyl(1.85, .35, (0, .0, 0), "mosaic", sections=N, base=True)   # basin floor
b.cyl(1.82, .06, (0, .5, 0), "water", sections=N)               # water surface
# ---- pedestal + statue
b.cyl(.8, .25, (0, .5, 0), "stone", sections=12, base=True)
b.cyl(.6, .5, (0, .75, 0), "stone2", sections=12, base=True)
for i in range(6):                                   # mosaic band
    a = 2 * np.pi * i / 6
    b.box((.3, .14, .08), (np.cos(a) * .58, 1.0, np.sin(a) * .58), "mosaic",
          rot=[("y", -np.degrees(a))])
b.cyl(.42, .35, (0, 1.25, 0), "stone", sections=10, base=True)
# stylised figure holding a jug
b.box((.5, .9, .35), (0, 1.6, 0), "stone2", base=True)           # robe/body
b.pyramid(.62, .45, .35, (0, 1.6, 0), "stone2")
b.ball(.22, (0, 2.62, 0), "stone", sub=1)                        # head
b.cyl(.26, .08, (0, 2.78, 0), "stone2", sections=8)
b.box((.14, .6, .14), (-.3, 2.2, .05), "stone2", rot=[("z", 28)])  # left arm down
b.box((.14, .55, .14), (.32, 2.35, .05), "stone2", rot=[("z", -42)])  # right arm up
b.cyl(.2, .3, (.62, 2.6, .05), "blue2", sections=8, base=True)   # jug
b.cyl(.1, .14, (.62, 2.9, .05), "blue2", sections=8)
# ---- water pouring from the jug into the basin
b.box((.14, 1.6, .14), (.72, 1.8, .08), "water", rot=[("z", -4)])
b.ball(.2, (.78, .62, .08), "water", sub=1)
for i in range(4):                                   # small side jets
    a = 2 * np.pi * i / 4 + .4
    x, z = np.cos(a) * .55, np.sin(a) * .55
    b.cyl(.07, .5, (x, 1.3, z), "water", sections=6, base=True)
    b.mesh([(x, 1.8, z), (x * 2.6, .6, z * 2.6), (x * 2.6 + .1, .6, z * 2.6 + .1)],
           [(0, 1, 2), (0, 2, 1)], "water")
# ---- benches around the fountain
for i in range(4):
    a = 2 * np.pi * i / 4 + np.pi / 4
    ang = np.degrees(a)
    cx, cz = np.cos(a) * 3.3, np.sin(a) * 3.3
    for s in (-.55, .55):
        dx, dz = -np.sin(a) * s, np.cos(a) * s
        b.box((.16, .45, .2), (cx + dx, 0, cz + dz), "stone", base=True)
    b.box((1.7, .14, .5), (cx, .52, cz), "wood", rot=[("y", -ang + 90)])
    b.box((1.7, .5, .12), (cx + np.cos(a) * .22, .78, cz + np.sin(a) * .22), "wood2",
          rot=[("y", -ang + 90)])
    for s in (-.55, .55):
        dx, dz = -np.sin(a) * s, np.cos(a) * s
        b.box((.12, .55, .14), (cx + dx + np.cos(a) * .22, .5, cz + dz + np.sin(a) * .22),
              "stone", base=True)
# ---- light stone paving ring
for i in range(N):
    a = 2 * np.pi * i / N
    b.box((.9, .08, .7), (np.cos(a) * 2.8, .04, np.sin(a) * 2.8), "stone2",
          rot=[("y", -np.degrees(a))])
finish(b, "out/kasna.glb", "Kasna")
