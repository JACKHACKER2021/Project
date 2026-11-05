"""Build BP/structures/reaktor.mcstructure: a complete, working RadioÚstí reactor plant.

Load in game with:  /structure load reaktor ~ ~ ~
Layout matches README "Stavba a provoz reaktoru" exactly (3x3x3 shell, coolant loop with pump and
water, nuclear generator, PC on a data cable, waste container, emergency button, chest with fuel).
"""
import os
import struct

import content as CT
from geo import rot_vec

NS = CT.NS
BLOCK_VERSION = (1 << 24) | (21 << 16) | (90 << 8)  # 1.21.90

# ---------------------------------------------------------------- minimal little-endian NBT writer
TAG_END, TAG_BYTE, TAG_SHORT, TAG_INT, TAG_STRING, TAG_LIST, TAG_COMPOUND = 0, 1, 2, 3, 8, 9, 10


class Byte(int):
    pass


class Short(int):
    pass


def _tag_of(v):
    if isinstance(v, Byte) or isinstance(v, bool):
        return TAG_BYTE
    if isinstance(v, Short):
        return TAG_SHORT
    if isinstance(v, int):
        return TAG_INT
    if isinstance(v, str):
        return TAG_STRING
    if isinstance(v, list):
        return TAG_LIST
    if isinstance(v, dict):
        return TAG_COMPOUND
    raise TypeError(type(v))


def _str(s):
    b = s.encode("utf-8")
    return struct.pack("<H", len(b)) + b


def _payload(v):
    t = _tag_of(v)
    if t == TAG_BYTE:
        return struct.pack("<b", int(v))
    if t == TAG_SHORT:
        return struct.pack("<h", int(v))
    if t == TAG_INT:
        return struct.pack("<i", int(v))
    if t == TAG_STRING:
        return _str(v)
    if t == TAG_LIST:
        et = _tag_of(v[0]) if v else TAG_INT
        return struct.pack("<bi", et, len(v)) + b"".join(_payload(x) for x in v)
    out = b""
    for k, x in v.items():
        out += struct.pack("<b", _tag_of(x)) + _str(k) + _payload(x)
    return out + struct.pack("<b", TAG_END)


def nbt_root(d):
    return struct.pack("<b", TAG_COMPOUND) + _str("") + _payload(d)


# ---------------------------------------------------------------- layout
SX, SY, SZ = 15, 6, 12


def build_layout():
    B = {}  # (x,y,z) -> (name, states)

    def put(x, y, z, name, **states):
        B[(x, y, z)] = (name if ":" in name else f"{NS}:{name}", states)

    # floor + warning ring
    for x in range(SX):
        for z in range(SZ):
            put(x, 0, z, "cement_block")
    for x in range(5, 10):
        for z in range(3, 10):
            put(x, 0, z, "npp_floor_warning")
    # reactor shell 3x3x3 around the core (7,2,6)
    cx, cy, cz = 7, 2, 6
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                put(cx + dx, cy + dy, cz + dz, "reactor_casing")
    put(cx, cy, cz, "reactor_core", **{f"{NS}:active": False})
    put(cx, cy, cz - 1, "reactor_control_panel", **{"minecraft:cardinal_direction": "north"})
    put(cx, cy, cz + 1, "reactor_glass")
    put(cx - 1, cy, cz, "reactor_port_coolant")
    put(cx + 1, cy, cz, "reactor_port_power")
    put(cx - 1, cy - 1, cz - 1, "reactor_port_waste")
    # coolant loop: port (6,2,6) -> pipe -> valve -> pipe -> pipe ; cooling unit under (3,2,6), pump under (2,2,6), water at (1,1,6)
    put(5, 2, 6, "water_pipe")
    put(4, 2, 6, "water_valve", **{f"{NS}:open": True})
    put(3, 2, 6, "water_pipe")
    put(2, 2, 6, "water_pipe")
    put(3, 1, 6, "reactor_cooling_unit", **{"minecraft:cardinal_direction": "north"})
    put(2, 1, 6, "water_pump", **{"minecraft:cardinal_direction": "north"})
    put(1, 1, 6, "minecraft:water", liquid_depth=0)
    for x, z in ((0, 6), (1, 5), (1, 7), (0, 5), (0, 7)):
        put(x, 1, z, "minecraft:stone_bricks")
    # power: port (8,2,6) -> HV cable -> nuclear generator (2x2x2, origin (11,1,5), facing north)
    put(9, 2, 6, "high_voltage_cable")
    put(10, 2, 6, "high_voltage_cable")
    gen = f"{NS}:generator_nuclear"
    offs = next(b for b in CT.BLOCKS if b["id"] == "generator_nuclear")["meta"]["multiblock"]
    for i, (ox, oy, oz) in enumerate(offs):
        wx, wz = rot_vec("north", ox, oz)
        put(11 + wx, 1 + oy, 5 + wz, gen, **{f"{NS}:part": i, f"{NS}:active": False, "minecraft:cardinal_direction": "north"})
    # generator -> electrical cable -> Old PC (13,1,2) facing south
    put(13, 1, 5, "electrical_cable")
    put(13, 1, 4, "electrical_cable")
    put(13, 1, 3, "electrical_cable")
    put(13, 1, 2, "old_pc", **{"minecraft:cardinal_direction": "south", f"{NS}:active": False})
    # data: PC -> network cable -> control panel (remote start from ÚstíOS)
    for x in range(12, 6, -1):
        put(x, 1, 2, "network_cable")
    put(7, 1, 3, "network_cable")
    put(7, 2, 3, "network_cable")
    put(7, 2, 4, "network_cable")  # touches the control panel at (7,2,5)
    # waste: port (6,1,5) -> radioactive pipe -> container
    put(6, 1, 4, "radioactive_pipe")
    put(6, 1, 3, "radioactive_pipe")
    put(5, 1, 3, "radioactive_waste_container", **{"minecraft:cardinal_direction": "north"})
    # safety & atmosphere
    put(4, 1, 1, "emergency_shutdown_button")
    put(10, 1, 9, "radiation_indicator", **{"minecraft:cardinal_direction": "north", f"{NS}:level": 0})
    put(1, 1, 1, "warning_beacon", **{f"{NS}:lit": False})
    put(13, 1, 10, "warning_beacon", **{f"{NS}:lit": False})
    put(7, 4, 6, "alarm", **{"minecraft:block_face": "up", f"{NS}:lit": False})
    put(2, 1, 2, "minecraft:chest", **{"minecraft:cardinal_direction": "south"})
    return B


