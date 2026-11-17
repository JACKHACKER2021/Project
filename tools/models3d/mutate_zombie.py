"""Turn the boss-zombie GLB into a giant mutated, muscular, creepy monster.

Everything is done so the original rig, skin weights and the walk animation
keep working: the mesh is reshaped in BIND pose, bones are only scaled
(the animation has no scale channels), and new parts (horns, spikes, claws,
glowing eyes, tumours) are parented to bones, so they move with the body.
"""
import numpy as np, struct, io
from pygltflib import GLTF2, BufferFormat, Accessor, BufferView, Mesh, Primitive, \
    Attributes, Node, Material, PbrMetallicRoughness
from PIL import Image, ImageFilter, ImageEnhance
import trimesh

SRC = "/root/.claude/uploads/5e61afe3-a57c-5673-9010-2a3892e4949d/98942743-sef_zombaku.glb"
OUT = "out/monstrum_sef_zombaku.glb"
TARGET_H = 4.6                      # final height in metres (a giant)

g = GLTF2().load(SRC)
g.convert_buffers(BufferFormat.BINARYBLOB)
blob = bytearray(g.binary_blob())

DT = {5126: np.float32, 5123: np.uint16, 5121: np.uint8, 5125: np.uint32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}

def read(ix):
    a = g.accessors[ix]; bv = g.bufferViews[a.bufferView]
    off = (bv.byteOffset or 0) + (a.byteOffset or 0)
    n = NC[a.type]
    return np.frombuffer(blob, dtype=DT[a.componentType], count=a.count * n,
                         offset=off).reshape(a.count, n).copy()

def write(ix, arr):
    a = g.accessors[ix]; bv = g.bufferViews[a.bufferView]
    off = (bv.byteOffset or 0) + (a.byteOffset or 0)
    raw = arr.astype(DT[a.componentType]).tobytes()
    blob[off:off + len(raw)] = raw
    if a.type == "VEC3":
        a.min = arr.min(0).tolist(); a.max = arr.max(0).tolist()

def append(arr, target=34962):
    """Append raw data as a new bufferView, return its index."""
    while len(blob) % 4:
        blob.append(0)
    off = len(blob)
    raw = arr.tobytes()
    blob.extend(raw)
    g.bufferViews.append(BufferView(buffer=0, byteOffset=off, byteLength=len(raw),
                                    target=target))
    return len(g.bufferViews) - 1

def add_acc(arr, ctype, atype, target=34962):
    bv = append(arr, target)
    a = Accessor(bufferView=bv, componentType=ctype, count=len(arr), type=atype)
    if atype == "VEC3":
        a.min = arr.min(0).astype(float).tolist(); a.max = arr.max(0).astype(float).tolist()
    g.accessors.append(a)
    return len(g.accessors) - 1

# ---------------------------------------------------------------- rig data
skin = g.skins[0]
IBM = read(skin.inverseBindMatrices).reshape(-1, 4, 4).transpose(0, 2, 1)
JN = [g.nodes[j].name for j in skin.joints]
JPOS = {nm: np.linalg.inv(IBM[k])[:3, 3] for k, nm in enumerate(JN)}
JIX = {nm: k for k, nm in enumerate(JN)}

def J(frag):
    """Joint index by name fragment."""
    for k, nm in enumerate(JN):
        if frag in nm:
            return k
    raise KeyError(frag)

