"""Shared pieces of the candy race track.

Convention for every track piece:
  * the ENTRY is at the origin, the track runs toward -Z,
  * roadway width TW, bottom on y = 0, nothing is re-centred on export,
  * each builder returns (exit_x, exit_z, exit_yaw_deg) of its far end,
    so pieces can be chained.
"""
from lib3d import *
import numpy as np

TW = 7.0            # roadway width
ST = .9             # one candy stripe
CAND = ("lol", "white")

def _stripe(b, i, pos, ang=0.0, length=ST, w=TW):
    b.box((w, .12, length), (pos[0], .06 + pos[1], pos[2]),
          "pink" if i % 2 == 0 else "white", rot=[("y", ang)])

def kerb(b, i, pos, ang=0.0, length=ST):
    """Candy-cane kerb cylinder on both edges."""
    a = np.radians(ang)
    nx, nz = np.cos(a), -np.sin(a)      # sideways direction
    for s in (-1, 1):
        x = pos[0] + s * nx * (TW / 2 + .2)
        z = pos[2] + s * nz * (TW / 2 + .2)
        b.cyl(.22, length, (x, .06 + pos[1], z), CAND[i % 2], sections=8,
              axis="z" if abs(ang) < 1e-6 else "z", base=False) if abs(ang) < 1e-6 \
            else b.box((.4, .4, length), (x, .18 + pos[1], z), CAND[i % 2],
                       rot=[("y", ang)])

def straight(b, L=7.2, x0=0.0, z0=0.0, y0=0.0, kerbs=True):
    n = int(round(L / ST))
    for i in range(n):
        z = z0 - (i + .5) * ST
        _stripe(b, i, (x0, y0, z))
        if kerbs:
            kerb(b, i, (x0, y0, z))
    return (x0, z0 - n * ST, 0.0)

def curve(b, R=7.0, x0=0.0, z0=0.0, left=True, deg=90.0):
    """Arc turning left (toward -X) or right (toward +X)."""
    s = -1 if left else 1
    cx, cz = x0 + s * R, z0
    N = max(6, int(np.radians(deg) * R / ST))
    dt = np.radians(deg) / N
    for i in range(N):
        t = (i + .5) * dt
        px = cx - s * R * np.cos(t)
        pz = cz - R * np.sin(t)
        ang = np.degrees(t) * (1 if left else -1)
        seg = R * dt + .12
        # annulus sector instead of a rotated box, so the segments meet cleanly
        t0, t1 = i * dt, (i + 1) * dt + 1e-4
        r1, r2 = R - TW / 2, R + TW / 2
        def P(r, tt, y):
            return (cx - s * r * np.cos(tt), y, cz - r * np.sin(tt))
        col = "pink" if i % 2 == 0 else "white"
        for y in (.12,):
            b.mesh([P(r1, t0, y), P(r2, t0, y), P(r2, t1, y), P(r1, t1, y)],
                   [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)], col)
        for r in (r1, r2):                         # side rims give it thickness
            b.mesh([P(r, t0, 0), P(r, t1, 0), P(r, t1, .12), P(r, t0, .12)],
                   [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)], col)
        a = np.radians(ang)
        nx, nz = np.cos(a), -np.sin(a)
        for e in (-1, 1):
            b.box((.4, .4, seg + .05),
                  (px + e * nx * (TW / 2 + .2), .18, pz + e * nz * (TW / 2 + .2)),
                  CAND[i % 2], rot=[("y", ang)])
    tt = np.radians(deg)
    return (cx - s * R * np.cos(tt), cz - R * np.sin(tt), deg * (1 if left else -1))

