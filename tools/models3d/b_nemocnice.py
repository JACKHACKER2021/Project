from lib3d import *
b = Builder()
W, D, F = 8.0, 5.5, 2.5
b.box((W + .3, .25, D + .3), (0, 0, 0), "grey", base=True)
# three white floors, top one slightly narrower; flat roofs with parapets
T = .26
FY = .54                                      # ground floor (door threshold)
xs0 = [-3.2, -2.0, -.8, .8, 2.0, 3.2]
b.shell(W, D, F * 2, .25, T, "white", holes={
    "front": [(0, 3.0, FY - .25, 2.2)] + [(x, .95, .625, 1.25) for x in xs0]
             + [(x, .95, .625 + F, 1.25) for x in xs0],
    "back":  [(x, .9, .7, 1.1) for x in (-2.4, 0, 2.4)]
             + [(x, .9, .7 + F, 1.1) for x in (-2.4, 0, 2.4)],
    "left":  [(z, .9, .65, 1.2) for z in (-1.7, -.4, 1.0)]
             + [(z, .9, .65 + F, 1.2) for z in (-1.7, -.4, 1.0)],
    "right": [(z, .9, .65, 1.2) for z in (-1.7, -.4, 1.0)]
             + [(z, .9, .65 + F, 1.2) for z in (-1.7, -.4, 1.0)]})
b.shell(W - 1.6, D - .6, F, .25 + F * 2, T, "bone", holes={
    "front": [(x, .9, .75, 1.1) for x in (-1.9, -.6, .6, 1.9)],
    "left":  [(z, .8, .8, 1.0) for z in (-1.2, .6)],
    "right": [(z, .8, .8, 1.0) for z in (-1.2, .6)]})
b.box((W - T * 2, FY - .25, D - T * 2), (0, .25 + (FY - .25) / 2, 0), "grey")
b.box((W - T * 2, .1, D - T * 2), (0, FY - .05, 0), "bone")          # ground floor
b.box((W - T * 2, .2, D - T * 2 - 2.2), (0, .25 + F - .1, -1.1), "grey")   # 1st slab
b.box((W - T * 2, .2, 2.2), (0, .25 + F * 2 - .1, 1.65), "grey")           # 2nd slab
b.box((W - 1.6 - T * 2, .2, 2.0), (0, .25 + F * 2 - .1, -1.6), "grey")
b.box((W - 1.6 - T * 2, .16, D - .6 - T * 2), (0, .25 + F * 3 - .08, 0), "bone")
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
    b.window(.9, 1.1, (x, T2 + 1.3, (D - .6) / 2),
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
b.box((3.6, .3, .35), (0, FY + 2.25, DZ + .02), "bone")
for s in (-1, 1):                     # sliding doors pushed aside
    b.box((1.25, 2.0, .12), (s * 1.45, FY + 1.0, DZ - .25), "glass")
    b.box((.1, 2.05, .16), (s * 2.05, FY + 1.0, DZ - .25), "grey3")
b.box((3.6, .18, 1.4), (0, .54 + 2.3, DZ + .55), "grey")    # canopy
for s in (-1, 1):
    b.box((.12, 2.3, .12), (s * 1.6, .54 + 1.15, DZ + 1.1), "grey3")
b.box((.95, .3, .12), (0, .54 + 3.0, DZ + .06), "red2")     # red cross
b.box((.3, .95, .12), (0, .54 + 3.0, DZ + .06), "red2")
# ---------------- interior: reception, corridor, wards -----------------------
IY = FY
b.box((W - T * 2, .05, D - T * 2), (0, IY + .03, 0), "mint")        # lino floor
for i in range(7):                                                   # floor tile lines
    b.box((W - T * 2, .03, .06), (0, IY + .06, -2.4 + i * .8), "white")
# reception desk
b.box((2.6, 1.05, .6), (-1.4, IY, .9), "white", base=True)
b.box((2.8, .1, .8), (-1.4, IY + 1.08, .9), "mint")
b.box((2.6, .12, .6), (-1.4, IY + .55, .95), "red")
b.chair((-1.4, IY, .2), ang=0, seat="mint", back="grey3")
# waiting bench
for s in (0, 1):
    b.box((2.2, .45, .5), (1.9, IY, 1.3 - s * .0), "grey", base=True)
b.box((2.3, .1, .55), (1.9, IY + .5, 1.3), "blue")
b.box((2.3, .5, .1), (1.9, IY + .75, 1.05), "blue")
# corridor partition with two ward doorways
b.wall("x", (-.6, 0), W - T * 2, 2.1, IY, .18, "white",
       holes=[(-2.2, 1.1, 0, 1.95), (2.2, 1.1, 0, 1.95)])
for x in (-2.2, 2.2):                                 # open door leaves
    b.box((1.05, 1.9, .07), (x + .98, IY + .95, -.95), "mint", rot=[("y", 68)])
# two wards behind it: beds with curtains
for (bx, s) in ((-2.4, -1), (2.4, 1)):
    for i in range(2):
        z = -1.4 - i * 1.1
        b.box((.95, .5, 1.9), (bx, IY, z), "grey3", base=True)
        b.box((1.0, .18, 1.95), (bx, IY + .6, z), "white")
        b.box((.7, .16, .4), (bx, IY + .77, z - .7), "bone")        # pillow
        b.box((1.0, .08, 1.2), (bx, IY + .73, z + .3), "blue")      # blanket
        b.box((1.0, .55, .1), (bx, IY + .9, z - 1.0), "grey4")      # headboard
        b.box((.4, .6, .4), (bx + s * .75, IY, z - .4), "white", base=True)
        b.cyl(.04, 1.5, (bx - s * .75, IY, z - .7), "grey3", sections=6, base=True)
        b.box((.2, .3, .2), (bx - s * .75, IY + 1.4, z - .7), "mint")   # drip bag
# staircase to the first floor at the back
b.stairs_inside((0, IY, -D / 2 + T + .3), w=1.4, n=9, rise=(F - .1) / 9, run=.32,
                color="grey3", dirz=1)
# first floor: corridor and a few beds
UY = .25 + F
b.box((W - T * 2, .05, D - T * 2 - 2.2), (0, UY + .03, -1.1), "mint")
b.wall("x", (-1.6, 0), W - T * 2, 2.0, UY, .16, "white",
       holes=[(-2.0, 1.1, 0, 1.9), (2.0, 1.1, 0, 1.9)])
for bx in (-2.6, 2.6):
    b.box((.95, .5, 1.9), (bx, UY, -2.6), "grey3", base=True)
    b.box((1.0, .18, 1.95), (bx, UY + .6, -2.6), "white")
    b.box((1.0, .08, 1.2), (bx, UY + .73, -2.3), "blue")
b.box((2.0, .9, .5), (0, UY, -.2), "white", base=True)              # nurse station
b.box((2.2, .1, .7), (0, UY + .92, -.2), "mint")
finish(b, "out/nemocnice.glb", "Nemocnice")
