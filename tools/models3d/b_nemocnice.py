from lib3d import *
b = Builder()
W, D, F = 8.0, 5.5, 2.5
b.box((W + .3, .25, D + .3), (0, 0, 0), "grey", base=True)
# three white floors, top one slightly narrower; flat roofs with parapets
b.box((W, F * 2, D), (0, .25, 0), "white", base=True)
b.box((W - 1.6, F, D - .6), (0, .25 + F * 2, 0), "bone", base=True)
T2, T3 = .25 + F * 2, .25 + F * 3
b.box((W + .2, .2, D + .2), (0, T2 + .1, 0), "grey")               # roof slab fl.2
b.box((W - 1.4, .2, D - .4), (0, T3 + .1, 0), "grey")              # roof slab fl.3
for s in (1, -1):                                                   # parapets
    b.box((W + .2, .3, .14), (0, T2 + .35, s * (D / 2 + .03)), "bone")
    b.box((.14, .3, D + .2), (s * (W / 2 + .03), T2 + .35, 0), "bone")
b.box((1.2, .5, 1.2), (0, T3 + .2, -1.0), "grey3", base=True)      # roof box
# ---- rows of windows (right side intact, left side wrecked)
xs = [-3.2, -2.0, -.8, .8, 2.0, 3.2]
for fl, y in ((0, 1.5), (1, 1.5 + F)):
    for x in xs:
        if x < 0:   # damaged half: broken dark panes, some boarded
            b.window(.95, 1.25, (x, y, D / 2), color="glassdark", frame="plaster2")
            b.box((.9, .1, .1), (x, y + .15, D / 2 + .1), "darkwood", rot=[("z", 14)])
            b.box((.5, .1, .1), (x + .1, y - .3, D / 2 + .1), "darkwood", rot=[("z", -22)])
        else:
            b.window(.95, 1.25, (x, y, D / 2))
for x in (-1.9, -.6, .6, 1.9):
    b.window(.9, 1.1, (x, T2 + 1.3, D / 2 - .8),
             color="glassdark" if x < 0 else "glass", frame="white")
for s, f in ((1, "x"), (-1, "-x")):
    for z in (-1.7, -.4, 1.0):
        for y in (1.5, 1.5 + F):
            dmg = s < 0
            b.window(.9, 1.2, (s * W / 2, y, z),
                     color="glassdark" if dmg else "glass",
                     frame="plaster2" if dmg else "white")
# ---- peeling plaster + dark stains on the damaged (left / -X) side
for (x, y, z, w, h) in [(-3.6, 3.4, 0, 1.4, 1.1), (-2.2, 1.0, 0, 1.1, .8),
                        (-3.0, 5.4, 0, 1.6, .9), (-1.4, 4.2, 0, .9, 1.3)]:
    b.box((w, h, .07), (x, y, D / 2 + .035), "plaster2")
for (y, z, w, h) in [(4.4, -.6, 1.6, 1.4), (2.2, 1.2, 1.2, 1.0), (6.0, .2, 1.0, 1.2)]:
    b.box((.07, h, w), (-W / 2 - .035, y, z), "plaster2")
for (x, y, w, h) in [(-3.3, 2.3, .7, 1.6), (-1.1, 5.1, .5, 1.8), (-2.4, 3.9, .6, 1.2)]:
    b.box((w, h, .05), (x, y, D / 2 + .09), "soot")
for (y, z, w, h) in [(3.2, -1.4, .6, 1.9), (5.6, 1.4, .5, 1.3)]:
    b.box((.05, h, w), (-W / 2 - .08, y, z), "soot")
# cracked corner chunk missing
b.box((.6, .5, .6), (-W / 2 + .2, T2 + .4, -D / 2 + .25), "grey3", rot=[("y", 18)])
# ---- entrance: canopy, doors, red cross
b.steps(3.0, 3, .18, .4, D / 2 + .02, color="grey")
DZ = D / 2
b.box((3.0, 2.2, .25), (0, .54 + 1.1, DZ + .08), "bone")
for s in (-1, 1):
    b.box((1.25, 2.0, .2), (s * .75, .54 + 1.0, DZ + .2), "glass")
    b.box((.08, 2.0, .24), (s * .05, .54 + 1.0, DZ + .22), "grey3")
b.box((3.6, .18, 1.4), (0, .54 + 2.3, DZ + .55), "grey")    # canopy
for s in (-1, 1):
    b.box((.12, 2.3, .12), (s * 1.6, .54 + 1.15, DZ + 1.1), "grey3")
b.box((.95, .3, .12), (0, .54 + 3.0, DZ + .06), "red2")     # red cross
b.box((.3, .95, .12), (0, .54 + 3.0, DZ + .06), "red2")
finish(b, "out/nemocnice.glb", "Nemocnice")
