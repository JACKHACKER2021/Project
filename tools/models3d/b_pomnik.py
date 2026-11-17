from lib3d import *
b = Builder()
# ---- bit of track the memorial stands beside
for i in range(9):
    b.box((2.6, .12, .26), (0, .06, -2.4 + i * .6), "darkwood")
b.box((2.9, .18, 5.4), (0, 0, .6), "mud2", base=True)
for s in (-1, 1):                                   # rails
    b.box((.12, .14, 5.4), (s * .72, .25, .6), "grey3")
    b.box((.2, .05, 5.4), (s * .72, .34, .6), "grey")
# ---- gravel plinth
b.box((2.4, .25, 1.4), (0, .0, 2.6), "stone2", base=True)
b.box((2.0, .18, 1.1), (0, .25, 2.6), "grey", base=True)
# ---- two stones side by side: blue for Leox, red for Nelea
for (s, c, c2) in ((-1, "deepblue", "blue"), (1, "red2", "red")):
    x = s * .52
    b.box((.78, 1.05, .3), (x, .43, 2.55), c, base=True, rot=[("z", s * 1.5)])
    b.cyl(.39, .3, (x, 1.46, 2.55), c, sections=10, axis="z")      # rounded top
    b.box((.52, .66, .1), (x, .95, 2.42), c2)                      # inset panel
    b.cyl(.26, .12, (x, 1.44, 2.42), c2, sections=10, axis="z")
    b.ball(.1, (x, 1.46, 2.38), "cream", sub=1)                    # little portrait dot
    for k in range(3):                                             # engraved lines
        b.box((.34, .05, .05), (x, .78 + k * .17, 2.37), "cream")
# small joined plaque between them
b.box((.5, .3, .12), (0, .62, 2.42), "grey3")
b.box((.34, .06, .06), (0, .68, 2.36), "cream")
b.box((.34, .06, .06), (0, .56, 2.36), "cream")
# ---- candles
for (x, z, h) in [(-1.0, 2.05, .22), (-.6, 1.95, .18), (.65, 1.98, .24), (1.05, 2.1, .2)]:
    b.cyl(.09, h, (x, .43, z), "glass", sections=8, base=True)
    b.cyl(.07, h * .7, (x, .45, z), "cream", sections=8, base=True)
    b.box((.02, .05, .02), (x, .43 + h, z), "dark")
    b.ball(.055, (x, .46 + h + .03, z), "candle", sub=1)
    b.ball(.03, (x, .46 + h + .09, z), "yellow", sub=0)
# ---- flowers laid at the base
import random; random.seed(13)
cols = ["pink", "lol", "yellow", "white", "blue", "purple"]
for i in range(14):
    x = random.uniform(-.95, .95); z = random.uniform(1.95, 2.25)
    ang = random.uniform(0, 90)
    b.box((.32, .04, .05), (x, .46, z), "green2", rot=[("y", ang), ("z", 6)])
    b.ball(.085, (x + .14, .51, z), random.choice(cols), sub=0)
    b.ball(.05, (x + .14, .55, z), "cream", sub=0)
# small bunch leaning on the blue stone
for k in range(4):
    b.box((.05, .5, .05), (-.75 + k * .05, .68, 2.3), "green2", rot=[("z", -22 + k * 6)])
    b.ball(.08, (-.86 + k * .05, .92, 2.3), cols[k], sub=0)
# ---- grass tufts
for i in range(16):
    x = random.uniform(-1.9, 1.9); z = random.uniform(1.6, 3.6)
    if abs(x) < 1.2 and 1.9 < z < 3.3: continue
    h = random.uniform(.12, .26)
    b.box((.06, h, .06), (x, h / 2, z), random.choice(["green2", "moss"]),
          rot=[("z", random.uniform(-30, 30))])
finish(b, "out/pomnik_u_koleji.glb", "PomnikUKoleji")
