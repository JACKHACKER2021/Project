"""Geometry helpers and model library for RadioÚstí.

Models are written in block-local pixel coordinates:
  x: 0..16 west->east, y: 0..16 bottom->top, z: 0..16 north->south.
The FRONT of every directional model faces NORTH (-Z). Rotations are applied
here in Python (not via minecraft:transformation) so that the geometry, the
collision boxes and the script-side multiblock offsets all share one rotation
convention (see rot_xz / DIRS, mirrored in scripts/lib/util.js).
"""

DIRS = ["north", "east", "south", "west"]


def rot_vec(d, x, z):
    """Rotate a direction-vector (x,z) from local (front=north) to world facing d."""
    if d == "north":
        return x, z
    if d == "south":
        return -x, -z
    if d == "west":
        return z, -x
    if d == "east":
        return -z, x
    raise ValueError(d)


FACE_VEC = {"north": (0, -1), "south": (0, 1), "west": (-1, 0), "east": (1, 0)}
VEC_FACE = {v: k for k, v in FACE_VEC.items()}


def rot_face(d, face):
    if face in ("up", "down"):
        return face
    x, z = FACE_VEC[face]
    return VEC_FACE[rot_vec(d, x, z)]


def C(x, y, z, w, h, d, mat=None, faces=None):
    """A cube: origin (min corner) + size. mat = material instance name for all faces."""
    return {"o": (x, y, z), "s": (w, h, d), "mat": mat, "faces": faces}


def B(name, *cubes):
    return {"name": name, "cubes": list(cubes)}


def rot_cube(c, d, cx=8, cz=8):
    (x, y, z), (w, h, dd) = c["o"], c["s"]
    pts = []
    for px in (x, x + w):
        for pz in (z, z + dd):
            rx, rz = rot_vec(d, px - cx, pz - cz)
            pts.append((rx + cx, rz + cz))
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    faces = None
    if c.get("faces"):
        faces = {rot_face(d, f): m for f, m in c["faces"].items()}
    return {"o": (min(xs), y, min(zs)), "s": (max(xs) - min(xs), h, max(zs) - min(zs)),
            "mat": c["mat"], "faces": faces}


def rot_model(bones, d):
    if d == "north":
        return bones
    return [{"name": b["name"], "cubes": [rot_cube(c, d) for c in b["cubes"]]} for b in bones]


def _uv(face, o, s):
    x, y, z = o
    w, h, d = s

    def fit(a, size):
        size = min(max(size, 0), 16)
        a = a % 16
        if a + size > 16:
            a = 16 - size
        return round(a, 3), round(size, 3)

    if face in ("north", "south"):
        u, uw = fit(x, w)
        v, vh = fit(16 - (y + h), h)
    elif face in ("east", "west"):
        u, uw = fit(z, d)
        v, vh = fit(16 - (y + h), h)
    else:
        u, uw = fit(x, w)
        v, vh = fit(z, d)
    return [u, v], [uw, vh]


def cube_json(c):
    o, s = c["o"], c["s"]
    uv = {}
    for f in ("north", "south", "east", "west", "up", "down"):
        u, us = _uv(f, o, s)
        e = {"uv": u, "uv_size": us}
        m = (c.get("faces") or {}).get(f, c["mat"])
        if m:
            e["material_instance"] = m
        uv[f] = e
    return {"origin": [round(o[0] - 8, 3), round(o[1], 3), round(o[2] - 8, 3)],
            "size": [round(s[0], 3), round(s[1], 3), round(s[2], 3)], "uv": uv}


def geometry_entry(ident, bones):
    out = []
    for b in bones:
        out.append({"name": b["name"], "pivot": [0, 0, 0],
                    "cubes": [cube_json(c) for c in b["cubes"]]})
    return {"description": {"identifier": ident, "texture_width": 16, "texture_height": 16,
                            "visible_bounds_width": 3, "visible_bounds_height": 3,
                            "visible_bounds_offset": [0, 1, 0]},
            "bones": out}


def bbox(bones):
    xs0, ys0, zs0, xs1, ys1, zs1 = [], [], [], [], [], []
    for b in bones:
        for c in b["cubes"]:
            (x, y, z), (w, h, d) = c["o"], c["s"]
            xs0.append(x); ys0.append(y); zs0.append(z)
            xs1.append(x + w); ys1.append(y + h); zs1.append(z + d)
    if not xs0:
        return None
    x0 = max(0, min(xs0)); y0 = max(0, min(ys0)); z0 = max(0, min(zs0))
    x1 = min(16, max(xs1)); y1 = min(16, max(ys1)); z1 = min(16, max(zs1))
    if x1 - x0 < 1:
        x1 = min(16, x0 + 1)
    if y1 - y0 < 1:
        y1 = min(16, y0 + 1)
    if z1 - z0 < 1:
        z1 = min(16, z0 + 1)
    return {"origin": [round(x0 - 8, 3), round(y0, 3), round(z0 - 8, 3)],
            "size": [round(x1 - x0, 3), round(y1 - y0, 3), round(z1 - z0, 3)]}


def slice_model(bones, dx, dy, dz):
    """Cut a multi-block model (coords may exceed 16) into the part at offset (dx,dy,dz)."""
    x0, y0, z0 = dx * 16, dy * 16, dz * 16
    out = []
    for b in bones:
        cubes = []
        for c in b["cubes"]:
            (x, y, z), (w, h, d) = c["o"], c["s"]
            ax0, ay0, az0 = max(x, x0), max(y, y0), max(z, z0)
            ax1, ay1, az1 = min(x + w, x0 + 16), min(y + h, y0 + 16), min(z + d, z0 + 16)
            if ax1 - ax0 <= 0 or ay1 - ay0 <= 0 or az1 - az0 <= 0:
                continue
            cubes.append({"o": (ax0 - x0, ay0 - y0, az0 - z0),
                          "s": (ax1 - ax0, ay1 - ay0, az1 - az0), "mat": c["mat"],
                          "faces": c.get("faces")})
        if cubes:
            out.append({"name": b["name"], "cubes": cubes})
    if not out:  # keep geometry valid even for an empty slice
        out = [{"name": "root", "cubes": [C(7.9, 0, 7.9, 0.2, 0.2, 0.2)]}]
    return out


# ---------------------------------------------------------------- pipes/cables

