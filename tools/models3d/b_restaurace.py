from lib3d import *
b = Builder()
W, D, H = 6.0, 4.6, 3.2
b.box((W + .4, .3, D + .4), (0, 0, 0), "stone2", base=True)
b.box((W, H, D), (0, .3, 0), "cream", base=True)
b.box((W + .3, .25, D + .3), (0, .3 + H + .12, 0), "gold2")   # gilded cornice
b.box((W + .1, .12, D + .1), (0, 1.0, 0), "gold2")
TOP = .3 + H + .25
b.box((W + .2, .3, D + .2), (0, TOP, 0), "dark", base=True)    # flat roof parapet
b.box((W - .4, .25, D - .4), (0, TOP + .3, 0), "grey4", base=True)
b.box((1.0, .9, 1.0), (-1.8, TOP + .3, -1.2), "grey4", base=True)  # kitchen vent
b.cyl(.22, .5, (-1.8, TOP + 1.2, -1.2), "grey3", sections=8, base=True)
# ---- big windows with tables glimpsed inside
for x in (-2.0, 0, 2.0):
    b.box((1.6, 2.0, .1), (x, 1.65, D / 2 - .04), "glassdark")
    b.box((1.8, .2, .3), (x, 2.72, D / 2 + .08), "gold2")
    b.box((1.8, .2, .3), (x, .6, D / 2 + .08), "gold2")
    for s in (-1, 1):
        b.box((.16, 2.3, .3), (x + s * .88, 1.65, D / 2 + .08), "gold2")
    # table + two chairs behind the glass
    b.cyl(.06, .7, (x, .75, D / 2 - .55), "dark", sections=6, base=True)
    b.cyl(.36, .07, (x, 1.45, D / 2 - .55), "white", sections=10)
    b.cyl(.1, .09, (x, 1.52, D / 2 - .55), "red", sections=8)
    b.box((.04, .22, .04), (x + .12, 1.6, D / 2 - .55), "gold")
    for s in (-1, 1):
        b.box((.3, .06, .3), (x + s * .55, 1.1, D / 2 - .55), "red2")
        b.box((.3, .5, .06), (x + s * .55, 1.35, D / 2 - .7), "red2")
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
b.box((2.2, 2.4, .25), (0, .6 + 1.2, DZ + .08), "darkwood")
for s in (-1, 1):
    b.box((.95, 2.2, .14), (s * .54, .6 + 1.15, DZ + .18), "glassdark")
    b.box((.06, 1.0, .18), (s * .54, .6 + 1.1, DZ + .24), "gold")
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
finish(b, "out/restaurace_zlata_vidlicka.glb", "RestauraceZlataVidlicka")
