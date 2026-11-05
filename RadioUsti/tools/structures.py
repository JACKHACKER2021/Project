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


def build(path, layout=None, size=None, void="minecraft:air"):
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
                name, st = B.get((x, y, z), (void, {}))
                key = (name, tuple(sorted((k, v) for k, v in st.items() if k != "__loot")))
                if key not in index:
                    states = {}
                    for k, v in st.items():
                        if k == "__loot":
                            continue
                        states[k] = Byte(1 if v else 0) if isinstance(v, bool) else v
                    index[key] = len(palette)
                    palette.append({"name": name, "states": states, "version": BLOCK_VERSION})
                i = len(layer0)
                layer0.append(index[key])
                if name == "minecraft:chest":
                    loot = st.get("__loot")
                    bed = {"id": "Chest", "Findable": Byte(0), "isMovable": Byte(1), "x": x, "y": y, "z": z}
                    if loot:
                        bed["LootTable"] = loot
                        bed["LootTableSeed"] = 0
                        bed["Items"] = []
                    else:
                        bed["Items"] = chest_items()
                    pos_data[str(i)] = {"block_entity_data": bed}
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
    data = nbt_root(root)
    for lst in ("entities", "Items"):
        data = data.replace(struct.pack("<b", TAG_LIST) + _str(lst) + struct.pack("<bi", TAG_INT, 0),
                            struct.pack("<b", TAG_LIST) + _str(lst) + struct.pack("<bi", TAG_COMPOUND, 0))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return len(palette), sum(1 for v in layer0 if palette[v]["name"] not in ("minecraft:air", "minecraft:structure_void"))


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


# ================================================================ world-generated structures (v2.0)
import random as _random


class Lay:
    """Small helper for writing structure layouts."""

    def __init__(self, size, seed):
        self.size = size
        self.B = {}
        self.r = _random.Random(seed)

    def put(self, x, y, z, name, **st):
        X, Y, Z = self.size
        if 0 <= x < X and 0 <= y < Y and 0 <= z < Z:
            self.B[(x, y, z)] = (name if ":" in name else f"{NS}:{name}", st)

    def fill(self, x0, y0, z0, x1, y1, z1, name, **st):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                for z in range(z0, z1 + 1):
                    self.put(x, y, z, name, **st)

    def clear(self, x0, y0, z0, x1, y1, z1):
        self.fill(x0, y0, z0, x1, y1, z1, "minecraft:air")

    def shell(self, x0, y0, z0, x1, y1, z1, wall, floor=None, roof=None, ruin=0.0, window=None):
        for x in range(x0, x1 + 1):
            for z in range(z0, z1 + 1):
                if floor:
                    self.put(x, y0, z, floor)
                if roof and self.r.random() >= ruin * 1.6:
                    self.put(x, y1, z, roof)
        for y in range(y0 + 1, y1):
            for x in range(x0, x1 + 1):
                for z in range(z0, z1 + 1):
                    edge = x in (x0, x1) or z in (z0, z1)
                    if not edge:
                        self.put(x, y, z, "minecraft:air")
                        continue
                    if self.r.random() < ruin * (y - y0) / max(1, y1 - y0):
                        self.put(x, y, z, "minecraft:air")
                    elif window and y == y0 + 2 and (x + z) % 3 == 0 and not (x in (x0, x1) and z in (z0, z1)):
                        self.put(x, y, z, window)
                    else:
                        self.put(x, y, z, wall)

    def chest(self, x, y, z, table, face="south"):
        self.put(x, y, z, "minecraft:chest", **{"minecraft:cardinal_direction": face})
        self.B[(x, y, z)][1]["__loot"] = table

    def multi(self, x, y, z, name, parts, face="north"):
        for i, (ox, oy, oz) in enumerate(parts):
            wx, wz = rot_vec(face, ox, oz)
            self.put(x + wx, y + oy, z + wz, name, **{f"{NS}:part": i, "minecraft:cardinal_direction": face})

    def door(self, x, y, z, name, face="south"):
        self.put(x, y, z, name, **{"minecraft:cardinal_direction": face, f"{NS}:upper": False, f"{NS}:open": False})
        self.put(x, y + 1, z, name, **{"minecraft:cardinal_direction": face, f"{NS}:upper": True, f"{NS}:open": False})

    def scatter(self, x0, z0, x1, z1, y, names, n):
        for _ in range(n):
            x, z = self.r.randint(x0, x1), self.r.randint(z0, z1)
            if (x, y, z) not in self.B or self.B[(x, y, z)][0] == "minecraft:air":
                self.put(x, y, z, self.r.choice(names))

    def layout(self):
        return self.B


