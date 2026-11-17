from lib3d import *
b = Builder()
W, D, H = 4.4, 3.8, 2.4
b.box((W + .4, .3, D + .4), (0, 0, 0), "mud2", base=True)
# two crooked storeys of mud brick, the upper one jutting out and tilted
T = .26
b.shell(W, D, H, .3, T, "mud", holes={
    "front": [(0, 1.0, 0, 2.0), (-1.2, .8, .7, 1.0), (1.2, .8, .6, 1.0)],
    "left":  [(-.9, .7, .75, .9)],
    "right": [(-.9, .7, .75, .9)]})
b.shell(W + .5, D + .4, H - .3, .3 + H, T, "mud", holes={
    "front": [(-1.0, .75, .75, .9), (1.3, .75, .85, .9)],
    "left":  [(0, .7, .8, .9)]})
b.box((W - T * 2, .3, D - T * 2), (0, .45, 0), "mud2")            # ground floor
b.box((W + .5 - T * 2, .2, D + .4 - T * 2), (0, .3 + H - .1, 0), "wood2")  # 1st slab
b.box((W + .1, .18, D + .1), (0, .3 + H + .09, 0), "wood2")
Y2 = .3 + H; TOP = Y2 + H - .3
for y in (.9, 1.7, Y2 + .8, Y2 + 1.6):                      # brick courses
    b.box((W + .55, .08, D + .45), (.06, y, 0), "mud2")
# ---- steep crooked roof + attic gable
b.gable(W + .7, D + .6, 2.0, (0, TOP, 0), "purple2", ridge_along="x", over=.3)
b.box((W + 1.4, .14, .3), (0, TOP + .06, D / 2 + .45), "wood2")
b.mesh([(-2.6, TOP, D / 2 + .5), (2.6, TOP, D / 2 + .5), (0, TOP + 2.0, D / 2 + .5)],
       [(0, 1, 2)], "mud")
# round attic window
b.cyl(.46, .14, (0, TOP + .75, D / 2 + .54), "wood2", sections=12, axis="z")
b.cyl(.37, .16, (0, TOP + .75, D / 2 + .56), "candle", sections=12, axis="z")
b.box((.72, .07, .1), (0, TOP + .75, D / 2 + .64), "wood2")
b.box((.07, .72, .1), (0, TOP + .75, D / 2 + .64), "wood2")
# ---- chimney with purple smoke
b.box((.7, 1.8, .7), (-1.4, TOP + .6, -.6), "mud2", base=True, rot=[("z", 4)])
b.box((.85, .2, .85), (-1.5, TOP + 2.4, -.6), "mud2")
for i, (r, dy, dx) in enumerate([(.3, .35, .05), (.38, .85, .22), (.3, 1.4, .5),
                                 (.24, 1.85, .82)]):
    b.ball(r, (-1.5 + dx, TOP + 2.5 + dy, -.6 + dx * .3),
           "purple" if i % 2 == 0 else "lilac", sub=1)
# ---- crooked shutters + windows with herbs and potions
def win(x, y, z, w=.8, h=1.0, tilt=6, facing="z"):
    b.window(w, h, (x, y, z), color="candle", frame="wood2", facing=facing)
    for s in (-1, 1):
        if facing == "z":
            b.box((.3, h + .1, .07), (x + s * (w / 2 + .17), y, z + .1), "purple2",
                  rot=[("z", s * tilt)])
            for k in range(3):
                b.box((.26, .05, .09), (x + s * (w / 2 + .17), y - .3 + k * .3, z + .13),
                      "lilac", rot=[("z", s * tilt)])
    # herb pots on the sill
    if facing == "z":
        b.box((w + .3, .1, .3), (x, y - h / 2 - .06, z + .15), "wood2")
        for k in (-1, 1):
            b.cyl(.1, .16, (x + k * .22, y - h / 2, z + .2), "rust", sections=8, base=True)
            b.ball(.13, (x + k * .22, y - h / 2 + .24, z + .2), "green2", sub=1)
            b.box((.04, .18, .04), (x + k * .22 + .06, y - h / 2 + .3, z + .2), "green",
                  rot=[("z", 18)])
win(-1.2, 1.5, D / 2, tilt=7)
win(1.2, 1.4, D / 2, tilt=-5)
win(-1.0, Y2 + 1.2, D / 2 + .22, .75, .9, 8)
win(1.3, Y2 + 1.3, D / 2 + .22, .75, .9, -6)
for s, f in ((1, "x"), (-1, "-x")):
    b.window(.7, .9, (s * (W / 2), 1.5, -.9), color="candle", frame="wood2",
             facing=f if s > 0 else "-x")
# potion bottles in the lower windows
for (x, c) in ((-1.45, "mint"), (-1.0, "lol"), (1.0, "teal"), (1.45, "purple")):
    b.cyl(.07, .22, (x, 1.06, D / 2 + .2), c, sections=8, base=True)
    b.box((.04, .06, .04), (x, 1.3, D / 2 + .2), "cream")
