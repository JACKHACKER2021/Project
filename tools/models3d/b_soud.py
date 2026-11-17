from lib3d import *
b = Builder()
W, D, H = 7.0, 5.0, 4.2
b.steps(5.6, 5, .2, .45, D / 2 + 1.2, color="stone2")
b.box((W + .6, 1.0, D + .6), (0, 0, 0), "stone2", base=True)      # podium
T = .3
b.shell(W, D, H, 1.0, T, "bone", holes={                      # hollow cella
    "front": [(0, 2.0, 0, 3.0)] + [(x, 1.0, .8, 2.0) for x in (-2.4, 2.4)],
    "left":  [(z, .9, .9, 2.2) for z in (-1.5, 0, 1.5)],
    "right": [(z, .9, .9, 2.2) for z in (-1.5, 0, 1.5)],
    "back":  [(0, 1.0, .9, 2.0)]})
b.box((W - T * 2, .12, D - T * 2), (0, 1.06, 0), "stone2")    # courtroom floor
b.box((W - T * 2, .18, D - T * 2), (0, 1.0 + H - .09, 0), "bone")   # ceiling
b.box((W + .3, .3, D + .3), (0, 1.0 + H + .15, 0), "stone")       # cornice
# ---- portico: 6 fluted columns
PZ = D / 2 + 1.0
for x in (-2.75, -1.65, -.55, .55, 1.65, 2.75):
    b.cyl(.22, .25, (x, 1.0, PZ), "stone", sections=10, base=True)       # base
    b.cyl(.19, H - .9, (x, 1.25, PZ), "bone", sections=10, base=True)    # shaft
    b.cyl(.24, .22, (x, 1.0 + H - .55, PZ), "stone", sections=10, base=True)
b.box((6.6, .5, 2.6), (0, 1.0 + H - .08, PZ - .3), "stone")       # architrave
b.box((6.9, .3, 2.9), (0, 1.0 + H + .35, PZ - .3), "stone2")
# ---- triangular pediment over the entrance
PY = 1.0 + H + .5
for s, zz in ((1, PZ - 1.75), (-1, PZ + 1.15)):
    b.mesh([(-3.45, PY, zz), (3.45, PY, zz), (0, PY + 1.5, zz)],
           [(0, 1, 2)] if s > 0 else [(0, 2, 1)], "bone")
b.mesh([(-3.45, PY, PZ - 1.75), (0, PY + 1.5, PZ - 1.75), (0, PY + 1.5, PZ + 1.15),
        (-3.45, PY, PZ + 1.15)], [(0, 1, 2), (0, 2, 3)], "stone")
b.mesh([(3.45, PY, PZ - 1.75), (3.45, PY, PZ + 1.15), (0, PY + 1.5, PZ + 1.15),
        (0, PY + 1.5, PZ - 1.75)], [(0, 1, 2), (0, 2, 3)], "stone")
b.ball(.42, (0, PY + .55, PZ + 1.18), "stone2", sub=1)            # relief medallion
# ---- "SOUD" inscription on the frieze (blocky letters)
def seg(w, h, x, y):
    b.box((w, h, .09), (x, y, PZ + 1.49), "dark")
LY = PY - .22; o = -1.45
# S
seg(.5, .09, o, LY + .22); seg(.09, .18, o - .2, LY + .13); seg(.5, .09, o, LY)
seg(.09, .18, o + .2, LY - .13); seg(.5, .09, o, LY - .22)
# O
o += .95
seg(.5, .09, o, LY + .22); seg(.5, .09, o, LY - .22)
seg(.09, .45, o - .2, LY); seg(.09, .45, o + .2, LY)
# U
o += .95
seg(.09, .45, o - .2, LY + .03); seg(.09, .45, o + .2, LY + .03); seg(.5, .09, o, LY - .22)
# D
o += .95
seg(.09, .53, o - .2, LY); seg(.42, .09, o + .02, LY + .22); seg(.42, .09, o + .02, LY - .22)
seg(.09, .36, o + .2, LY)
# ---- tall doorway + side windows
for s in (-1, 1):                              # tall doors standing open
    b.box((.95, 3.0, .12), (s * 1.4, 1.0 + 1.5, D / 2 - .5), "wood2",
          rot=[("y", s * 65)])
    b.box((.08, 2.4, .14), (s * 1.6, 1.0 + 1.5, D / 2 - .7), "gold2", rot=[("y", s * 65)])
b.box((2.4, .28, .45), (0, 1.0 + 3.14, D / 2 + .16), "stone")
for s in (-1, 1):
    b.window(1.0, 2.0, (s * 2.4, 1.0 + 1.8, D / 2 + .02), frame="stone")
for s, f in ((1, "x"), (-1, "-x")):
    for z in (-1.5, 0, 1.5):
        b.window(.9, 2.2, (s * W / 2, 1.0 + 2.0, z), frame="stone")
# ---------------- interior: courtroom ---------------------------------------
IY = 1.12
b.box((W - T * 2, .04, D - T * 2), (0, IY + .02, 0), "wood")          # parquet
for i in range(6):
    b.box((W - T * 2, .02, .08), (0, IY + .05, -2.0 + i * .8), "wood2")
# judge's bench on a dais at the back
b.box((4.2, .35, 1.6), (0, IY, -1.5), "stone2", base=True)
b.box((3.4, 1.0, .7), (0, IY + .35, -1.6), "wood2", base=True)
b.box((3.6, .12, .9), (0, IY + 1.42, -1.6), "wood")
b.chair((0, IY + .35, -2.0), ang=180, seat="red2", back="wood2")
b.box((1.0, 1.6, .1), (0, IY + 2.0, -D / 2 + T + .12), "gold2")      # emblem panel
b.ball(.22, (0, IY + 2.6, -D / 2 + T + .2), "gold")
# clerk's desk and witness stand
b.table((-1.9, IY, -.5), w=1.3, d=.7, h=.72, top="wood", leg="wood2")
b.chair((-1.9, IY, -.1), ang=180)
b.box((1.0, 1.1, .9), (2.0, IY, -.6), "wood2", base=True)
b.box((1.2, .1, 1.0), (2.0, IY + 1.12, -.6), "wood")
b.chair((2.0, IY, -1.0), ang=180)
# public benches with a central aisle
for i in range(4):
    z = .4 + i * .9
    for s in (-1, 1):
        b.box((2.4, .45, .45), (s * 1.6, IY, z), "wood2", base=True)
        b.box((2.5, .1, .5), (s * 1.6, IY + .5, z), "wood")
        b.box((2.5, .55, .1), (s * 1.6, IY + .78, z - .22), "wood")
b.box((1.1, .03, 3.8), (0, IY + .06, 1.3), "red2")                    # aisle carpet
# low rail separating court from public
b.wall("x", (.0, 0), W - T * 2, .9, IY, .1, "wood2", holes=[(0, 1.1, 0, .9)])
for x in (-2.6, -1.0, 1.0, 2.6):
    b.box((.1, 1.0, .14), (x, IY + .5, 0), "wood")
finish(b, "out/soud.glb", "Soud")