# connection rules (mirror of scripts/systems/connections.js)
INFO = {f"{NS}:{b['id']}": b for b in CT.BLOCKS}


def fam(name):
    b = INFO.get(name)
    return b and b["kind"] in ("pipe", "valve", "cable") and b["meta"].get("family")


def accepts(name, family):
    if name == "minecraft:water":
        return family == "water"
    b = INFO.get(name)
    if not b:
        return False
    m = b["meta"]
    if family == "power":
        if b["kind"] == "reactor_port":
            return m.get("family") == "power"
        return b["kind"] == "machine" and m.get("role") in ("generator", "battery", "computer", "server", "station")
    if family == "data":
        return b["kind"] in ("machine", "reactor_shell", "reactor_port")
    if b["kind"] == "reactor_port":
        return m.get("family") == family
    if b["kind"] == "machine":
        extra = {f"{NS}:generator_standard": ["oil"], f"{NS}:generator_industrial": ["gas", "molten"], f"{NS}:chemical_analysis_table": ["gas"]}
        return m.get("family") == family or family in extra.get(name, [])
    return False


DIRS = {"n": (0, 0, -1), "s": (0, 0, 1), "e": (1, 0, 0), "w": (-1, 0, 0), "u": (0, 1, 0), "d": (0, -1, 0)}
OPP = {"n": "s", "s": "n", "e": "w", "w": "e", "u": "d", "d": "u"}


def resolve_conduits(B):
    for pos, (name, st) in list(B.items()):
        f = fam(name)
        if not f:
            continue
        on = []
        for k, (dx, dy, dz) in DIRS.items():
            nb = B.get((pos[0] + dx, pos[1] + dy, pos[2] + dz))
            c = False
            if nb:
                nf = fam(nb[0])
                c = (nf == f) if nf else accepts(nb[0], f)
            st[f"{NS}:{k}"] = c
            if c:
                on.append(k)
        if INFO[name]["kind"] != "valve":
            straight = len(on) == 2 and OPP[on[0]] == on[1]
            st[f"{NS}:joint"] = len(on) >= 3 or (len(on) == 2 and not straight)


BUNKER_CHEST = [("minecraft:bread", 16), ("minecraft:cooked_beef", 8), ("minecraft:water_bucket", 1), (f"{NS}:anti_radiation_pills", 16),
                (f"{NS}:zed_serum", 2), (f"{NS}:gas_mask", 1), (f"{NS}:hazmat_suit", 1), (f"{NS}:hazmat_pants", 1), (f"{NS}:hazmat_boots", 1),
                (f"{NS}:security_tablet", 1), (f"{NS}:hand_siren", 1)]
