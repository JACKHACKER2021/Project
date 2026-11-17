from lib3d import *
b = Builder()
W, D, H = 5.0, 4.0, 3.0
b.box((W + .3, .25, D + .3), (0, 0, 0), "darkwood", base=True)
b.box((W, H, D), (0, .25, 0), "oak", base=True)
for y in (1.0, 2.1, 3.0):                                  # dark oak plank lines
    b.box((W + .06, .1, D + .06), (0, y, 0), "wood2")
for s in (-1, 1):                                          # corner posts
    b.box((.22, H, .22), (s * (W / 2 - .09), .25, D / 2 - .09), "darkwood", base=True)
    b.box((.22, H, .22), (s * (W / 2 - .09), .25, -D / 2 + .09), "darkwood", base=True)
TOP = .25 + H
b.gable(W, D, 1.5, (0, TOP, 0), "roof2", ridge_along="x", over=.25)
b.box((W + .6, .16, .25), (0, TOP + .04, D / 2 + .22), "wood")      # fascia
# ---- big shop window full of sweets
b.box((3.4, 2.0, .12), (0, 1.0, D / 2 + .06), "glass")
b.box((3.7, .18, .26), (0, 2.09, D / 2 + .1), "cream")
b.box((3.7, .18, .26), (0, -.09 + .1, D / 2 + .1), "cream")
for s in (-1, 1):
    b.box((.18, 2.2, .26), (s * 1.78, 1.0, D / 2 + .1), "cream")
b.box((.1, 2.0, .2), (0, 1.0, D / 2 + .1), "cream")
for sy, sh in ((.35, .1), (1.15, .1)):                     # display shelves
    b.box((3.3, sh, .5), (0, sy, D / 2 - .18), "wood")
import random; random.seed(7)
jars = ["lol", "pink", "blue", "mint", "yellow", "teal", "purple", "red", "gold"]
for row, sy in ((0, .4), (1, 1.2)):
    for i in range(7):
        x = -1.45 + i * .48
        c = jars[(i + row * 3) % len(jars)]
        if i % 3 == 0:                                     # jar of candy
            b.cyl(.15, .44, (x, sy + .05, D / 2 - .2), "glass", sections=8, base=True)
            b.cyl(.12, .3, (x, sy + .07, D / 2 - .2), c, sections=8, base=True)
            b.cyl(.16, .05, (x, sy + .49, D / 2 - .2), c, sections=8, base=True)
        elif i % 3 == 1:                                   # lollipop
            b.box((.04, .34, .04), (x, sy + .22, D / 2 - .2), "cream")
            b.cyl(.14, .05, (x, sy + .45, D / 2 - .2), c, sections=10, axis="z")
            b.cyl(.07, .06, (x, sy + .45, D / 2 - .22), "white", sections=8, axis="z")
        else:                                              # stack of wrapped sweets
            for k in range(3):
                b.box((.26, .12, .3), (x, sy + .11 + k * .13, D / 2 - .2),
                      jars[(i + k) % len(jars)], rot=[("y", k * 12)])
# ---- striped awning (pink / white) over the window
AZ = D / 2 + .1
for i in range(8):
    x = -1.95 + i * .5
    c = "pink" if i % 2 == 0 else "white"
    b.mesh([(x, 2.55, AZ), (x + .5, 2.55, AZ), (x + .5, 1.95, AZ + 1.0), (x, 1.95, AZ + 1.0)],
           [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)], c)
    b.box((.5, .18, .1), (x + .25, 1.92, AZ + 1.02), c)
b.box((4.1, .14, .14), (0, 2.58, AZ + .02), "wood2")
# ---- door
b.box((1.0, 2.2, .16), (-1.9, .25 + 1.1, D / 2 + .04), "wood2")
b.box((.7, .8, .1), (-1.9, 2.0, D / 2 + .1), "glass")
b.ball(.07, (-1.5, 1.3, D / 2 + .14), "gold")
b.box((1.2, .16, .3), (-1.9, 2.5, D / 2 + .1), "wood")
# ---- lollipop-shaped sign on a bracket
b.box((.1, .1, .9), (1.9, 3.1, D / 2 + .5), "wood2")
b.box((.07, .07, .5), (1.9, 2.85, D / 2 + .95), "wood2", rot=[("x", 42)])
b.box((.06, .5, .06), (1.9, 2.75, D / 2 + .92), "cream")
b.cyl(.42, .1, (1.9, 2.35, D / 2 + .92), "pink", sections=12, axis="z")
b.cyl(.3, .12, (1.9, 2.35, D / 2 + .92), "white", sections=12, axis="z")
b.cyl(.17, .14, (1.9, 2.35, D / 2 + .92), "lol", sections=12, axis="z")
# ---- side windows
for s, f in ((1, "x"), (-1, "-x")):
    b.window(.9, 1.1, (s * W / 2, 1.6, -.6), frame="cream")
# ---- stairs down to the cellar at the back
b.box((1.6, .2, 1.8), (0, 0, -D / 2 - .9), "stone2", base=True)
for i in range(4):
    b.box((1.2, .2, .4), (0, -.1 - i * .22, -D / 2 - .35 - i * .4), "stone2")
b.box((1.0, 1.4, .16), (0, -.55, -D / 2 - .05), "darkwood")
for s in (-1, 1):
    b.box((.12, .9, 1.8), (s * .72, -.3, -D / 2 - .9), "stone2")
b.box((1.2, .14, .3), (0, .18, -D / 2 - .12), "wood2")
finish(b, "out/obchod_sladkosti.glb", "ObchodSladkosti")
