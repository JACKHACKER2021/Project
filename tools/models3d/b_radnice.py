from lib3d import *
b = Builder()
W, D, H = 7.0, 5.0, 2.6     # floor 1
# ---- base plinth
b.box((W + .4, .3, D + .4), (0, 0, 0), "stone2", base=True)
# ---- two storeys of light plaster
T = .28
FY = .72                                   # interior floor level (= door threshold)
b.shell(W, D, H, .3, T, "plaster", holes={
    "front": [(0, 2.4, FY - .3, 2.2)] + [(x, 1.05, .55, 1.5) for x in
                                         (-2.45, -.85, .85, 2.45)],
    "back":  [(0, 1.0, FY - .3, 1.9)],
    "left":  [(z, 1.0, .55, 1.4) for z in (-1.3, .3)],
    "right": [(z, 1.0, .55, 1.4) for z in (-1.3, .3)]})
b.shell(W - .3, D - .3, H - .2, .3 + H, T, "plaster2", holes={
    "front": [(x, 1.0, .65, 1.4) for x in (-2.45, 2.45)],
    "left":  [(z, .9, .7, 1.2) for z in (-1.3, .3)],
    "right": [(z, .9, .7, 1.2) for z in (-1.3, .3)]})
b.box((W - T * 2, FY - .3, D - T * 2), (0, .3 + (FY - .3) / 2, 0), "stone2")  # sub-floor
b.box((W - T * 2, .1, D - T * 2), (0, FY - .05, 0), "wood")       # floor boards
# pink string course between floors + blue cornice on top
b.box((W + .25, .18, D + .25), (0, .3 + H + .09, 0), "pink")
b.box((W + .3, .22, D + .3), (0, .3 + H + H - .2 + .11, 0), "blue2")
Y2 = .3 + H
TOP = Y2 + H - .2 + .22
# first-floor slab, left open above the staircase
b.box((W - T * 2, .2, 2.3), (0, Y2 - .1, -(D - T * 2) / 2 + 1.15), "wood2")
b.box((2.2, .2, D - T * 2 - 2.3), (-(W - T * 2) / 2 + 1.1, Y2 - .1, 1.15), "wood2")
b.box((2.2, .2, D - T * 2 - 2.3), ((W - T * 2) / 2 - 1.1, Y2 - .1, 1.15), "wood2")
b.box((W - T * 2, .16, D - T * 2), (0, Y2 + H - .2 + .08, 0), "plaster2")  # ceiling
# ---- hip roof
b.pyramid(W + .5, D + .5, 1.3, (0, TOP, 0), "roof")
# ---- clock tower in the middle of the roof
b.box((1.5, 1.6, 1.5), (0, TOP + .5, 0), "plaster", base=True)
b.box((1.7, .16, 1.7), (0, TOP + 2.1 + .08, 0), "blue2")
for s in (1, -1):
    b.cyl(.52, .12, (0, TOP + 1.45, s * .76), "white", sections=12, axis="z")  # clock face
    b.cyl(.56, .07, (0, TOP + 1.45, s * .80), "gold2", sections=12, axis="z")
    b.box((.5, .06, .06), (.12, TOP + 1.45, s * .84), "dark", rot=[("z", 20)])
    b.box((.06, .34, .06), (0, TOP + 1.58, s * .84), "dark")
b.pyramid(1.9, 1.9, 1.5, (0, TOP + 2.18, 0), "pink2")
b.ball(.13, (0, TOP + 3.78, 0), "gold")
# ---- big framed windows, both floors, front and sides
for xi in (-2.45, -.85, .85, 2.45):
    b.window(1.05, 1.5, (xi, 1.55, D / 2), facing="z")
for xi in (-2.45, -.85, .85, 2.45):
    if abs(xi) > 1.2:
        b.window(1.0, 1.4, (xi, Y2 + 1.35, D / 2 - .15), facing="z")
for s, f in ((1, "x"), (-1, "-x")):
    for zi in (-1.3, .3):
        b.window(1.0, 1.4, (s * W / 2, 1.55, zi), facing=f)
        b.window(.9, 1.2, (s * (W / 2 - .15), Y2 + 1.3, zi), facing=f)
# ---- entrance: wide steps + double door + portal
b.steps(3.6, 4, .18, .42, D / 2 + .02, color="stone")
DZ = D / 2
for s in (-1, 1):                       # double doors standing open
    b.box((1.15, 2.0, .12), (s * 1.62, FY + 1.0, DZ - .62), "wood2",
          rot=[("y", s * 62)])
    b.box((.1, 1.6, .14), (s * 1.75, FY + 1.0, DZ - .78), "gold2", rot=[("y", s * 62)])
