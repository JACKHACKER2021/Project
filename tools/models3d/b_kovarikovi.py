from lib3d import *
import sys

def build(ruined=False):
    b = Builder()
    W, D, H = 4.2, 3.6, 2.3
    wall = "plaster2" if not ruined else "grey"
    b.box((W + .3, .25, D + .3), (0, 0, 0), "stone2", base=True)
    T = .22
    IY = .42
    if not ruined:
        b.shell(W, D, H, .25, T, wall, holes={
            "front": [(0, 1.0, 0, 2.0)] + [(x, .85, .625, .95) for x in (-1.3, 1.3)],
            "back":  [(-.9, .9, 0, 1.8)],
            "left":  [(-.7, .8, .7, .9)],
            "right": [(-.7, .8, .7, .9)]})
        b.box((W - T * 2, .2, D - T * 2), (0, .33, 0), "stone2")
        b.box((W - T * 2, .05, D - T * 2), (0, IY + .02, 0), "wood")
    else:
        # broken walls: front wall partially collapsed, jagged tops
        b.box((W, H, .22), (0, .25, -D / 2 + .11), wall, base=True)        # back
        b.box((W - T * 2, .2, D - T * 2), (0, .33, 0), "stone2")
        b.box((W - T * 2, .05, D - T * 2), (0, IY + .02, 0), "grey")
        b.box((.22, H * .8, D), (-W / 2 + .11, .25, 0), wall, base=True)   # left, lower
        b.box((.22, H, D * .7), (W / 2 - .11, .25, -D * .12), wall, base=True)
        b.box((W * .35, H * .55, .22), (-W * .3, .25, D / 2 - .11), wall, base=True)
        b.box((W * .2, H * .3, .22), (W * .38, .25, D / 2 - .11), wall, base=True)
        for (x, y, z, w, h, a) in [(-.4, 1.6, D / 2 - .11, .8, .5, 18),
                                   (1.0, .9, D / 2 - .11, .6, .5, -22),
                                   (-W / 2 + .11, 2.0, .6, .3, .6, 12)]:
            b.box((w, h, .24) if abs(z) > 1 else (.24, h, w), (x, y, z), "grey3",
                  rot=[("z", a)])
        # rubble on the ground
        import random; random.seed(11)
        for i in range(22):
            x = random.uniform(-2.6, 2.6); z = random.uniform(.4, 3.0)
            s = random.uniform(.12, .38)
            b.box((s, s * .7, s), (x, s * .35, z), random.choice(["grey", "grey3", "stone2"]),
                  rot=[("y", random.uniform(0, 90)), ("z", random.uniform(-20, 20))])
    TOP = .25 + H
    if not ruined:
        b.gable(W, D, 1.6, (0, TOP, 0), "roof", ridge_along="x", over=.3)
        b.box((W + .7, .14, .25), (0, TOP + .05, D / 2 + .28), "wood")
        b.mesh([(-W / 2, TOP, D / 2), (W / 2, TOP, D / 2), (0, TOP + 1.6, D / 2)],
               [(0, 1, 2)], "plaster")
        b.mesh([(-W / 2, TOP, -D / 2), (0, TOP + 1.6, -D / 2), (W / 2, TOP, -D / 2)],
               [(0, 1, 2)], "plaster")
    else:
        # caved-in roof: two sagging slabs tilted into the house
        b.box((W + .4, .16, D * .55), (-.2, TOP + .35, -.5), "roof2",
              rot=[("z", 6), ("x", -26)])
        b.box((W * .55, .16, D * .5), (1.1, TOP - .25, .7), "roof2",
              rot=[("z", -14), ("x", 32)])
        for (x, y, z, a) in [(-1.4, TOP + .1, .9, 34), (.3, TOP - .1, 1.1, -20),
                             (1.8, TOP - .4, -.3, 50)]:
            b.box((.12, 1.6, .12), (x, y, z), "wood2", rot=[("z", a), ("x", a * .4)])
        b.mesh([(-W / 2, TOP, -D / 2), (0, TOP + 1.3, -D / 2), (W / 2, TOP, -D / 2)],
               [(0, 1, 2)], "grey")
    b.box((.55, 1.5, .55), (-1.3, TOP + .2, -1.0), "red2" if not ruined else "grey3",
          base=True, rot=[("z", 0 if not ruined else 8)])
    # ---- yellow-lit windows
    if not ruined:
        for x in (-1.3, 1.3):
            b.window(.85, .95, (x, 1.35, D / 2), color="yellow", frame="white")
            b.box((.2, 1.0, .07), (x - .58, 1.35, D / 2 + .09), "blue2")
            b.box((.2, 1.0, .07), (x + .58, 1.35, D / 2 + .09), "blue2")
        for s, f in ((1, "x"), (-1, "-x")):
            b.window(.8, .9, (s * W / 2, 1.4, -.7), color="yellow", frame="white", facing=f)
        b.window(.7, .7, (0, TOP + .7, D / 2 + .02), color="yellow", frame="white")
    else:
        for x in (-1.3, 1.3):
            b.box((.85, .95, .1), (x, 1.35, D / 2 - .06), "black")
            for (dx, dy, a) in [(-.2, .2, 25), (.25, -.1, -30)]:
                b.box((.4, .25, .14), (x + dx, 1.35 + dy, D / 2 - .1), "grey3",
                      rot=[("z", a)])
        b.box((.8, .9, .1), (W / 2 - .12, 1.4, -.7), "black")
    # ---- porch
    PZ = D / 2 + .9
    b.box((3.0, .22, 1.8), (0, .25, PZ - .1), "wood" if not ruined else "wood2", base=True)
    if not ruined:
        for s in (-1, 1):
            b.box((.14, 2.2, .14), (s * 1.35, .47, PZ + .7), "wood", base=True)
            b.box((.14, .9, 1.7), (s * 1.35, .47, PZ - .05), "wood", base=True)
        b.box((3.3, .16, 2.1), (0, 2.72, PZ), "roof2")
        b.box((3.4, .2, .18), (0, 2.68, PZ + 1.0), "wood")
    else:
        b.box((.14, 1.4, .14), (-1.35, .47, PZ + .7), "wood2", rot=[("z", 16)])
        b.box((2.4, .14, 1.4), (.3, 1.5, PZ + .2), "roof2", rot=[("z", -22), ("x", 14)])
    b.steps(1.4, 2, .22, .3, PZ + .85, color="wood" if not ruined else "grey3")
    # ---- front door
    if not ruined:
        b.box((1.0, 2.0, .1), (-.78, 1.25, D / 2 - .42), "blue2",   # door, open
              rot=[("y", 58)])
        b.box((.5, .5, .12), (-.95, 1.9, D / 2 - .55), "glass", rot=[("y", 58)])
        b.ball(.07, (-1.2, 1.25, D / 2 - .7), "gold")
    else:
        b.box((1.0, 2.0, .1), (0, 1.47, D / 2 - .05), "black")
        b.box((.9, 1.2, .14), (-.15, .9, D / 2 + .1), "wood2", rot=[("z", 58)])
        b.box((.5, .8, .12), (1.4, .4, PZ + .3), "blue2", rot=[("z", 76), ("y", 20)])
    # ---- back door
    b.box((.9, 1.8, .12), (-1.62, 1.15, -D / 2 + .38), "wood2", rot=[("y", -58)])
    if not ruined:
        b.ball(.06, (-.55, 1.0, -D / 2 - .14), "gold2")
        b.box((1.1, .14, .3), (-.9, 2.1, -D / 2 - .12), "roof2")
    # ---- garden: carrots + marigolds, picket fence
    import random; random.seed(5)
    gz = PZ + 1.4
    for row in range(2):
        for i in range(6):
            x = -2.2 + i * .5 + row * .22; z = gz + row * .55
            if not ruined:
                b.box((.34, .09, .34), (x, .05, z), "mud2")
                for k in range(3):
                    b.box((.05, .3, .05), (x - .08 + k * .08, .2, z), "green2",
                          rot=[("z", -16 + k * 16)])
                b.cone(.09, .18, (x, .0, z), "rust", sections=6)
            else:
                b.box((.34, .07, .34), (x, .04, z), "mud2")
                b.box((.05, .14, .05), (x, .1, z), "moss", rot=[("z", 40)])
    for i in range(7):
        x = -2.4 + i * .8
        if not ruined:
            b.box((.06, .32, .06), (x, .16, gz + 1.25), "green2")
            b.ball(.11, (x, .38, gz + 1.25), "gold", sub=0)
            b.ball(.06, (x, .44, gz + 1.25), "yellow", sub=0)
        else:
            b.box((.06, .14, .06), (x, .07, gz + 1.25), "moss", rot=[("z", 55)])
    FX, FZ = 3.2, gz + 1.9
    for i in range(10):
        x = -FX + i * (FX * 2 / 9)
        h = .7 if not ruined else random.choice([.7, .35, .55, 0])
        if h <= 0: continue
        b.box((.1, h, .07), (x, h / 2, FZ), "white" if not ruined else "grey",
              rot=[("z", 0 if not ruined else random.uniform(-14, 14))])
        if not ruined:
            b.pyramid(.1, .07, .1, (x, h, FZ), "white")
    for yy in (.25, .55):
        b.box((FX * 2, .06, .05), (0, yy, FZ), "white" if not ruined else "grey")
    for s in (-1, 1):
        for i in range(5):
            z = FZ - i * ((FZ - (-D / 2 - .6)) / 4.5)
            h = .7 if not ruined else random.choice([.7, .4, .6])
            b.box((.07, h, .1), (s * FX, h / 2, z), "white" if not ruined else "grey")
    # ---------------- interior ----------------
    if not ruined:
        b.table((-.9, IY, -.6), w=1.4, d=.9, h=.74)
        for (dx, dz, a) in ((-.9, .1, 180), (-.9, -1.3, 0), (-.1, -.6, 270)):
            b.chair((dx, IY, dz), ang=a)
        b.box((.9, .9, .6), (1.4, IY, -1.0), "grey3", base=True)        # stove
        b.box((1.0, .1, .7), (1.4, IY + .92, -1.0), "grey4")
        b.cyl(.18, .25, (1.2, IY + 1.05, -1.0), "red2", sections=8, base=True)
        b.box((.3, 1.2, .3), (1.8, IY + 1.5, -1.3), "grey3")            # flue
        b.box((1.2, 1.6, .5), (1.5, IY, .9), "wood2", base=True)        # dresser
        b.box((1.3, .1, .6), (1.5, IY + 1.64, .9), "wood")
        for k in range(2):
            b.box((1.1, .07, .4), (1.5, IY + .6 + k * .5, .9), "wood")
            for i in range(3):
                b.cyl(.09, .18, (1.1 + i * .4, IY + .64 + k * .5, .9),
                      ["blue", "yellow", "pink"][i], sections=8, base=True)
        b.box((1.6, .5, .9), (-1.4, IY, 1.0), "blue2", base=True)       # bench + rug
        b.box((1.7, .1, 1.0), (-1.4, IY + .52, 1.0), "wood")
        b.box((1.8, .03, 1.2), (0, IY + .05, .6), "red")
        b.box((.5, .04, .34), (-.9, IY + .78, -.6), "white")            # bread on table
        b.ball(.1, (-.5, IY + .82, -.4), "gold2")
    else:
        b.box((1.2, .12, .8), (-.8, IY + .1, -.5), "wood2", rot=[("z", 22), ("y", 14)])
        for sx in (-1, 1):
            b.box((.07, .7, .07), (-.8 + sx * .5, IY + .3, -.5), "wood2",
                  rot=[("z", sx * 34)])
        b.chair((.4, IY, .2), ang=38, seat="wood", back="wood2")
        b.box((.9, .9, .6), (1.4, IY, -1.0), "grey3", base=True)
        b.box((1.0, .1, .7), (1.5, IY + .95, -1.05), "grey4", rot=[("z", 9)])
        b.box((1.2, .9, .5), (1.5, IY, .9), "wood2", base=True, rot=[("z", -7)])
        for i in range(5):
            b.box((.3, .06, .22), (-.2 + i * .5, IY + .04, .3 + (i % 3) * .5), "wood",
                  rot=[("y", i * 24)])
    name = "dum_kovarikovi_zniceny" if ruined else "dum_kovarikovi"
    finish(b, f"out/{name}.glb", name)

build(False)
build(True)