CHAIN = {  # bone -> its child, to get the bone axis
 "bip Pelvis": "bip Spine018", "bip Spine018": "bip Spine019",
 "bip Spine019": "bip Neck", "bip Neck": "bip Head009_0356",
 "bip L Clavicle": "bip L UpperArm", "bip L UpperArm": "bip L Forearm",
 "bip L Forearm": "bip L Hand", "bip L Hand": "bip L Finger046",
 "bip R Clavicle": "bip R UpperArm", "bip R UpperArm": "bip R Forearm",
 "bip R Forearm": "bip R Hand", "bip R Hand": "bip R Finger046",
 "bip L Thigh": "bip L Calf", "bip L Calf": "bip L Foot",
 "bip R Thigh": "bip R Calf", "bip R Calf": "bip R Foot",
}
# how much muscle each bone gains (cm), and the left-side mutation bonus
GAIN = {"bip Pelvis": 3.2, "bip Spine018": 4.2, "bip Spine019": 5.6, "bip Neck": 3.0,
        "bip Head009_0356": 1.2, "bip jaw": 1.0,
        "bip L Clavicle": 6.5, "bip L UpperArm": 7.0, "bip L Forearm": 5.0,
        "bip L Hand": 2.0, "bip R Clavicle": 5.0, "bip R UpperArm": 5.4,
        "bip R Forearm": 3.8, "bip R Hand": 1.6,
        "bip L Thigh": 4.6, "bip L Calf": 3.4, "bip R Thigh": 4.2, "bip R Calf": 3.0}

def seg_for(k):
    nm = JN[k]
    for a, bq in CHAIN.items():
        if nm.startswith(a):
            return JPOS[nm], JPOS[[x for x in JN if x.startswith(bq)][0]]
    return JPOS[nm], JPOS[nm] + np.array([0, 1e-3, 0])

def gain_for(k):
    nm = JN[k]
    for a, v in GAIN.items():
        if nm.startswith(a):
            return v
    return 0.4

def lump(v):
    """Low-frequency noise so the muscle reads as lumpy mutated flesh."""
    x, y, z = v[:, 0], v[:, 1], v[:, 2]
    return (np.sin(x * .17 + y * .09) * np.cos(z * .21 - y * .07) * .55
            + np.sin(y * .31 + z * .13) * .3 + np.cos(x * .09 - y * .23) * .25)

HEAD = J("bip Head009_0356")
JAW = J("bip jaw009")

def mutate_mesh(prim):
    P = read(prim.attributes.POSITION).astype(np.float64)
    N = read(prim.attributes.NORMAL).astype(np.float64)
    JJ = read(prim.attributes.JOINTS_0).astype(int)
    WW = read(prim.attributes.WEIGHTS_0).astype(np.float64)
    WW = WW / np.clip(WW.sum(1, keepdims=True), 1e-6, None)
    noise = lump(P)
    disp = np.zeros_like(P)
    for slot in range(JJ.shape[1]):
        for k in np.unique(JJ[:, slot]):
            m = (JJ[:, slot] == k) & (WW[:, slot] > 1e-4)
            if not m.any():
                continue
            a, bq = seg_for(k)
            d = bq - a
            L2 = max(float(d @ d), 1e-6)
            t = np.clip(((P[m] - a) @ d) / L2, 0, 1)[:, None]
            rad = P[m] - (a + t * d)
            rl = np.linalg.norm(rad, axis=1, keepdims=True)
            dirv = rad / np.clip(rl, 1e-6, None)
            belly = np.sin(np.pi * np.clip(t, 0, 1)) * .75 + .45   # thickest mid-bone
            amt = gain_for(k) * belly * (1 + .55 * noise[m][:, None])
            disp[m] += WW[m, slot][:, None] * (dirv * amt)
    P += disp
    P += N * (noise[:, None] * 1.1)                        # bumpy skin
    # bigger, longer skull and a dropped, stretched jaw
    hw = np.zeros(len(P))
    for slot in range(JJ.shape[1]):
        hw += np.where(JJ[:, slot] == HEAD, WW[:, slot], 0)
    hp = JPOS[JN[HEAD]]
    P += hw[:, None] * ((P - hp) * np.array([.22, .30, .26]))
    jw = np.zeros(len(P))
    for slot in range(JJ.shape[1]):
        jw += np.where(JJ[:, slot] == JAW, WW[:, slot], 0)
    P += jw[:, None] * np.array([0, -5.0, 5.5])
    write(prim.attributes.POSITION, P.astype(np.float32))
    return P

allP = []
for mi in (0, 1):
    for pr in g.meshes[mi].primitives:
        allP.append(mutate_mesh(pr))

