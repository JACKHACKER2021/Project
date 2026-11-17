from lib3d import *
import numpy as np
b = Builder()

def lounger(cx, cz, ang=0, c1="lol", c2="white"):
    g = Builder.__dict__
    def P(p):   # rotate point around (cx,cz)
        a = np.radians(ang)
        x, y, z = p
        return (cx + x * np.cos(a) - z * np.sin(a), y, cz + x * np.sin(a) + z * np.cos(a))
    R = [("y", -ang)]
    # frame legs
    for sx in (-1, 1):
        for sz in (-1, 1):
            b.box((.07, .36, .07), P((sx * .32, .18, sz * .72)), "cream", rot=R)
    # seat: striped slats
    for i in range(7):
        z = -.75 + i * .25
        b.box((.78, .08, .22), P((0, .4, z)), c1 if i % 2 == 0 else c2, rot=R)
    # reclined back
    for i in range(5):
        t = i * .18
        b.box((.78, .08, .22), P((0, .52 + t * .86, -.85 - t * .5)),
              c1 if i % 2 == 0 else c2, rot=[("y", -ang), ("x", -30)])
    for sx in (-1, 1):
        b.box((.07, .95, .07), P((sx * .34, .72, -1.1)), "cream",
              rot=[("y", -ang), ("x", -30)])
        b.box((.06, .06, 1.6), P((sx * .34, .42, 0)), "cream", rot=R)
    # small pillow
    b.box((.5, .14, .3), P((0, 1.0, -1.28)), "mint", rot=[("y", -ang), ("x", -30)])

def parasol(cx, cz, cols=("lol", "white")):
    b.cyl(.4, .12, (cx, 0, cz), "sand", sections=10, base=True)      # base
    b.cyl(.07, 2.5, (cx, .12, cz), "cream", sections=8, base=True)   # pole
    b.ball(.1, (cx, 2.7, cz), "gold", sub=0)
    N = 10
    for i in range(N):
        a0 = 2 * np.pi * i / N; a1 = 2 * np.pi * (i + 1) / N
        r = 1.5
        apex = (cx, 2.6, cz)
        p0 = (cx + np.cos(a0) * r, 1.95, cz + np.sin(a0) * r)
        p1 = (cx + np.cos(a1) * r, 1.95, cz + np.sin(a1) * r)
        c = cols[i % 2]
        b.mesh([apex, p0, p1], [(0, 1, 2), (0, 2, 1)], c)
        b.box((.05, .05, r), (cx + np.cos(a0) * r / 2, 2.0,
                              cz + np.sin(a0) * r / 2), "cream",
              rot=[("y", -np.degrees(a0)), ("z", -8)])
        b.ball(.07, p0, c, sub=0)

# a set: three loungers + two parasols + a little side table
lounger(-2.3, .2, ang=-6, c1="lol", c2="white")
lounger(0.0, 0.0, ang=0, c1="blue", c2="white")
lounger(2.3, .2, ang=7, c1="mint", c2="white")
parasol(-1.2, -1.2, ("lol", "white"))
parasol(1.4, -1.2, ("blue", "white"))
b.cyl(.34, .45, (0, 0, 1.3), "cream", sections=10, base=True)
b.cyl(.42, .09, (0, .45, 1.3), "sand", sections=10)
b.cyl(.12, .3, (-.12, .54, 1.3), "mint", sections=8, base=True)   # drink
b.box((.03, .3, .03), (-.12, .8, 1.3), "lol", rot=[("z", 14)])
b.box((.3, .06, .22), (.16, .5, 1.34), "white", rot=[("y", 18)])  # book
finish(b, "out/plazova_lehatka.glb", "PlazovaLehatka")