CAR = [(0, 0, 0), (0, 0, 1)]
LAMP = [(0, 0, 0), (0, 1, 0)]


def ruined_house(seed=1):
    L = Lay((11, 10, 11), seed)
    L.fill(0, 0, 0, 10, 0, 10, "sidewalk")
    L.shell(1, 0, 1, 9, 4, 9, "house_block", floor="cement_block", roof="cement_block", ruin=0.25, window="old_glass")
    L.shell(1, 4, 1, 9, 8, 9, "house_block", floor="cement_block", roof=None, ruin=0.55, window="minecraft:air")
    L.door(5, 1, 1, "lab_door", "north")
    L.put(3, 1, 7, "wooden_table", **{"minecraft:cardinal_direction": "north"})
    L.put(4, 1, 7, "wooden_chair", **{"minecraft:cardinal_direction": "west"})
    L.chest(7, 1, 7, "loot_tables/chests/radiousti_house.json", "west")
    L.put(2, 5, 3, "scattered_papers", **{f"{NS}:variant": 1})
    L.scatter(2, 2, 8, 8, 1, ["rubble", "scattered_papers", "blood_puddle"], 5)
    L.put(5, 2, 9, "poster_evacuation", **{"minecraft:block_face": "north"})
    L.scatter(0, 0, 10, 10, 1, ["radioactive_dust"], 6)
    return L.layout()


def road_segment(seed=2):
    L = Lay((16, 3, 7), seed)
    for x in range(16):
        L.put(x, 0, 0, "sidewalk")
        L.put(x, 0, 6, "sidewalk")
        for z in range(1, 6):
            L.put(x, 0, z, "asphalt_line" if z == 3 and x % 4 < 2 else ("asphalt_cracked" if L.r.random() < 0.2 else "asphalt"))
    L.multi(5, 1, 1, "car_wreck", CAR, "east")
    L.multi(2, 1, 6, "street_lamp", LAMP, "north")
    L.multi(13, 1, 0, "street_lamp", LAMP, "south")
    L.scatter(0, 1, 15, 5, 1, ["rubble", "barricade", "blood_puddle"], 3)
    return L.layout()


def city_block(seed=3):
    X, Y, Z = 31, 16, 31
    L = Lay((X, Y, Z), seed)
    L.fill(0, 0, 0, X - 1, 0, Z - 1, "sidewalk")
    for i in range(X):  # two crossing roads
        for w in range(13, 18):
            line = w == 15 and i % 4 < 2
            L.put(i, 0, w, "asphalt_line" if line else ("asphalt_cracked" if L.r.random() < 0.25 else "asphalt"))
            L.put(w, 0, i, "asphalt_line" if line else ("asphalt_cracked" if L.r.random() < 0.25 else "asphalt"))
    # four ruined buildings
    L.shell(1, 0, 1, 11, 9, 11, "house_block", floor="cement_block", roof="cement_block", ruin=0.45, window="old_glass")       # panelák
    L.shell(1, 4, 1, 11, 4, 11, "cement_block")
    L.shell(19, 0, 1, 29, 5, 10, "czechoslovak_industrial_wall", floor="cement_block", roof="cement_block", ruin=0.35, window="minecraft:glass")  # shop
    L.shell(1, 0, 19, 10, 6, 29, "old_brick", floor="cement_block", roof="cement_block", ruin=0.5, window="minecraft:air")    # brick house
    L.shell(19, 0, 19, 29, 7, 29, "yellow_old_cement", floor="cement_block", roof="cement_block", ruin=0.4, window="help_glass")  # clinic
    for x, z, f in ((6, 11, "south"), (24, 10, "south"), (5, 19, "north"), (24, 19, "north")):
        L.door(x, 1, z, "lab_door", f)
    # contents
    L.chest(3, 1, 3, "loot_tables/chests/radiousti_house.json")
    L.chest(3, 5, 9, "loot_tables/chests/radiousti_house.json")
    for x in range(21, 28, 2):
        L.put(x, 1, 3, "shop_shelf", **{"minecraft:cardinal_direction": "south"})
    L.put(27, 1, 8, "cash_register", **{"minecraft:cardinal_direction": "west"})
    L.chest(21, 1, 8, "loot_tables/chests/radiousti_city.json", "east")
    L.multi(21, 1, 22, "hospital_bed", [(0, 0, 0), (0, 0, 1)], "north")
    L.put(25, 1, 22, "medical_cabinet", **{"minecraft:cardinal_direction": "south"})
    L.chest(27, 1, 27, "loot_tables/chests/radiousti_lab.json", "west")
    L.multi(4, 1, 24, "dead_postman", [(0, 0, 0), (0, 0, 1)], "east")
    L.chest(8, 1, 27, "loot_tables/chests/radiousti_city.json", "north")
    # street furniture
    L.multi(14, 1, 3, "car_wreck", CAR, "north")
    L.multi(25, 1, 16, "car_wreck", CAR, "east")
    L.multi(4, 1, 14, "car_wreck", CAR, "west")
    for x, z in ((12, 12), (18, 12), (12, 18), (18, 18)):
        L.multi(x, 1, z, "street_lamp", LAMP, "north")
    L.scatter(0, 0, 30, 30, 1, ["rubble", "barricade", "blood_puddle", "radioactive_dust", "scattered_papers"], 26)
    L.put(15, 1, 15, "radiation_sign", **{"minecraft:block_face": "up"})
    return L.layout()


