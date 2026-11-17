from lib3d import *
b = Builder()
W, D, H = 4.6, 3.8, 2.2
b.box((W + .4, .3, D + .4), (0, 0, 0), "darkwood", base=True)   # stone/log footing
for s in (-1, 1):
    for z in (-1, 1):
        b.box((.4, .4, .4), (s * (W / 2 - .1), .0, z * (D / 2 - .1)), "grey3", base=True)
# ---- stacked log walls (round timber)
NL = 7; lh = H / NL
for i in range(NL):
    y = .3 + lh / 2 + i * lh
    c = "wood2" if i % 2 == 0 else "wood"
    b.cyl(lh * .55, W + .5, (0, y, -D / 2 + lh * .5), c, sections=7, axis="x")
    if i < NL - 1 or True:
        b.cyl(lh * .55, D - lh, (-W / 2 + lh * .5, y, 0), c, sections=7, axis="z")
        b.cyl(lh * .55, D - lh, (W / 2 - lh * .5, y, 0), c, sections=7, axis="z")
    # front wall logs, split around the doorway
    if y > .3 + 2.0:
        b.cyl(lh * .55, W + .5, (0, y, D / 2 - lh * .5), c, sections=7, axis="x")
    else:
        for s in (-1, 1):
            b.cyl(lh * .55, W / 2 - .55, (s * (W / 4 + .3), y, D / 2 - lh * .5), c,
                  sections=7, axis="x")
TOP = .3 + H
# ---- mossy gable roof
b.gable(W + .6, D + .5, 1.5, (0, TOP, 0), "wood2", ridge_along="x", over=.3)
b.gable(W + .75, D + .62, 1.42, (0, TOP + .14, 0), "moss", ridge_along="x", over=.32)
import random; random.seed(9)
for i in range(16):                                            # moss clumps
    x = random.uniform(-2.8, 2.8); s = random.choice([1, -1])
    t = random.uniform(.15, .75)
    b.ball(random.uniform(.12, .22),
           (x, TOP + .18 + 1.4 * (1 - t), s * (D / 2 + .3) * t), "green2", sub=0)
b.mesh([(-W / 2 - .3, TOP, D / 2 + .25), (W / 2 + .3, TOP, D / 2 + .25),
        (0, TOP + 1.5, D / 2 + .25)], [(0, 1, 2)], "wood")
b.mesh([(-W / 2 - .3, TOP, -D / 2 - .25), (0, TOP + 1.5, -D / 2 - .25),
        (W / 2 + .3, TOP, -D / 2 - .25)], [(0, 1, 2)], "wood")
b.cyl(.09, 2.0, (0, TOP + .8, D / 2 + .3), "wood2", sections=6, axis="x")  # ridge pole
# antlers nailed over the gable
for s in (-1, 1):
    b.box((.06, .5, .06), (s * .18, TOP + 1.05, D / 2 + .32), "bone", rot=[("z", s * 18)])
    for k in range(3):
        b.box((.05, .22, .05), (s * (.3 + k * .06), TOP + 1.2 + k * .12, D / 2 + .32),
              "bone", rot=[("z", s * (45 + k * 10))])
# ---- stone chimney
b.box((.75, 2.2, .75), (-1.6, TOP - .6, -.9), "grey3", base=True)
b.box((.9, .18, .9), (-1.6, TOP + 1.65, -.9), "grey4")
for y in (TOP - .2, TOP + .4, TOP + 1.0):
    b.box((.8, .08, .8), (-1.6, y, -.9), "grey")
# ---- windows with shutters
for x in (-1.5, 1.5):
    b.window(.7, .8, (x, 1.5, D / 2 + .05), color="dark", frame="wood", facing="z")
    for s in (-1, 1):
        b.box((.26, .9, .07), (x + s * .5, 1.5, D / 2 + .14), "wood2",
              rot=[("z", s * 4)])
        for k in range(3):
            b.box((.22, .05, .09), (x + s * .5, 1.25 + k * .25, D / 2 + .17), "moss")
b.window(.6, .7, (W / 2 + .05, 1.5, -.8), color="dark", frame="wood", facing="x")
# ---- plank door with a bar
b.box((1.1, 2.0, .14), (0, 1.3, D / 2 + .06), "wood2")
for k in range(4):
    b.box((.25, 2.0, .16), (-.4 + k * .27, 1.3, D / 2 + .08), "wood" if k % 2 else "wood2")
b.box((1.3, .13, .1), (0, 1.0, D / 2 + .16), "grey4")          # iron bar
b.box((.18, .3, .12), (-.6, 1.0, D / 2 + .18), "grey4")
b.ball(.07, (.4, 1.3, D / 2 + .16), "grey4")
# ---- small porch
PZ = D / 2 + .85
b.box((2.6, .2, 1.5), (0, .3, PZ), "wood", base=True)
for s in (-1, 1):
    b.box((.14, 1.9, .14), (s * 1.15, .5, PZ + .6), "wood2", base=True)
b.box((2.8, .14, 1.7), (0, 2.5, PZ + .05), "wood2")
b.gable(2.8, 1.7, .5, (0, 2.57, PZ + .05), "moss", ridge_along="x", over=.1)
b.box((2.4, .08, .1), (0, .95, PZ + .68), "wood2")             # low rail
b.steps(1.3, 2, .2, .3, PZ + .78, color="wood2")
# firewood stack beside the porch
for r in range(3):
    for i in range(5):
        b.cyl(.09, 1.1, (1.9 + r * .02, .1 + r * .19, PZ - .2 - .0 + i * .0), "wood2",
              sections=6, axis="x") if False else None
for r in range(3):
    for i in range(4):
        b.cyl(.1, .9, (2.2, .12 + r * .21, PZ - .45 + i * .24), "wood2", sections=6, axis="x")
finish(b, "out/myslivna.glb", "Myslivna")
