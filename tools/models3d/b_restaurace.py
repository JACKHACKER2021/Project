from lib3d import *
import numpy as np
b = Builder()
W, D, H = 6.0, 4.6, 3.2
b.box((W + .4, .3, D + .4), (0, 0, 0), "stone2", base=True)
T = .26
FY = .62
b.shell(W, D, H, .3, T, "cream", holes={
    "front": [(0, 2.2, FY - .3, 2.4)] + [(x, 1.6, .35, 2.0) for x in (-2.0, 0, 2.0)],
    "left":  [(-1.2, 1.0, .8, 1.4)],
    "right": [(-1.2, 1.0, .8, 1.4)],
    "back":  [(1.4, 1.1, FY - .3, 2.1)]})
b.box((W - T * 2, FY - .3, D - T * 2), (0, .3 + (FY - .3) / 2, 0), "stone2")
b.box((W - T * 2, .05, D - T * 2), (0, FY + .02, 0), "darkwood")
b.box((W - T * 2, .16, D - T * 2), (0, .3 + H - .08, 0), "cream")
b.box((W + .3, .25, D + .3), (0, .3 + H + .12, 0), "gold2")   # gilded cornice
b.box((W + .1, .12, D + .1), (0, 1.0, 0), "gold2")
TOP = .3 + H + .25
b.box((W + .2, .3, D + .2), (0, TOP, 0), "dark", base=True)    # flat roof parapet
b.box((W - .4, .25, D - .4), (0, TOP + .3, 0), "grey4", base=True)
b.box((1.0, .9, 1.0), (-1.8, TOP + .3, -1.2), "grey4", base=True)  # kitchen vent
b.cyl(.22, .5, (-1.8, TOP + 1.2, -1.2), "grey3", sections=8, base=True)
# ---- big windows with tables glimpsed inside
for x in (-2.0, 0, 2.0):
    b.box((1.6, 2.0, .08), (x, 1.65, D / 2 - .14), "glassdark")
    b.box((1.8, .2, .3), (x, 2.72, D / 2 + .08), "gold2")
    b.box((1.8, .2, .3), (x, .6, D / 2 + .08), "gold2")
    for s in (-1, 1):
        b.box((.16, 2.3, .3), (x + s * .88, 1.65, D / 2 + .08), "gold2")

# faint greenish kitchen glow spilling from the left side
for s, f in ((1, "x"), (-1, "-x")):
    b.window(1.0, 1.4, (s * W / 2, 1.8, -1.2),
             color="mint" if s < 0 else "glassdark", frame="gold2", facing=f)
b.box((2.4, .9, .08), (-W / 2 - .04, .9, -1.0), "mint")     # glow patch low on wall
b.box((1.8, .1, 1.4), (-W / 2 - .9, .06, -1.0), "mint")     # light pooling on ground
# ---- entrance: steps, revolving-style double door, red carpet
b.steps(3.2, 3, .2, .45, D / 2 + .02, color="stone")
b.box((2.0, .04, 1.6), (0, .62, D / 2 + .85), "red2")
DZ = D / 2
for s in (-1, 1):                       # doors standing open
    b.box((1.0, 2.3, .12), (s * 1.55, FY + 1.15, DZ - .55), "darkwood",
          rot=[("y", s * 60)])
    b.box((.06, 1.0, .16), (s * 1.75, FY + 1.1, DZ - .72), "gold", rot=[("y", s * 60)])
b.box((2.6, .3, .5), (0, .6 + 2.5, DZ + .16), "gold2")
for s in (-1, 1):                                            # lamps by the door
    b.box((.1, 1.2, .1), (s * 1.45, .6 + .6, DZ + .3), "dark", base=False)
    b.ball(.15, (s * 1.45, .6 + 1.3, DZ + .3), "mint", sub=1)