def pipe_model(r, flange=True, bracket=False, joint=True):
    """Connectable pipe. r = half thickness in px. Bones: core,n,s,e,w,u,d (+ joint, fl_*)."""
    a, b = 8 - r, 8 + r
    t = 2 * r
    bones = [B("core", C(a, a, a, t, t, t))]
    bones += [
        B("n", C(a, a, 0, t, t, a)),
        B("s", C(a, a, b, t, t, 16 - b)),
        B("w", C(0, a, a, a, t, t)),
        B("e", C(b, a, a, 16 - b, t, t)),
        B("d", C(a, 0, a, t, a, t)),
        B("u", C(a, b, a, t, 16 - b, t)),
    ]
    if flange:
        f = r + 1
        fa, ft = 8 - f, 2 * f
        bones += [
            B("fl_n", C(fa, fa, 0, ft, ft, 1.5, "detail")),
            B("fl_s", C(fa, fa, 14.5, ft, ft, 1.5, "detail")),
            B("fl_w", C(0, fa, fa, 1.5, ft, ft, "detail")),
            B("fl_e", C(14.5, fa, fa, 1.5, ft, ft, "detail")),
            B("fl_d", C(fa, 0, fa, ft, 1.5, ft, "detail")),
            B("fl_u", C(fa, 14.5, fa, ft, 1.5, ft, "detail")),
        ]
    if joint:
        j = r + 1.5
        bones.append(B("joint", C(8 - j, 8 - j, 8 - j, 2 * j, 2 * j, 2 * j, "detail")))
    if bracket:
        bones.append(B("bracket", C(7, 0, 7, 2, 8 - r, 2, "detail")))
    return bones


def valve_model(r):
    bones = pipe_model(r, flange=True, joint=False)
    j = r + 1
    bones.append(B("body", C(8 - j, 8 - j, 8 - j, 2 * j, 2 * j, 2 * j, "detail")))
    # stem + wheel (open: wheel parallel to pipe, closed: across)
    bones.append(B("stem", C(7.5, 8 + j, 7.5, 1, 2.5, 1, "detail")))
    bones.append(B("wheel_open", C(4.5, 8 + j + 2.5, 7, 7, 1, 2, "wheel"), C(7, 8 + j + 2.5, 4.5, 2, 1, 7, "wheel")))
    bones.append(B("wheel_closed", C(5, 8 + j + 2.5, 5, 6, 1, 6, "wheel")))
    bones.append(B("lamp_open", C(8 + j, 8 + j - 1.5, 7, 1, 1.5, 2, "lamp_green")))
    bones.append(B("lamp_closed", C(8 + j, 8 + j - 1.5, 7, 1, 1.5, 2, "lamp_red")))
    return bones


# ---------------------------------------------------------------- generic shapes

def full():
    return [B("root", C(0, 0, 0, 16, 16, 16))]


def slab_wall(th=8):
    return [B("root", C(0, 0, 8 - th / 2, 16, 16, th))]


def table(top_y=14, top_th=2, inset=1, leg=2, extra=None, top_mat=None):
    cubes = [C(0, top_y, 0, 16, top_th, 16, top_mat)]
    for lx in (inset, 16 - inset - leg):
        for lz in (inset, 16 - inset - leg):
            cubes.append(C(lx, 0, lz, leg, top_y, leg))
    bones = [B("root", *cubes)]
    if extra:
        bones += extra
    return bones


def chair(seat_y=7, back=True, mat=None):
    cubes = [C(2, seat_y, 2, 12, 2, 12, mat)]
    for lx in (2, 12):
        for lz in (2, 12):
            cubes.append(C(lx, 0, lz, 2, seat_y, 2))
    if back:
        cubes.append(C(2, seat_y + 2, 12, 12, 16 - seat_y - 2, 2, mat))
    return [B("root", *cubes)]


def office_chair():
    return [B("root",
              C(7, 0, 2, 2, 1, 12), C(2, 0, 7, 12, 1, 2),          # star base
              C(7, 1, 7, 2, 5, 2, "detail"),                        # gas lift
              C(2, 6, 2, 12, 2, 12, "fabric"),                      # seat
              C(3, 8, 12, 10, 8, 2, "fabric"),                      # backrest (front = north)
              C(1, 8, 4, 1, 3, 7), C(14, 8, 4, 1, 3, 7))]           # arm rests


def stool():
    return [B("root", C(4, 9, 4, 8, 1, 8, "fabric"), C(7, 0, 7, 2, 9, 2, "detail"),
              C(4, 0, 7, 8, 1, 2), C(7, 0, 4, 2, 1, 8))]


