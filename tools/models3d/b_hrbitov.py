from lib3d import *
import random

def gate(b, ox=0.0):
    for s in (-1, 1):                                  # two black brick pillars
        x = ox + s * 1.9
        b.box((1.0, .3, 1.0), (x, 0, 0), "black", base=True)
        for i in range(6):
            b.box((.8 - i * .01, .42, .8), (x, .3 + i * .42, 0),
                  "black" if i % 2 == 0 else "dark", base=True)
        b.box((1.0, .22, 1.0), (x, 2.9, 0), "dark")
        b.pyramid(.95, .95, .55, (x, 3.01, 0), "black")
        b.ball(.1, (x, 3.62, 0), "grey4")
    b.box((2.9, .3, .5), (ox, 3.0, 0), "dark")          # arch lintel
    for i in range(7):                                  # arch bars
        b.box((.08, .55, .08), (ox - 1.2 + i * .4, 2.65, 0), "grey4")
    # wrought-iron gate wings, slightly ajar
    for s in (-1, 1):
        b.box((1.3, 2.3, .09), (ox + s * .78, 1.2, s * .22), "grey4",
              rot=[("y", s * -14)])
        for i in range(4):
            b.box((.07, 2.2, .07), (ox + s * (.3 + i * .36), 1.2, s * (.1 + i * .06)),
                  "dark")
        b.box((1.3, .08, .12), (ox + s * .78, 2.3, s * .22), "grey4", rot=[("y", s * -14)])

def wall(b):
    for (x0, x1, h) in [(-7.4, -2.6, 2.2), (2.6, 4.4, 2.2), (4.4, 5.6, 1.4),
                        (5.6, 6.6, .8), (6.6, 7.4, 1.8)]:
        w = x1 - x0
        b.box((w, h, .55), ((x0 + x1) / 2, 0, 0), "black", base=True)
        b.box((w + .1, .18, .7), ((x0 + x1) / 2, h, 0), "dark")
        for y in (.6, 1.2, 1.8):
            if y < h - .1:
                b.box((w + .04, .07, .58), ((x0 + x1) / 2, y, 0), "dark")
    random.seed(4)
    for i in range(14):                                 # fallen bricks by the gap
        x = random.uniform(4.3, 7.0); z = random.uniform(-.9, .9)
        s = random.uniform(.18, .34)
        b.box((s, s * .6, s * .8), (x, s * .3, z), random.choice(["black", "dark", "grey4"]),
              rot=[("y", random.uniform(0, 90)), ("z", random.uniform(-25, 25))])
    for (x, y, w, h, a) in [(4.3, 1.5, .5, .6, 20), (5.5, .95, .4, .5, -25),
                            (6.5, 1.9, .45, .4, 14)]:
        b.box((w, h, .58), (x, y, 0), "dark", rot=[("z", a)])

def cross(b, ox=0.0, oz=0.0):
    b.box((1.9, .35, 1.9), (ox, 0, oz), "mud2", base=True)
    b.box((1.5, .3, 1.5), (ox, .35, oz), "mud2", base=True)
    b.box((.7, 3.4, .55), (ox, .65, oz), "mud", base=True)
    b.box((2.4, .6, .5), (ox, 2.7, oz), "mud")
    for (x, y, w, h) in [(-.25, 1.4, .18, .5), (.22, 2.2, .14, .4), (-.9, 2.7, .3, .18)]:
        b.box((w, h, .56), (ox + x, y, oz), "mud2")
    b.pyramid(.7, .55, .3, (ox, 4.05, oz), "mud2")

def stones(b):
    random.seed(21)
    spots = [(-5.6, 2.6), (-3.9, 3.4), (-2.2, 2.4), (-5.0, 5.2), (-3.0, 6.0),
             (2.2, 2.6), (3.9, 3.5), (5.6, 2.5), (4.8, 5.4), (2.8, 6.2),
             (-1.4, 7.4), (1.4, 7.6), (-6.4, 7.0), (6.2, 6.8), (0, 4.6)]
    for (x, z) in spots:
        k = random.randint(0, 3)
        a = random.uniform(-9, 9)
        c = random.choice(["grey", "grey3", "stone2", "grey4"])
        b.box((1.0, .16, .8), (x, 0, z), "mud2", base=True)     # plot kerb
        if k == 0:        # rounded headstone
            b.box((.7, .8, .18), (x, .16, z), c, base=True, rot=[("z", a)])
            b.cyl(.35, .18, (x, 1.0, z), c, sections=8, axis="z")
        elif k == 1:      # slab with shoulders
            b.box((.8, 1.0, .2), (x, .16, z), c, base=True, rot=[("z", a)])
            b.box((.95, .14, .26), (x, 1.2, z), c, rot=[("z", a)])
        elif k == 2:      # small cross
            b.box((.2, 1.1, .18), (x, .16, z), c, base=True, rot=[("z", a)])
            b.box((.7, .2, .18), (x, .95, z), c, rot=[("z", a)])
        else:             # leaning broken stub
            b.box((.65, .7, .2), (x, .16, z), c, base=True, rot=[("z", a * 2.4)])
            b.box((.4, .22, .2), (x + .1, .85, z), c, rot=[("z", a * 3)])
        if random.random() < .5:
            b.ball(.12, (x + random.uniform(-.3, .3), .22, z + .45), "green2", sub=0)

# ---- full cemetery
b = Builder(); gate(b); wall(b); cross(b, 0, 5.0); stones(b)
finish(b, "out/hrbitov.glb", "Hrbitov")
# ---- separate parts
b = Builder(); gate(b); finish(b, "out/hrbitov_brana.glb", "HrbitovBrana")
b = Builder(); wall(b); finish(b, "out/hrbitov_zed.glb", "HrbitovZed")
b = Builder(); cross(b); finish(b, "out/hrbitov_kriz.glb", "HrbitovKriz")
b = Builder(); stones(b); finish(b, "out/hrbitov_nahrobky.glb", "HrbitovNahrobky")