def survivor_village(seed=4):
    X, Y, Z = 31, 12, 31
    L = Lay((X, Y, Z), seed)
    L.fill(0, 0, 0, X - 1, 0, Z - 1, "minecraft:grass_block")
    L.fill(2, 0, 2, X - 3, 0, Z - 3, "minecraft:dirt_path")
    # defensive wall with sandbags and spikes outside
    for y in range(1, 5):
        for i in range(X):
            for (x, z) in ((i, 0), (i, Z - 1), (0, i), (X - 1, i)):
                L.put(x, y, z, "fortress_stone" if y < 4 else "fortress_battlement", **({"minecraft:cardinal_direction": "north"} if y == 4 else {}))
    for i in range(1, X - 1, 2):
        L.put(i, 1, 1, "sandbags", **{"minecraft:cardinal_direction": "north"})
    # gate: security shutter door + decontamination curtain behind it
    L.door(15, 1, 0, "security_door", "south")
    L.door(15, 1, 2, "decontamination_curtain", "south")
    L.put(14, 2, 1, "door_control_button", **{"minecraft:block_face": "north"})
    # watchtowers in the corners
    for cx, cz in ((1, 1), (X - 4, 1), (1, Z - 4), (X - 4, Z - 4)):
        L.fill(cx, 1, cz, cx + 2, 7, cz + 2, "fortress_stone")
        L.clear(cx + 1, 1, cz + 1, cx + 1, 6, cz + 1)
        L.put(cx + 1, 8, cz + 1, "stage_spotlight", **{"minecraft:cardinal_direction": "north", f"{NS}:lit": True})
        L.put(cx, 8, cz, "siren", **{"minecraft:cardinal_direction": "south", f"{NS}:lit": False})
    # houses with barricaded windows
    for i, (hx, hz) in enumerate(((5, 6), (19, 6), (5, 19), (19, 19))):
        L.shell(hx, 0, hz, hx + 6, 4, hz + 5, "cement_block", floor="cement_block", roof="bunker_concrete", window="minecraft:glass")
        for wx in range(hx + 1, hx + 6):
            if L.B.get((wx, 2, hz), ("",))[0] == "minecraft:glass":
                L.put(wx, 2, hz - 1, "window_barricade", **{"minecraft:block_face": "north"})
        L.door(hx + 3, 1, hz, "barricaded_door", "north")
        L.multi(hx + 1, 1, hz + 3, "hospital_bed", [(0, 0, 0), (0, 0, 1)], "north")
        L.chest(hx + 5, 1, hz + 4, "loot_tables/chests/radiousti_village.json", "west")
        L.put(hx + 3, 3, hz + 3, "old_light_block", **{f"{NS}:lit": True})
    # square: bell (keeps a survivor trader around), well with purified water, alarm, indicator
    L.put(15, 1, 15, "village_bell")
    L.fill(12, 0, 12, 13, 0, 13, "minecraft:water")
    L.put(17, 1, 13, "radiation_indicator", **{"minecraft:cardinal_direction": "south", f"{NS}:level": 0})
    L.put(17, 1, 17, "fortress_brazier")
    L.put(13, 1, 17, "fortress_brazier")
    for x in range(8, 23, 3):
        L.put(x, 1, 14, "minecraft:hay_block")
    return L.layout()


