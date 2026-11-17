"""Modular candy race-track pieces. Entry at origin, track runs toward -Z."""
from draha_lib import *

# ---------------- 1. start section (gate, start line, grandstand) ------------
def p_start():
    b = Builder()
    straight(b, 9.0)
    chequer(b, 0, -.2, rows=2)
    arch(b, 0, 0, label="START")
    flags(b, 0, -1.6, n=4)
    GX = TW / 2 + 2.6                               # grandstand on the right
    b.box((3.6, .3, 6.0), (GX, 0, -4.0), "cream", base=True)
    for i in range(5):
        y = .3 + i * .45
        b.box((3.2 - i * .1, .45, .9), (GX + i * .42, y, -4.0), "sand", base=True)
        b.box((3.0 - i * .1, .16, .8), (GX + i * .42, y + .45, -4.0),
              "lol" if i % 2 else "mint")
        for k in range(5):
            b.box((.5, .3, .5), (GX + i * .42 - 1.2 + k * .6, y + .53, -4.0),
                  ["pink", "blue", "yellow", "mint", "lol"][(k + i) % 5], base=True)
    b.box((4.4, .22, 6.4), (GX + 1.0, 3.0, -4.0), "pink2")
    for i in range(8):
        b.box((4.4, .24, .8), (GX + 1.0, 3.02, -7.0 + i * .8),
              "white" if i % 2 == 0 else "pink")
    for z in (-1.4, -4.0, -6.6):
        b.box((.18, 2.8, .18), (GX + 2.9, 1.5, z), "cream")
    b.box((.14, 1.0, 6.0), (GX - 1.7, .8, -4.0), "white")
    return b, "draha_start", "DrahaStart"

# ---------------- 2. straight ------------------------------------------------
def p_rovna():
    b = Builder(); straight(b, 7.2)
    for s in (-1, 1):                               # low candy barrier
        for i in range(8):
            b.box((.3, .55, .8), (s * (TW / 2 + .55), .28, -.45 - i * .9),
                  CAND[i % 2], base=False)
    return b, "draha_rovna", "DrahaRovna"

# ---------------- 2b. short straight (3.6 m, for fine tuning) ----------------
def p_rovna_kratka():
    b = Builder(); straight(b, 3.6)
    for s in (-1, 1):
        for i in range(4):
            b.box((.3, .55, .8), (s * (TW / 2 + .55), .28, -.45 - i * .9),
                  CAND[i % 2])
    return b, "draha_rovna_kratka", "DrahaRovnaKratka"

# ---------------- 3. straight with flags (decorative) ------------------------
def p_rovna_vlajky():
    b = Builder(); straight(b, 7.2); flags(b, 0, 0, n=4, step=1.8)
    return b, "draha_rovna_vlajky", "DrahaRovnaVlajky"

# ---------------- 4./5. 90 degree curves -------------------------------------
def p_zatacka(left=True):
    b = Builder()
    ex = curve(b, R=7.0, left=left, deg=90.0)
    s = -1 if left else 1
    for i in range(7):                              # bunting on the outside
        t = np.radians(90) * (i + .5) / 7
        R2 = 7.0 + TW / 2 + 1.2
        x = s * 7.0 - s * R2 * np.cos(t); z = -R2 * np.sin(t)
        b.box((.09, 2.2, .09), (x, 1.1, z), "cream")
        b.ball(.12, (x, 2.3, z), "gold", sub=0)
        b.mesh([(x, 2.1, z), (x, 1.6, z), (x - s * .6, 1.85, z + .1)],
               [(0, 1, 2), (0, 2, 1)], ["lol", "mint", "blue"][i % 3])
    name = "draha_zatacka_vlevo" if left else "draha_zatacka_vpravo"
    return b, name, "DrahaZatacka"

# ---------------- 6./7. ramps -------------------------------------------------
def p_rampa(down=False):
    b = Builder(); ramp(b, L=7.2, H=1.6, down=down)
    name = "draha_klesani" if down else "draha_stoupani"
    return b, name, "DrahaRampa"

# ---------------- 8. jump with a gap -----------------------------------------
def p_skok():
    b = Builder()
    ramp(b, L=4.5, H=1.8)                           # take-off
    for s in (-1, 1):                               # gap marked by candy posts
        for i in range(3):
            b.box((.3, 1.0, .3), (s * (TW / 2 + .4), .5, -5.2 - i * 1.3),
                  CAND[i % 2], base=False)
    b.box((TW + 1.6, .2, 5.4), (0, .05, -7.2), "mint")      # jelly landing zone
    for i in range(6):
        b.box((TW, .1, .8), (0, .2, -4.9 - i * .9), "teal" if i % 2 else "mint")
    ramp(b, L=4.5, H=1.8, z0=-9.9, down=True)
    for i in range(5):                              # chevrons before the ramp
        b.box((TW - 1.0, .06, .3), (0, .14, -.4 - i * .8), "yellow")
    return b, "draha_skok", "DrahaSkok"