CHEST = None


def chest_items():
    if CHEST is not None:
        return [{"Count": Byte(n), "Damage": Short(0), "Name": name, "Slot": Byte(i), "WasPickedUp": Byte(0)} for i, (name, n) in enumerate(CHEST)]
    items = [(f"{NS}:uranium_fuel_rod", 4), (f"{NS}:system_analyzer", 1), (f"{NS}:handbook", 1), (f"{NS}:gas_mask", 1),
             (f"{NS}:hazmat_suit", 1), (f"{NS}:hazmat_pants", 1), (f"{NS}:hazmat_boots", 1), (f"{NS}:anti_radiation_pills", 8),
             (f"{NS}:experiment_registry", 1)]
    return [{"Count": Byte(n), "Damage": Short(0), "Name": name, "Slot": Byte(i), "WasPickedUp": Byte(0)} for i, (name, n) in enumerate(items)]


def build(path, layout=None, size=None):
    global SX, SY, SZ
    if size:
        SX, SY, SZ = size
    B = (layout or build_layout)()
    resolve_conduits(B)
    palette, index = [], {}
    layer0 = []
    pos_data = {}
    for x in range(SX):
        for y in range(SY):
            for z in range(SZ):
                name, st = B.get((x, y, z), ("minecraft:air", {}))
                key = (name, tuple(sorted(st.items())))
                if key not in index:
                    states = {}
                    for k, v in st.items():
                        states[k] = Byte(1 if v else 0) if isinstance(v, bool) else v
                    index[key] = len(palette)
                    palette.append({"name": name, "states": states, "version": BLOCK_VERSION})
                i = len(layer0)
                layer0.append(index[key])
                if name == "minecraft:chest":
                    pos_data[str(i)] = {"block_entity_data": {"id": "Chest", "Items": chest_items(), "Findable": Byte(0),
                                                              "isMovable": Byte(1), "x": x, "y": y, "z": z}}
    root = {
        "format_version": 1,
        "size": [SX, SY, SZ],
        "structure": {
            "block_indices": [layer0, [-1] * len(layer0)],
            "entities": [],
            "palette": {"default": {"block_palette": palette, "block_position_data": pos_data}},
        },
        "structure_world_origin": [0, 0, 0],
    }
    if not palette:
        raise RuntimeError("empty structure")
    # entities list must carry a compound element type even when empty
    data = nbt_root(root).replace(struct.pack("<b", TAG_LIST) + _str("entities") + struct.pack("<bi", TAG_INT, 0),
                                  struct.pack("<b", TAG_LIST) + _str("entities") + struct.pack("<bi", TAG_COMPOUND, 0))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return len(palette), sum(1 for v in layer0 if palette[v]["name"] != "minecraft:air")


# ---------------------------------------------------------------- Muzeum RadioÚstí (/structure load muzeum)
MSIZE = (15, 7, 13)


