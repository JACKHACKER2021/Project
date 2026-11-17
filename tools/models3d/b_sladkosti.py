from lib3d import *
b = Builder()
W, D, H = 5.0, 4.0, 3.0
b.box((W + .3, .25, D + .3), (0, 0, 0), "darkwood", base=True)
T = .24
b.shell(W, D, H, .25, T, "oak", holes={
    "front": [(0, 3.4, .45, 1.7), (-1.9, 1.0, 0, 2.2)],
    "left":  [(-.6, .9, .9, 1.1)],
    "right": [(-.6, .9, .9, 1.1)],
    "back":  [(0, 1.0, 0, 1.4)]})
b.box((W - T * 2, .25, D - T * 2), (0, .25 + .12, 0), "darkwood")   # shop floor
b.box((W - T * 2, .16, D - T * 2), (0, .25 + H - .08, 0), "wood2")  # ceiling
for y in (1.0, 2.1, 3.0):                                  # dark oak plank lines
    b.box((W + .06, .1, D + .06), (0, y, 0), "wood2")
for s in (-1, 1):                                          # corner posts
    b.box((.22, H, .22), (s * (W / 2 - .09), .25, D / 2 - .09), "darkwood", base=True)
    b.box((.22, H, .22), (s * (W / 2 - .09), .25, -D / 2 + .09), "darkwood", base=True)
TOP = .25 + H
b.gable(W, D, 1.5, (0, TOP, 0), "roof2", ridge_along="x", over=.25)
b.box((W + .6, .16, .25), (0, TOP + .04, D / 2 + .22), "wood")      # fascia
# ---- big shop window full of sweets
b.box((3.4, 1.7, .1), (0, 1.55, D / 2 - .1), "glass")
b.box((3.7, .18, .26), (0, 2.46, D / 2 + .02), "cream")
b.box((3.7, .18, .26), (0, .64, D / 2 + .02), "cream")
for s in (-1, 1):
    b.box((.18, 2.0, .26), (s * 1.78, 1.55, D / 2 + .02), "cream")
b.box((.1, 1.7, .16), (0, 1.55, D / 2 + .0), "cream")
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
b.box((1.0, 2.2, .12), (-2.75, .25 + 1.1, D / 2 - .45), "wood2",   # door, open
      rot=[("y", 62)])
b.box((.7, .8, .14), (-2.9, 2.0, D / 2 - .5), "glass", rot=[("y", 62)])
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
# ---------------- interior: counter, shelves, crates ------------------------
IY = .5
b.box((W - T * 2, .04, D - T * 2), (0, IY + .02, 0), "wood")
# serving counter
b.box((3.2, 1.0, .7), (.4, IY, -.4), "wood2", base=True)
b.box((3.4, .1, .9), (.4, IY + 1.03, -.4), "wood")
b.box((3.2, .14, .72), (.4, IY + .55, -.42), "pink")
b.cyl(.25, .3, (1.5, IY + 1.08, -.4), "glass", sections=10, base=True)   # jar on top
b.cyl(.22, .2, (1.5, IY + 1.1, -.4), "lol", sections=10, base=True)
b.box((.45, .3, .35), (-.6, IY + 1.18, -.4), "gold2")                    # till
b.box((.3, .06, .3), (-.6, IY + 1.34, -.45), "cream")
# shelf wall behind the counter, full of jars
for k in range(3):
    y = IY + .7 + k * .62
    b.box((3.6, .08, .4), (.2, y, -D / 2 + T + .25), "wood")
    for i in range(6):
        x = -1.4 + i * .62
        c = ["lol", "mint", "yellow", "teal", "purple", "blue"][(i + k) % 6]
        b.cyl(.14, .4, (x, y + .04, -D / 2 + T + .25), "glass", sections=8, base=True)
        b.cyl(.11, .26, (x, y + .06, -D / 2 + T + .25), c, sections=8, base=True)
# side shelves
for k in range(3):
    y = IY + .55 + k * .6
    b.box((.4, .08, 2.0), (W / 2 - T - .22, y, .2), "wood")
    for i in range(4):
        b.box((.3, .26, .3), (W / 2 - T - .22, y + .17, -.5 + i * .5),
              ["pink", "mint", "yellow", "lol"][(i + k) % 4])
# crates and barrel of lollipops
for (x, z, c) in ((-2.0, 1.1, "wood2"), (-1.5, 1.5, "wood")):
    b.box((.6, .5, .6), (x, IY, z), c, base=True)
    b.box((.5, .1, .5), (x, IY + .52, z), "pink")
b.cyl(.35, .7, (-2.1, IY, -.6), "wood2", sections=10, base=True)
for i in range(6):
    b.box((.04, .5, .04), (-2.1 + (i - 2.5) * .1, IY + .9, -.6), "cream",
          rot=[("z", (i - 2.5) * 7)])
    b.cyl(.1, .05, (-2.1 + (i - 2.5) * .13, IY + 1.16, -.6),
          ["lol", "mint", "yellow"][i % 3], sections=8, axis="z")
# hatch down to the cellar at the back
b.box((1.2, .06, 1.2), (1.6, IY + .03, -1.1), "darkwood")
b.box((1.1, .1, .5), (1.6, IY + .06, -1.4), "wood2", rot=[("x", 55)])
finish(b, "out/obchod_sladkosti.glb", "ObchodSladkosti")
