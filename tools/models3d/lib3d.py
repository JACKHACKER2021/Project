"""Low-poly building generator helpers.

Convention: Y up, model centred on XZ, bottom at y=0, entrance faces +Z.
Colours are baked as vertex colours (flat hand-painted look, pastel palette).
"""
import numpy as np
import trimesh
from trimesh.creation import box as _box, cylinder as _cyl, cone as _cone, icosphere as _ico

# ---------------------------------------------------------------- palette
P = dict(
    plaster="#F6EFE2", plaster2="#EADFCB", white="#FBFBF7", bone="#F0EAD8",
    pink="#F2B8C6", pink2="#E79CB0", blue="#A8CBE8", blue2="#7FA9D0",
    deepblue="#4E6E96", red="#E2726E", red2="#C1504C", gold="#E8C56A",
    gold2="#CFA43F", wood="#8A5A3B", wood2="#6B4229", darkwood="#4A2E1E",
    oak="#5C3A24", roof="#C27B6B", roof2="#9E5E52", green="#9CC98A",
    green2="#6FA463", moss="#8AA86B", grey="#B9B9B4", grey3="#8E8E88",
    grey4="#6E6E69", dark="#44444A", stone="#D8D2C4", stone2="#BDB5A3",
    purple="#B49AD4", purple2="#8E74B5", lilac="#D7C6EC", glass="#CFE6F2",
    glassdark="#5E7A86", rust="#A9683F", mud="#9A7A5C", mud2="#7C5F45",
    black="#2E2E33", candle="#FFE9A8", flesh="#E8C9A8", water="#9FD6E8",
    mosaic="#5E9BC9", cream="#F5E7C8", mint="#BFE3D0", lol="#F09ACB",
    sand="#E8D9B5", soot="#5A4A44", yellow="#F2D26B", teal="#7EC4B8",
)

def _rgba(c):
    c = P.get(c, c).lstrip("#")
    return [int(c[i:i+2], 16) for i in (0, 2, 4)] + [255]

