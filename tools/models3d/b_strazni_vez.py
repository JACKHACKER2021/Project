from lib3d import *
b = Builder()
H = 9.0
b.box((3.0, .4, 3.0), (0, 0, 0), "grey4", base=True)
# tapered dark shaft in three segments
segs = [(1.3, 0.4, 3.2), (1.05, 3.6, 3.0), (.85, 6.6, 2.0)]
for (r, y0, h) in segs:
    b.box((r * 2, h, r * 2), (0, y0, 0), "dark", base=True)
for y in (1.4, 2.6, 4.6, 6.0, 7.4):                        # rusty bands
    r = 1.33 if y < 3.6 else (1.08 if y < 6.6 else .88)
    b.box((r * 2, .16, r * 2), (0, y, 0), "rust")
for (x, y, z, w, h) in [(1.3, 2.1, .4, .5, .7), (-1.3, 5.0, -.5, .4, .9),
                        (.3, 7.2, .85, .6, .5)]:           # rust streaks
    b.box((.06, h, w), (x * 1.02, y, z), "rust") if abs(x) > 1 else \
        b.box((w, h, .06), (x, y, z * 1.02), "rust")
# ---- metal stairs spiralling around the tower
import numpy as np
N = 26
for i in range(N):
    t = i / N; ang = t * 540.0; y = .5 + t * 7.4
    r = 1.55 - t * .25
    a = np.radians(ang)
    x, z = np.cos(a) * r, np.sin(a) * r
    b.box((.62, .08, .46), (x, y, z), "grey4", rot=[("y", -ang)])
    b.box((.07, .8, .07), (x * 1.12, y + .4, z * 1.12), "grey3")    # rail post
    if i % 2 == 0:
        b.box((.05, .05, .62), (x * 1.14, y + .78, z * 1.14), "grey3", rot=[("y", -ang + 12)])
    b.box((.07, .5, .07), (x * .72, y - .25, z * .72), "grey4")     # support
# ---- platform with railing at the top
PY = 7.9
b.box((3.4, .22, 3.4), (0, PY, 0), "grey4")
b.box((3.0, .1, 3.0), (0, PY + .16, 0), "grey3")
for s in (-1, 1):
    b.box((3.5, .9, .1), (0, PY + .6, s * 1.7), "grey3")
    b.box((.1, .9, 3.5), (s * 1.7, PY + .6, 0), "grey3")
    for t in (-1.2, -.4, .4, 1.2):
        b.box((.08, .9, .08), (t, PY + .6, s * 1.7), "rust")
        b.box((.08, .9, .08), (s * 1.7, PY + .6, t), "rust")
# gap in the railing at the front where the stairs arrive
b.box((.9, .95, .3), (0, PY + .6, 1.72), "dark")
# ---- cabin + searchlight
b.shell(1.7, 1.7, 1.5, PY + .26, .14, "dark", holes={
    "front": [(0, .85, 0, 1.4)],
    "back":  [(0, .9, .55, .7)],
    "left":  [(0, .6, .6, .6)],
    "right": [(0, .6, .6, .6)]})
b.box((1.7 - .28, .08, 1.7 - .28), (0, PY + .3, -.1), "grey4")       # cabin floor
# cabin interior: desk, stool, radio
b.box((.9, .7, .35), (0, PY + .34, -.65), "grey3", base=True)
b.box((1.0, .07, .45), (0, PY + 1.07, -.65), "grey4")
b.box((.3, .22, .22), (-.3, PY + 1.18, -.65), "rust")
b.ball(.05, (-.3, PY + 1.32, -.6), "red2", sub=0)
b.box((.26, .06, .2), (.25, PY + 1.12, -.65), "cream")
b.cyl(.16, .45, (.5, PY + .34, .3), "grey4", sections=8, base=True)
b.box((.4, .1, .4), (.5, PY + .82, .3), "dark")
b.window(.9, .7, (0, PY + 1.45, .78), color="candle", frame="grey4")
b.window(.6, .6, (.86, PY + 1.4, -.1), color="candle", frame="grey4", facing="x")
b.pyramid(2.1, 2.1, .6, (0, PY + 1.76, -.1), "grey4")
b.cyl(.1, .5, (0, PY + 2.36, -.1), "grey4", sections=8, base=True)
# searchlight head aimed forward (+Z)
b.cyl(.42, .7, (0, PY + 3.0, .25), "grey4", sections=10, axis="z")
b.cyl(.44, .12, (0, PY + 3.0, .62), "rust", sections=10, axis="z")
b.cyl(.36, .1, (0, PY + 3.0, .68), "candle", sections=10, axis="z")
b.box((.14, .5, .14), (0, PY + 2.75, .25), "grey3")
b.box((.6, .12, .12), (0, PY + 3.0, -.15), "grey4")
b.ball(.12, (0, PY + 3.45, .1), "rust", sub=0)
# warning light + antenna
b.box((.09, 1.6, .09), (.6, PY + 2.4, -.7), "grey3")
b.ball(.12, (.6, PY + 3.25, -.7), "red2", sub=1)
finish(b, "out/strazni_vez.glb", "StrazniVez")