def ramp(b, L=7.2, H=1.6, x0=0.0, z0=0.0, down=False):
    """Wedge going up (or down) along -Z."""
    n = int(round(L / ST))
    slope = np.degrees(np.arctan2(H, L))
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        y = (H * (t0 + t1) / 2) if not down else H * (1 - (t0 + t1) / 2)
        z = z0 - (i + .5) * ST
        b.box((TW, .14, ST / np.cos(np.radians(slope)) + .04), (0 + x0, y + .07, z),
              "pink" if i % 2 == 0 else "white", rot=[("x", slope if not down else -slope)])
        for e in (-1, 1):
            b.box((.4, .4, ST), (x0 + e * (TW / 2 + .2), y + .2, z), CAND[i % 2],
                  rot=[("x", slope if not down else -slope)])
    for e in (-1, 1):                       # solid side walls under the ramp
        x = x0 + e * TW / 2
        a, c = (0.0, H) if not down else (H, 0.0)
        b.mesh([(x, 0, z0), (x, 0, z0 - L), (x, c, z0 - L), (x, a, z0)],
               [(0, 1, 2), (0, 2, 3), (0, 2, 1), (0, 3, 2)], "cream")
    b.box((TW, .3, .3), (x0, (H if not down else 0) + .1, z0 - L + .1), "cream")
    return (x0, z0 - L, 0.0)

def flags(b, x0, z0, n=4, step=1.5, h=2.4):
    for i in range(n):
        z = z0 - .6 - i * step
        for s in (-1, 1):
            x = x0 + s * (TW / 2 + 1.1)
            b.box((.09, h, .09), (x, h / 2, z), "cream")
            b.ball(.13, (x, h + .1, z), "gold", sub=0)
            c = ["lol", "mint", "blue", "yellow"][i % 4]
            b.mesh([(x, h - .1, z), (x, h - .65, z), (x + s * .7, h - .35, z + .1)],
                   [(0, 1, 2), (0, 2, 1)], c)

def arch(b, x0, z0, label=None, cheq=False, h=4.6):
    """Candy-cane gate across the track."""
    for s in (-1, 1):
        x = x0 + s * (TW / 2 + .55)
        b.cyl(.5, .3, (x, 0, z0), "cream", sections=12, base=True)
        for i in range(int(h / .45)):
            b.cyl(.32, .46, (x, .3 + i * .45, z0), CAND[i % 2], sections=8, base=True)
        b.cyl(.4, .2, (x, h + .2, z0), "cream", sections=12, base=True)
        b.ball(.3, (x, h + .55, z0), "mint", sub=1)
    b.box((TW + 2.2, .55, .8), (x0, h, z0), "pink2")
    for i in range(12):
        c = ("white" if i % 2 == 0 else "lol") if not cheq else \
            ("white" if (i % 2) == 0 else "dark")
        b.box((.45, .5, .84), (x0 - TW / 2 - .8 + i * (TW + 1.6) / 11, h, z0), c)
    b.box((TW + 2.4, .18, 1.0), (x0, h + .42, z0), "cream")
    b.box((TW + 2.4, .18, 1.0), (x0, h - .42, z0), "cream")
    if label:
        b.box((5.2, 1.1, .2), (x0, h + 1.1, z0 + .12), "cream")
        for o in (-1.8, -.9, 0, .9, 1.8)[:len(label)]:
            b.box((.5, .7, .14), (x0 + o, h + 1.1, z0 + .26), "red2")
            b.box((.3, .45, .18), (x0 + o, h + 1.1, z0 + .3), "cream")
        b.box((5.4, .2, .3), (x0, h + 1.72, z0 + .14), "pink2")
    for i in range(9):                       # pennants
        x = x0 - TW / 2 - .6 + i * (TW + 1.2) / 8
        c = ["lol", "mint", "yellow", "blue"][i % 4]
        b.mesh([(x - .22, h - .5, z0 + .3), (x + .22, h - .5, z0 + .3),
                (x, h - 1.05, z0 + .3)], [(0, 1, 2), (0, 2, 1)], c)

def chequer(b, x0, z0, rows=2):
    for r in range(rows):
        for i in range(14):
            c = "white" if (i + r) % 2 == 0 else "dark"
            b.box((TW / 14, .06, .5), (x0 - TW / 2 + TW / 28 + i * TW / 14, .15,
                                       z0 - .25 - r * .5), c)
