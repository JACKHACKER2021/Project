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
        "console": G.console, "ore": G.ore_crystals, "bottle": G.bottle, "jar_small": lambda fill=True: G.jar(8, 6),
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
        vis = {}
        for s in ("n", "s", "e", "w", "u", "d"):
            vis[s] = f"q.block_state('{NS}:{s}')"
            if any(bb["name"] == f"fl_{s}" for bb in bones):
                vis[f"fl_{s}"] = f"q.block_state('{NS}:{s}')"
        if any(bb["name"] == "joint" for bb in bones):
            vis["joint"] = f"q.block_state('{NS}:joint')"
        if model[0] == "valve":
            vis["wheel_open"] = f"q.block_state('{NS}:open')"
            vis["wheel_closed"] = f"!q.block_state('{NS}:open')"
            vis["lamp_open"] = f"q.block_state('{NS}:open')"
            vis["lamp_closed"] = f"!q.block_state('{NS}:open')"
        if any(bb["name"] == "bracket" for bb in bones):
            vis["bracket"] = f"!q.block_state('{NS}:d')"
        geo_files[b["id"]] = [G.geometry_entry(gbase, bones)]
        comps["minecraft:geometry"] = {"identifier": gbase, "bone_visibility": vis}
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
                    pb = G.rot_model(G.door_model(op, up), d)
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


def emit_attachables():
    for iid, kind, layer, geom, script in (
            ("gas_mask", "mask", "gas_mask_layer", "geometry.humanoid.armor.helmet", "variable.helmet_layer_visible = 0.0;"),
            ("hazmat_suit", "suit", "hazmat_layer", "geometry.humanoid.armor.chestplate", "variable.chest_layer_visible = 0.0;")):
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
        "en": {"pack.name": "RadioÚstí", "pack.description": "RadioÚstí | Zeds World add-on by Jackhack2021"},
        "cs": {"pack.name": "RadioÚstí", "pack.description": "RadioÚstí | Zeds World add-on od Jackhack2021"},
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
           "station": "stanice", "glassware": "laboratorní sklo", "toxic": "toxický materiál", "liquid": "tekutina"}
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
              os.path.join(RP, "textures", "models"), os.path.join(RP, "attachables"), os.path.join(RP, "sounds", "radiousti")):
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