# ---------------- 9. chicane --------------------------------------------------
def p_sikana():
    b = Builder()
    straight(b, 9.0)
    for i, (x, z) in enumerate([(-1.8, -2.0), (1.8, -4.4), (-1.8, -6.8)]):
        b.cyl(.55, 1.3, (x, .12, z), CAND[i % 2], sections=10, base=True)
        b.cyl(.62, .18, (x, 1.42, z), "cream", sections=10, base=True)
        b.ball(.3, (x, 1.75, z), ["lol", "mint", "yellow"][i % 3], sub=1)
    for s in (-1, 1):
        for i in range(10):
            b.box((.3, .5, .8), (s * (TW / 2 + .55), .25, -.45 - i * .9),
                  CAND[i % 2])
    return b, "draha_sikana", "DrahaSikana"

# ---------------- 10. liquorice tunnel ---------------------------------------
def p_tunel():
    b = Builder()
    straight(b, 7.2)
    N, M = 9, 11
    RX, RY = TW / 2 + .5, TW / 2 + .2
    def P(i, z, r=1.0):
        a0 = np.pi * i / (M - 1)
        return (np.cos(a0) * RX * r, np.sin(a0) * RY * r, z)
    for k in range(N):                              # continuous candy vault
        z0, z1 = -.05 - k * .8, -.05 - (k + 1) * .8
        for i in range(M - 1):
            c = CAND[(k + i) % 2]
            b.mesh([P(i, z0), P(i + 1, z0), P(i + 1, z1), P(i, z1)],
                   [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)], c)
            b.mesh([P(i, z0, .93), P(i + 1, z0, .93), P(i + 1, z1, .93), P(i, z1, .93)],
                   [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)],
                   "cream" if (k + i) % 2 else c)
    for e in (0, M - 1):                            # thicker rims at both ends
        for k in (0, N):
            z = -.05 - k * .8
            b.cyl(.3, .3, P(e, z)[:2] + (z,), "pink2", sections=8, base=False)
    for s in (-1, 1):                               # candy drips inside
        for i in range(4):
            b.ball(.22, (s * 1.6, 2.9, -1.2 - i * 1.8),
                   ["lol", "mint", "yellow", "blue"][i % 4], sub=1)
    return b, "draha_tunel", "DrahaTunel"

# ---------------- 11. finish gate ---------------------------------------------
def p_cil():
    """Overlay gantry - place it over any straight piece, it adds no length."""
    b = Builder()
    chequer(b, 0, -1.0, rows=3)
    arch(b, 0, 0, label="CIL", cheq=True)
    for s in (-1, 1):                               # chequered flags
        x = s * (TW / 2 + 1.4)
        b.box((.1, 3.0, .1), (x, 1.5, -1.9), "cream")
        for i in range(9):
            r, c = divmod(i, 3)
            b.box((.26, .26, .06), (x + s * (.2 + c * .26), 2.5 - r * .26, -1.9),
                  "white" if (r + c) % 2 == 0 else "dark")
    return b, "draha_cil", "DrahaCil"

# ---------------- 12. barrier set (decoration) --------------------------------
def p_bariery():
    b = Builder()
    for i in range(8):
        z = -.45 - i * .9
        b.box((.35, .6, .8), (0, .3, z), CAND[i % 2])
        b.box((.45, .14, .85), (0, .66, z), "cream")
    for i in range(4):
        b.cyl(.3, .14, (0, .75, -.9 - i * 1.8), ["lol", "mint", "yellow", "blue"][i],
              sections=10, axis="y", base=True)
    return b, "draha_bariery", "DrahaBariery"

for fn, args in [(p_start, ()), (p_rovna, ()), (p_rovna_kratka, ()), (p_rovna_vlajky, ()),
                 (p_zatacka, (True,)), (p_zatacka, (False,)),
                 (p_rampa, (False,)), (p_rampa, (True,)), (p_skok, ()),
                 (p_sikana, ()), (p_tunel, ()), (p_cil, ()), (p_bariery, ())]:
    bb, fname, nname = fn(*args)
    finish(bb, f"out/{fname}.glb", nname, center=False)