class Builder:
    """Collects coloured primitives into one mesh."""
    def __init__(self):
        self.parts = []

    def add(self, mesh, color):
        mesh.visual = trimesh.visual.ColorVisuals(
            mesh=mesh, vertex_colors=np.tile(_rgba(color), (len(mesh.vertices), 1)))
        self.parts.append((mesh, color if color in P else "custom"))
        return mesh

    # ---- primitives (pos = centre, unless noted) ----
    def box(self, size, pos=(0, 0, 0), color="plaster", rot=None, base=False):
        m = _box(extents=size)
        if rot is not None:
            for axis, ang in rot:
                m.apply_transform(trimesh.transformations.rotation_matrix(
                    np.radians(ang), {"x": [1, 0, 0], "y": [0, 1, 0], "z": [0, 0, 1]}[axis]))
        p = list(pos)
        if base:
            p[1] += size[1] / 2.0
        m.apply_translation(p)
        return self.add(m, color)

    def cyl(self, r, h, pos=(0, 0, 0), color="stone", sections=10, axis="y", base=False):
        m = _cyl(radius=r, height=h, sections=sections)   # trimesh: axis = Z
        if axis == "x":
            m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(90), [0, 1, 0]))
        elif axis == "y":
            m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(90), [1, 0, 0]))
        p = list(pos)
        if base:
            p[1] += h / 2.0
        m.apply_translation(p)
        return self.add(m, color)

    def cone(self, r, h, pos=(0, 0, 0), color="pink", sections=8, base=True):
        m = _cone(radius=r, height=h, sections=sections)
        p = list(pos)
        if not base:
            p[1] -= h / 2.0
        m.apply_translation(p)
        return self.add(m, color)

    def ball(self, r, pos=(0, 0, 0), color="gold", sub=1):
        m = _ico(subdivisions=sub, radius=r)
        m.apply_translation(pos)
        return self.add(m, color)

    def mesh(self, verts, faces, color):
        m = trimesh.Trimesh(vertices=np.array(verts, float), faces=np.array(faces, int),
                            process=False)
        return self.add(m, color)

    def gable(self, w, d, h, pos=(0, 0, 0), color="roof", ridge_along="x", over=0.0):
        """Triangular-prism roof. pos = centre of its base."""
        w += over * 2; d += over * 2
        x, y, z = pos
        hw, hd = w / 2.0, d / 2.0
        if ridge_along == "x":
            v = [(-hw, 0, -hd), (hw, 0, -hd), (hw, 0, hd), (-hw, 0, hd),
                 (-hw, h, 0), (hw, h, 0)]
            f = [(0, 1, 5), (0, 5, 4), (3, 2, 1), (3, 1, 0), (2, 3, 4), (2, 4, 5),
                 (0, 4, 3), (1, 2, 5)]
        else:
            v = [(-hw, 0, -hd), (hw, 0, -hd), (hw, 0, hd), (-hw, 0, hd),
                 (0, h, -hd), (0, h, hd)]
            f = [(0, 1, 4), (1, 2, 5), (1, 5, 4), (2, 3, 5), (3, 0, 4), (3, 4, 5),
                 (0, 3, 2), (0, 2, 1)]
        m = trimesh.Trimesh(vertices=np.array(v, float) + np.array([x, y, z]),
                            faces=np.array(f, int), process=False)
        return self.add(m, color)

    def pyramid(self, w, d, h, pos=(0, 0, 0), color="pink"):
        x, y, z = pos; hw, hd = w / 2.0, d / 2.0
        v = [(-hw, 0, -hd), (hw, 0, -hd), (hw, 0, hd), (-hw, 0, hd), (0, h, 0)]
        f = [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (0, 3, 2), (0, 2, 1)]
        m = trimesh.Trimesh(vertices=np.array(v, float) + np.array([x, y, z]),
                            faces=np.array(f, int), process=False)
        return self.add(m, color)

    def quad(self, a, b, c, d, color="glass"):
        m = trimesh.Trimesh(vertices=np.array([a, b, c, d], float),
                            faces=np.array([(0, 1, 2), (0, 2, 3)]), process=False)
        return self.add(m, color)

    # ---- composite helpers ----
    def window(self, w, h, pos, color="glass", frame="white", fd=0.06, facing="z",
               depth=0.05):
        """Framed window plate on a wall. pos = centre on the wall surface."""
        x, y, z = pos
        if facing in ("z", "-z"):
            s = 1 if facing == "z" else -1
            self.box((w, h, depth), (x, y, z + s * depth / 2), color)
            self.box((w + fd * 2, fd, depth * 1.2), (x, y + h / 2 + fd / 2, z + s * depth / 2), frame)
            self.box((w + fd * 2, fd, depth * 1.2), (x, y - h / 2 - fd / 2, z + s * depth / 2), frame)
            self.box((fd, h, depth * 1.2), (x - w / 2 - fd / 2, y, z + s * depth / 2), frame)
            self.box((fd, h, depth * 1.2), (x + w / 2 + fd / 2, y, z + s * depth / 2), frame)
        else:
            s = 1 if facing == "x" else -1
            self.box((depth, h, w), (x + s * depth / 2, y, z), color)
            self.box((depth * 1.2, fd, w + fd * 2), (x + s * depth / 2, y + h / 2 + fd / 2, z), frame)
            self.box((depth * 1.2, fd, w + fd * 2), (x + s * depth / 2, y - h / 2 - fd / 2, z), frame)
            self.box((depth * 1.2, h, fd), (x + s * depth / 2, y, z - w / 2 - fd / 2), frame)
            self.box((depth * 1.2, h, fd), (x + s * depth / 2, y, z + w / 2 + fd / 2), frame)

    def steps(self, w, n, rise, run, top_z, y0=0.0, color="stone"):
        """Stairs descending toward +Z from top_z."""
        for i in range(n):
            self.box((w, rise * (i + 1), run),
                     (0, (rise * (i + 1)) / 2 + y0, top_z + run * (n - 1 - i) + run / 2), color)

    def fence(self, p0, p1, h=0.9, posts=None, color="wood2", r=0.05, rail=True):
        p0, p1 = np.array(p0, float), np.array(p1, float)
        L = np.linalg.norm(p1 - p0)
        n = posts or max(2, int(L / 0.55) + 1)
        for i in range(n):
            p = p0 + (p1 - p0) * (i / (n - 1))
            self.box((r * 2, h, r * 2), (p[0], h / 2, p[2]), color)
        if rail:
            mid = (p0 + p1) / 2
            d = p1 - p0
            ang = np.degrees(np.arctan2(d[0], d[2]))
            for yy in (h * 0.75, h * 0.35):
                self.box((0.05, 0.08, L), (mid[0], yy, mid[2]), color, rot=[("y", ang)])

    # ---- export ----
    def export(self, path, name=""):
        # one mesh (and one flat PBR material) per colour, so engines show the paint
        groups = {}
        for mesh, col in self.parts:
            groups.setdefault(col, []).append(mesh)
        merged = {}
        for col, meshes in groups.items():
            m = trimesh.util.concatenate(meshes)
            m.merge_vertices()
            m.unmerge_vertices()          # flat faceted shading, low-poly look
            merged[col] = m
        whole = trimesh.util.concatenate(list(merged.values()))
        lo, hi = whole.bounds                 # centre on XZ, bottom on the ground
        off = np.array([-(lo[0] + hi[0]) / 2, -lo[1], -(lo[2] + hi[2]) / 2])
        nodes, tris, verts = {}, 0, 0
        for col, m in merged.items():
            m.apply_translation(off)
            rgba = _rgba(col)
            m.visual = trimesh.visual.TextureVisuals(
                material=trimesh.visual.material.PBRMaterial(
                    name=col, baseColorFactor=rgba, metallicFactor=0.0,
                    roughnessFactor=0.85 if col not in ("gold", "gold2", "water",
                                                        "glass", "mosaic") else 0.35))
            nodes[f"{name or 'model'}_{col}"] = m
            tris += len(m.faces); verts += len(m.vertices)
        trimesh.Scene(nodes).export(path, include_normals=True)
        return tris, verts

def finish(b, path, name=""):
    tris, verts = b.export(path, name)
    print(f"{path.split('/')[-1]:34s} {tris:6d} tris  {verts:6d} verts")
    return tris
