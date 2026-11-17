"""Chain track pieces into one demo circuit."""
import numpy as np, trimesh, sys

EXIT = {  # piece -> (dx, dz, dyaw) of its far end, in local coords
 "draha_start": (0, -9.0, 0), "draha_rovna": (0, -7.2, 0),
 "draha_rovna_vlajky": (0, -7.2, 0), "draha_sikana": (0, -9.0, 0),
 "draha_tunel": (0, -7.2, 0), "draha_cil": (0, 0, 0),   # overlay gantry
 "draha_rovna_kratka": (0, -3.6, 0),
 "draha_stoupani": (0, -7.2, 0), "draha_klesani": (0, -7.2, 0),
 "draha_skok": (0, -14.4, 0),
 "draha_zatacka_vlevo": (-7.0, -7.0, 90), "draha_zatacka_vpravo": (7.0, -7.0, -90),
}

def rot(a, v):
    c, s = np.cos(np.radians(a)), np.sin(np.radians(a))
    return np.array([v[0] * c + v[1] * s, -v[0] * s + v[1] * c])

def build(seq, out, name="Okruh"):
    pos = np.array([0.0, 0.0]); yaw = 0.0
    groups = {}                      # material name -> meshes (materials kept)
    for p in seq:
        sc = trimesh.load(f"out/{p}.glb")
        T = trimesh.transformations.rotation_matrix(np.radians(yaw), [0, 1, 0])
        for g in sc.geometry.values():
            g = g.copy()
            g.apply_transform(T)
            g.apply_translation([pos[0], 0, pos[1]])
            mat = g.visual.material
            key = (mat.name or "x", tuple(np.array(mat.baseColorFactor, float)))
            groups.setdefault(key, []).append(g)
        dx, dz, dy = EXIT[p]
        pos = pos + rot(yaw, np.array([dx, dz]))
        yaw += dy
    merged = {k: trimesh.util.concatenate(v) for k, v in groups.items()}
    allm = trimesh.util.concatenate(list(merged.values()))
    lo, hi = allm.bounds
    off = [-(lo[0] + hi[0]) / 2, -lo[1], -(lo[2] + hi[2]) / 2]
    nodes, tris = {}, 0
    for (cname, rgba), m in merged.items():
        m.apply_translation(off)
        m.visual = trimesh.visual.TextureVisuals(
            material=trimesh.visual.material.PBRMaterial(
                name=cname, baseColorFactor=np.array(rgba).astype(np.uint8),
                metallicFactor=0.0,
                roughnessFactor=0.85))
        nodes[f"{name}_{cname}"] = m
        tris += len(m.faces)
    trimesh.Scene(nodes).export(out, include_normals=True)
    print(f"{out.split('/')[-1]:30s} {tris:6d} tris   konec: "
          f"x={pos[0]:.1f} z={pos[1]:.1f} yaw={yaw%360:.0f}")

# closed oval: sides 23.4 / 14.4 / 23.4 / 14.4
SEQ = ["draha_start", "draha_rovna_vlajky", "draha_rovna",     # 23.4
       "draha_zatacka_vlevo",
       "draha_skok",                                           # 14.4
       "draha_zatacka_vlevo",
       "draha_tunel", "draha_sikana", "draha_rovna",           # 23.4
       "draha_zatacka_vlevo",
       "draha_rovna", "draha_cil", "draha_rovna",              # 14.4 + finish gate
       "draha_zatacka_vlevo"]
build(SEQ, "out/draha_okruh_ukazka.glb")
