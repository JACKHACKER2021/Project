from lib3d import *
b = Builder()
W, D, H = 7.0, 5.0, 2.6     # floor 1
# ---- base plinth
b.box((W + .4, .3, D + .4), (0, 0, 0), "stone2", base=True)
# ---- two storeys of light plaster
b.box((W, H, D), (0, .3, 0), "plaster", base=True)
b.box((W - .3, H - .2, D - .3), (0, .3 + H, 0), "plaster2", base=True)
# pink string course between floors + blue cornice on top
b.box((W + .25, .18, D + .25), (0, .3 + H + .09, 0), "pink")
b.box((W + .3, .22, D + .3), (0, .3 + H + H - .2 + .11, 0), "blue2")
Y2 = .3 + H
TOP = Y2 + H - .2 + .22
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
b.box((2.4, 2.0, .3), (0, .72 + 1.0, DZ + .1), "wood2")
for s in (-1, 1):
    b.box((.1, 2.0, .34), (s * .6, .72 + 1.0, DZ + .12), "gold2")
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
finish(b, "out/radnice.glb", "Radnice")