b.box((2.9, .25, .5), (0, .72 + 2.1, DZ + .18), "pink2")   # door lintel
for s in (-1, 1):
    b.box((.26, 2.1, .36), (s * 1.45, .72 + 1.05, DZ + .12), "blue2")  # pilasters
b.ball(.09, (0, .72 + .95, DZ + .3), "gold")
# ---- banners above the entrance
for i, c in ((-1, "pink"), (0, "blue"), (1, "pink2")):
    x = i * .95
    b.box((.62, .9, .05), (x, .72 + 2.6, DZ + .34), c)
    b.mesh([(x - .31, .72 + 2.15, DZ + .345), (x + .31, .72 + 2.15, DZ + .345),
            (x, .72 + 1.9, DZ + .345)], [(0, 1, 2), (0, 2, 1)], c)
b.box((2.9, .08, .08), (0, .72 + 3.06, DZ + .34), "gold2")
# ---- small cellar door at the back, slightly sunken
b.box((1.5, .6, .9), (0, 0, -D / 2 - .45), "stone2", base=True)
b.box((1.0, 1.1, .18), (0, .55, -D / 2 - .06), "darkwood")
b.box((1.2, .14, .3), (0, 1.13, -D / 2 - .1), "grey3")
b.ball(.06, (.33, 1.0, -D / 2 - .16), "gold2")
b.steps(1.1, 2, .2, .3, -D / 2 - .5, color="stone2")
# ---------------- interior: entrance hall, counter, benches, stairs ----------
IY = FY
for s in (-1, 1):                          # two columns in the hall
    b.cyl(.22, Y2 - IY - .1, (s * 1.9, IY, .9), "plaster2", sections=8, base=True)
    b.box((.5, .18, .5), (s * 1.9, IY + .09, .9), "pink")
    b.box((.5, .18, .5), (s * 1.9, Y2 - .2, .9), "blue2")
for i in range(5):                                                   # pink runner
    b.box((1.6, .04, .9), (0, IY + .02, D / 2 - 1.0 - i * .9), "pink")
# clerk's counter at the back
b.box((3.4, 1.0, .5), (0, IY, -1.1), "wood2", base=True)
b.box((3.6, .1, .7), (0, IY + 1.03, -1.1), "wood")
for s in (-1, 1):
    b.box((.12, 1.05, .6), (s * 1.7, IY, -1.15), "blue2", base=True)
b.chair((0, IY, -1.75), ang=180)
b.box((.5, .06, .36), (-.6, IY + 1.1, -1.2), "white")               # papers
b.box((.3, .3, .26), (.9, IY + 1.2, -1.2), "glass")                 # lamp
b.ball(.1, (.9, IY + 1.42, -1.2), "candle")
# benches along the side walls
for s in (-1, 1):
    for z in (-.2, 1.1):
        b.box((.5, .45, 1.1), (s * (W / 2 - T - .45), IY, z), "wood2", base=True)
        b.box((.6, .1, 1.2), (s * (W / 2 - T - .45), IY + .5, z), "wood")
        b.box((.14, .5, 1.2), (s * (W / 2 - T - .1), IY + .75, z), "wood")
# staircase up to the first floor, along the back-left wall
b.stairs_inside((-(W - T * 2) / 2 + .8, IY, -D / 2 + T + .3), w=1.3, n=9,
                rise=(Y2 - IY + .1) / 9, run=.33, dirz=1)
b.box((1.3, .2, 1.0), (-(W - T * 2) / 2 + .8, Y2 - .1, -D / 2 + T + 3.3), "wood2")
# upstairs: a council table with chairs
for i, (dx, dz) in enumerate([(-.9, .9), (.9, .9), (-.9, -.9), (.9, -.9)]):
    b.chair((dx * 1.5, Y2, dz * 1.1), ang=0 if dz > 0 else 180)
b.table((0, Y2, 0), w=2.6, d=1.3, h=.78)
b.box((.8, .5, .12), (0, Y2 + 1.4, -D / 2 + T + .2), "pink")        # wall crest
b.ball(.14, (0, Y2 + 1.75, -D / 2 + T + .2), "gold")
finish(b, "out/radnice.glb", "Radnice")
