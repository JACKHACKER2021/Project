#!/usr/bin/env python3
"""Static validation of the RadioÚstí packs (no Minecraft needed).

Checks: JSON syntax, manifest UUIDs + dependencies, texture/geometry/bone/material references,
lang keys, loot paths, recipe item ids (incl. vanilla ids from tools/vanilla_ids.json),
custom-component registration, sound ids used by scripts, script import resolution and
`node --check` syntax (if node is installed), PNG sizes, collision/geometry bounds.
Exit code 1 if any ERROR is found.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BP = os.path.join(ROOT, "RadioUsti_BP")
RP = os.path.join(ROOT, "RadioUsti_RP")
errors, warnings = [], []


def err(m):
    errors.append(m)


def warn(m):
    warnings.append(m)


def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:  # noqa: BLE001
        err(f"JSON {os.path.relpath(path, ROOT)}: {e}")
        return None


def walk(root, ext):
    for dp, _, fn in os.walk(root):
        for f in fn:
            if f.endswith(ext):
                yield os.path.join(dp, f)


# ---------------------------------------------------------------- JSON syntax everywhere
all_json = {p: load(p) for p in list(walk(BP, ".json")) + list(walk(RP, ".json"))}

# ---------------------------------------------------------------- manifests
bpm, rpm = all_json[os.path.join(BP, "manifest.json")], all_json[os.path.join(RP, "manifest.json")]
uuids = []
for m, label in ((bpm, "BP"), (rpm, "RP")):
    uuids.append(m["header"]["uuid"])
    uuids += [x["uuid"] for x in m["modules"]]
for u in uuids:
    try:
        uuid.UUID(u)
    except ValueError:
        err(f"invalid UUID {u}")
if len(set(uuids)) != len(uuids):
    err("duplicate UUIDs in manifests")
dep = [d for d in bpm.get("dependencies", []) if "uuid" in d]
if not dep or dep[0]["uuid"] != rpm["header"]["uuid"] or dep[0]["version"] != rpm["header"]["version"]:
    err("BP manifest does not depend on the RP header uuid/version")
scripts = [x for x in bpm["modules"] if x["type"] == "script"]
if not scripts or not os.path.exists(os.path.join(BP, scripts[0]["entry"])):
    err("script entry missing")
mods = {d.get("module_name"): d.get("version") for d in bpm.get("dependencies", []) if "module_name" in d}
for need in ("@minecraft/server", "@minecraft/server-ui"):
    if need not in mods:
        err(f"BP manifest missing dependency {need}")

# ---------------------------------------------------------------- textures
terrain = all_json[os.path.join(RP, "textures", "terrain_texture.json")]["texture_data"]
itemtex = all_json[os.path.join(RP, "textures", "item_texture.json")]["texture_data"]
for name, d in list(terrain.items()) + list(itemtex.items()):
    if not os.path.exists(os.path.join(RP, d["textures"] + ".png")):
        err(f"texture file missing for {name}: {d['textures']}.png")

try:
    from PIL import Image
    for p in walk(os.path.join(RP, "textures"), ".png"):
        w, h = Image.open(p).size
        if w not in (16, 32, 64) or h not in (16, 32, 64):
            warn(f"unusual texture size {w}x{h}: {os.path.relpath(p, ROOT)}")
    for p in (os.path.join(BP, "pack_icon.png"), os.path.join(RP, "pack_icon.png")):
        w, h = Image.open(p).size
        if w != h:
            err(f"pack icon not square: {p}")
except ImportError:
    warn("Pillow not installed: PNG sizes not checked")

# ---------------------------------------------------------------- geometry index
geos = {}
for p in walk(os.path.join(RP, "models"), ".geo.json"):
    d = all_json.get(p)
    if not d:
        continue
    for g in d["minecraft:geometry"]:
        gid = g["description"]["identifier"]
        if gid in geos:
            err(f"duplicate geometry id {gid}")
        geos[gid] = g
        for b in g.get("bones", []):
            for c in b.get("cubes", []):
                o, s = c["origin"], c["size"]
                if o[0] < -8.01 or o[2] < -8.01 or o[1] < -0.01 or o[0] + s[0] > 8.01 or o[2] + s[2] > 8.01 or o[1] + s[1] > 16.01:
                    warn(f"{gid}/{b['name']}: cube outside the 16px block {o}+{s}")


def geo_materials(g):
    mats = set()
    for b in g.get("bones", []):
        for c in b.get("cubes", []):
            for face in c.get("uv", {}).values():
                if isinstance(face, dict) and "material_instance" in face:
                    mats.add(face["material_instance"])
    return mats


# ---------------------------------------------------------------- blocks
lang = {}
for code in ("en_US", "cs_CZ"):
    lang[code] = {}
    with open(os.path.join(RP, "texts", f"{code}.lang"), encoding="utf-8") as f:
        for line in f:
            if "=" in line and not line.startswith("#"):
                k, v = line.rstrip("\n").split("=", 1)
                lang[code][k] = v

blocks_json = all_json[os.path.join(RP, "blocks.json")]
block_ids, item_ids, used_components = set(), set(), set()
state_names = set()
BOX_RE = None
for p in walk(os.path.join(BP, "blocks"), ".json"):
    d = all_json.get(p)
    if not d:
        continue
    blk = d["minecraft:block"]
    bid = blk["description"]["identifier"]
    block_ids.add(bid)
    comps_list = [blk["components"]] + [x["components"] for x in blk.get("permutations", [])]
    states = blk["description"].get("states", {})
    state_names.update(k.split(":", 1)[1] for k in states)
    for comps in comps_list:
        for k in comps:
            if k.startswith("radiousti:"):
                used_components.add(k)
        g = comps.get("minecraft:geometry")
        gid = g if isinstance(g, str) else (g or {}).get("identifier")
        if gid and not gid.startswith("minecraft:geometry.") and gid not in geos:
            err(f"{bid}: geometry {gid} not found")
        if isinstance(g, dict) and gid in geos:
            bones = {b["name"] for b in geos[gid]["bones"]}
            for bn, expr in g.get("bone_visibility", {}).items():
                if bn not in bones:
                    err(f"{bid}: bone_visibility references missing bone {bn}")
                for st in re.findall(r"q\.block_state\('([^']+)'\)", str(expr)):
                    if st not in states:
                        err(f"{bid}: bone_visibility uses unknown state {st}")
        mi = comps.get("minecraft:material_instances")
        if mi:
            for k, v in mi.items():
                if v["texture"] not in terrain:
                    err(f"{bid}: texture {v['texture']} not in terrain_texture.json")
        for bx in ("minecraft:collision_box", "minecraft:selection_box"):
            b = comps.get(bx)
            if isinstance(b, dict):
                o, s = b["origin"], b["size"]
                if o[0] < -8 or o[2] < -8 or o[1] < 0 or o[0] + s[0] > 8 or o[2] + s[2] > 8 or o[1] + s[1] > 16:
                    err(f"{bid}: {bx} outside block bounds {o}+{s}")
        loot = comps.get("minecraft:loot")
        if loot and not os.path.exists(os.path.join(BP, loot)):
            err(f"{bid}: loot table {loot} missing")
    # material names used by geometry must exist in material_instances
    base_mi = blk["components"].get("minecraft:material_instances", {})
    for comps in comps_list:
        g = comps.get("minecraft:geometry")
        gid = g if isinstance(g, str) else (g or {}).get("identifier")
        if gid in geos:
            for m in geo_materials(geos[gid]):
                if m not in base_mi:
                    err(f"{bid}: geometry {gid} uses material '{m}' missing from material_instances")
    for perm in blk.get("permutations", []):
        for st in re.findall(r"q\.block_state\('([^']+)'\)", perm["condition"]):
            traits = blk["description"].get("traits", {})
            trait_states = [s for t in traits.values() for s in t.get("enabled_states", [])]
            if st not in states and st not in trait_states:
                err(f"{bid}: permutation uses unknown state {st}")
    if f"tile.{bid}.name" not in lang["en_US"] or f"tile.{bid}.name" not in lang["cs_CZ"]:
        err(f"{bid}: missing tile lang key")
    if bid not in blocks_json:
        warn(f"{bid}: not in RP blocks.json (no custom sound)")

# ---------------------------------------------------------------- items
for p in walk(os.path.join(BP, "items"), ".json"):
    d = all_json.get(p)
    if not d:
        continue
    it = d["minecraft:item"]
    iid = it["description"]["identifier"]
    item_ids.add(iid)
    c = it["components"]
    icon = c.get("minecraft:icon", {}).get("textures", {}).get("default")
    if icon not in itemtex:
        err(f"{iid}: icon {icon} not in item_texture.json")
    dn = c.get("minecraft:display_name", {}).get("value")
    for code in ("en_US", "cs_CZ"):
        if dn and dn.startswith(("item.", "tile.")) and dn not in lang[code]:
            err(f"{iid}: display name key {dn} missing in {code}")
    bp_ = c.get("minecraft:block_placer")
    if bp_ and bp_["block"] not in block_ids and not os.path.exists(os.path.join(BP, "blocks", bp_["block"].split(":")[1] + ".json")):
        err(f"{iid}: block_placer target {bp_['block']} missing")

# ---------------------------------------------------------------- recipes
vanilla = {}
vp = os.path.join(ROOT, "tools", "vanilla_ids.json")
if os.path.exists(vp):
    vanilla = json.load(open(vp, encoding="utf-8"))
vitems = set(vanilla.get("items", []))
entity_ids = set()
for p in walk(os.path.join(BP, "entities"), ".json"):
    d = all_json.get(p)
    if d:
        entity_ids.add(d["minecraft:entity"]["description"]["identifier"])
particle_ids = set()
for p in walk(os.path.join(RP, "particles"), ".json"):
    d = all_json.get(p)
    if d:
        particle_ids.add(d["particle_effect"]["description"]["identifier"])
known = block_ids | item_ids | entity_ids | particle_ids
VANILLA_TAGS = {"minecraft:planks", "minecraft:coals", "minecraft:logs", "minecraft:wool"}


def check_ref(rid, ref, where):
    if isinstance(ref, dict) and "tag" in ref:
        if ref["tag"] not in VANILLA_TAGS:
            warn(f"{rid}: unverified tag {ref['tag']} in {where}")
        return
    name = ref["item"] if isinstance(ref, dict) else ref
    if name.startswith("radiousti:"):
        if name not in known:
            err(f"{rid}: unknown RadioÚstí id {name} in {where}")
    elif vitems and name not in vitems:
        err(f"{rid}: unknown vanilla item {name} in {where}")


recipe_tags = set()
for p in walk(os.path.join(BP, "recipes"), ".json"):
    d = all_json.get(p)
    if not d:
        continue
    for kind, r in d.items():
        if kind == "format_version":
            continue
        rid = r["description"]["identifier"]
        recipe_tags.update(r.get("tags", []))
        if kind == "minecraft:recipe_shaped":
            for row in r["pattern"]:
                for ch in row:
                    if ch != " " and ch not in r["key"]:
                        err(f"{rid}: pattern symbol {ch} has no key")
            for v in r["key"].values():
                check_ref(rid, v, "key")
            check_ref(rid, r["result"], "result")
        elif kind == "minecraft:recipe_shapeless":
            for v in r["ingredients"]:
                check_ref(rid, v, "ingredients")
            check_ref(rid, r["result"], "result")
        elif kind == "minecraft:recipe_furnace":
            check_ref(rid, r["input"], "input")
            check_ref(rid, r["output"], "output")
table_tags = set()
for p in walk(os.path.join(BP, "blocks"), ".json"):
    ct = (all_json.get(p) or {}).get("minecraft:block", {}).get("components", {}).get("minecraft:crafting_table")
    if ct:
        table_tags.update(ct["crafting_tags"])
for t in recipe_tags - table_tags - {"crafting_table", "furnace", "blast_furnace", "smoker", "campfire"}:
    err(f"recipe tag {t} has no crafting table")

# ---------------------------------------------------------------- scripts
script_dir = os.path.join(BP, "scripts")
src = {p: open(p, encoding="utf-8").read() for p in walk(script_dir, ".js")}
registered = set()
for code in src.values():
    registered.update("radiousti:" + m for m in re.findall(r'reg\("([a-z_]+)"', code))
for c in used_components - registered:
    err(f"custom component {c} used by a block but never registered in scripts")
for c in registered - used_components:
    warn(f"custom component {c} registered but unused")
sound_defs = all_json[os.path.join(RP, "sounds", "sound_definitions.json")]["sound_definitions"]
for sid, d in sound_defs.items():
    for s in d["sounds"]:
        n = s["name"] if isinstance(s, dict) else s
        if not any(os.path.exists(os.path.join(RP, n + ext)) for ext in (".ogg", ".wav", ".fsb")):
            err(f"sound file missing for {sid}: {n}")
for p, code in src.items():
    for sid in re.findall(r'"(radiousti\.[a-z_]+)"', code):
        if sid not in sound_defs:
            err(f"{os.path.relpath(p, ROOT)}: sound {sid} not defined")
    for imp in re.findall(r'from "(\.[^"]+)"', code):
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(p), imp))):
            err(f"{os.path.relpath(p, ROOT)}: import {imp} not found")
    for ref in re.findall(r'`\$\{NS\}:([a-z0-9_]+)`', code):
        if ref in state_names or ref in ("config", "status") or ref.endswith("_"):
            continue  # block states, scriptevent ids and id prefixes
        if f"radiousti:{ref}" not in known:
            err(f"{os.path.relpath(p, ROOT)}: unknown id radiousti:{ref}")
    for ref in re.findall(r'"(minecraft:[a-z0-9_]+)"', code):
        if vanilla and ref not in vitems and ref not in set(vanilla.get("blocks", [])) and ref.split(":")[1] not in [e.split(":")[-1] for e in vanilla.get("effects", [])]:
            if ref not in ("minecraft:inventory", "minecraft:equippable", "minecraft:durability", "minecraft:cardinal_direction", "minecraft:player",
                           "minecraft:zombie_villager", "minecraft:zombie", "minecraft:husk", "minecraft:drowned", "minecraft:zombie_villager_v2", "minecraft:air",
                           "minecraft:overworld", "minecraft:water_splash_particle", "minecraft:campfire_smoke_particle", "minecraft:basic_flame_particle"):
                warn(f"{os.path.relpath(p, ROOT)}: unverified vanilla id {ref}")
node = shutil.which("node")
if node:
    for p in src:
        r = subprocess.run([node, "--check", "--input-type=module"], stdin=open(p, "rb"), capture_output=True, text=True)
        if r.returncode != 0:
            err(f"syntax {os.path.relpath(p, ROOT)}: {r.stderr.strip()[:300]}")
else:
    warn("node not installed: script syntax not checked")

# ---------------------------------------------------------------- lang sanity
for k in lang["en_US"]:
    if k not in lang["cs_CZ"]:
        err(f"lang key {k} missing in cs_CZ")

print(f"Blocks {len(block_ids)}, items {len(item_ids)}, geometries {len(geos)}, terrain textures {len(terrain)}, item textures {len(itemtex)}, "
      f"sounds {len(sound_defs)}, scripts {len(src)}, json files {len(all_json)}")
for w in warnings:
    print("WARN ", w)
for e in errors:
    print("ERROR", e)
print(f"{len(errors)} errors, {len(warnings)} warnings")
sys.exit(1 if errors else 0)