# ---------------------------------------------------------------- bone scaling
def scale_bone(frag, s):
    k = J(frag)
    n = g.nodes[skin.joints[k]]
    cur = np.array(n.scale if n.scale else [1, 1, 1], float)
    n.scale = (cur * s).tolist()

for frag, s in [("bip L Clavicle", 1.22), ("bip R Clavicle", 1.12),
                ("bip L UpperArm", 1.22), ("bip R UpperArm", 1.10),
                ("bip L Forearm", 1.12), ("bip R Forearm", 1.06),
                ("bip L Hand009", 1.40), ("bip R Hand009", 1.30),
                ("bip Spine018", 1.10), ("bip Spine019", 1.12),
                ("bip Head009_0356_0", 1.0), ("bip Neck009", 1.06),
                ("bip L Thigh", 1.10), ("bip R Thigh", 1.08)]:
    scale_bone(frag, s)

# ---------------------------------------------------------------- new parts
BONE_MAT = len(g.materials)
g.materials.append(Material(name="mutant_bone", doubleSided=False,
    pbrMetallicRoughness=PbrMetallicRoughness(
        baseColorFactor=[0.84, 0.82, 0.70, 1.0], metallicFactor=0.0,
        roughnessFactor=0.75)))
EYE_MAT = len(g.materials)
g.materials.append(Material(name="mutant_glow", doubleSided=False,
    emissiveFactor=[0.55, 1.0, 0.25],
    pbrMetallicRoughness=PbrMetallicRoughness(
        baseColorFactor=[0.25, 0.45, 0.10, 1.0], metallicFactor=0.0,
        roughnessFactor=0.4)))
FLESH_MAT = len(g.materials)
g.materials.append(Material(name="mutant_flesh", doubleSided=False,
    pbrMetallicRoughness=PbrMetallicRoughness(
        baseColorFactor=[0.42, 0.47, 0.33, 1.0], metallicFactor=0.0,
        roughnessFactor=0.9)))

def spike(p0, p1, r0, r1=0.0, sections=6):
    """Tapered bone spike from p0 to p1."""
    m = trimesh.creation.cone(radius=r0, height=1.0, sections=sections)
    v = np.asarray(m.vertices).copy()
    tip = v[:, 2] > .5
    v[:, 2] = np.where(tip, 1.0, 0.0)
    rr = np.where(tip, r1, r0)
    nrm = np.linalg.norm(v[:, :2], axis=1, keepdims=True)
    v[:, :2] = np.where(nrm > 1e-6, v[:, :2] / np.clip(nrm, 1e-6, None) * rr[:, None], 0)
    d = np.array(p1, float) - np.array(p0, float)
    L = np.linalg.norm(d); d = d / L
    zz = np.array([0, 0, 1.0])
    ax = np.cross(zz, d); s = np.linalg.norm(ax)
    if s < 1e-6:
        R = np.eye(3) if d[2] > 0 else -np.eye(3)
    else:
        ax = ax / s; c = float(zz @ d); K = np.array([[0, -ax[2], ax[1]],
                                                      [ax[2], 0, -ax[0]],
                                                      [-ax[1], ax[0], 0]])
        R = np.eye(3) + K * s + K @ K * (1 - c)
    v[:, 2] *= L
    return trimesh.Trimesh(vertices=(R @ v.T).T + np.array(p0, float),
                           faces=np.asarray(m.faces), process=False)

def ball(c, r, sub=1):
    m = trimesh.creation.icosphere(subdivisions=sub, radius=r)
    m.apply_translation(c)
    return m

PARTS = {}      # joint index -> {material: [meshes in bind space]}
def part(jointfrag, mesh, mat):
    k = J(jointfrag)
    PARTS.setdefault(k, {}).setdefault(mat, []).append(mesh)

