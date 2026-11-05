#!/usr/bin/env python3
"""Generate RadioÚstí pack content from tools/content.py.

Usage: python3 tools/build.py   (run from the RadioUsti/ folder or anywhere)

Generated (overwritten on each run):
  BP: blocks/, items/, loot_tables/, recipes/, features/, feature_rules/, scripts/data/registry.js
  RP: models/blocks/, textures/blocks|items|models, textures/*_texture.json, blocks.json,
      texts/*.lang, sounds/ (sound_definitions.json + .ogg), attachables/, pack icons
Hand-written (never touched): manifests, scripts/*.js except scripts/data/, docs, README.
"""
import json
import os
import shutil
import sys
from itertools import product

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo as G  # noqa: E402
import content as CT  # noqa: E402
import textures as T  # noqa: E402
import recipes as R  # noqa: E402
import sounds as SND  # noqa: E402
import structures as STR  # noqa: E402

ROOT = os.path.dirname(HERE)
BP = os.path.join(ROOT, "RadioUsti_BP")
RP = os.path.join(ROOT, "RadioUsti_RP")
NS = CT.NS
FMT_BLOCK = "1.21.90"
FMT_ITEM = "1.21.90"


def wjson(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def clean(path):
    if os.path.isdir(path):
        shutil.rmtree(path)
    os.makedirs(path, exist_ok=True)


# ------------------------------------------------------------------ models

def resolve_model(m):
    k = m[0]
    a = m[1:]
    table = {
        "full_clear": lambda: G.full(), "cooling_unit": G.cooling_unit, "button": G.button_model,
        "indicator": G.indicator_model, "pump": G.pump, "tank": G.tank, "waste_container": G.waste_container,
        "barrel": G.barrel, "server": G.server_rack, "lamp_hanging": G.lamp_hanging, "lamp_wall": G.lamp_wall,
        "lamp_ceiling": G.lamp_ceiling, "lamp_floor_beacon": G.lamp_floor_beacon, "alarm": G.alarm_model,
        "flat_wall": G.flat_wall, "flat_floor": G.flat_floor, "bars": G.bars_model, "crates": G.crate_stack,
        "battlement": G.battlement, "barricade": G.barricade, "barbed": G.barbed_wire, "sandbags": G.sandbags,
        "spikes": G.spikes, "rubble": G.rubble, "desk": G.desk, "chair": G.chair, "office_chair": G.office_chair,
        "stool": G.stool, "exam": G.exam_table, "iv": G.iv_stand, "med_monitor": G.med_monitor, "doc_pile": G.doc_pile,
        "clock": G.clock_model, "jar": G.jar, "flask_set": G.flask_set, "tube_rack": G.tube_rack, "growth": G.growth,
        "bin": G.bin_model, "crystal": G.crystal, "erlenmeyer": G.erlenmeyer, "round_flask": G.round_flask,
        "tube_stand": G.tube_stand, "vat": G.vat, "theater_seat": G.theater_seat, "curtain": G.curtain,
        "spotlight": G.spotlight, "crt_tv": G.crt_tv, "antenna": G.antenna, "shop_shelf": G.shop_shelf, "cash_register": G.cash_register,
        "school_desk": G.school_desk, "chalkboard": G.chalkboard, "canteen_table": G.canteen_table, "lunch_tray": G.lunch_tray,
        "serving_counter": G.serving_counter, "kitchen_pot": G.kitchen_pot, "shower_head": G.shower_head, "floor_drain": G.floor_drain,
        "lab_sink": G.lab_sink, "brazier": G.brazier, "pillar": G.pillar, "chainlink": G.chainlink, "steam_vent": G.steam_vent,
        "console": G.console, "ore": G.ore_crystals, "window_barricade": G.window_barricade,
        "security_camera": G.security_camera, "door_button": G.door_button, "display_case": G.display_case,
        "pedestal": G.pedestal, "rope_barrier": G.rope_barrier, "bench": G.bench, "nuke": G.nuke, "siren": G.siren, "village_bell": G.village_bell, "bottle": G.bottle, "jar_small": lambda fill=True: G.jar(8, 6),
    }
    if k in table:
        return table[k](*a)
    if k == "table":
        if a:
            return G.table(top_y=a[0], top_th=a[1], inset=a[2], leg=a[3])
        return G.table()
    if k == "cabinet":
        return G.cabinet(*a)
    if k == "slab_wall":
        return G.slab_wall(*a)
    if k == "pc":
        return G.pc_model(a[0])
    if k == "lab":
        return G.lab_table_kit(a[0])
    if k == "faces_full":
        return [G.B("root", G.C(0, 0, 0, 16, 16, 16, None, faces=a[0]))]
    raise ValueError(m)


def multi_source(mk):
    if isinstance(mk, tuple):
        if mk[0] == "corpse":
            return G.corpse_lying(mk[1])
        if mk[0] == "car":
            return G.car_wreck()
        if mk[0] == "lamp":
            return G.street_lamp()
        return G.radiak_statue()
    if mk == "bed":
        return G.bed_long()
    if mk == "optable":
        return G.operating_table()
    return G.gen_model(mk)


def face_variant_models(base):
    """Placement on a block face: wall (horizontal faces), floor (up), ceiling (down)."""
    wall = base
    # floor: lay the wall model flat (back on the bottom) -> map z (back=16) to y=0
    def to_floor(bones, ceiling=False):
        out = []
        for b in bones:
            cs = []
            for c in b["cubes"]:
                (x, y, z), (w, h, d) = c["o"], c["s"]
                ny = 16 - (z + d)
                nz = y
                if ceiling:
                    ny = z
                cs.append({"o": (x, ny, nz), "s": (w, d, h), "mat": c["mat"], "faces": None})
            out.append({"name": b["name"], "cubes": cs})
        return out
    return {"wall": wall, "floor": to_floor(base), "ceiling": to_floor(base, ceiling=True)}


# ------------------------------------------------------------------ block emit

def q(state, val):
    if isinstance(val, bool):
        return f"q.block_state('{state}') == {'true' if val else 'false'}"
    if isinstance(val, int):
        return f"q.block_state('{state}') == {val}"
    return f"q.block_state('{state}') == '{val}'"


def mat_instances(texmap, render):
    out = {}
    for k, v in texmap.items():
        out[k] = {"texture": v, "render_method": render}
        if render != "opaque":
            out[k]["ambient_occlusion"] = False
    return out


def box_json(bb):
    return {"origin": bb["origin"], "size": bb["size"]}


def emit_block(b, geo_files, blocks_json, lang, registry):
    bid = f"{NS}:{b['id']}"
    comps = {
        "minecraft:destructible_by_mining": {"seconds_to_destroy": b["hardness"]},
        "minecraft:destructible_by_explosion": {"explosion_resistance": b["resist"]},
        "minecraft:map_color": b["mapc"],
    }
    if b["light"]:
        comps["minecraft:light_emission"] = b["light"]
    for t in b["tags"]:
        comps[f"tag:{t}"] = {}
    custom = list(b["comps"])
    if b["kind"] == "machine" and not custom:
        custom.append(f"{NS}:machine")
    for c in custom:
        comps[c] = {}
    if b.get("tick"):
        comps["minecraft:tick"] = {"interval_range": list(b["tick"]), "looping": True}
    if b.get("crafting"):
        comps["minecraft:crafting_table"] = {"crafting_tags": [b["crafting"]],
                                             "table_name": f"tile.{bid}.name"}
    if b["loot"] == "empty":
        comps["minecraft:loot"] = "loot_tables/blocks/radiousti_empty.json"
    elif b["loot"] != "self":
        comps["minecraft:loot"] = b["loot"]

    states = dict(b["states"])
    traits = {}
    perms = []
    rot = b["rot"]
    dirs = ["north"]
    if rot == "cardinal":
        traits["minecraft:placement_direction"] = {"enabled_states": ["minecraft:cardinal_direction"], "y_rotation_offset": 180}
        dirs = G.DIRS
    elif rot == "face":
        traits["minecraft:placement_position"] = {"enabled_states": ["minecraft:block_face"]}

    model = b["model"]
    geos = []  # (condition, identifier, bones, collision, selection)
    gbase = f"geometry.{NS}.{b['id']}"
    is_full_cube = model is None
    pipe_like = model is not None and model[0] in ("pipe", "valve")

    if model is None:
        comps["minecraft:geometry"] = "minecraft:geometry.full_block"
    elif pipe_like:
        if model[0] == "pipe":
            _, r, fl, br = model
            bones = G.pipe_model(r, flange=fl, bracket=br)
        else:
            r = model[1]
            bones = G.valve_model(r)
        # Explicit permutations (no Molang in bone_visibility): one per connection combination.
        names = {bb["name"] for bb in bones}
        sides = ("n", "s", "e", "w", "u", "d")
        opp = {"n": "s", "s": "n", "e": "w", "w": "e", "u": "d", "d": "u"}
        valve = model[0] == "valve"
        for mask in range(64):
            on = {k: bool(mask >> i & 1) for i, k in enumerate(sides)}
            act = [k for k in sides if on[k]]
            straight = len(act) == 2 and opp[act[0]] == act[1]
            for op in ((True, False) if valve else (None,)):
                vis = {}
                for k in sides:
                    vis[k] = on[k]
                    if f"fl_{k}" in names:
                        vis[f"fl_{k}"] = on[k]
                if "joint" in names:
                    vis["joint"] = len(act) >= 3 or (len(act) == 2 and not straight)
                if "bracket" in names:
                    vis["bracket"] = not on["d"]
                if valve:
                    vis.update({"wheel_open": op, "wheel_closed": not op, "lamp_open": op, "lamp_closed": not op})
                cond = " && ".join(q(f"{NS}:{k}", on[k]) for k in sides)
                if valve:
                    cond += " && " + q(f"{NS}:open", op)
                perms.append({"condition": cond, "components": {"minecraft:geometry": {"identifier": gbase, "bone_visibility": vis}}})
        base_vis = {bb["name"]: bb["name"] in ("core", "body", "stem", "wheel_open", "lamp_open") for bb in bones}
        comps[f"{NS}:conduit"] = {}
        geo_files[b["id"]] = [G.geometry_entry(gbase, bones)]
        comps["minecraft:geometry"] = {"identifier": gbase, "bone_visibility": base_vis}
        rr = max(r, 2)
        core = {"origin": [-rr, 8 - rr, -rr], "size": [2 * rr, 2 * rr, 2 * rr]}
        comps["minecraft:collision_box"] = core
        sel = rr + 1
        comps["minecraft:selection_box"] = {"origin": [-sel, 8 - sel, -sel], "size": [2 * sel, 2 * sel, 2 * sel]}
        comps["minecraft:light_dampening"] = 0
    elif model[0] == "multi":
        _, mk, offs = model
        src = multi_source(mk)
        entries = []
        for pi, (dx, dy, dz) in enumerate(offs):
            part = G.slice_model(src, dx, dy, dz)
            for d in dirs:
                pb = G.rot_model(part, d)
                ident = f"{gbase}.p{pi}.{d}"
                entries.append(G.geometry_entry(ident, pb))
                cond = q(f"{NS}:part", pi) + (" && " + q("minecraft:cardinal_direction", d) if rot == "cardinal" else "")
                geos.append((cond, ident, pb))
        geo_files[b["id"]] = entries
    elif model[0] == "liquid_levels":
        entries = []
        for lv in range(5):
            pb = G.liquid(lv)
            ident = f"{gbase}.l{lv}"
            entries.append(G.geometry_entry(ident, pb))
            geos.append((q(f"{NS}:level", lv), ident, pb))
        geo_files[b["id"]] = entries
    elif b["kind"] == "door":
        entries = []
        for d in dirs:
            for op in (False, True):
                for up in (False, True):
                    pb = G.rot_model(G.door_model(op, up, b.get("door_style", "swing")), d)
                    ident = f"{gbase}.{'open' if op else 'closed'}.{'upper' if up else 'lower'}.{d}"
                    entries.append(G.geometry_entry(ident, pb))
                    geos.append((q("minecraft:cardinal_direction", d) + " && " + q(f"{NS}:open", op) + " && " + q(f"{NS}:upper", up), ident, pb))
        geo_files[b["id"]] = entries
    elif rot == "face":
        variants = face_variant_models(resolve_model(model))
        entries = []
        for face in ("north", "south", "east", "west", "up", "down"):
            if face in G.DIRS:
                pb = G.rot_model(variants["wall"], face)
            elif face == "up":
                pb = variants["floor"]
            else:
                pb = variants["ceiling"]
            ident = f"{gbase}.{face}"
            entries.append(G.geometry_entry(ident, pb))
            geos.append((q("minecraft:block_face", face), ident, pb))
        geo_files[b["id"]] = entries
    else:
        base = resolve_model(model)
        if rot == "cardinal":
            entries = []
            for d in dirs:
                pb = G.rot_model(base, d)
                ident = f"{gbase}.{d}"
                entries.append(G.geometry_entry(ident, pb))
                geos.append((q("minecraft:cardinal_direction", d), ident, pb))
            geo_files[b["id"]] = entries
        else:
            geo_files[b["id"]] = [G.geometry_entry(gbase, base)]
            comps["minecraft:geometry"] = gbase
            if model[0] != "full_clear":
                bb = G.bbox(base)
                if b["collision"] is False:
                    comps["minecraft:collision_box"] = False
                else:
                    comps["minecraft:collision_box"] = box_json(bb)
                comps["minecraft:selection_box"] = box_json(bb)
                comps["minecraft:light_dampening"] = 0
            else:
                comps["minecraft:light_dampening"] = 0

    if geos:
        # default geometry = first variant (keeps the block valid if no permutation matched)
        comps["minecraft:geometry"] = geos[0][1]
        comps["minecraft:light_dampening"] = 0
        for cond, ident, pb in geos:
            bb = G.bbox(pb)
            pc = {"minecraft:geometry": ident, "minecraft:selection_box": box_json(bb)}
            if b["collision"] is False:
                pc["minecraft:collision_box"] = False
            elif model is not None and model[0] == "faces_full":
                pc.pop("minecraft:selection_box")
            else:
                pc["minecraft:collision_box"] = box_json(bb)
            perms.append({"condition": cond, "components": pc})

    if model is not None and model[0] == "faces_full":
        comps["minecraft:light_dampening"] = 15

    # materials
    render = b["render"]
    base_tex = {k: v for k, v in b["tex"].items()}
    if is_full_cube:
        # full blocks: use face keys directly
        pass
    comps["minecraft:material_instances"] = mat_instances(base_tex, render)

    def mat_perm(cond, override, light=None):
        m = dict(base_tex)
        m.update(override)
        pc = {"minecraft:material_instances": mat_instances(m, render)}
        if light is not None:
            pc["minecraft:light_emission"] = light
        perms.append({"condition": cond, "components": pc})

    if b.get("tex_active"):
        mat_perm(q(f"{NS}:active", True), b["tex_active"], b.get("light_active"))
    if b.get("tex_lit"):
        mat_perm(q(f"{NS}:lit", True), b["tex_lit"], b.get("light_lit"))
    if b.get("tex_upper"):
        mat_perm(q(f"{NS}:upper", True), b["tex_upper"])
    if b.get("level_tex"):
        for lv, t in b["level_tex"].items():
            if lv:
                mat_perm(q(f"{NS}:level", lv), {"glow": t})
    if b.get("fill_tex"):
        for lv, t in b["fill_tex"].items():
            if lv:
                mat_perm(q(f"{NS}:fill", lv), {"fill": t})
    if b.get("variant_tex"):
        for lv, t in b["variant_tex"].items():
            if lv:
                mat_perm(q(f"{NS}:variant", lv), {"*": t})

    cat = b["cat"]
    if b.get("placer_icon"):
        cat = "none"
    desc = {"identifier": bid, "menu_category": {"category": cat}}
    if states:
        desc["states"] = states
    if traits:
        desc["traits"] = traits
    comps["minecraft:display_name"] = b["cs"]
    data = {"format_version": FMT_BLOCK, "minecraft:block": {"description": desc, "components": comps}}
    if perms:
        data["minecraft:block"]["permutations"] = perms
    wjson(os.path.join(BP, "blocks", f"{b['id']}.json"), data)

    blocks_json[bid] = {"sound": b["sound"]}
    for k in (f"tile.{bid}.name", f"tile.{bid}", f"item.{bid}.name", f"item.{bid}"):
        lang["en"][k] = b["en"]
        lang["cs"][k] = b["cs"]

    meta = dict(b["meta"])
    reg = {"kind": b["kind"], "en": b["en"], "cs": b["cs"], **meta}
    if "multiblock" in reg:
        reg["multiblock"] = [list(o) for o in reg["multiblock"]]
    if rot:
        reg["rot"] = rot
    registry["blocks"][bid] = reg

    if b.get("placer_icon"):
        kind, col = b["placer_icon"]
        icon = CT.itex(f"{b['id']}_icon", lambda n, k=kind, c=col: T.item(n, k, c))
        item = {"format_version": FMT_ITEM, "minecraft:item": {
            "description": {"identifier": bid, "menu_category": {"category": b["cat"] if b["cat"] != "none" else "equipment"}},
            "components": {
                "minecraft:icon": {"textures": {"default": icon}},
                "minecraft:display_name": {"value": b["cs"]},
                "minecraft:max_stack_size": 16,
                "minecraft:block_placer": {"block": bid, "replace_block_item": True},
            }}}
        wjson(os.path.join(BP, "items", f"{b['id']}.json"), item)
        lang["en"][f"item.{NS}.{b['id']}.name"] = b["en"]
        lang["cs"][f"item.{NS}.{b['id']}.name"] = b["cs"]


def emit_item(it, lang, registry):
    iid = f"{NS}:{it['id']}"
    comps = {"minecraft:icon": {"textures": {"default": it["icon"]}},
             "minecraft:display_name": {"value": it["cs"]},
             "minecraft:max_stack_size": it["stack"]}
    comps.update(it["comps"])
    data = {"format_version": FMT_ITEM, "minecraft:item": {
        "description": {"identifier": iid, "menu_category": {"category": it["cat"]}}, "components": comps}}
    wjson(os.path.join(BP, "items", f"{it['id']}.json"), data)
    for k in (f"item.{NS}.{it['id']}.name", f"item.{iid}.name", f"item.{iid}"):
        lang["en"][k] = it["en"]
        lang["cs"][k] = it["cs"]
    registry["items"][iid] = {"kind": it["kind"], "en": it["en"], "cs": it["cs"], **it["meta"]}


# ------------------------------------------------------------------ misc emitters

def emit_loot():
    d = os.path.join(BP, "loot_tables", "blocks")
    wjson(os.path.join(d, "radiousti_empty.json"), {"pools": []})
    wjson(os.path.join(d, "uranium_ore.json"), {"pools": [{"rolls": 1, "entries": [
        {"type": "item", "name": f"{NS}:raw_uranium", "weight": 1,
         "functions": [{"function": "set_count", "count": {"min": 1, "max": 2}}]}]}]})
    for b in CT.BLOCKS:
        if b["kind"] == "glassware":
            wjson(os.path.join(BP, b["loot"]), {"pools": [{"rolls": 1, "entries": [{"type": "item", "name": b["meta"]["item"], "weight": 1}]}]})
    wjson(os.path.join(d, "liverocrystal_ore.json"), {"pools": [{"rolls": 1, "entries": [
        {"type": "item", "name": f"{NS}:liverocrystal_shard", "weight": 1,
         "functions": [{"function": "set_count", "count": {"min": 1, "max": 2}}]}]}]})
    wjson(os.path.join(d, "contaminated_grass.json"), {"pools": [{"rolls": 1, "entries": [
        {"type": "item", "name": f"{NS}:contaminated_dirt", "weight": 1}]}]})


def emit_worldgen():
    wjson(os.path.join(BP, "features", "uranium_ore_feature.json"), {
        "format_version": "1.13.0",
        "minecraft:ore_feature": {
            "description": {"identifier": f"{NS}:uranium_ore_feature"},
            "count": 5,
            "replace_rules": [
                {"places_block": f"{NS}:uranium_ore",
                 "may_replace": ["minecraft:stone", "minecraft:andesite", "minecraft:diorite", "minecraft:granite", "minecraft:tuff"]},
                {"places_block": f"{NS}:deepslate_uranium_ore", "may_replace": ["minecraft:deepslate"]}]}})
    wjson(os.path.join(BP, "feature_rules", "uranium_ore_rule.json"), {
        "format_version": "1.13.0",
        "minecraft:feature_rules": {
            "description": {"identifier": f"{NS}:uranium_ore_rule", "places_feature": f"{NS}:uranium_ore_feature"},
            "conditions": {"placement_pass": "underground_pass",
                           "minecraft:biome_filter": [{"test": "has_biome_tag", "operator": "==", "value": "overworld"}]},
            "distribution": {"iterations": 3, "coordinate_eval_order": "zyx",
                             "x": {"distribution": "uniform", "extent": [0, 16]},
                             "y": {"distribution": "uniform", "extent": [-48, 24]},
                             "z": {"distribution": "uniform", "extent": [0, 16]}}}})


def emit_lc_worldgen():
    wjson(os.path.join(BP, "features", "liverocrystal_ore_feature.json"), {
        "format_version": "1.13.0",
        "minecraft:ore_feature": {"description": {"identifier": f"{NS}:liverocrystal_ore_feature"}, "count": 4,
                                  "replace_rules": [{"places_block": f"{NS}:liverocrystal_ore",
                                                     "may_replace": ["minecraft:stone", "minecraft:deepslate", "minecraft:tuff"]}]}})
    wjson(os.path.join(BP, "feature_rules", "liverocrystal_ore_rule.json"), {
        "format_version": "1.13.0",
        "minecraft:feature_rules": {
            "description": {"identifier": f"{NS}:liverocrystal_ore_rule", "places_feature": f"{NS}:liverocrystal_ore_feature"},
            "conditions": {"placement_pass": "underground_pass",
                           "minecraft:biome_filter": [{"test": "has_biome_tag", "operator": "==", "value": "overworld"}]},
            "distribution": {"iterations": 2, "coordinate_eval_order": "zyx",
                             "x": {"distribution": "uniform", "extent": [0, 16]},
                             "y": {"distribution": "uniform", "extent": [-60, -10]},
                             "z": {"distribution": "uniform", "extent": [0, 16]}}}})


SKY = "#7f9a62"  # permanent greenish post-apocalyptic sky


def emit_environment():
    """Client biomes (sky colour + RadioÚstí atmosphere), fog presets and Vibrant Visuals atmosphere."""
    src = os.path.join(HERE, "vanilla_client_biomes")
    out = os.path.join(RP, "biomes")
    clean(out)
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.endswith(".client_biome.json"):
            continue
        with open(os.path.join(src, f), encoding="utf-8") as fh:
            d = json.load(fh)
        comps = d["minecraft:client_biome"].setdefault("components", {})
        comps["minecraft:sky_color"] = {"sky_color": SKY}
        comps["minecraft:water_appearance"] = {"surface_color": "#4f7a2a"}
        comps["minecraft:atmosphere_identifier"] = {"atmosphere_identifier": f"{NS}:atmosphere"}
        wjson(os.path.join(out, f), d)
        n += 1
    # Vibrant Visuals atmosphere: time keys 0 = noon, 0.25 = sunset, 0.5 = midnight, 0.75 = sunrise
    with open(os.path.join(src, "_default_atmospherics.json"), encoding="utf-8") as fh:
        atm = json.load(fh)
    a = atm["minecraft:atmosphere_settings"]
    a["description"]["identifier"] = f"{NS}:atmosphere"
    a["sky_zenith_color"] = {"0.000000": [92, 122, 74], "0.200000": [96, 120, 70], "0.250000": [120, 48, 34],
                             "0.300000": [70, 14, 14], "0.500000": [52, 6, 8], "0.700000": [70, 14, 14],
                             "0.750000": [124, 56, 36], "0.800000": [96, 120, 70], "1.000000": [92, 122, 74]}
    a["sky_horizon_color"] = {"0.000000": [150, 168, 104], "0.200000": [160, 160, 96], "0.240000": [214, 98, 56],
                              "0.280000": [170, 40, 30], "0.400000": [96, 16, 16], "0.600000": [96, 16, 16],
                              "0.720000": [176, 52, 34], "0.760000": [210, 110, 64], "0.800000": [158, 166, 102], "1.000000": [150, 168, 104]}
    clean(os.path.join(RP, "atmospherics"))
    wjson(os.path.join(RP, "atmospherics", "radiousti_atmosphere.json"), atm)
    # fog presets pushed by scripts/systems/environment.js with /fog
    clean(os.path.join(RP, "fogs"))
    for fid, col, start, end, kind in (
            ("day", "#8ea86b", 0.55, 1.0, "render"), ("dusk", "#c0603a", 0.5, 1.0, "render"),
            ("night", "#5a0e0e", 0.45, 0.95, "render"), ("dawn", "#a8502f", 0.5, 1.0, "render"),
            ("smog", "#7c8a5a", 2, 36, "fixed"), ("rain", "#6f9a3a", 6, 64, "fixed")):
        d = {"format_version": "1.16.100", "minecraft:fog_settings": {
            "description": {"identifier": f"{NS}:fog_{fid}"},
            "distance": {"air": {"fog_start": start, "fog_end": end, "fog_color": col, "render_distance_type": kind},
                         "weather": {"fog_start": min(start, 4) if kind == "fixed" else 0.3, "fog_end": end if kind == "fixed" else 0.7,
                                     "fog_color": "#5f7f35", "render_distance_type": kind}}}}
        wjson(os.path.join(RP, "fogs", f"radiousti_fog_{fid}.json"), d)
    return n


ZED = f"{NS}:irradiated_zed"


def zed_texture(src, dst, variant="zed"):
    """Recolour the vanilla zombie skin into a radioactive RadioÚstí Zed (toxic skin, worn hazmat suit, glowing eyes)."""
    import numpy as np
    from PIL import Image
    im = np.array(Image.open(src).convert("RGBA")).astype(int)
    rng = np.random.default_rng(72)
    h, w = im.shape[:2]
    for y in range(h):
        for x in range(w):
            r, g, b, a = im[y, x]
            if a == 0:
                continue
            lum = (r + g + b) / 3
            if g > r + 8 and g > b:          # skin
                tone = 0.6 + lum / 255 * 0.7
                c = [int(110 * tone), int(150 * tone), int(52 * tone)]
                if variant == "radiak":
                    c = [int(60 * tone), int(200 * tone), int(60 * tone)]
                if rng.random() < (0.08 if variant == "zed" else 0.2):
                    c = [190, 255, 90] if variant == "zed" else [125, 255, 58]   # radioactive blisters / uranium crystals
            elif b > r and b >= g:            # shirt -> worn hazmat yellow (Radiak: burnt mechanical suit)
                tone = 0.55 + lum / 255 * 0.8
                c = [int(175 * tone), int(150 * tone), int(40 * tone)] if variant == "zed" else [int(70 * tone), int(78 * tone), int(84 * tone)]
                if rng.random() < 0.05:
                    c = [80, 60, 30]
            else:                             # trousers and rest -> dark grey-green
                tone = 0.5 + lum / 255 * 0.8
                c = [int(55 * tone), int(68 * tone), int(55 * tone)]
            im[y, x, :3] = np.clip(c, 0, 255)
    # glowing eyes on the head front (8..16, 8..16)
    for ex, ey in ((9, 12), (10, 12), (13, 12), (14, 12)):
        if ey < h and ex < w:
            im[ey, ex] = [190, 255, 90, 255]
    Image.fromarray(im.astype("uint8"), "RGBA").save(dst)


def emit_zed(lang, ident=ZED, variant="zed", health=26, damage=4, weight=60, names=None, loot=None, egg=("#3f6f2a", "#c6ff5a")):
    src = os.path.join(HERE, "vanilla_entities")
    with open(os.path.join(src, "zombie.behavior.json"), encoding="utf-8") as f:
        bp = json.load(f)
    e = bp["minecraft:entity"]
    e["description"]["identifier"] = ident
    e["description"]["runtime_identifier"] = "minecraft:zombie"
    e["components"].pop("minecraft:burns_in_daylight", None)
    for g in ("minecraft:look_to_start_transformations", "minecraft:start_drowned_transformation",
              "minecraft:convert_to_drowned", "minecraft:convert_to_baby_drowned"):
        e["component_groups"].pop(g, None)
    for ev in ("minecraft:start_transforming_into_drowned", "minecraft:stop_transforming", "minecraft:convert_to_drowned"):
        e["events"].pop(ev, None)
    for grp in e["component_groups"].values():
        for k in list(grp):
            if "transformation" in k:
                grp.pop(k)
    sensor = e["components"].get("minecraft:environment_sensor")
    if sensor:
        sensor["triggers"] = [t for t in sensor["triggers"] if "drowned" not in t.get("event", "")]
    for ev in e["events"].values():
        for part in ([ev] + ev.get("sequence", [])):
            for key in ("add", "remove"):
                if key in part:
                    part[key]["component_groups"] = [g for g in part[key].get("component_groups", []) if g in e["component_groups"]]
    short = ident.split(":")[1]
    e["components"]["minecraft:type_family"] = {"family": ["zombie", "undead", "monster", "mob", "radiousti_zed"]}
    e["components"]["minecraft:health"] = {"value": health, "max": health}
    e["components"]["minecraft:attack"] = {"damage": damage}
    e["components"]["minecraft:loot"] = {"table": f"loot_tables/entities/{short}.json"}
    wjson(os.path.join(BP, "entities", f"{short}.json"), bp)
    wjson(os.path.join(BP, "loot_tables", "entities", f"{short}.json"), loot or {"pools": [
        {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:infected_flesh", "weight": 1,
                                  "functions": [{"function": "set_count", "count": {"min": 0, "max": 2}}]}]},
        {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:blood_bottle", "weight": 3}, {"type": "empty", "weight": 7}]},
        {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:raw_uranium", "weight": 1}, {"type": "empty", "weight": 9}]},
        {"rolls": 1, "entries": [{"type": "item", "name": "minecraft:rotten_flesh", "weight": 1,
                                  "functions": [{"function": "set_count", "count": {"min": 0, "max": 1}}]}]}]})
    # spawning: any light level (also in daylight), overworld surface
    wjson(os.path.join(BP, "spawn_rules", f"{short}.json"), {
        "format_version": "1.8.0",
        "minecraft:spawn_rules": {"description": {"identifier": ident, "population_control": "monster"},
                                  "conditions": [{"minecraft:spawns_on_surface": {}, "minecraft:spawns_underground": {},
                                                  "minecraft:brightness_filter": {"min": 0, "max": 15, "adjust_for_weather": False},
                                                  "minecraft:difficulty_filter": {"min": "easy", "max": "hard"},
                                                  "minecraft:weight": {"default": weight},
                                                  "minecraft:herd": {"min_size": 1, "max_size": 3},
                                                  "minecraft:biome_filter": {"test": "has_biome_tag", "value": "overworld"}}]}})
    with open(os.path.join(src, "zombie.client_entity.json"), encoding="utf-8") as f:
        rp = json.load(f)
    d = rp["minecraft:client_entity"]["description"]
    d["identifier"] = ident
    d["textures"] = {"default": f"textures/entity/radiousti_{short}", "baby": f"textures/entity/radiousti_{short}_baby"}
    d["spawn_egg"] = {"base_color": egg[0], "overlay_color": egg[1]}
    os.makedirs(os.path.join(RP, "entity"), exist_ok=True)
    os.makedirs(os.path.join(RP, "textures", "entity"), exist_ok=True)
    wjson(os.path.join(RP, "entity", f"{short}.entity.json"), rp)
    zed_texture(os.path.join(src, "zombie.png"), os.path.join(RP, "textures", "entity", f"radiousti_{short}.png"), variant)
    zed_texture(os.path.join(src, "zombie_baby.png"), os.path.join(RP, "textures", "entity", f"radiousti_{short}_baby.png"), variant)
    for code, name in (names or (("en", "Irradiated Zed of RadioÚstí"), ("cs", "Ozářený Zed z RadioÚstí"))):
        lang[code][f"entity.{ident}.name"] = name
        lang[code][f"item.spawn_egg.entity.{ident}.name"] = ("Spawn " if code == "en" else "Vyvolat: ") + name


def emit_particles():
    """Tiny glowing radiation motes floating in the air (spawned by scripts/systems/radiation.js)."""
    from PIL import Image
    d = os.path.join(RP, "particles")
    os.makedirs(d, exist_ok=True)
    os.makedirs(os.path.join(RP, "textures", "particle"), exist_ok=True)
    im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    for x, y, a in ((1, 1, 255), (2, 1, 255), (1, 2, 255), (2, 2, 255), (0, 1, 90), (3, 2, 90), (1, 0, 90), (2, 3, 90)):
        im.putpixel((x, y), (220, 255, 170, a))
    im.save(os.path.join(RP, "textures", "particle", "radiousti_mote.png"))
    puff = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(16):
            dist = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if dist < 7.5:
                puff.putpixel((x, y), (255, 255, 255, int(255 * (1 - dist / 7.5) ** 0.6)))
    puff.save(os.path.join(RP, "textures", "particle", "radiousti_puff.png"))
    for pid, n, radius, size, rise, colors, shape in (
            ("nuke_cloud", 30, 3, 2.2, 0.6, [[1.0, 0.75, 0.3, 0.9], [0.35, 0.3, 0.28, 0.0]], "sphere"),
            ("nuke_cap", 45, 9, 3.2, 0.15, [[1.0, 0.55, 0.2, 0.9], [0.3, 0.27, 0.25, 0.0]], "disc")):
        shp = {"minecraft:emitter_shape_sphere": {"radius": radius, "surface_only": False, "direction": "outwards"}} if shape == "sphere" else \
            {"minecraft:emitter_shape_disc": {"radius": radius, "surface_only": False, "plane_normal": "y", "direction": "outwards"}}
        wjson(os.path.join(d, f"radiousti_{pid}.json"), {"format_version": "1.10.0", "particle_effect": {
            "description": {"identifier": f"{NS}:{pid}",
                            "basic_render_parameters": {"material": "particles_blend", "texture": "textures/particle/radiousti_puff"}},
            "components": {
                "minecraft:emitter_rate_instant": {"num_particles": n},
                "minecraft:emitter_lifetime_once": {"active_time": 0.1},
                **shp,
                "minecraft:particle_lifetime_expression": {"max_lifetime": "math.random(5, 8)"},
                "minecraft:particle_initial_speed": 0.6,
                "minecraft:particle_motion_dynamic": {"linear_acceleration": [0, rise, 0], "linear_drag_coefficient": 0.8},
                "minecraft:particle_appearance_billboard": {"size": [size, size], "facing_camera_mode": "rotate_xyz",
                                                            "uv": {"texture_width": 16, "texture_height": 16, "uv": [0, 0], "uv_size": [16, 16]}},
                "minecraft:particle_appearance_tinting": {"color": {"gradient": colors, "interpolant": "v.particle_age / v.particle_lifetime"}}}}})
    for pid, n, radius, tint in (("radiation_mote", 8, 7, [0.55, 1.0, 0.3, 0.9]), ("liverocrystal_mote", 6, 4, [0.35, 0.75, 1.0, 0.9])):
        wjson(os.path.join(d, f"radiousti_{pid}.json"), {"format_version": "1.10.0", "particle_effect": {
            "description": {"identifier": f"{NS}:{pid}",
                            "basic_render_parameters": {"material": "particles_add", "texture": "textures/particle/radiousti_mote"}},
            "components": {
                "minecraft:emitter_rate_instant": {"num_particles": n},
                "minecraft:emitter_lifetime_once": {"active_time": 0.1},
                "minecraft:emitter_shape_sphere": {"radius": radius, "surface_only": False, "direction": "outwards"},
                "minecraft:particle_lifetime_expression": {"max_lifetime": "math.random(2.5, 4.5)"},
                "minecraft:particle_initial_speed": 0.08,
                "minecraft:particle_motion_dynamic": {"linear_acceleration": [0, 0.03, 0], "linear_drag_coefficient": 1.5},
                "minecraft:particle_appearance_billboard": {"size": [0.03, 0.03], "facing_camera_mode": "rotate_xyz",
                                                            "uv": {"texture_width": 4, "texture_height": 4, "uv": [0, 0], "uv_size": [4, 4]}},
                "minecraft:particle_appearance_tinting": {"color": tint}}}})


def emit_slime(lang):
    import numpy as np
    from PIL import Image
    src = os.path.join(HERE, "vanilla_entities")
    ident = f"{NS}:radiak_slime"
    with open(os.path.join(src, "slime.behavior.json"), encoding="utf-8") as f:
        bp = json.load(f)
    e = bp["minecraft:entity"]
    e["description"]["identifier"] = ident
    e["description"]["runtime_identifier"] = "minecraft:slime"
    fam = e["components"].get("minecraft:type_family", {"family": ["slime", "monster", "mob"]})
    fam["family"] = list(dict.fromkeys(fam["family"] + ["radiousti_slime"]))
    e["components"]["minecraft:type_family"] = fam
    e["components"]["minecraft:loot"] = {"table": "loot_tables/entities/radiak_slime.json"}
    wjson(os.path.join(BP, "entities", "radiak_slime.json"), bp)
    wjson(os.path.join(BP, "loot_tables", "entities", "radiak_slime.json"), {"pools": [
        {"rolls": 1, "entries": [{"type": "item", "name": "minecraft:slime_ball", "weight": 1,
                                  "functions": [{"function": "set_count", "count": {"min": 0, "max": 2}}]}]},
        {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:raw_uranium", "weight": 1}, {"type": "empty", "weight": 2}]}]})
    wjson(os.path.join(BP, "spawn_rules", "radiak_slime.json"), {"format_version": "1.8.0", "minecraft:spawn_rules": {
        "description": {"identifier": ident, "population_control": "monster"},
        "conditions": [{"minecraft:spawns_on_surface": {}, "minecraft:spawns_underground": {},
                        "minecraft:brightness_filter": {"min": 0, "max": 15, "adjust_for_weather": False},
                        "minecraft:difficulty_filter": {"min": "easy", "max": "hard"}, "minecraft:weight": {"default": 15},
                        "minecraft:herd": {"min_size": 1, "max_size": 2},
                        "minecraft:biome_filter": {"test": "has_biome_tag", "value": "overworld"}}]}})
    with open(os.path.join(src, "slime.client_entity.json"), encoding="utf-8") as f:
        rp = json.load(f)
    d = rp["minecraft:client_entity"]["description"]
    d["identifier"] = ident
    d["textures"] = {"default": "textures/entity/radiousti_radiak_slime"}
    d["spawn_egg"] = {"base_color": "#2f8f1f", "overlay_color": "#d6ff7a"}
    wjson(os.path.join(RP, "entity", "radiak_slime.entity.json"), rp)
    im = np.array(Image.open(os.path.join(src, "slime.png")).convert("RGBA")).astype(int)
    lum = im[:, :, :3].mean(axis=2)
    im[:, :, 0] = np.clip(lum * 0.45, 0, 255)
    im[:, :, 1] = np.clip(lum * 1.15 + 40, 0, 255)
    im[:, :, 2] = np.clip(lum * 0.25, 0, 255)
    Image.fromarray(im.astype("uint8"), "RGBA").save(os.path.join(RP, "textures", "entity", "radiousti_radiak_slime.png"))
    for code, name in (("en", "Radiak's Reactor Slime"), ("cs", "Radiakův reaktorový sliz")):
        lang[code][f"entity.{ident}.name"] = name
        lang[code][f"item.spawn_egg.entity.{ident}.name"] = ("Spawn " if code == "en" else "Vyvolat: ") + name


def emit_falling_nuke(lang):
    """Entity used for bombs falling from the sky (gravity via minecraft:physics, scripts detonate on impact)."""
    import numpy as np
    from PIL import Image
    ident = f"{NS}:falling_nuke"
    wjson(os.path.join(BP, "entities", "falling_nuke.json"), {"format_version": "1.21.0", "minecraft:entity": {
        "description": {"identifier": ident, "is_spawnable": False, "is_summonable": True},
        "components": {
            "minecraft:collision_box": {"width": 0.9, "height": 1.8},
            "minecraft:physics": {},
            "minecraft:pushable": {"is_pushable": False, "is_pushable_by_piston": False},
            "minecraft:damage_sensor": {"triggers": [{"cause": "all", "deals_damage": "no"}]},
            "minecraft:health": {"value": 100, "max": 100},
            "minecraft:fire_immune": {},
            "minecraft:knockback_resistance": {"value": 1.0},
            "minecraft:type_family": {"family": ["inanimate", "radiousti_nuke"]}}}})
    bones = [{"name": "bomb", "pivot": [0, 0, 0], "cubes": [
        {"origin": [-2, 2, -2], "size": [4, 2, 4], "uv": [0, 0]},       # nose
        {"origin": [-3, 4, -3], "size": [6, 18, 6], "uv": [0, 6]},      # body
        {"origin": [-2, 22, -2], "size": [4, 4, 4], "uv": [24, 0]},     # tail
        {"origin": [-5, 22, -0.5], "size": [10, 6, 1], "uv": [24, 8]},  # fins
        {"origin": [-0.5, 22, -5], "size": [1, 6, 10], "uv": [24, 15]}]}]
    os.makedirs(os.path.join(RP, "models", "entity"), exist_ok=True)
    wjson(os.path.join(RP, "models", "entity", "falling_nuke.geo.json"), {"format_version": "1.12.0", "minecraft:geometry": [
        {"description": {"identifier": "geometry.radiousti.falling_nuke", "texture_width": 64, "texture_height": 64,
                         "visible_bounds_width": 3, "visible_bounds_height": 4, "visible_bounds_offset": [0, 1.5, 0]}, "bones": bones}]})
    im = np.zeros((64, 64, 4), dtype=np.uint8)
    im[:, :] = (94, 111, 85, 255)
    rng = np.random.default_rng(84)
    im[:, :, :3] = np.clip(im[:, :, :3].astype(int) + rng.integers(-10, 10, (64, 64, 1)), 0, 255)
    for y in range(12, 16):
        for x in range(0, 24):
            im[y, x] = (224, 168, 0, 255) if (x // 3) % 2 == 0 else (29, 29, 29, 255)
    im[0:6, 0:16] = (60, 66, 70, 255)
    Image.fromarray(im, "RGBA").save(os.path.join(RP, "textures", "entity", "radiousti_falling_nuke.png"))
    wjson(os.path.join(RP, "entity", "falling_nuke.entity.json"), {"format_version": "1.10.0", "minecraft:client_entity": {"description": {
        "identifier": ident, "materials": {"default": "entity_alphatest"},
        "textures": {"default": "textures/entity/radiousti_falling_nuke"},
        "geometry": {"default": "geometry.radiousti.falling_nuke"}, "render_controllers": ["controller.render.default"]}}})
    for code, name in (("en", "Falling Atomic Bomb"), ("cs", "Padající atomová bomba")):
        lang[code][f"entity.{ident}.name"] = name


TRADES = [  # (wants, quantity) -> (gives, quantity): bunker parts and supplies for anything found in the ruins
    (("minecraft:rotten_flesh", 16), (f"{NS}:bunker_concrete", 4)), ((f"{NS}:infected_flesh", 6), (f"{NS}:bunker_concrete", 6)),
    (("minecraft:bone", 10), (f"{NS}:bunker_window", 2)), (("minecraft:iron_ingot", 6), (f"{NS}:bunker_reinforced", 4)),
    (("minecraft:copper_ingot", 10), (f"{NS}:bunker_door", 1)), ((f"{NS}:raw_uranium", 4), (f"{NS}:bunker_reinforced", 6)),
    ((f"{NS}:lab_waste", 4), (f"{NS}:gas_mask", 1)), (("minecraft:string", 12), (f"{NS}:hazmat_suit", 1)),
    (("minecraft:gunpowder", 6), (f"{NS}:hazmat_pants", 1)), (("minecraft:leather", 6), (f"{NS}:hazmat_boots", 1)),
    (("minecraft:coal", 12), (f"{NS}:canned_food", 3)), (("minecraft:paper", 12), (f"{NS}:mre_ration", 1)),
    ((f"{NS}:document_bundle", 1), (f"{NS}:anti_radiation_pills", 6)), ((f"{NS}:blood_bottle", 3), (f"{NS}:zed_serum", 1)),
    (("minecraft:gold_ingot", 4), (f"{NS}:security_tablet", 1)), (("minecraft:redstone", 16), (f"{NS}:security_camera", 2)),
    (("minecraft:emerald", 2), (f"{NS}:window_barricade", 8)), (("minecraft:spider_eye", 4), (f"{NS}:purified_water", 4)),
]


def emit_trader(lang):
    """Survivor trader: wandering trader base, never despawns, sells bunker parts and supplies."""
    import numpy as np
    from PIL import Image
    src = os.path.join(HERE, "vanilla_entities")
    ident = f"{NS}:survivor_trader"
    with open(os.path.join(src, "wandering_trader.behavior.json"), encoding="utf-8") as f:
        bp = json.load(f)
    e = bp["minecraft:entity"]
    e["description"]["identifier"] = ident
    e["description"]["is_spawnable"] = True
    e["description"]["is_summonable"] = True
    e["description"].pop("runtime_identifier", None)
    for k in ("minecraft:despawn", "minecraft:timer", "minecraft:spawn_entity", "minecraft:behavior.drink_potion", "minecraft:behavior.drink_milk"):
        e["components"].pop(k, None)
    e["component_groups"].pop("despawning", None)
    for ev in e.get("events", {}).values():
        for part in [ev] + ev.get("sequence", []) + ev.get("randomize", []):
            for key in ("add", "remove"):
                if key in part:
                    part[key]["component_groups"] = [g for g in part[key].get("component_groups", []) if g in e["component_groups"]]
    e["components"]["minecraft:economy_trade_table"] = {"display_name": f"entity.{ident}.name", "new_screen": True,
                                                       "table": "trading/economy_trades/radiousti_survivor_trades.json"}
    e["components"]["minecraft:type_family"] = {"family": ["wandering_trader", "radiousti_survivor", "mob"]}
    e["components"]["minecraft:health"] = {"value": 30, "max": 30}
    wjson(os.path.join(BP, "entities", "survivor_trader.json"), bp)
    groups = []
    for i in range(0, len(TRADES), 6):
        groups.append({"num_to_select": 4, "trades": [
            {"wants": [{"item": w[0], "quantity": w[1]}], "gives": [{"item": g[0], "quantity": g[1]}], "trader_exp": 1, "max_uses": 8, "reward_exp": True}
            for w, g in TRADES[i:i + 6]]})
    wjson(os.path.join(BP, "trading", "economy_trades", "radiousti_survivor_trades.json"), {"tiers": [{"total_exp_required": 0, "groups": groups}]})
    wjson(os.path.join(BP, "spawn_rules", "survivor_trader.json"), {"format_version": "1.8.0", "minecraft:spawn_rules": {
        "description": {"identifier": ident, "population_control": "animal"},
        "conditions": [{"minecraft:spawns_on_surface": {}, "minecraft:brightness_filter": {"min": 0, "max": 15, "adjust_for_weather": False},
                        "minecraft:weight": {"default": 2}, "minecraft:herd": {"min_size": 1, "max_size": 1},
                        "minecraft:biome_filter": {"test": "has_biome_tag", "value": "overworld"}}]}})
    with open(os.path.join(src, "wandering_trader.client_entity.json"), encoding="utf-8") as f:
        rp = json.load(f)
    d = rp["minecraft:client_entity"]["description"]
    d["identifier"] = ident
    d["textures"] = {"default": "textures/entity/radiousti_survivor_trader"}
    d["spawn_egg"] = {"base_color": "#c9aa2a", "overlay_color": "#3c4246"}
    wjson(os.path.join(RP, "entity", "survivor_trader.entity.json"), rp)
    im = np.array(Image.open(os.path.join(src, "wandering_trader.png")).convert("RGBA")).astype(int)
    blue = (im[:, :, 2] > im[:, :, 0] + 10) & (im[:, :, 3] > 0)     # robe -> worn hazmat yellow
    lum = im[:, :, :3].mean(axis=2)
    im[blue, 0] = np.clip(lum[blue] * 1.25 + 40, 0, 255)
    im[blue, 1] = np.clip(lum[blue] * 1.05 + 30, 0, 255)
    im[blue, 2] = np.clip(lum[blue] * 0.3, 0, 255)
    Image.fromarray(im.astype("uint8"), "RGBA").save(os.path.join(RP, "textures", "entity", "radiousti_survivor_trader.png"))
    for code, name in (("en", "RadioÚstí Survivor Trader"), ("cs", "Přeživší obchodník z RadioÚstí")):
        lang[code][f"entity.{ident}.name"] = name
        lang[code][f"item.spawn_egg.entity.{ident}.name"] = ("Spawn " if code == "en" else "Vyvolat: ") + name


LOOT = {
    "radiousti_house": [("minecraft:bread", 1, 3, 4), (f"{NS}:canned_food", 1, 2, 5), ("minecraft:iron_nugget", 2, 8, 6), ("minecraft:paper", 2, 6, 5),
                        (f"{NS}:document_evacuation", 1, 1, 3), (f"{NS}:anti_radiation_pills", 1, 2, 3), ("minecraft:string", 1, 4, 4),
                        ("minecraft:coal", 2, 6, 4), (f"{NS}:purified_water", 1, 2, 3), (f"{NS}:historical_photo", 1, 1, 2)],
    "radiousti_city": [(f"{NS}:canned_food", 1, 4, 6), (f"{NS}:mre_ration", 1, 1, 3), ("minecraft:iron_ingot", 1, 4, 5), ("minecraft:copper_ingot", 2, 6, 5),
                       ("minecraft:redstone", 2, 8, 4), (f"{NS}:gas_mask", 1, 1, 2), (f"{NS}:empty_canister", 1, 2, 4), (f"{NS}:canister_industrial_oil", 1, 1, 3),
                       (f"{NS}:document_printout", 1, 1, 3), ("minecraft:gunpowder", 1, 4, 3), (f"{NS}:window_barricade", 2, 6, 3), ("minecraft:emerald", 1, 3, 2)],
    "radiousti_lab": [(f"{NS}:empty_flask", 1, 3, 5), (f"{NS}:reagent_flask_green", 1, 2, 4), (f"{NS}:reagent_flask_blue", 1, 2, 4), (f"{NS}:blood_sample", 1, 3, 4),
                      (f"{NS}:zed_serum", 1, 1, 2), (f"{NS}:anti_radiation_pills", 1, 3, 4), (f"{NS}:document_lab_report", 1, 1, 4),
                      (f"{NS}:document_research_record", 1, 1, 3), (f"{NS}:raw_uranium", 1, 3, 3), (f"{NS}:hazmat_suit", 1, 1, 1), (f"{NS}:biogenic_serum", 1, 1, 2)],
    "radiousti_village": [(f"{NS}:canned_food", 2, 5, 6), (f"{NS}:decontaminated_bread", 2, 6, 5), (f"{NS}:purified_water", 1, 3, 5),
                          (f"{NS}:window_barricade", 2, 8, 4), (f"{NS}:bunker_concrete", 2, 8, 3), ("minecraft:emerald", 1, 4, 3),
                          (f"{NS}:anti_radiation_pills", 1, 2, 3), (f"{NS}:hand_siren", 1, 1, 1)],
    "radiousti_fortress": [("minecraft:gold_ingot", 1, 4, 4), ("minecraft:iron_sword", 1, 1, 2), ("minecraft:shield", 1, 1, 2), (f"{NS}:document_bundle", 1, 1, 3),
                           ("minecraft:emerald", 1, 4, 3), (f"{NS}:soul_essence", 1, 2, 3), ("minecraft:arrow", 4, 12, 4), (f"{NS}:liverocrystal_shard", 1, 3, 2)],
}


def emit_world_structures():
    """Structures generated in the overworld (structure_template_feature + feature rules) and their loot tables."""
    for name, items in LOOT.items():
        wjson(os.path.join(BP, "loot_tables", "chests", f"{name}.json"), {"pools": [{"rolls": {"min": 3, "max": 7}, "entries": [
            {"type": "item", "name": i, "weight": w, "functions": [{"function": "set_count", "count": {"min": a, "max": b}}]} for i, a, b, w in items]}]})
    sdir = os.path.join(BP, "structures", "radiousti")
    os.makedirs(sdir, exist_ok=True)
    for name, (fn, size, denom, adj) in STR.WORLD_STRUCTURES.items():
        STR.build(os.path.join(sdir, f"{name}.mcstructure"), fn, size, void="minecraft:structure_void")
        wjson(os.path.join(BP, "features", f"{name}_feature.json"), {"format_version": "1.13.0", "minecraft:structure_template_feature": {
            "description": {"identifier": f"{NS}:{name}_feature"}, "structure_name": f"{NS}:{name}", "adjustment_radius": adj,
            "facing_direction": "random", "constraints": {"grounded": {}, "unburied": {}, "block_intersection": {"block_allowlist": [
                "minecraft:air", "minecraft:short_grass", "minecraft:tall_grass", "minecraft:fern", "minecraft:snow_layer", "minecraft:dandelion", "minecraft:poppy"]}}}})
        wjson(os.path.join(BP, "feature_rules", f"{name}_rule.json"), {"format_version": "1.13.0", "minecraft:feature_rules": {
            "description": {"identifier": f"{NS}:{name}_rule", "places_feature": f"{NS}:{name}_feature"},
            "conditions": {"placement_pass": "surface_pass", "minecraft:biome_filter": [
                {"test": "has_biome_tag", "operator": "==", "value": "overworld"},
                {"test": "has_biome_tag", "operator": "!=", "value": "ocean"}, {"test": "has_biome_tag", "operator": "!=", "value": "river"}]},
            "distribution": {"iterations": 1, "scatter_chance": {"numerator": 1, "denominator": denom},
                             "x": {"distribution": "uniform", "extent": [0, 15]}, "y": "q.heightmap(v.worldx, v.worldz)",
                             "z": {"distribution": "uniform", "extent": [0, 15]}}}})
        print(f"  world structure {name}: {size}")


def emit_attachables():
    for iid, kind, layer, geom, script in (
            ("gas_mask", "mask", "gas_mask_layer", "geometry.humanoid.armor.helmet", "variable.helmet_layer_visible = 0.0;"),
            ("hazmat_suit", "suit", "hazmat_layer", "geometry.humanoid.armor.chestplate", "variable.chest_layer_visible = 0.0;"),
            ("hazmat_pants", "pants", "hazmat_layer2", "geometry.humanoid.armor.leggings", "variable.leg_layer_visible = 0.0;"),
            ("hazmat_boots", "boots", "hazmat_layer3", "geometry.humanoid.armor.boots", "variable.boot_layer_visible = 0.0;")):
        os.makedirs(os.path.join(RP, "textures", "models", "armor"), exist_ok=True)
        T.armor_layer(layer, kind).save(os.path.join(RP, "textures", "models", "armor", f"radiousti_{layer}.png"))
        wjson(os.path.join(RP, "attachables", f"{iid}.json"), {
            "format_version": "1.10.0",
            "minecraft:attachable": {"description": {
                "identifier": f"{NS}:{iid}",
                "materials": {"default": "armor", "enchanted": "armor_enchanted"},
                "textures": {"default": f"textures/models/armor/radiousti_{layer}", "enchanted": "textures/misc/enchanted_item_glint"},
                "geometry": {"default": geom},
                "scripts": {"parent_setup": script},
                "render_controllers": ["controller.render.armor"]}}})


def pack_icon(path, size=256):
    """Zeds World: RadioÚstí logo (64 px pixel art, upscaled): green sky, mushroom cloud over a cooling tower,
    radiation trefoil and the ZW / RADIOÚSTÍ lettering."""
    import math
    from PIL import Image, ImageDraw
    W = 64
    im = Image.new("RGBA", (W, W))
    d = ImageDraw.Draw(im)
    for y in range(W):  # green post-apocalyptic sky -> red horizon
        t = y / W
        d.line([(0, y), (W, y)], fill=(int(60 + 120 * t), int(95 + 20 * (1 - t)), int(50 * (1 - t)), 255))
    d.rectangle([0, 46, W, W], fill=(24, 26, 22, 255))                     # ground
    # mushroom cloud
    d.rectangle([28, 16, 36, 40], fill=(150, 112, 78, 255))
    d.ellipse([16, 4, 48, 22], fill=(210, 130, 70, 255))
    d.ellipse([20, 2, 44, 14], fill=(240, 180, 100, 255))
    d.ellipse([22, 14, 42, 24], fill=(180, 100, 60, 255))
    # cooling tower (hyperbolic silhouette) and second tower
    for y in range(28, 47):
        w = 7 + int(abs(y - 38) * 0.45)
        d.line([(46 - w, y), (46 + w, y)], fill=(160, 156, 148, 255))
    for y in range(34, 47):
        w = 4 + int(abs(y - 41) * 0.4)
        d.line([(10 - w, y), (10 + w, y)], fill=(130, 126, 120, 255))
    # radiation trefoil
    cx, cy, r = 16, 26, 9
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(224, 168, 0, 255), outline=(20, 20, 20, 255))
    for k in range(3):
        a0 = -90 + k * 120 - 30
        d.pieslice([cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], a0, a0 + 60, fill=(20, 20, 20, 255))
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(224, 168, 0, 255))
    d.ellipse([cx - 1.6, cy - 1.6, cx + 1.6, cy + 1.6], fill=(20, 20, 20, 255))
    t = T.Tex("logo_text", size=64, base="#000000", alpha=0)
    t.a = __import__("numpy").array(im).astype(int)
    t.text("ZW", 3, 49, "#7dff3a", 2)
    t.text("RADIOÚSTÍ", 22, 53, "#e6e1d0", 1)
    import numpy as np
    out = Image.fromarray(np.clip(t.a, 0, 255).astype("uint8"), "RGBA").resize((size, size), Image.NEAREST)
    out.save(path)


def _old_pack_icon(path, size=256):
    t = T.Tex("pack_icon", size=32, base="#1f2a22")
    t.rect(0, 0, 32, 32, "#2a2e2a")
    for y in range(32):
        t.rect(0, y, 32, 1, "#%02x%02x%02x" % (30 + y, 36 + y, 30 + y // 2))
    t.rect(0, 26, 32, 6, "#e0a800")
    for x in range(-6, 32, 6):
        t.rect(x + 3, 26, 3, 6, "#1d1d1d")
    # radiation trefoil
    t.rect(14, 10, 4, 4, "#e0a800")
    t.rect(13, 2, 6, 6, "#e0a800"); t.rect(5, 14, 6, 6, "#e0a800"); t.rect(21, 14, 6, 6, "#e0a800")
    t.text("RU", 2, 20, "#e6e1d0")
    import numpy as np
    from PIL import Image
    a = np.clip(t.a, 0, 255).astype("uint8")
    Image.fromarray(a, "RGBA").resize((size, size), Image.NEAREST).save(path)


def write_lang(lang):
    header = {"en": "## RadioÚstí — English (generated by tools/build.py)\n",
              "cs": "## RadioÚstí — čeština (generováno nástrojem tools/build.py)\n"}
    extra = {
        "en": {"pack.name": "Zeds World: RadioÚstí", "pack.description": "Zeds World: RadioÚstí 2.0 – post-apocalyptic survival add-on by Jackhack2021"},
        "cs": {"pack.name": "Zeds World: RadioÚstí", "pack.description": "Zeds World: RadioÚstí 2.0 – postapokalyptický survival add-on od Jackhack2021"},
    }
    for code, fname in (("en", "en_US.lang"), ("cs", "cs_CZ.lang")):
        lines = [header[code]]
        for k, v in sorted({**extra[code], **lang[code]}.items()):
            lines.append(f"{k}={v}\n")
        with open(os.path.join(RP, "texts", fname), "w", encoding="utf-8") as f:
            f.writelines(lines)


KIND_CS = {"pipe": "potrubí", "valve": "ventil", "cable": "kabel", "machine": "stroj", "reactor_shell": "plášť reaktoru",
           "reactor_port": "port reaktoru", "door": "dveře", "light": "světlo", "alarm": "alarm", "indicator": "indikátor",
           "radioactive": "radioaktivní", "decor": "dekorace", "furniture": "nábytek", "document": "dokument", "clock": "hodiny",
           "jar": "nádoba", "organic": "organické", "soul": "duše", "control": "ovládání", "craft_table": "pracovní stůl",
           "station": "stanice", "glassware": "laboratorní sklo", "toxic": "toxický materiál", "liquid": "tekutina",
           "corpse": "mrtvola / socha", "nuke": "výbušnina", "bunker": "bunkr", "barricade": "barikáda", "camera": "kamera"}
CAT_CS = {"construction": "Stavba", "equipment": "Vybavení", "items": "Předměty", "nature": "Příroda",
          "none": "Pokládané laboratorní sklo a multibloky (pokládají se předmětem)"}
TABLE_CS = {"crafting_table": "Pracovní stůl", "radiousti_industrial": "Průmyslový ponk", "radiousti_lab": "Laboratorní stůl"}


def write_docs():
    names = {f"{NS}:{b['id']}": b["cs"] for b in CT.BLOCKS}
    names.update({f"{NS}:{i['id']}": i["cs"] for i in CT.ITEMS})
    d = os.path.join(ROOT, "docs")
    os.makedirs(d, exist_ok=True)
    L = ["# Katalog RadioÚstí\n", "_Generováno nástrojem `tools/build.py` – odpovídá obsahu balíčku._\n"]
    for cat in ("construction", "equipment", "items", "nature", "none"):
        rows = [b for b in CT.BLOCKS if (b["cat"] if not b.get("placer_icon") else "none") == cat]
        L.append(f"\n## Bloky – {CAT_CS[cat]} ({len(rows)})\n\n| Název | English | ID | Typ |\n|---|---|---|---|")
        for b in rows:
            L.append(f"| {b['cs']} | {b['en']} | `{NS}:{b['id']}` | {KIND_CS.get(b['kind'], b['kind'])} |")
    L.append(f"\n## Předměty ({len(CT.ITEMS)})\n\n| Název | English | ID | Popis |\n|---|---|---|---|")
    for i in CT.ITEMS:
        L.append(f"| {i['cs']} | {i['en']} | `{NS}:{i['id']}` | {i.get('desc_cs', '')} |")
    with open(os.path.join(d, "CATALOG.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")

    def nm(x):
        if isinstance(x, str) and x.startswith("#"):
            return f"libovolné {x.split(':')[1]}"
        if ":" not in x:
            x = f"{NS}:{x}"
        return names.get(x, x.replace("minecraft:", ""))
    R2 = ["# Recepty RadioÚstí\n", "_Generováno nástrojem `tools/build.py` z `tools/recipes.py`._\n",
          "\nLaboratorní stanice (zpracování vzorků, palivové tyče…) jsou popsané v README v kapitole Laboratoř.\n"]
    for table in ("crafting_table", "radiousti_industrial", "radiousti_lab", None):
        rows = [r for r in R.RECIPES if r[5] == table]
        R2.append(f"\n## {TABLE_CS.get(table, 'Pec')} ({len(rows)})\n")
        for kind, out, a, b, n, _ in rows:
            if kind == "shaped":
                key = ", ".join(f"`{k}` = {nm(v)}" for k, v in b.items())
                R2.append(f"- **{nm(out)}** ×{n}: vzor `{' / '.join(a)}` – {key}")
            elif kind == "shapeless":
                cnt = {}
                for x in a:
                    cnt[x] = cnt.get(x, 0) + 1
                R2.append(f"- **{nm(out)}** ×{n}: " + " + ".join(f"{c}× {nm(x)}" for x, c in cnt.items()))
            else:
                R2.append(f"- **{nm(out)}**: vypálit {nm(a)}")
    with open(os.path.join(d, "RECIPES.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(R2) + "\n")


def main():
    for d in (os.path.join(BP, "blocks"), os.path.join(BP, "items"), os.path.join(BP, "recipes"), os.path.join(BP, "loot_tables"),
              os.path.join(BP, "features"), os.path.join(BP, "feature_rules"),
              os.path.join(RP, "models", "blocks"), os.path.join(RP, "textures", "blocks"), os.path.join(RP, "textures", "items"),
              os.path.join(RP, "textures", "models"), os.path.join(RP, "attachables"), os.path.join(RP, "sounds", "radiousti"),
              os.path.join(BP, "spawn_rules"), os.path.join(RP, "entity"), os.path.join(RP, "textures", "entity"), os.path.join(BP, "trading")):
        clean(d)

    lang = {"en": {}, "cs": {}}
    registry = {"blocks": {}, "items": {}}
    geo_files = {}
    blocks_json = {"format_version": [1, 1, 0]}
    for b in CT.BLOCKS:
        emit_block(b, geo_files, blocks_json, lang, registry)
    for it in CT.ITEMS:
        emit_item(it, lang, registry)

    for bid, entries in geo_files.items():
        path = os.path.join(RP, "models", "blocks", f"{bid}.geo.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"format_version": "1.21.0", "minecraft:geometry": entries}, f, separators=(",", ":"))
    wjson(os.path.join(RP, "blocks.json"), blocks_json)

    # textures
    terrain = {}
    for name, fn in CT.TEX.items():
        fn(name).save(os.path.join(RP, "textures", "blocks", f"{name}.png"))
        terrain[name] = {"textures": f"textures/blocks/{name}"}
    items = {}
    for name, fn in CT.ITEM_TEX.items():
        fn(name).save(os.path.join(RP, "textures", "items", f"{name}.png"))
        items[name] = {"textures": f"textures/items/{name}"}
    wjson(os.path.join(RP, "textures", "terrain_texture.json"),
          {"resource_pack_name": "radiousti", "texture_name": "atlas.terrain", "padding": 8, "num_mip_levels": 4, "texture_data": terrain})
    wjson(os.path.join(RP, "textures", "item_texture.json"),
          {"resource_pack_name": "radiousti", "texture_name": "atlas.items", "texture_data": items})

    emit_loot()
    emit_worldgen()
    emit_lc_worldgen()
    emit_environment()
    emit_attachables()
    R.emit(os.path.join(BP, "recipes"), wjson, NS)
    SND.emit(os.path.join(RP, "sounds"), wjson)
    pack_icon(os.path.join(BP, "pack_icon.png"))
    pack_icon(os.path.join(RP, "pack_icon.png"))
    emit_zed(lang)
    emit_zed(lang, ident=f"{NS}:radiak_zombie", variant="radiak", health=34, damage=6, weight=25,
             names=(("en", "Radiak's Zombie"), ("cs", "Radiakova zombie")), egg=("#1f4f1f", "#7dff3a"),
             loot={"pools": [
                 {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:raw_uranium", "weight": 1,
                                           "functions": [{"function": "set_count", "count": {"min": 1, "max": 3}}]}]},
                 {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:uranium_ingot", "weight": 1}, {"type": "empty", "weight": 4}]},
                 {"rolls": 1, "entries": [{"type": "item", "name": f"{NS}:infected_flesh", "weight": 1}]}]})
    emit_slime(lang)
    emit_falling_nuke(lang)
    emit_trader(lang)
    emit_particles()
    for f in os.listdir(os.path.join(BP, "structures")):
        if f.endswith(".mcstructure"):
            os.remove(os.path.join(BP, "structures", f))
    pal, nblocks = STR.build(os.path.join(BP, "structures", "reaktor.mcstructure"), STR.build_layout, (15, 6, 12))
    print(f"structure reaktor: {nblocks} blocks, {pal} palette entries")
    pal, nblocks = STR.build(os.path.join(BP, "structures", "muzeum.mcstructure"), STR.museum_layout, STR.MSIZE)
    print(f"structure muzeum: {nblocks} blocks, {pal} palette entries")
    emit_world_structures()
    STR.CHEST = STR.BUNKER_CHEST
    pal, nblocks = STR.build(os.path.join(BP, "structures", "bunkr.mcstructure"), STR.bunker_layout, STR.BSIZE)
    STR.CHEST = None
    print(f"structure bunkr: {nblocks} blocks, {pal} palette entries")
    write_lang(lang)
    write_docs()

    os.makedirs(os.path.join(BP, "scripts", "data"), exist_ok=True)
    with open(os.path.join(BP, "scripts", "data", "registry.js"), "w", encoding="utf-8") as f:
        f.write("// Generated by tools/build.py from tools/content.py - do not edit by hand.\n")
        f.write("export const REGISTRY = ")
        json.dump(registry, f, ensure_ascii=False, indent=1)
        f.write(";\n")
        f.write("export const SOUNDS = ")
        json.dump(sorted(SND.SOUNDS.keys()), f)
        f.write(";\n")

    # remove starter README placeholders from folders that now contain generated content
    for root in (BP, RP):
        for dp, dn, fn in os.walk(root):
            if "README.txt" in fn and len(fn) > 1:
                os.remove(os.path.join(dp, "README.txt"))
    print(f"blocks={len(CT.BLOCKS)} items={len(CT.ITEMS)} block_textures={len(CT.TEX)} item_textures={len(CT.ITEM_TEX)} "
          f"geometry_files={len(geo_files)} recipes={R.COUNT[0]} sounds={len(SND.SOUNDS)}")


if __name__ == "__main__":
    main()