def museum_layout():
    X, Y, Z = MSIZE
    B = {}

    def put(x, y, z, name, **st):
        B[(x, y, z)] = (name if ":" in name else f"{NS}:{name}", st)

    for x in range(X):
        for z in range(Z):
            put(x, 0, z, "shower_tiles_blue" if (x + z) % 2 else "cement_block")
            put(x, 6, z, "cement_block")
    for y in range(1, 6):
        for x in range(X):
            put(x, y, 0, "house_block")
            put(x, y, Z - 1, "house_block")
        for z in range(Z):
            put(0, y, z, "house_block")
            put(X - 1, y, z, "house_block")
    # entrance (laboratory door) in the north wall, centre
    put(7, 1, 0, "lab_door", **{"minecraft:cardinal_direction": "south", f"{NS}:upper": False, f"{NS}:open": False})
    put(7, 2, 0, "lab_door", **{"minecraft:cardinal_direction": "south", f"{NS}:upper": True, f"{NS}:open": False})
    for x in (3, 11):
        put(x, 3, 0, "old_glass")
    # ceiling lights (lit)
    for x in (3, 7, 11):
        for z in (3, 9):
            put(x, 5, z, "lab_light", **{f"{NS}:lit": True})
    # centrepiece: Radiak in his suit on a raised floor, behind rope barriers
    put(7, 1, 7, "radiak_statue", **{f"{NS}:part": 0, "minecraft:cardinal_direction": "north"})
    put(7, 2, 7, "radiak_statue", **{f"{NS}:part": 1, "minecraft:cardinal_direction": "north"})
    for x in (5, 9):
        put(x, 1, 5, "museum_rope_barrier", **{"minecraft:cardinal_direction": "north"})
    put(7, 1, 5, "museum_rope_barrier", **{"minecraft:cardinal_direction": "north"})
    put(7, 2, 9, "museum_plaque", **{"minecraft:block_face": "north"})
    # corpses (2 blocks long, laid along +z) behind barriers on the east and west sides
    for (x, cid) in ((2, "dead_mayor"), (12, "dead_postman")):
        put(x, 1, 4, cid, **{f"{NS}:part": 0, "minecraft:cardinal_direction": "north"})
        put(x, 1, 5, cid, **{f"{NS}:part": 1, "minecraft:cardinal_direction": "north"})
        put(x + (1 if x < 7 else -1), 1, 4, "museum_rope_barrier", **{"minecraft:cardinal_direction": "west"})
        put(x, 2, 1, "museum_plaque", **{"minecraft:block_face": "south"})
    put(2, 1, 8, "dead_technician", **{f"{NS}:part": 0, "minecraft:cardinal_direction": "north"})
    put(2, 1, 9, "dead_technician", **{f"{NS}:part": 1, "minecraft:cardinal_direction": "north"})
    # display cases, pedestal with a reactor core, posters, benches
    for x in (10, 12):
        put(x, 1, 9, "museum_display_case")
    put(11, 1, 11, "museum_pedestal")
    for x, pid in ((1, "poster_outbreak_2072"), (13, "poster_radiation")):
        put(x, 3, 6, pid, **{"minecraft:block_face": "east" if x == 1 else "west"})
    put(4, 3, 11, "poster_collapse", **{"minecraft:block_face": "north"})
    put(10, 3, 11, "poster_zeds_world", **{"minecraft:block_face": "north"})
    put(5, 1, 10, "museum_bench", **{"minecraft:cardinal_direction": "north"})
    put(9, 1, 10, "museum_bench", **{"minecraft:cardinal_direction": "north"})
    put(13, 2, 2, "security_camera", **{"minecraft:block_face": "west"})
    put(1, 1, 11, "radiation_sign", **{"minecraft:block_face": "east"})
    return B


# ---------------------------------------------------------------- Bunkr (/structure load bunkr)
BSIZE = (9, 6, 9)


def bunker_layout():
    X, Y, Z = BSIZE
    B = {}

    def put(x, y, z, name, **st):
        B[(x, y, z)] = (name if ":" in name else f"{NS}:{name}", st)

    for x in range(X):
        for z in range(Z):
            put(x, 0, z, "bunker_reinforced")
            put(x, 5, z, "bunker_reinforced")
    for y in range(1, 5):
        for x in range(X):
            for z in range(Z):
                if x in (0, X - 1) or z in (0, Z - 1):
                    put(x, y, z, "bunker_concrete")
    put(4, 1, 0, "bunker_door", **{"minecraft:cardinal_direction": "south", f"{NS}:upper": False, f"{NS}:open": False})
    put(4, 2, 0, "bunker_door", **{"minecraft:cardinal_direction": "south", f"{NS}:upper": True, f"{NS}:open": False})
    for x in (2, 6):
        put(x, 2, 0, "bunker_window")
    put(0, 2, 4, "bunker_window")
    put(X - 1, 2, 4, "bunker_window")
    put(4, 4, 4, "ceiling_light", **{f"{NS}:lit": True})
    put(1, 1, 6, "hospital_bed", **{f"{NS}:part": 0, "minecraft:cardinal_direction": "north"})
    put(1, 1, 7, "hospital_bed", **{f"{NS}:part": 1, "minecraft:cardinal_direction": "north"})
    put(7, 1, 7, "minecraft:chest", **{"minecraft:cardinal_direction": "west"})
    put(7, 1, 6, "storage_boxes", **{"minecraft:cardinal_direction": "west"})
    put(4, 1, 7, "metal_table", **{"minecraft:cardinal_direction": "north"})
    put(5, 1, 7, "metal_chair", **{"minecraft:cardinal_direction": "south"})
    put(1, 1, 1, "radiation_indicator", **{"minecraft:cardinal_direction": "south", f"{NS}:level": 0})
    put(7, 2, 1, "siren", **{"minecraft:cardinal_direction": "south", f"{NS}:lit": False})
    put(4, 3, 8, "poster_evacuation", **{"minecraft:block_face": "north"})
    return B
