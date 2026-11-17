from lib3d import *
b = Builder()
W, D, H = 4.4, 3.8, 2.4
b.box((W + .4, .3, D + .4), (0, 0, 0), "mud2", base=True)
# two crooked storeys of mud brick, the upper one jutting out and tilted
b.box((W, H, D), (0, .3, 0), "mud", base=True)
b.box((W + .5, H - .3, D + .4), (.12, .3 + H, 0), "mud", base=True, rot=[("z", -2.5)])
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
b.box((1.0, 2.0, .18), (0, 1.0, D / 2 + .06), "darkwood", rot=[("z", 2)])
for y in (.5, 1.5):
    b.box((1.02, .1, .22), (0, y, D / 2 + .09), "wood2", rot=[("z", 2)])
b.ball(.08, (.36, 1.0, D / 2 + .18), "gold2")
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
finish(b, "out/kouzelnicin_dum.glb", "KouzelnicinDum")
