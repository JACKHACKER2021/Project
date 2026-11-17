from lib3d import *
import numpy as np
b = Builder()
TW = 7.0           # track width
# ---- candy track surface with lollipop stripes
for i in range(10):
    z = -2.0 + i * .9
    b.box((TW, .12, .9), (0, .06, z), "pink" if i % 2 == 0 else "white")
for s in (-1, 1):  # candy-cane kerbs
    for i in range(12):
        b.cyl(.22, .75, (s * (TW / 2 + .2), .06, -2.2 + i * .75), "lol" if i % 2 else "white",
              sections=8, axis="z", base=True)
# ---- start line (chequered)
for i in range(14):
    b.box((TW / 14, .06, .5), (-TW / 2 + TW / 28 + i * TW / 14, .15, 0),
          "white" if i % 2 == 0 else "dark")
    b.box((TW / 14, .06, .5), (-TW / 2 + TW / 28 + i * TW / 14, .15, .5),
          "dark" if i % 2 == 0 else "white")
# ---- start gate: two lollipop/candy-cane towers + arch
for s in (-1, 1):
    x = s * (TW / 2 + .55)
    b.cyl(.5, .3, (x, 0, 0), "cream", sections=12, base=True)
    for i in range(10):                          # twisted candy cane column
        b.cyl(.32, .46, (x, .3 + i * .45, 0), "lol" if i % 2 == 0 else "white",
              sections=8, base=True, axis="y")
    b.cyl(.4, .2, (x, 4.8, 0), "cream", sections=12, base=True)
    b.ball(.3, (x, 5.15, 0), "mint", sub=1)
AY = 4.6
b.box((TW + 2.2, .55, .8), (0, AY, 0), "pink2")                     # arch beam
b.box((TW + 2.4, .18, 1.0), (0, AY + .42, 0), "cream")
b.box((TW + 2.4, .18, 1.0), (0, AY - .42, 0), "cream")
for i in range(12):                                                  # candy stripes
    b.box((.45, .5, .84), (-TW / 2 - .8 + i * (TW + 1.6) / 11, AY, 0),
          "white" if i % 2 == 0 else "lol")
b.box((5.2, 1.1, .2), (0, AY + 1.1, .12), "cream")                   # "START" board
for i, o in enumerate((-1.8, -.9, 0, .9, 1.8)):                      # chunky letters
    b.box((.5, .7, .14), (o, AY + 1.1, .26), "red2")
    b.box((.3, .45, .18), (o, AY + 1.1, .3), "cream")
b.box((5.4, .2, .3), (0, AY + 1.72, .14), "pink2")
for i in range(9):                                                   # hanging pennants
    x = -TW / 2 - .6 + i * (TW + 1.2) / 8
    c = ["lol", "mint", "yellow", "blue"][i % 4]
    b.mesh([(x - .22, AY - .5, .3), (x + .22, AY - .5, .3), (x, AY - 1.05, .3)],
           [(0, 1, 2), (0, 2, 1)], c)
# ---- grandstand on the right side
GX = TW / 2 + 2.6
b.box((3.6, .3, 6.0), (GX, 0, 1.0), "cream", base=True)
for i in range(5):                                  # tiered seat rows
    y = .3 + i * .45; w = 3.2 - i * .1
    b.box((w, .45, .9), (GX + i * .42, y, 1.0), "sand", base=True)
    b.box((w - .2, .16, .8), (GX + i * .42, y + .45, 1.0), "lol" if i % 2 else "mint")
    for k in range(5):                              # seats
        b.box((.5, .3, .5), (GX + i * .42 - 1.2 + k * .6, y + .53, 1.0),
              ["pink", "blue", "yellow", "mint", "lol"][(k + i) % 5], base=True)
b.box((4.4, .22, 6.4), (GX + 1.0, 3.0, 1.0), "pink2")                # canopy
for i in range(8):
    b.box((4.4, .24, .8), (GX + 1.0, 3.02, -2.0 + i * .8),
          "white" if i % 2 == 0 else "pink")
for z in (-1.8, 1.0, 3.8):
    b.box((.18, 2.8, .18), (GX + 2.9, 1.5, z), "cream")
b.box((.14, 1.0, 6.0), (GX - 1.7, .8, 1.0), "white")                 # front rail
for z in np.arange(-1.8, 4.0, .9):
    b.box((.12, 1.0, .12), (GX - 1.7, .8, z), "cream")
# ---- flags along both sides
for s in (-1, 1):
    for i in range(5):
        z = -1.6 + i * 1.5
        x = s * (TW / 2 + 1.3)
        if s > 0 and z > -2: x = TW / 2 + 1.2
        b.box((.09, 2.4, .09), (x, 1.2, z), "cream")
        b.ball(.13, (x, 2.5, z), "gold", sub=0)
        c = ["lol", "mint", "blue", "yellow", "pink"][i % 5]
        b.mesh([(x, 2.3, z), (x, 1.75, z), (x + s * .7, 2.05, z + .1)],
               [(0, 1, 2), (0, 2, 1)], c)
finish(b, "out/zavodni_draha.glb", "ZavodniDraha")
