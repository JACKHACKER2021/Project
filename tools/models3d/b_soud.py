from lib3d import *
b = Builder()
W, D, H = 7.0, 5.0, 4.2
b.steps(5.6, 5, .2, .45, D / 2 + 1.2, color="stone2")
b.box((W + .6, 1.0, D + .6), (0, 0, 0), "stone2", base=True)      # podium
b.box((W, H, D), (0, 1.0, 0), "bone", base=True)                  # cella
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
b.box((2.0, 3.0, .3), (0, 1.0 + 1.5, D / 2 + .1), "wood2")
for s in (-1, 1):
    b.box((.08, 3.0, .34), (s * .5, 1.0 + 1.5, D / 2 + .12), "gold2")
b.box((2.4, .28, .45), (0, 1.0 + 3.14, D / 2 + .16), "stone")
for s in (-1, 1):
    b.window(1.0, 2.0, (s * 2.4, 1.0 + 1.8, D / 2 + .02), frame="stone")
for s, f in ((1, "x"), (-1, "-x")):
    for z in (-1.5, 0, 1.5):
        b.window(.9, 2.2, (s * W / 2, 1.0 + 2.0, z), frame="stone")
finish(b, "out/soud.glb", "Soud")