def cabinet(h=16, drawers=True):
    cubes = [C(1, 0, 1, 14, h, 14)]
    if drawers:
        for i in range(3):
            cubes.append(C(6, 2 + i * (h // 3), 0.5, 4, 1, 0.5, "detail"))
    return [B("root", *cubes)]


def crate_stack():
    return [B("root", C(0, 0, 0, 9, 8, 9), C(9, 0, 1, 7, 7, 7), C(2, 8, 2, 7, 6, 7), C(1, 0, 10, 8, 6, 6))]


def pc_model(variant="old"):
    if variant == "terminal":
        # industrial terminal: angled console on a steel pedestal
        return [B("root", C(2, 0, 4, 12, 1, 10, "detail"), C(4, 1, 6, 8, 6, 7), C(1, 7, 3, 14, 3, 12), C(2, 10, 6, 12, 6, 9),
                  C(3, 16 - 0.01, 8, 10, 0.01, 5, "detail"), C(13, 11, 4.5, 1.5, 4, 1, "detail")),
                B("screen", C(3, 10.8, 5.9, 10, 4.4, 0.2, "screen")),
                B("keys", C(2, 9.5, 2.8, 12, 0.8, 3, "keys"), C(11, 10.3, 3.3, 2, 0.6, 1, "detail"))]
    if variant == "lab":
        # flat monitor on a stand + tower case on the side
        return [B("root", C(2, 0, 7, 6, 1, 6, "detail"), C(4.25, 1, 9, 1.5, 3, 1.5, "detail"), C(0.5, 4, 8, 9, 7, 2.5),
                  C(11, 0, 4, 4.5, 11, 10), C(11.8, 8, 3.9, 2.8, 0.4, 0.2, "detail"), C(12.6, 2, 3.9, 1.2, 1.2, 0.2, "detail")),
                B("screen", C(1, 4.5, 7.9, 8, 6, 0.2, "screen")),
                B("keys", C(1, 0, 1.5, 9, 0.8, 3.5, "keys"), C(10.5, 0, 2, 1.5, 0.8, 2, "detail"))]
    if variant == "office":
        # beige desktop case lying under a CRT, separate keyboard and mouse
        return [B("root", C(1, 0, 4, 14, 3.5, 11), C(2, 0.8, 3.9, 5, 0.8, 0.2, "detail"), C(10, 1, 3.9, 3, 1, 0.2, "detail"),
                  C(2.5, 3.5, 5, 11, 9, 2.5), C(3.5, 4.5, 7.5, 9, 7, 3.5), C(5, 5.5, 11, 6, 5, 3)),
                B("screen", C(3.5, 4.5, 4.9, 9, 7, 0.2, "screen")),
                B("keys", C(1.5, 0, 0.3, 10, 0.8, 3.2, "keys"), C(12.5, 0, 0.8, 1.5, 0.7, 2, "detail"))]
    # old: heavy CRT with a bezel and tapered tube, desktop case with floppy drive
    return [B("root", C(1, 0, 3, 14, 4, 12), C(2, 1.6, 2.9, 4.5, 0.6, 0.2, "detail"), C(10.5, 1.2, 2.9, 3, 1.4, 0.2, "detail"),
              C(12.8, 2.8, 2.9, 0.8, 0.4, 0.2, "screen"),
              C(1.5, 4, 3.5, 13, 11, 2), C(2.5, 5, 5.5, 11, 9, 4), C(4, 6, 9.5, 8, 7, 3), C(5.5, 7, 12.5, 5, 5, 2)),
            B("screen", C(2.5, 5, 3.3, 11, 9, 0.2, "screen")),
            B("keys", C(1.5, 0, 0, 11, 0.9, 2.8, "keys"), C(13, 0, 0.5, 1.6, 0.7, 2.2, "detail"))]

def server_rack():
    cubes = [C(1, 0, 1, 14, 16, 14), C(0.5, 0, 0.5, 1, 16, 1, "detail"), C(14.5, 0, 0.5, 1, 16, 1, "detail"),
             C(0.5, 0, 14.5, 1, 16, 1, "detail"), C(14.5, 0, 14.5, 1, 16, 1, "detail")]
    for y in (1, 5, 9, 13):
        cubes.append(C(2, y + 2.6, 0.6, 12, 0.4, 0.4, "detail"))
    return [B("root", *cubes), B("leds", C(2, 1, 0.8, 12, 14, 0.2, "screen"))]

def lamp_hanging():
    return [B("root", C(7.5, 10, 7.5, 1, 6, 1, "detail"), C(4, 6, 4, 8, 4, 8), C(5, 5, 5, 6, 1, 6, "glow"))]


def lamp_wall():
    # mounted on the SOUTH face (back), light faces north
    return [B("root", C(5, 4, 14, 6, 8, 2, "detail"), C(5.5, 5, 10, 5, 6, 4), C(6, 6, 9.5, 4, 4, 0.5, "glow"))]


def lamp_ceiling():
    return [B("root", C(2, 14, 2, 12, 2, 12), C(3, 13.5, 3, 10, 0.5, 10, "glow"))]


def lamp_floor_beacon():
    return [B("root", C(4, 0, 4, 8, 2, 8, "detail"), C(5, 2, 5, 6, 6, 6, "glow"), C(4.5, 8, 4.5, 7, 1, 7, "detail"))]


def alarm_model():
    return [B("root", C(4, 4, 13, 8, 8, 3, "detail"), C(5, 5, 10, 6, 6, 3), C(5.5, 5.5, 9.5, 5, 5, 0.5, "glow"))]


def button_model():
    return [B("root", C(4, 0, 4, 8, 3, 8, "detail"), C(5.5, 3, 5.5, 5, 2, 5, "glow"))]


def indicator_model():
    return [B("root", C(3, 2, 13, 10, 12, 3)), B("dial", C(4, 6, 12.8, 8, 7, 0.2, "screen")),
            B("lamp", C(6, 3, 12.5, 4, 2, 0.5, "glow"))]


def clock_model():
    return [B("root", C(3, 3, 15, 10, 10, 1)), B("face", C(4, 4, 14.8, 8, 8, 0.2, "screen"))]


def flat_wall(th=0.5):
    return [B("root", C(0.5, 0.5, 16 - th, 15, 15, th))]


def flat_floor(th=0.25):
    return [B("root", C(0.5, 0, 0.5, 15, th, 15))]


def door_model(open_, upper=False, style="swing"):
    """Door halves. style: swing (hinged panel), shutter (slides up into the frame), curtain (plastic strips)."""
    if style == "shutter":
        posts = [C(0, 0, 0, 1.5, 16, 3, "detail"), C(14.5, 0, 0, 1.5, 16, 3, "detail")]
        if not open_:
            cubes = posts + [C(1.5, 0, 0.5, 13, 16, 2)]
            for y in (3.5, 7.5, 11.5, 15.5):
                cubes.append(C(1.5, y, 0.3, 13, 0.4, 0.2, "detail"))
            return [B("root", *cubes)]
        if upper:
            return [B("root", *posts, C(1.5, 12.5, 0.3, 13, 3.5, 2.4, "detail"))]   # rolled-up shutter
        return [B("root", *posts)]
    if style == "curtain":
        cubes = [C(0, 15, 0, 16, 1, 2, "detail")] if upper else []
        if not open_:
            for i, x in enumerate(range(0, 16, 2)):
                cubes.append(C(x + 0.1, 0 if not upper else 0, 0.8 + (i % 2) * 0.4, 1.8, 16 if not upper else 15, 0.3))
        else:
            for x in (0.2, 1.2, 2.2, 13.6, 14.6):
                cubes.append(C(x, 0, 0.8, 1.2, 16 if not upper else 15, 0.3))
        return [B("root", *cubes)]
    if open_:
        cubes = [C(0, 0, 0, 3, 16, 16), C(0, 0, 0, 3.2, 16, 1, "detail")]
        if not upper:
            cubes += [C(3, 7, 12.5, 0.8, 1, 2.5, "detail"), C(-0.8 + 0.8, 7, 12.5, 0.01, 1, 2.5, "detail")]
        return [B("root", *cubes)]
    cubes = [C(0, 0, 0, 16, 16, 3), C(0, 0, 0, 1, 16, 3.2, "detail")]
    if not upper:
        cubes += [C(12.5, 7, 3, 2.5, 1, 0.8, "detail"), C(12.5, 7, 0, 2.5, 1, 0.01, "detail")]
    return [B("root", *cubes)]

def bars_model():
    cubes = [C(0, 0, 7, 16, 2, 2), C(0, 14, 7, 16, 2, 2)]
    for x in (1, 5, 9, 13):
        cubes.append(C(x, 0, 7.25, 1.5, 16, 1.5))
    return [B("root", *cubes)]


def battlement():
    return [B("root", C(0, 0, 0, 16, 8, 16), C(0, 8, 0, 6, 8, 16), C(10, 8, 0, 6, 8, 16))]


def barricade():
    return [B("root", C(0, 2, 6, 16, 4, 2), C(0, 9, 6, 16, 4, 2), C(2, 0, 8, 2, 15, 2, "detail"), C(12, 0, 8, 2, 15, 2, "detail"))]


def barbed_wire():
    cubes = []
    for i in range(4):
        cubes.append(C(0, 2 + i * 3, 7.5, 16, 0.5, 0.5))
        cubes.append(C(7.5, 2 + i * 3, 0, 0.5, 0.5, 16))
    cubes += [C(1, 0, 1, 1, 14, 1, "detail"), C(14, 0, 14, 1, 14, 1, "detail")]
    return [B("root", *cubes)]


def sandbags():
    return [B("root", C(0, 0, 2, 8, 4, 12), C(8, 0, 2, 8, 4, 12), C(4, 4, 2, 8, 4, 12))]


def spikes():
    cubes = [C(0, 0, 0, 16, 2, 16, "detail")]
    for x in (2, 7, 12):
        for z in (2, 7, 12):
            cubes.append(C(x + 0.5, 2, z + 0.5, 1.5, 7, 1.5))
    return [B("root", *cubes)]


def rubble():
    return [B("root", C(0, 0, 0, 16, 3, 16), C(2, 3, 3, 6, 3, 5), C(9, 3, 8, 5, 2, 6), C(5, 5, 9, 3, 2, 3))]


def jar(h=10, w=8):
    a = 8 - w / 2
    return [B("root", C(a, 0, a, w, 1, w, "detail"), C(a + 0.5, 1, a + 0.5, w - 1, h - 2, w - 1),
              C(a, h - 1, a, w, 1.5, w, "detail")),
            B("fill", C(a + 1, 1, a + 1, w - 2, (h - 3) * 0.8, w - 2, "fill"))]


def flask_set():
    return [B("root", C(2, 0, 2, 4, 5, 4), C(3, 5, 3, 2, 3, 2), C(9, 0, 3, 5, 4, 5), C(10.5, 4, 4.5, 2, 4, 2),
              C(4, 0, 10, 3, 7, 3), C(10, 0, 10, 3, 3, 3))]


def tube_rack():
    cubes = [C(2, 0, 5, 12, 1, 6, "detail"), C(2, 4, 5, 12, 1, 6, "detail"),
             C(2, 0, 5, 1, 5, 6, "detail"), C(13, 0, 5, 1, 5, 6, "detail")]
    for x in (3.5, 6.5, 9.5, 12):
        cubes.append(C(x, 1, 7, 1.5, 7, 1.5))
    return [B("root", *cubes)]


def growth():
    return [B("root", C(1, 0, 1, 14, 4, 14), C(3, 4, 3, 9, 5, 8), C(5, 9, 6, 5, 4, 4), C(10, 4, 9, 4, 6, 4))]


def crystal():
    return [B("root", C(6, 0, 6, 4, 12, 4), C(2, 0, 3, 3, 7, 3), C(11, 0, 9, 3, 8, 3), C(3, 0, 11, 3, 5, 3))]


def bin_model():
    return [B("root", C(3, 0, 3, 10, 12, 10), C(2.5, 12, 2.5, 11, 1, 11, "detail"))]


def iv_stand():
    return [B("root", C(4, 0, 7, 8, 1, 2), C(7, 0, 4, 2, 1, 8), C(7.5, 1, 7.5, 1, 15, 1, "detail"),
              C(5, 14, 7.5, 6, 0.5, 1, "detail"), C(5, 9, 7, 3, 5, 2, "fill"))]


def med_monitor():
    return [B("root", C(5, 0, 5, 6, 1, 6), C(7.5, 1, 7.5, 1, 7, 1, "detail"), C(3, 8, 6, 10, 7, 4)),
            B("screen", C(4, 9, 5.9, 8, 5, 0.2, "screen"))]


def bed_long():
    # 2-block long bed (16 x 32), headboard at the far end (local south/back)
    return [B("root", C(0, 3, 0, 16, 3, 32, "frame"), C(0, 0, 0, 2, 3, 2, "frame"), C(14, 0, 0, 2, 3, 2, "frame"),
              C(0, 0, 30, 2, 3, 2, "frame"), C(14, 0, 30, 2, 3, 2, "frame"),
              C(1, 6, 1, 14, 3, 30), C(2, 9, 24, 12, 2, 6, "fabric"), C(0, 3, 31, 16, 11, 1, "frame"))]


def operating_table():
    return [B("root", C(1, 9, 0, 14, 2, 32), C(6, 0, 6, 4, 9, 4, "frame"), C(6, 0, 22, 4, 9, 4, "frame"),
              C(3, 0, 4, 10, 1, 8, "frame"), C(3, 0, 20, 10, 1, 8, "frame"), C(2, 11, 26, 12, 1, 5, "fabric"))]


def exam_table():
    return [B("root", C(0, 0, 0, 16, 7, 16, "frame"), C(0, 7, 0, 16, 2, 16), C(1, 9, 10, 14, 4, 6))]


def tank(h=16):
    """Upright gas cylinder: two crossed boxes read as a round tank, with domed cap and valve."""
    return [B("root", C(3, 0, 3, 10, 1, 10, "detail"), C(2.5, 1, 4, 11, h - 4, 8), C(4, 1, 2.5, 8, h - 4, 11),
              C(3.5, h - 3, 4.5, 9, 1.5, 7), C(4.5, h - 3, 3.5, 7, 1.5, 9), C(6.5, h - 1.5, 6.5, 3, 1, 3, "detail"),
              C(7.5, h - 0.5, 5, 1, 0.5, 6, "detail"), C(2.3, 4, 6, 0.4, 1, 4, "detail"), C(2.3, 10, 6, 0.4, 1, 4, "detail")),
            B("gauge", C(6, 7, 2.3, 4, 4, 0.2, "screen"))]

def barrel():
    return [B("root", C(2, 0, 2, 12, 14, 12), C(1.5, 3, 1.5, 13, 1, 13, "detail"), C(1.5, 10, 1.5, 13, 1, 13, "detail"),
              C(6, 14, 6, 4, 1, 4, "detail"))]


def pump():
    """Electric water pump: motor with cooling fins, volute casing and pipe stubs."""
    cubes = [C(0, 0, 1, 16, 2, 14, "detail"), C(1, 2, 4, 7, 7, 8)]
    for x in (1.5, 3.5, 5.5):
        cubes.append(C(x, 9, 4.5, 1, 0.6, 7, "detail"))
    cubes += [C(8, 2, 3, 6, 9, 10), C(9, 11, 6, 4, 3, 4, "detail"), C(14, 4, 6, 2, 4, 4, "detail"), C(10, 3, 1, 3, 4, 2, "detail")]
    return [B("root", *cubes)]

def cooling_unit():
    """Cooling unit: louvred housing, top fan, coolant stubs on both sides."""
    cubes = [C(0.5, 0, 0.5, 15, 15.5, 15)]
    for y in (3, 6, 9, 12):
        cubes.append(C(1.5, y, 0.2, 13, 0.6, 0.3, "detail"))
    cubes += [C(0, 6, 6, 0.5, 4, 4, "detail"), C(15.5, 6, 6, 0.5, 4, 4, "detail")]
    return [B("root", *cubes), B("fan", C(2, 15.6, 2, 12, 0.2, 12, "screen"))]

def waste_container():
    return [B("root", C(1, 0, 1, 14, 13, 14), C(0.5, 13, 0.5, 15, 2, 15, "detail")), B("gauge", C(5, 5, 0.9, 6, 4, 0.2, "screen"))]


def lab_table_kit(kind):
    extra = []
    if kind == "chemical":
        extra = [B("kit", C(2, 16 - 0.01, 3, 3, 0.01, 3), C(2.5, 16, 3.5, 2, 4, 2, "glass"), C(9, 16, 9, 4, 3, 4, "glass"),
                   C(10.5, 19, 10.5, 1, 3, 1, "glass"))]
    elif kind == "bio":
        extra = [B("kit", C(3, 16, 3, 6, 2, 4, "detail"), C(5, 18, 4, 2, 5, 2, "detail"), C(4, 23, 3.5, 4, 1, 3, "detail"),
                   C(10, 16, 9, 4, 4, 4, "glass"))]
    elif kind == "nuclear":
        extra = [B("kit", C(3, 16, 3, 10, 6, 6, "detail"), C(4, 17, 2.9, 8, 4, 0.2, "screen"))]
    elif kind == "contamination":
        extra = [B("kit", C(2, 16, 8, 12, 8, 6, "detail"), C(3, 17, 7.9, 10, 6, 0.2, "screen"), C(4, 16, 2, 4, 3, 4, "glass"))]
    elif kind == "prep":
        extra = [B("kit", C(2, 16, 2, 5, 1, 5, "detail"), C(9, 16, 3, 1.5, 5, 1.5, "glass"), C(11, 16, 3, 1.5, 5, 1.5, "glass"),
                   C(9, 16, 9, 5, 3, 5, "glass"))]
    elif kind == "workstation":
        extra = [B("screen_box", C(3, 16, 7, 10, 8, 7, "detail")), B("screen", C(4, 17, 6.9, 8, 6, 0.2, "screen")),
                 B("keys", C(3, 16, 2, 10, 0.8, 3, "keys"))]
    elif kind == "industrial":
        extra = [B("kit", C(1, 16, 10, 14, 1, 5, "detail"), C(2, 16, 2, 4, 3, 3, "detail"), C(11, 16, 3, 3, 2, 5, "detail"))]
    elif kind == "standard":
        extra = [B("kit", C(3, 16, 4, 3, 5, 3, "glass"), C(10, 16, 9, 3, 3, 3, "glass"))]
    # lab tables: solid lower cabinet + worktop (y 10..12), front = north.
    # Kits are authored on a y=16 worktop; shift them down 4 px and clip to the block (<= 16 px).
    base = [B("root", C(0, 10, 0, 16, 2, 16, "top"), C(1, 0, 1, 14, 10, 14))]
    out = []
    for b in extra:
        cubes = []
        for c in b["cubes"]:
            (x, y, z), (w, h, d) = c["o"], c["s"]
            y -= 4
            h = min(h, 16 - y)
            if h > 0:
                cubes.append({"o": (x, y, z), "s": (w, h, d), "mat": c["mat"], "faces": c.get("faces")})
        if cubes:
            out.append({"name": b["name"], "cubes": cubes})
    return base + out


# ---------------------------------------------------------------- multiblock models (up to 32x32x32)

def gen_model(kind):
    if kind == "standard":
        return [B("root", C(0, 0, 0, 32, 3, 32, "detail"), C(2, 3, 2, 28, 20, 28), C(4, 23, 4, 10, 6, 10, "detail"),
                  C(6, 29, 6, 6, 3, 6, "detail"), C(18, 23, 18, 10, 4, 10), C(0.5, 8, 6, 1.5, 3, 20, "detail"),
                  C(30, 8, 6, 1.5, 3, 20, "detail"), C(24, 27, 24, 3, 5, 3, "detail")),
                B("panel", C(4, 8, 1.9, 24, 10, 0.2, "screen"), C(4, 19, 1.9, 24, 2, 0.2, "hazard"))]
    if kind == "industrial":
        return [B("root", C(0, 0, 0, 32, 4, 32, "detail"), C(1, 4, 1, 30, 22, 30), C(3, 26, 3, 26, 3, 26, "detail"),
                  C(22, 29, 4, 6, 3, 6, "detail"), C(4, 29, 22, 6, 3, 6, "detail")),
                B("panel", C(3, 8, 0.9, 26, 12, 0.2, "screen"), C(3, 22, 0.9, 26, 2, 0.2, "hazard"))]
    if kind == "nuclear":
        return [B("root", C(0, 0, 0, 32, 4, 32, "detail"), C(2, 4, 2, 28, 26, 28), C(0, 12, 0, 32, 3, 32, "detail"),
                  C(10, 30, 10, 12, 2, 12, "detail")),
                B("panel", C(4, 16, 1.9, 24, 10, 0.2, "screen"), C(4, 5, 1.9, 24, 3, 0.2, "hazard"))]
    if kind == "backup":
        return [B("root", C(0, 0, 0, 32, 2, 32, "detail"), C(2, 2, 2, 28, 12, 28), C(22, 14, 22, 5, 2, 5, "detail")),
                B("panel", C(4, 4, 1.9, 16, 8, 0.2, "screen"), C(22, 4, 1.9, 6, 8, 0.2, "hazard"))]
    if kind == "lab":
        return [B("root", C(1, 0, 1, 30, 14, 30), C(0, 14, 0, 32, 2, 32, "detail")),
                B("panel", C(4, 3, 0.9, 24, 9, 0.2, "screen"))]
    if kind == "server":
        return [B("root", C(1, 0, 1, 14, 16, 30), C(17, 0, 1, 14, 16, 30)),
                B("panel", C(2, 2, 0.9, 12, 12, 0.2, "screen"), C(18, 2, 0.9, 12, 12, 0.2, "screen"))]
    raise ValueError(kind)


def desk():
    return [B("root", C(0, 14, 0, 16, 2, 16), C(0, 0, 1, 6, 14, 14, "detail"), C(14, 0, 1, 2, 14, 14),
              C(1, 10, 0.5, 4, 1, 0.5), C(1, 5, 0.5, 4, 1, 0.5))]


def doc_pile():
    return [B("root", C(2, 0, 2, 11, 2, 10), C(3, 2, 3, 10, 1.5, 9, "detail"), C(4, 3.5, 2.5, 9, 1, 9),
              C(9, 0, 9, 6, 3, 6, "detail"))]


# ---------------------------------------------------------------- placeable laboratory glassware

def erlenmeyer(fill=True):
    """Conical (Erlenmeyer) flask, ~10 px tall."""
    bones = [B("root", C(4, 0, 4, 8, 0.5, 8), C(4, 0.5, 4, 8, 2.5, 8), C(4.5, 3, 4.5, 7, 2, 7), C(5.5, 5, 5.5, 5, 1.5, 5),
               C(6.5, 6.5, 6.5, 3, 1.5, 3), C(7, 8, 7, 2, 2.5, 2), C(6.5, 10.5, 6.5, 3, 0.7, 3))]
    if fill:
        bones.append(B("fill", C(4.6, 0.6, 4.6, 6.8, 2.6, 6.8, "fill"), C(5.1, 3, 5.1, 5.8, 1.4, 5.8, "fill")))
    return bones


def round_flask(fill=True):
    """Round-bottom flask with a long neck."""
    bones = [B("root", C(5, 0, 5, 6, 0.5, 6), C(4, 0.5, 4.5, 8, 4, 7), C(4.5, 0.5, 4, 7, 4, 8), C(5, 4.5, 5, 6, 1, 6),
               C(7, 5.5, 7, 2, 5.5, 2), C(6.5, 11, 6.5, 3, 0.6, 3))]
    if fill:
        bones.append(B("fill", C(4.6, 0.6, 5.1, 6.8, 2.8, 5.8, "fill"), C(5.1, 0.6, 4.6, 5.8, 2.8, 6.8, "fill")))
    return bones


def tube_stand(fill=True):
    """One test tube held by a small wooden stand."""
    bones = [B("root", C(5, 0, 6, 6, 1, 4, "detail"), C(5, 5, 6, 6, 1, 4, "detail"), C(5, 1, 6, 1, 4, 4, "detail"),
               C(10, 1, 6, 1, 4, 4, "detail"), C(7.25, 1, 7.25, 1.5, 9, 1.5))]
    if fill:
        bones.append(B("fill", C(7.5, 1.3, 7.5, 1, 4, 1, "fill")))
    return bones


def bottle(fill=True):
    """Glass bottle with a cork."""
    bones = [B("root", C(5, 0, 5, 6, 6, 6), C(6, 6, 6, 4, 1.5, 4), C(7, 7.5, 7, 2, 2.5, 2), C(6.75, 10, 6.75, 2.5, 1.5, 2.5, "detail"))]
    if fill:
        bones.append(B("fill", C(5.6, 0.6, 5.6, 4.8, 4.5, 4.8, "fill")))
    return bones


def vat():
    """Tall glass vat with fluid, steel base and lid."""
    return [B("root", C(1, 0, 1, 14, 2, 14, "detail"), C(2, 2, 2, 12, 12, 12), C(1, 14, 1, 14, 2, 14, "detail"),
              C(7, 15.5, 7, 2, 0.5, 2, "detail")),
            B("fill", C(2.6, 2, 2.6, 10.8, 9, 10.8, "fill"))]


def liquid(level):
    """Pseudo-liquid surface: level 0 = source (14 px) ... 4 = thin film."""
    h = {0: 14, 1: 12, 2: 9, 3: 6, 4: 3}[level]
    return [B("root", C(0, 0, 0, 16, h, 16))]


# ---------------------------------------------------------------- locations (v1.4)

def theater_seat():
    return [B("root", C(2, 0, 3, 1.5, 7, 10, "detail"), C(12.5, 0, 3, 1.5, 7, 10, "detail"), C(3, 4, 2, 10, 2.5, 10),
              C(3, 6.5, 11, 10, 9, 2.5), C(2, 7, 3, 1.5, 0.8, 8, "detail"), C(12.5, 7, 3, 1.5, 0.8, 8, "detail"))]


def curtain():
    cubes = [C(0, 15, 6.5, 16, 1, 3, "detail")]
    for i, x in enumerate(range(0, 16, 4)):
        cubes.append(C(x, 0, 7 + (i % 2), 4, 15, 1.5))
    return [B("root", *cubes)]


def spotlight():
    return [B("root", C(4, 0, 4, 8, 1, 8, "detail"), C(7, 1, 7, 2, 5, 2, "detail"), C(4, 6, 5, 8, 6, 7), C(4.5, 6.5, 4.6, 7, 5, 0.4, "glow"))]


def crt_tv():
    return [B("root", C(1, 0, 3, 14, 13, 10), C(3, 2, 13, 10, 9, 2), C(6, 13, 8, 0.6, 3, 0.6, "detail"), C(9.4, 13, 8, 0.6, 3, 0.6, "detail"),
              C(12, 2, 2.9, 1.5, 1.5, 0.2, "detail"), C(12, 5, 2.9, 1.5, 1.5, 0.2, "detail")),
            B("screen", C(2, 2, 2.9, 9, 9, 0.2, "screen"))]


def antenna():
    return [B("root", C(6, 0, 6, 4, 1, 4, "detail"), C(7.5, 1, 7.5, 1, 15, 1), C(3, 12, 7.5, 10, 0.6, 1), C(4.5, 8, 7.5, 7, 0.6, 1),
              C(2, 4, 3, 5, 5, 1, "detail"), C(6, 13.5, 6, 4, 2.5, 0.5, "glow"))]


def shop_shelf():
    cubes = [C(0, 0, 9, 16, 16, 1), C(0, 0, 2, 1, 16, 8), C(15, 0, 2, 1, 16, 8)]
    for y in (0, 5, 10, 15):
        cubes.append(C(1, y, 2, 14, 0.8, 7.5, "detail"))
    goods = [C(2, 0.8, 3, 3, 3.5, 3, "goods"), C(6, 0.8, 3.5, 2.5, 2.5, 2.5, "goods"), C(10, 0.8, 3, 4, 3, 3, "goods"),
             C(2.5, 5.8, 3, 2, 3, 2, "goods"), C(5.5, 5.8, 3, 4, 2, 4, "goods"), C(11, 5.8, 3.5, 2.5, 3.5, 2.5, "goods"),
             C(2, 10.8, 3, 5, 2.5, 3, "goods"), C(9, 10.8, 3, 3, 3.5, 3, "goods")]
    return [B("root", *cubes), B("goods", *goods)]


def cash_register():
    return [B("root", C(0, 0, 0, 16, 9, 16, "detail"), C(3, 9, 5, 10, 3, 7), C(4, 12, 9, 8, 3, 2), C(3.5, 9.2, 2, 9, 1.6, 3, "keys")),
            B("screen", C(5, 12.5, 8.9, 6, 2, 0.2, "screen"))]


def school_desk():
    return [B("root", C(1, 10, 1, 14, 1.5, 10), C(1, 9, 1, 14, 1, 1, "detail"), C(1.5, 0, 1.5, 1.2, 10, 1.2, "detail"),
              C(13.3, 0, 1.5, 1.2, 10, 1.2, "detail"), C(1.5, 0, 9.3, 1.2, 10, 1.2, "detail"), C(13.3, 0, 9.3, 1.2, 10, 1.2, "detail"),
              C(2, 7, 2, 12, 1, 8, "detail"), C(3, 0, 12, 10, 6, 1, "detail"), C(3, 6, 11.5, 10, 1, 4))]


def chalkboard():
    return [B("root", C(0, 3, 15, 16, 12, 1, "detail"), C(0, 2, 13.5, 16, 1, 2.5, "detail")), B("board", C(1, 4, 14.8, 14, 10, 0.2, "screen"))]


def canteen_table():
    return [B("root", C(0, 9, 3, 16, 1.5, 10), C(1, 0, 7, 2, 9, 2, "detail"), C(13, 0, 7, 2, 9, 2, "detail"), C(0, 4, 7.5, 16, 1, 1, "detail"),
              C(0, 5, 0, 16, 1, 2.5, "detail"), C(0, 5, 13.5, 16, 1, 2.5, "detail"), C(1, 0, 0.5, 1, 5, 1, "detail"),
              C(14, 0, 0.5, 1, 5, 1, "detail"), C(1, 0, 14.5, 1, 5, 1, "detail"), C(14, 0, 14.5, 1, 5, 1, "detail"))]


def lunch_tray():
    return [B("root", C(2, 0, 3, 12, 0.6, 10), C(2.5, 0.6, 3.5, 5, 0.4, 4, "detail"), C(8.5, 0.6, 3.5, 5, 0.4, 4, "detail"),
              C(2.5, 0.6, 8.5, 11, 0.4, 4, "detail")), B("fill", C(3, 0.8, 4, 4, 0.6, 3, "fill"), C(9, 0.8, 4, 4, 0.6, 3, "fill"))]


def serving_counter():
    return [B("root", C(0, 0, 2, 16, 10, 14), C(0, 10, 0, 16, 1, 16, "detail"), C(1, 11, 9, 14, 3, 6, "glass"), C(1, 14, 9, 14, 0.5, 6, "detail")),
            B("fill", C(2, 10.6, 2, 5, 1, 5, "fill"), C(9, 10.6, 2, 5, 1, 5, "fill"))]


def kitchen_pot():
    return [B("root", C(3, 0, 3, 10, 8, 10), C(2.5, 7, 2.5, 11, 1, 11, "detail"), C(1, 5, 7, 2, 1, 2, "detail"), C(13, 5, 7, 2, 1, 2, "detail")),
            B("fill", C(3.5, 7.2, 3.5, 9, 0.5, 9, "fill"))]


def shower_head():
    return [B("root", C(7, 4, 15, 2, 12, 1, "detail"), C(7, 13, 10, 2, 1.5, 5, "detail"), C(5, 11.5, 8, 6, 1.5, 4, "detail"),
              C(6, 6, 14.5, 4, 2, 1, "detail")), B("glow", C(5.5, 11.3, 8.5, 5, 0.2, 3, "glow"))]


def floor_drain():
    return [B("root", C(3, 0, 3, 10, 0.3, 10, "detail"), C(4, 0.3, 4, 8, 0.05, 8))]


def lab_sink():
    return [B("root", C(0, 0, 1, 16, 10, 15), C(0, 10, 0, 16, 1, 16, "detail"), C(2, 10.5, 2, 12, 0.6, 9),
              C(7, 11, 12, 2, 4, 2, "detail"), C(7, 14, 8, 2, 1, 5, "detail"))]


def brazier():
    return [B("root", C(6, 0, 6, 4, 8, 4, "detail"), C(3, 8, 3, 10, 3, 10), C(3, 8, 3, 10, 0.5, 10, "detail")),
            B("glow", C(4, 11, 4, 8, 2, 8, "glow"))]


def pillar():
    return [B("root", C(1, 0, 1, 14, 2, 14), C(3, 2, 3, 10, 12, 10), C(1, 14, 1, 14, 2, 14))]


def chainlink():
    cubes = [C(0, 0, 7.5, 1, 16, 1, "detail"), C(15, 0, 7.5, 1, 16, 1, "detail"), C(0, 15, 7.6, 16, 0.6, 0.8, "detail")]
    return [B("root", C(1, 0, 7.9, 14, 15, 0.2), *cubes)]


def steam_vent():
    return [B("root", C(1, 0, 1, 14, 3, 14, "detail"), C(4, 3, 4, 8, 4, 8), C(3, 7, 3, 10, 1, 10, "detail"), C(5, 8, 5, 6, 0.2, 6, "glow"))]


def console():
    return [B("root", C(0, 0, 3, 16, 9, 13), C(0, 9, 4, 16, 2, 12, "detail"), C(0, 11, 9, 16, 5, 7)),
            B("screen", C(1, 11.5, 8.9, 14, 4, 0.2, "screen")), B("keys", C(1, 9.6, 3.9, 14, 1, 4, "keys"))]


def ore_crystals(seed=1):
    """Ore block: stone core inset 1 px with crystals breaking through every face (stays within the block)."""
    import random
    r = random.Random(seed)
    cubes = [C(1, 1, 1, 14, 14, 14)]
    for _ in range(3):  # top
        x, z = r.randint(2, 11), r.randint(2, 11)
        cubes.append(C(x, 13, z, r.choice((2, 3)), 3, r.choice((2, 3)), "crystal"))
    for face in ("north", "south", "east", "west"):
        for _ in range(2):
            a, y = r.randint(2, 11), r.randint(2, 11)
            w, h = r.choice((2, 3)), r.choice((2, 3))
            if face == "north":
                cubes.append(C(a, y, 0, w, h, 2, "crystal"))
            elif face == "south":
                cubes.append(C(a, y, 14, w, h, 2, "crystal"))
            elif face == "west":
                cubes.append(C(0, y, a, 2, h, w, "crystal"))
            else:
                cubes.append(C(14, y, a, 2, h, w, "crystal"))
    cubes.append(C(r.randint(3, 10), 0, r.randint(3, 10), 3, 2, 3, "crystal"))
    # edge fillers so the silhouette still reads as a full block
    cubes += [C(0, 0, 0, 16, 1, 16), C(0, 15, 0, 16, 1, 16), C(0, 1, 0, 1, 14, 1), C(15, 1, 0, 1, 14, 1), C(0, 1, 15, 1, 14, 1), C(15, 1, 15, 1, 14, 1)]
    return [B("root", *cubes)]



def window_barricade():
    """Boards nailed over a window: mounted on the SOUTH face (back), sticks out 2 px."""
    return [B("root", C(0, 2, 14, 16, 3, 1.5), C(0, 11, 14, 16, 3, 1.5), C(2, 0, 15, 3, 16, 1, "detail"),
              C(11, 0, 15, 3, 16, 1, "detail"), C(1, 6, 13.6, 14, 2.5, 1.2))]


def security_camera():
    """Wall camera on an arm; lens faces north (front)."""
    return [B("root", C(6, 9, 14, 4, 4, 2, "detail"), C(7.25, 10, 10, 1.5, 1.5, 4, "detail"), C(5, 9, 4, 6, 4, 7),
              C(4.5, 12.6, 3.5, 7, 0.6, 8, "detail")), B("lens", C(6.5, 10, 3.8, 3, 2, 0.3, "glow"))]


def door_button():
    return [B("root", C(4, 3, 14.5, 8, 10, 1.5, "detail"), C(5.5, 8.5, 13.8, 5, 3, 0.7, "glow"), C(5.5, 4.5, 13.8, 5, 3, 0.7))]


# ---------------------------------------------------------------- corpses, statue, museum (v1.8)

def corpse_lying(kind):
    """A corpse lying on its back along local +z (2 blocks: feet at z 0, head at z ~28). Front (north) = feet."""
    c = []
    # legs
    c += [C(4, 0, 1, 3.5, 3, 12, "cloth2"), C(8.5, 0, 1, 3.5, 3, 12, "cloth2"), C(4, 0, 0, 3.5, 3, 1.5, "shoe"), C(8.5, 0, 0, 3.5, 3, 1.5, "shoe")]
    # torso
    c += [C(3.5, 0, 13, 9, 3.5, 11, "cloth")]
    # arms
    c += [C(0.5, 0, 14, 3, 3, 10, "cloth"), C(12.5, 0, 14, 3, 3, 10, "cloth"), C(0.5, 0, 12, 3, 2.5, 2, "skin"), C(12.5, 0, 12, 3, 2.5, 2, "skin")]
    # head
    if kind == "mayor":
        c += [C(4.5, 0, 24, 3.5, 6, 6, "skin"), C(8, 0, 24, 3.5, 6, 6, "bone"),       # half flesh, half skull
              C(5.2, 5.9, 25.5, 1.6, 0.2, 1.6, "void"), C(8.9, 5.9, 25.5, 1.6, 0.2, 1.6, "void"),  # empty eye sockets
              C(3.5, 3.5, 15, 9, 0.3, 2, "sash"), C(6.5, 3.5, 17, 3, 0.3, 4, "sash")]           # mayoral sash
    else:
        c += [C(4.5, 0, 24, 7, 6, 6, "skin")]
    if kind == "postman":
        c += [C(4.5, 6, 24.5, 7, 1.2, 5, "cloth"), C(11, 0, 16, 5, 4, 6, "bag"),                # cap, mail bag
              C(13, 0.1, 2, 2.5, 0.2, 3, "paper"), C(1, 0.1, 6, 3, 0.2, 2.5, "paper"), C(14, 0.1, 9, 2, 0.2, 3, "paper")]
    if kind == "technician":
        c += [C(9, 3.5, 18, 2, 0.3, 2.5, "badge"), C(4.5, 6, 25, 7, 0.3, 5, "skin")]          # dosimeter badge, bald head
    c += [C(2, 0, 10, 12, 0.05, 20, "blood")]                                              # blood stain under the body
    return [B("root", *c)]


def radiak_statue():
    """Radiak in his mechanical suit (2 blocks tall): green liquid uranium visible through the visor and chest tank."""
    return [B("root", C(3, 0, 5, 4, 12, 6), C(9, 0, 5, 4, 12, 6), C(2, 0, 4, 5, 2, 8, "detail"), C(9, 0, 4, 5, 2, 8, "detail"),
              C(2, 12, 4, 12, 10, 8), C(0, 13, 5, 2.5, 9, 5, "detail"), C(13.5, 13, 5, 2.5, 9, 5, "detail"), C(0, 9, 5, 2.5, 4, 5),
              C(13.5, 9, 5, 2.5, 4, 5), C(4, 22, 4, 8, 8, 8), C(3.5, 29.5, 3.5, 9, 1, 9, "detail"), C(7, 24, 12, 2, 3, 2, "detail")),
            B("uranium", C(4.5, 23.5, 3.8, 7, 4, 0.3, "glow"), C(5, 15, 3.8, 6, 5, 0.3, "glow"))]


def display_case():
    return [B("root", C(1, 0, 1, 14, 8, 14, "detail"), C(0.5, 8, 0.5, 15, 0.5, 15, "detail"), C(1, 8.5, 1, 14, 7, 14, "glass"),
              C(0.5, 15.5, 0.5, 15, 0.5, 15, "detail")), B("exhibit", C(6.5, 8.5, 6.5, 3, 5, 3, "exhibit"))]


def pedestal():
    return [B("root", C(2, 0, 2, 12, 2, 12), C(4, 2, 4, 8, 9, 8), C(2.5, 11, 2.5, 11, 1.5, 11)),
            B("exhibit", C(5.5, 12.5, 5.5, 5, 3.5, 5, "exhibit"))]


def rope_barrier():
    return [B("root", C(1, 0, 6.5, 3, 1, 3, "detail"), C(2, 1, 7.5, 1, 9, 1, "detail"), C(12, 0, 6.5, 3, 1, 3, "detail"),
              C(13, 1, 7.5, 1, 9, 1, "detail"), C(1.5, 10, 7, 2, 1.5, 2, "detail"), C(12.5, 10, 7, 2, 1.5, 2, "detail")),
            B("rope", C(3, 8, 7.7, 10, 0.8, 0.6, "rope"))]


def bench():
    return [B("root", C(0, 5, 3, 16, 1.5, 10), C(1, 0, 4, 2, 5, 8, "detail"), C(13, 0, 4, 2, 5, 8, "detail"), C(0, 6.5, 11, 16, 6, 1.5))]


def nuke():
    return [B("root", C(2, 0, 2, 12, 2, 12, "detail"), C(4, 2, 4, 8, 9, 8), C(5, 11, 5, 6, 2, 6), C(6.5, 13, 6.5, 3, 2, 3, "detail"),
              C(3.5, 6, 3.5, 9, 1.5, 9, "hazard"), C(2, 2, 7, 2, 6, 2, "detail"), C(12, 2, 7, 2, 6, 2, "detail")),
            B("glow", C(7, 15, 7, 2, 1, 2, "glow"))]



def siren():
    """Air-raid siren on a short post: rotor housing with two horns (front = north)."""
    return [B("root", C(6.5, 0, 6.5, 3, 7, 3, "detail"), C(4, 7, 4, 8, 5, 8), C(3, 7.5, 1, 4, 4, 3.5, "detail"),
              C(9, 7.5, 1, 4, 4, 3.5, "detail"), C(6, 12, 6, 4, 2, 4, "detail")),
            B("glow", C(3.5, 8, 0.8, 3, 3, 0.3, "glow"), C(9.5, 8, 0.8, 3, 3, 0.3, "glow"))]