# --- horns and skull spines (head) -----------------------------------------
for s in (-1, 1):
    base = np.array([s * 7.0, 162.0, -3.0])
    mid = base + np.array([s * 7.5, 11.0, -7.0])
    tip = mid + np.array([s * 4.0, 13.0, 4.0])
    part("bip Head009_0356", spike(base, mid, 3.6, 2.4), BONE_MAT)
    part("bip Head009_0356", spike(mid, tip, 2.4, 0.2), BONE_MAT)
    part("bip Head009_0356", spike([s * 3.5, 166.0, 2.0], [s * 5.0, 173.0, -1.0],
                                   1.5, 0.1), BONE_MAT)
    # glowing eyes sunk in the skull
    part("bip Head009_0356", ball([s * 4.2, 153.5, 7.6], 1.9, sub=1), EYE_MAT)
# --- fangs in the stretched jaw ---------------------------------------------
for s in (-1, 1):
    for dx, h in ((2.0, 4.5), (4.2, 3.0)):
        part("bip jaw009", spike([s * dx, 146.0, 9.0], [s * dx, 141.0 - h, 8.0],
                                 1.0, 0.05), BONE_MAT)
    part("bip Head009_0356", spike([s * 3.0, 148.5, 9.2], [s * 3.0, 153.0, 8.4],
                                   0.9, 0.05), BONE_MAT)
# --- spine ridge down the back ----------------------------------------------
ridge = [(96, 10.5, 5.5), (104, 11.5, 7.0), (112, 12.0, 8.5), (120, 12.0, 8.0),
         (128, 11.5, 6.5), (136, 10.5, 5.0)]
for i, (y, z, h) in enumerate(ridge):
    j = "bip Spine018" if y < 110 else "bip Spine019"
    part(j, spike([0, y, -z], [0, y + h * .35, -z - h], 2.6, 0.15), BONE_MAT)
    for s in (-1, 1):
        if i % 2 == 0:
            part(j, spike([s * 5.5, y, -z + 1.5], [s * 9.0, y + 2.0, -z - h * .6],
                          1.7, 0.1), BONE_MAT)
# --- shoulder armour of bone (left shoulder is the mutated one) -------------
for s, frag, n in ((1, "bip L Clavicle", 4), (-1, "bip R Clavicle", 3)):
    for i in range(n):
        a = -0.5 + i * 0.55
        base = np.array([s * (16 + i * 3.5), 146.0 - i * 1.5, -2.0 + i * 2.0])
        part(frag, spike(base, base + np.array([s * 3.0, 9.0 + i * 1.5, -4.0]),
                         2.6 - i * .3, .12), BONE_MAT)
# --- tumours / flesh lumps ---------------------------------------------------
for (frag, c, r) in [("bip Spine019", [9.0, 128.0, -9.0], 4.4),
                     ("bip Spine019", [13.5, 122.0, -5.0], 3.4),
                     ("bip L UpperArm", [30.0, 141.0, -8.0], 4.0),
                     ("bip L UpperArm", [36.0, 133.0, 4.0], 3.0),
                     ("bip Spine018", [-8.0, 99.0, 9.0], 3.2),
                     ("bip L Thigh", [14.0, 70.0, 7.0], 3.4)]:
    part(frag, ball(c, r, sub=1), FLESH_MAT)
# --- claws -------------------------------------------------------------------
for s in (-1, 1):
    L = "L" if s > 0 else "R"
    for frag, tipp, dirv in [(f"bip {L} Finger045", [s * 74.5, 130.5, 5.6], [s * 7, -4, 5]),
                             (f"bip {L} Finger047", [s * 82.0, 133.6, -0.2], [s * 8, -3, 2])]:
        t = np.array(tipp, float)
        part(frag, spike(t, t + np.array(dirv, float), 1.5, 0.05), BONE_MAT)