# ---- big golden fork sign above the entrance
SY = .6 + 3.3; SZ = DZ + .45
b.box((2.8, 1.0, .12), (0, SY, SZ - .08), "dark")            # sign board
b.box((3.0, .1, .18), (0, SY + .55, SZ - .06), "gold2")
b.box((3.0, .1, .18), (0, SY - .55, SZ - .06), "gold2")
b.box((.16, 1.6, .16), (0, SY - .25, SZ + .12), "gold")      # fork handle
b.box((.5, .3, .16), (0, SY + .62, SZ + .12), "gold")        # fork base
for i in range(4):                                           # tines
    b.box((.1, .75, .14), (-.21 + i * .14, SY + 1.1, SZ + .12), "gold")
b.ball(.09, (0, SY - 1.08, SZ + .14), "gold2")
for s in (-1, 1):
    b.box((.08, .08, .55), (s * 1.3, SY + .5, SZ - .3), "gold2", rot=[("x", 35)])
# ---------------- interior: dining room, bar, kitchen door -------------------
IY = FY
for i in range(6):                                   # chequered floor accent
    b.box((5.4, .03, .5), (0, IY + .05, -1.8 + i * .75), "dark" if i % 2 else "stone2")
def seat(x, z):
    b.cyl(.07, .72, (x, IY, z), "dark", sections=6, base=True)
    b.cyl(.14, .06, (x, IY + .02, z), "grey4", sections=8)
    b.cyl(.42, .08, (x, IY + .74, z), "white", sections=10)
    b.cyl(.1, .1, (x, IY + .82, z), "red", sections=8)                # little vase
    b.box((.04, .2, .04), (x + .1, IY + .95, z), "gold")
    for s in (-1, 1):
        b.chair((x + s * .62, IY, z), ang=90 - 90 * s, seat="red2", back="darkwood")
for x in (-1.9, 0, 1.9):
    seat(x, 1.0)
for x in (-1.4, 1.4):
    seat(x, -.6)
# bar counter along the left wall
b.box((.8, 1.1, 3.0), (-W / 2 + T + .5, IY, -.4), "darkwood", base=True)
b.box((1.0, .1, 3.2), (-W / 2 + T + .5, IY + 1.14, -.4), "gold2")
for i in range(4):                                   # bottles on a back shelf
    b.cyl(.08, .3, (-W / 2 + T + .16, IY + 1.5, -1.4 + i * .6),
          ["mint", "gold", "red", "teal"][i], sections=8, base=True)
b.box((.3, .08, 3.0), (-W / 2 + T + .16, IY + 1.45, -.4), "gold2")
for i in range(3):                                   # bar stools
    b.cyl(.06, .75, (-W / 2 + T + 1.15, IY, -1.2 + i * .9), "gold2", sections=6, base=True)
    b.cyl(.22, .1, (-W / 2 + T + 1.15, IY + .78, -1.2 + i * .9), "red2", sections=8)
# kitchen doorway at the back, greenish light spilling out
b.wall("x", (-D / 2 + T + 1.0, 0), W - T * 2, H - .2, IY, .16, "cream",
       holes=[(1.4, 1.2, 0, 2.1)])
b.box((1.2, 2.1, .1), (1.4, IY + 1.05, -D / 2 + T + 1.06), "mint")
b.box((1.1, 1.9, .08), (2.2, IY + .95, -D / 2 + T + 1.5), "grey4", rot=[("y", 52)])
b.box((2.4, .04, 1.6), (1.4, IY + .07, -.4), "mint")                  # light on floor
b.box((1.6, 1.0, .5), (-1.2, IY, -D / 2 + T + 1.4), "grey3", base=True)  # pass counter
b.box((1.8, .1, .6), (-1.2, IY + 1.02, -D / 2 + T + 1.4), "grey4")
for i in range(2):
    b.cyl(.2, .08, (-1.5 + i * .6, IY + 1.1, -D / 2 + T + 1.4), "white", sections=8)
# chandelier
b.cyl(.06, .6, (0, IY + 2.3, .2), "gold2", sections=6, base=True)
b.cyl(.45, .14, (0, IY + 2.24, .2), "gold", sections=10)
for i in range(4):
    a = 1.57 * i
    b.ball(.1, (np.cos(a) * .4, IY + 2.2, .2 + np.sin(a) * .4), "candle", sub=0)
finish(b, "out/restaurace_zlata_vidlicka.glb", "RestauraceZlataVidlicka")
