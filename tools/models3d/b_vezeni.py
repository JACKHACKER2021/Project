from lib3d import *
import os
ROOF = os.environ.get('ROOF','1') == '1'
b = Builder()
W, D, H, T = 7.0, 5.0, 3.2, .3   # T = wall thickness
b.box((W + 1.2, .2, D + 1.2), (0, 0, 0), "grey3", base=True)
# ---- hollow stone shell: 4 walls + roof, so the corridor is visible inside
b.box((W, H, T), (0, .2, -D / 2 + T / 2), "grey", base=True)        # back wall
b.box((T, H, D - T * 2), (-W / 2 + T / 2, .2, 0), "grey", base=True)
b.box((T, H, D - T * 2), (W / 2 - T / 2, .2, 0), "grey", base=True)
# front wall with a doorway gap in the middle
for s in (-1, 1):
    b.box((W / 2 - .7, H, T), (s * (W / 4 + .35), .2, D / 2 - T / 2), "grey", base=True)
b.box((1.4, H - 2.2, T), (0, .2 + 2.2, D / 2 - T / 2), "grey", base=True)
if ROOF:
    b.box((W + .4, .35, D + .4), (0, .2 + H + .175, 0), "grey3")    # roof slab
b.box((W - .4, .15, D - .4), (0, .2, 0), "grey4", base=True)        # floor
# ---- three cells side by side along the back, bars facing the corridor
CZ = -D / 2 + T + 1.5          # cell block depth centre
for i, cx in enumerate((-2.1, 0, 2.1)):
    for s in (-1, 1):          # cell dividers
        b.box((.18, H - .5, 2.6), (cx + s * 1.05, .35, CZ), "grey4", base=True)
    for j in range(5):         # vertical bars at the cell front
        b.box((.08, 2.1, .08), (cx - .8 + j * .4, .35, CZ + 1.3), "dark", base=True)
    b.box((1.9, .1, .1), (cx, 2.5, CZ + 1.3), "dark")
    b.box((.6, .25, 1.4), (cx - .5, .35, CZ - .4), "grey4", base=True)   # bunk
    b.box((.6, .07, 1.4), (cx - .5, .62, CZ - .4), "plaster2")
# hole broken through the back wall of the middle-right cell
b.box((1.0, 1.2, T + .12), (2.1, .25, -D / 2 + T / 2), "black", base=True)
for (dx, dy, w, h, a) in [(-.55, 1.5, .5, .35, 20), (.52, .55, .45, .4, -15),
                          (-.1, 1.75, .7, .3, -8), (.3, 1.6, .4, .3, 30)]:
    b.box((w, h, T + .16), (2.1 + dx, .25 + dy, -D / 2 + T / 2), "grey3", rot=[("z", a)])
# ---- small barred windows high up
for cx in (-2.1, 0, 2.1):
    b.box((.7, .55, .12), (cx, 2.5, -D / 2 + .05), "black")
    for j in range(3):
        b.box((.06, .55, .1), (cx - .22 + j * .22, 2.5, -D / 2 + .02), "dark")
    b.box((.78, .12, .16), (cx, 2.82, -D / 2 + .03), "grey4")
for s, f in ((1, .05), (-1, -.05)):
    for z in (-1.0, .8):
        b.box((.12, .55, .7), (s * W / 2 + f, 2.5, z), "black")
        for j in range(3):
            b.box((.1, .55, .06), (s * W / 2 + f * 1.6, 2.5, z - .22 + j * .22), "dark")
# ---- heavy metal door
b.box((1.5, 2.3, .22), (0, .2 + 1.15, D / 2 - .02), "grey4")
for yy in (.7, 1.6, 2.5):
    b.box((1.5, .12, .28), (0, yy, D / 2 + .02), "dark")
for s in (-1, 1):
    for yy in (.6, 1.7):
        b.ball(.07, (s * .55, yy, D / 2 + .12), "dark")
b.cyl(.09, .3, (.5, 1.2, D / 2 + .14), "grey3", sections=8, axis="z")
b.box((.5, .3, .1), (0, 2.75, D / 2 + .05), "grey4")    # small sign plate
# ---- fence with barbed wire around the plot
FX, FZ = 5.2, 4.2
for (p0, p1) in [((-FX, 0, FZ), (-FX, 0, -FZ)), ((FX, 0, FZ), (FX, 0, -FZ)),
                 ((-FX, 0, -FZ), (FX, 0, -FZ)),
                 ((-FX, 0, FZ), (-1.3, 0, FZ)), ((1.3, 0, FZ), (FX, 0, FZ))]:
    p0n, p1n = np.array(p0, float), np.array(p1, float)
    L = np.linalg.norm(p1n - p0n); n = max(2, int(L / 1.3) + 1)
    d = p1n - p0n; ang = np.degrees(np.arctan2(d[0], d[2])); mid = (p0n + p1n) / 2
    for i in range(n):
        p = p0n + d * (i / (n - 1))
        b.box((.1, 2.4, .1), (p[0], 1.2, p[2]), "grey4")
    for yy in (.5, 1.2, 1.9):                                  # chain-link rails
        b.box((.05, .05, L), (mid[0], yy, mid[2]), "grey3", rot=[("y", ang)])
    for yy in (2.2, 2.35):                                     # barbed wire
        b.box((.04, .04, L), (mid[0], yy, mid[2]), "rust", rot=[("y", ang)])
    for i in range(int(L / .5)):
        p = p0n + d * ((i + .5) / (L / .5))
        b.box((.12, .12, .05), (p[0], 2.28, p[2]), "rust", rot=[("z", 45), ("y", ang)])
finish(b, "out/vezeni.glb" if ROOF else "out/vezeni_bez_strechy.glb",
       "Vezeni" if ROOF else "VezeniBezStrechy")