# --- bake the parts into the glTF -------------------------------------------
for k, bymat in PARTS.items():
    jn = skin.joints[k]
    inv = IBM[k]
    for mat, meshes in bymat.items():
        m = trimesh.util.concatenate(meshes)
        V = np.asarray(m.vertices, float)
        V = (inv @ np.c_[V, np.ones(len(V))].T).T[:, :3]      # into bone space
        m = trimesh.Trimesh(vertices=V, faces=np.asarray(m.faces), process=False)
        m.fix_normals()
        Nv = np.asarray(m.vertex_normals, float)
        pa = add_acc(np.asarray(m.vertices, np.float32), 5126, "VEC3")
        na = add_acc(Nv.astype(np.float32), 5126, "VEC3")
        ia = add_acc(np.asarray(m.faces, np.uint32).ravel(), 5125, "SCALAR", 34963)
        g.meshes.append(Mesh(primitives=[Primitive(
            attributes=Attributes(POSITION=pa, NORMAL=na), indices=ia, material=mat)]))
        g.nodes.append(Node(name=f"mutace_{len(g.nodes)}", mesh=len(g.meshes) - 1))
        ni = len(g.nodes) - 1
        g.nodes[jn].children = (g.nodes[jn].children or []) + [ni]

# ---------------------------------------------------------------- texture
img = g.images[0]
bv = g.bufferViews[img.bufferView]
raw = bytes(blob[(bv.byteOffset or 0):(bv.byteOffset or 0) + bv.byteLength])
im = Image.open(io.BytesIO(raw)).convert("RGB")
a = np.asarray(im).astype(np.float32) / 255.0
lum = a @ np.array([.299, .587, .114])
a = a * .35 + lum[..., None] * .65                       # desaturate
a *= np.array([0.74, 0.92, 0.66])                        # sickly green cast
a = np.clip((a - .5) * 1.25 + .42, 0, 1)                 # darker, harder contrast
h, w, _ = a.shape
yy, xx = np.mgrid[0:h, 0:w]
veins = (np.sin(xx * .09 + np.sin(yy * .05) * 3.0) * np.cos(yy * .07 + 1.3))
a *= (1 - .22 * np.clip(veins, 0, 1)[..., None])         # dark veins
blotch = (np.sin(xx * .021) * np.cos(yy * .017) + np.sin(yy * .033 + 2)) * .5
a *= (1 - .18 * np.clip(blotch, 0, 1)[..., None])
im2 = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
im2 = ImageEnhance.Sharpness(im2).enhance(1.3)
buf = io.BytesIO(); im2.save(buf, format="PNG")
newraw = buf.getvalue()
nbv = append(np.frombuffer(newraw, dtype=np.uint8), target=None)
g.bufferViews[nbv].target = None
img.bufferView = nbv

# ---------------------------------------------------------------- scale & place
rigM = None
for k in range(len(JN)):
    if JPOS[JN[k]].any():
        # world matrix of this joint in bind pose == rig transform
        pass
def node_matrix(n):
    if n.matrix:
        return np.array(n.matrix, float).reshape(4, 4).T
    M = np.eye(4)
    if n.rotation is not None:
        x, y, z, w = n.rotation
        M[:3, :3] = np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                              [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                              [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])
    if n.scale is not None:
        M = M @ np.diag(list(n.scale) + [1])
    if n.translation is not None:
        T = np.eye(4); T[:3, 3] = n.translation; M = T @ M
    return M
W = {}
def walk(i, par=np.eye(4)):
    W[i] = par @ node_matrix(g.nodes[i])
    for c in (g.nodes[i].children or []):
        walk(c, W[i])
walk(0)
R = W[skin.joints[2]] @ IBM[2]            # bind space (cm) -> world
V = np.vstack(allP)
Vw = (R @ np.c_[V, np.ones(len(V))].T).T[:, :3]
lo, hi = Vw.min(0), Vw.max(0)
s = TARGET_H / (hi[1] - lo[1])
g.nodes[0].scale = [s, s, s]
g.nodes[0].translation = [-s * (lo[0] + hi[0]) / 2, -s * lo[1], -s * (lo[2] + hi[2]) / 2]

g.buffers[0].byteLength = len(blob)
g.set_binary_blob(bytes(blob))
g.save(OUT)
print(f"{OUT}  vyska {TARGET_H} m  dilu+{len(PARTS)} kosti  "
      f"triangles ~{sum(len(read(p.indices))//3 for m in g.meshes for p in m.primitives)}")