# ---- crooked door
b.box((1.0, 2.0, .12), (-.78, 1.3, D / 2 - .42), "darkwood",       # door, ajar
      rot=[("y", 58), ("z", 2)])
b.ball(.08, (-1.2, 1.3, D / 2 - .72), "gold2")
b.box((1.5, .16, .5), (0, 2.1, D / 2 + .2), "purple2")
b.box((1.4, .25, .6), (0, .12, D / 2 + .25), "stone2")     # doorstep
# ---- overgrown little garden out front
import random; random.seed(3)
for i in range(26):
    a = random.uniform(0, 6.28); r = random.uniform(1.9, 3.4)
    x, z = np.cos(a) * r, abs(np.sin(a)) * r + 1.0
    if z < D / 2 + .4 and abs(x) < W / 2: continue
    h = random.uniform(.25, .7)
    b.box((.1, h, .1), (x, h / 2, z), random.choice(["green2", "moss", "green"]),
          rot=[("z", random.uniform(-25, 25)), ("y", random.uniform(0, 90))])
    if i % 3 == 0:
        b.ball(.12, (x, h + .05, z), random.choice(["lol", "purple", "yellow"]), sub=0)
for i in range(9):                                          # leaning garden fence
    x = -2.9 + i * .72
    b.box((.08, .6, .08), (x, .3, 3.5), "wood2", rot=[("z", random.uniform(-12, 12))])
b.box((5.8, .07, .07), (0, .48, 3.5), "wood2")
# ---------------- interior: workshop, cauldron, attic ------------------------
IY = .6
b.box((W - T * 2, .05, D - T * 2), (0, IY + .02, 0), "wood2")
# bubbling cauldron over a fire
b.cyl(.55, .5, (-1.1, IY + .25, -.7), "grey4", sections=10, base=True)
b.cyl(.58, .12, (-1.1, IY + .75, -.7), "dark", sections=10)
b.cyl(.5, .1, (-1.1, IY + .72, -.7), "mint", sections=10)
for i in range(3):
    b.ball(.12 + i * .03, (-1.1 + i * .12, IY + .9 + i * .22, -.7),
           "lilac" if i % 2 else "mint", sub=0)
for sx in (-1, 1):
    b.box((.08, .55, .08), (-1.1 + sx * .5, IY + .27, -.7 + sx * .3), "grey4")
b.ball(.16, (-1.1, IY + .1, -.7), "candle", sub=0)
# work table with potion bottles and a book
b.table((1.2, IY, -.6), w=1.6, d=.8, h=.8, top="wood", leg="darkwood")
for i, c in enumerate(("mint", "lol", "teal", "purple")):
    b.cyl(.08, .26, (.7 + i * .3, IY + .89, -.6), c, sections=8, base=True)
    b.box((.05, .07, .05), (.7 + i * .3, IY + 1.18, -.6), "cream")
b.box((.5, .08, .36), (1.5, IY + .9, -.95), "purple2")
b.box((.46, .04, .32), (1.5, IY + .95, -.95), "cream")
# shelves of herbs on the side walls
for k in range(3):
    y = IY + .9 + k * .55
    b.box((.36, .07, 1.8), (-W / 2 + T + .2, y, .5), "wood")
    for i in range(4):
        b.cyl(.09, .22, (-W / 2 + T + .2, y + .04, -.2 + i * .45),
              ["green2", "purple", "yellow", "teal"][(i + k) % 4], sections=8, base=True)
# ladder up to the attic
for i in range(8):
    b.box((.7, .06, .06), (1.5, IY + .2 + i * .28, 1.2), "wood")
for sx in (-1, 1):
    b.box((.07, 2.3, .07), (1.5 + sx * .32, IY + 1.2, 1.2), "wood2", rot=[("x", 6)])
b.box((1.0, .22, 1.0), (1.5, .3 + H - .1, 1.2), "mud")           # hatch opening frame
# attic: bed, trunk, broom
AY = .3 + H
b.box((1.1, .4, 2.0), (-1.3, AY, -.4), "wood2", base=True)
b.box((1.2, .16, 2.1), (-1.3, AY + .48, -.4), "purple")
b.box((.6, .14, .4), (-1.3, AY + .62, -1.2), "lilac")
b.box((.9, .5, .6), (1.3, AY, -1.1), "darkwood", base=True)
b.box((.95, .14, .65), (1.3, AY + .55, -1.1), "gold2")
b.box((.07, 1.5, .07), (1.9, AY + .75, .4), "wood2", rot=[("z", 14)])
b.cyl(.2, .5, (2.08, AY + .25, .4), "moss", sections=8, base=True)
finish(b, "out/kouzelnicin_dum.glb", "KouzelnicinDum")