def fortress_ruin(seed=5):
    X, Y, Z = 23, 16, 23
    L = Lay((X, Y, Z), seed)
    L.fill(0, 0, 0, X - 1, 0, Z - 1, "fortress_stone_cracked")
    L.shell(0, 0, 0, X - 1, 8, Z - 1, "fortress_stone", ruin=0.25)
    for i in range(0, X, 2):
        for (x, z) in ((i, 0), (i, Z - 1), (0, i), (X - 1, i)):
            if L.r.random() > 0.3:
                L.put(x, 8, z, "fortress_battlement", **{"minecraft:cardinal_direction": "north"})
    # towers
    for cx, cz in ((0, 0), (X - 5, 0), (0, Z - 5), (X - 5, Z - 5)):
        L.shell(cx, 0, cz, cx + 4, 12, cz + 4, "castle_side", floor="fortress_stone", roof="fortress_stone", ruin=0.2)
        L.put(cx + 2, 13, cz + 2, "fortress_brazier")
    # gate with bars, keep in the middle
    L.fill(10, 1, 0, 12, 4, 0, "castle_bars", **{"minecraft:cardinal_direction": "south"})
    L.shell(7, 0, 8, 15, 10, 15, "fortress_stone_mossy", floor="fortress_stone", roof="fortress_stone", ruin=0.3, window="castle_bars")
    L.door(11, 1, 8, "fortress_door", "north")
    L.chest(9, 1, 13, "loot_tables/chests/radiousti_fortress.json", "east")
    L.chest(13, 1, 13, "loot_tables/chests/radiousti_fortress.json", "west")
    L.put(11, 1, 13, "museum_pedestal")
    L.put(11, 3, 15, "poster_fortress", **{"minecraft:block_face": "north"})
    L.scatter(1, 1, X - 2, 6, 1, ["rubble", "wooden_spikes", "barricade"], 14)
    L.scatter(1, 16, X - 2, Z - 2, 1, ["rubble", "flesh_growth", "blood_puddle"], 10)
    return L.layout()


def laboratory(seed=6):
    X, Y, Z = 17, 9, 15
    L = Lay((X, Y, Z), seed)
    L.fill(0, 0, 0, X - 1, 0, Z - 1, "npp_floor_warning")
    L.shell(0, 0, 0, X - 1, 6, Z - 1, "lead_wall", floor="shower_tiles", roof="cement_block", ruin=0.08, window="hermetic_glass")
    L.fill(1, 1, 7, X - 2, 5, 7, "lead_wall")
    L.door(8, 1, 7, "containment_door", "north")
    L.door(8, 1, 0, "lab_door", "north")
    for x in (2, 5, 11, 14):
        L.put(x, 1, 2, ["chemical_analysis_table", "biological_research_table", "nuclear_research_table", "contamination_testing_station"][(x // 3) % 4],
              **{"minecraft:cardinal_direction": "south"})
    L.put(2, 1, 5, "lab_pc", **{"minecraft:cardinal_direction": "north", f"{NS}:active": False})
    L.put(14, 1, 5, "server_rack", **{"minecraft:cardinal_direction": "west", f"{NS}:active": False})
    for x in (3, 6, 10, 13):
        L.put(x, 1, 11, "specimen_jar", **{f"{NS}:fill": L.r.randint(1, 3)})
    L.put(5, 1, 13, "lab_sink", **{"minecraft:cardinal_direction": "north"})
    L.put(11, 1, 13, "flask_set")
    L.multi(7, 1, 10, "operating_table", [(0, 0, 0), (0, 0, 1)], "north")
    L.multi(2, 1, 9, "dead_technician", [(0, 0, 0), (0, 0, 1)], "north")
    L.chest(14, 1, 12, "loot_tables/chests/radiousti_lab.json", "west")
    L.chest(1, 1, 3, "loot_tables/chests/radiousti_lab.json", "east")
    for x in (4, 8, 12):
        for z in (3, 11):
            L.put(x, 5, z, "lab_light", **{f"{NS}:lit": True})
    L.put(1, 3, 10, "biohazard_sign", **{"minecraft:block_face": "east"})
    L.put(15, 3, 3, "radiation_sign", **{"minecraft:block_face": "west"})
    L.scatter(1, 8, X - 2, Z - 2, 1, ["radioactive_dust", "blood_puddle", "lab_waste_bin"], 7)
    return L.layout()


WORLD_STRUCTURES = {
    # name: (layout fn, size, scatter denominator, adjustment radius)
    "ruined_house": (ruined_house, (11, 10, 11), 18, 4),
    "road_segment": (road_segment, (16, 3, 7), 14, 2),
    "city_block": (city_block, (31, 16, 31), 70, 6),
    "survivor_village": (survivor_village, (31, 12, 31), 90, 8),
    "fortress_ruin": (fortress_ruin, (23, 16, 23), 110, 8),
    "laboratory": (laboratory, (17, 9, 15), 60, 6),
}
