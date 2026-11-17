from lib3d import *
import numpy as np
b = Builder()
CL, CW, CH = 7.0, 2.6, 2.5      # one car: length, width, body height
GAP = .55

def car(zc, front=False, back=False):
    y0 = .55                                           # top of bogies
    # ---- body with rounded ends (chamfer boxes)
    b.box((CW, CH, CL - 1.2), (0, y0, zc), "green", base=True)
    b.box((CW - .5, CH - .5, CL + .1), (0, y0 + .25, zc), "yellow", base=True)
    for s in (-1, 1):                                  # rounded cab/end faces
        ez = zc + s * (CL / 2 - .6)
        b.box((CW - .25, CH - .25, .5), (0, y0 + .12, ez + s * .25), "green", base=True)
        b.box((CW - .8, CH - .8, .5), (0, y0 + .4, ez + s * .5), "green", base=True)
        b.cyl(.42, CW - .3, (0, y0 + CH - .42, ez + s * .3), "yellow", sections=8, axis="x")
    # ---- yellow-green livery band
    b.box((CW + .06, .4, CL - .3), (0, y0 + 1.0, zc), "yellow")
    b.box((CW + .06, .14, CL - .3), (0, y0 + .75, zc), "green2")
    # ---- skirt / underframe
    b.box((CW - .2, .35, CL - .2), (0, .2, zc), "dark", base=True)
    # ---- big windows down both sides
    for s, f in ((1, "x"), (-1, "-x")):
        for i in range(5):
            z = zc - 2.4 + i * 1.2
            b.window(1.0, 1.0, (s * CW / 2, y0 + 1.55, z), color="glassdark",
                     frame="cream", facing=f if s > 0 else "-x")
        # doors
        for z in (zc - 1.8, zc + 1.8):
            b.box((.1, 1.9, .95), (s * (CW / 2 - .02), y0 + .95, z), "green2")
            b.box((.12, .8, .8), (s * (CW / 2 + .02), y0 + 1.6, z), "glassdark")
    # ---- roof
    b.box((CW - .1, .2, CL - .3), (0, y0 + CH, zc), "grey3", base=True)
    b.cyl(.35, CL - .5, (0, y0 + CH - .05, zc), "grey", sections=8, axis="z")
    b.box((.5, .3, 1.2), (0, y0 + CH + .2, zc - 1.5), "grey4", base=True)
    # ---- end faces: round front, red headlights
    for s, is_end in ((1, front), (-1, back)):
        ez = zc + s * (CL / 2 + .1)
        if is_end:
            b.cyl(.5, .5, (0, y0 + 1.5, ez + s * .1), "yellow", sections=10, axis="z")
            b.box((1.9, 1.1, .22), (0, y0 + 1.75, ez + s * .06), "glassdark")  # cab glass
            b.box((2.1, .2, .3), (0, y0 + 2.35, ez + s * .06), "green2")
            for d in (-.75, .75):                       # red lamps
                b.cyl(.2, .18, (d, y0 + .95, ez + s * .1), "red2", sections=8, axis="z")
                b.cyl(.12, .22, (d, y0 + .95, ez + s * .12), "red", sections=8, axis="z")
            b.box((2.3, .3, .3), (0, y0 + .4, ez + s * .1), "dark")   # bumper
            b.box((.3, .3, .5), (0, y0 - .05, ez + s * .2), "grey4")  # coupler
            b.box((2.2, .16, .4), (0, .18, ez + s * .05), "grey4")    # plough
        else:
            b.box((CW - .4, CH - .4, .25), (0, y0 + .2, ez), "dark", base=True)
            b.box((.3, .3, .6), (0, y0 + .5, ez + s * .15), "grey4")
    # ---- bogies and wheels
    for bz in (zc - 2.2, zc + 2.2):
        b.box((CW - .5, .3, 1.7), (0, .4, bz), "dark")
        for s in (-1, 1):
            for wz in (bz - .55, bz + .55):
                b.cyl(.38, .22, (s * (CW / 2 - .22), .38, wz), "grey4", sections=10, axis="x")
                b.cyl(.18, .26, (s * (CW / 2 - .22), .38, wz), "rust", sections=8, axis="x")

TOT = CL * 3 + GAP * 2
z0 = -TOT / 2 + CL / 2
car(z0 + (CL + GAP) * 0, back=True)
car(z0 + (CL + GAP) * 1)
car(z0 + (CL + GAP) * 2, front=True)
# ---- piece of track underneath
for i in range(int(TOT / .62) + 2):
    b.box((3.2, .14, .28), (0, .07, -TOT / 2 - .3 + i * .62), "darkwood")
for s in (-1, 1):
    b.box((.14, .18, TOT + 1.2), (s * (CW / 2 - .22), .23, 0), "grey3")
finish(b, "out/vlak_regionova.glb", "VlakRegionova")
