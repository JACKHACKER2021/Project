"""RadioÚstí content registry: the single source of truth for blocks, items and textures.

build.py turns this into Behavior/Resource pack JSON, geometry, textures, lang files
and scripts/data/registry.js (read by the gameplay scripts and the System Analyzer).
"""
import geo as G
import textures as T
from textures import P

NS = "radiousti"
TEX = {}      # texture name -> painter()
ITEM_TEX = {}  # item icon name -> painter()


def tex(name, fn):
    TEX["radiousti_" + name] = fn
    return "radiousti_" + name


def itex(name, fn):
    ITEM_TEX["radiousti_" + name] = fn
    return "radiousti_" + name


# ----------------------------------------------------------------- shared textures
S = {}
S["steel"] = tex("steel", lambda n: T.metal(n))
S["steel_dark"] = tex("steel_dark", lambda n: T.metal(n, P["steel_d"]))
S["steel_rusty"] = tex("steel_rusty", lambda n: T.metal(n, "#7a6f66", rust=10))
S["detail"] = tex("detail", lambda n: T.Tex(n, base="#5b6267").noise(5).frame("#3a3f43"))
S["brass"] = tex("brass", lambda n: T.Tex(n, base="#b08d3a").noise(8).frame("#6e5520"))
S["glass_clear"] = tex("glass_clear", lambda n: T.Tex(n, base="#cfe8ee", alpha=110).frame("#9fb9be", a=160))
S["glass_solid"] = tex("glass_solid", lambda n: T.Tex(n, base="#bcdde4").noise(4).frame("#8fb0b6"))
S["lamp_green"] = tex("lamp_green", lambda n: T.Tex(n, base="#3df25a").noise(4))
S["lamp_red"] = tex("lamp_red", lambda n: T.Tex(n, base="#ff3b2e").noise(4))
S["lamp_off"] = tex("lamp_off", lambda n: T.Tex(n, base="#4a4f52").noise(4))
S["glow_warm"] = tex("glow_warm", lambda n: T.Tex(n, base=P["glow_warm"]).noise(5))
S["glow_cold"] = tex("glow_cold", lambda n: T.Tex(n, base=P["glow_cold"]).noise(4))
S["glow_red"] = tex("glow_red", lambda n: T.Tex(n, base=P["glow_red"]).noise(6))
S["glow_orange"] = tex("glow_orange", lambda n: T.Tex(n, base=P["glow_orange"]).noise(6))
S["glow_off"] = tex("glow_off", lambda n: T.Tex(n, base="#6b6a63").noise(6))
S["glow_yellow"] = tex("glow_yellow", lambda n: T.Tex(n, base="#ffe14a").noise(5))
S["glow_green"] = tex("glow_green", lambda n: T.Tex(n, base="#7dff5a").noise(5))
S["screen_off"] = tex("screen_off", lambda n: T.screen(n, "off"))
S["screen_longhorn"] = tex("screen_longhorn", lambda n: T.screen(n, "longhorn"))
S["screen_terminal"] = tex("screen_terminal", lambda n: T.screen(n, "terminal"))
S["screen_leds"] = tex("screen_leds", lambda n: T.screen(n, "leds"))
S["screen_gauge"] = tex("screen_gauge", lambda n: T.screen(n, "gauge"))
S["screen_medical"] = tex("screen_medical", lambda n: T.screen(n, "medical"))
S["screen_dial"] = tex("screen_dial", lambda n: T.screen(n, "dial"))
S["screen_clock"] = tex("screen_clock", lambda n: T.screen(n, "clock"))
S["screen_fan"] = tex("screen_fan", lambda n: T.screen(n, "fan"))
S["keys"] = tex("keys", lambda n: T.Tex(n, base="#cbc3a8").noise(3).speckle(["#7a7465"], 40))
S["wood"] = tex("wood", lambda n: T.wood(n))
S["wood_dark"] = tex("wood_dark", lambda n: T.wood(n, "#5e4528"))
S["fabric_white"] = tex("fabric_white", lambda n: T.Tex(n, base=P["fabric_w"]).noise(5))
S["fabric_blue"] = tex("fabric_blue", lambda n: T.Tex(n, base=P["fabric_b"]).noise(6))
S["fabric_green"] = tex("fabric_green", lambda n: T.Tex(n, base="#4f6b52").noise(6))
S["fabric_black"] = tex("fabric_black", lambda n: T.Tex(n, base="#2a2b2d").noise(4))
S["lab_top"] = tex("lab_top", lambda n: T.Tex(n, base="#e9ece8").noise(3).frame("#c6cbc6"))
S["lab_top_black"] = tex("lab_top_black", lambda n: T.Tex(n, base="#26292a").noise(3).frame("#3a3f43"))
S["cabinet_beige"] = tex("cabinet_beige", lambda n: T.Tex(n, base=P["panel_beige"]).noise(4).frame("#8f866d"))
S["cabinet_green"] = tex("cabinet_green", lambda n: T.Tex(n, base=P["panel_green"]).noise(5).frame("#3b4736"))
S["hazard"] = tex("hazard", lambda n: T.Tex(n).stripes(P["hazard"], P["black"]))
S["blood_fill"] = tex("blood_fill", lambda n: T.Tex(n, base=P["blood"], alpha=230).noise(8))
S["flesh_fill"] = tex("flesh_fill", lambda n: T.flesh(n))
S["soul_fill"] = tex("soul_fill", lambda n: T.Tex(n, base=P["soul"], alpha=200).noise(10))
S["empty_fill"] = tex("empty_fill", lambda n: T.Tex(n, base="#cfe8ee", alpha=40))
S["iv_fill"] = tex("iv_fill", lambda n: T.Tex(n, base="#d6eef2", alpha=170).noise(3))

# ----------------------------------------------------------------- blocks
BLOCKS = []


def block(id, en, cs, **kw):
    d = dict(id=id, en=en, cs=cs, cat="construction", model=None, tex={"*": None}, render="opaque",
             sound="stone", hardness=1.5, resist=6, light=0, rot=None, comps=[], states={},
             kind="decor", meta={}, collision="auto", tags=[], loot="self", mapc="#8d8a82", desc_cs="", desc_en="")
    d.update(kw)
    BLOCKS.append(d)
    return d


# ---- pipes --------------------------------------------------------------------
PIPE_FAMILIES = {
    # family: (en, cs, resource description)
    "water": ("water", "voda"),
    "gas": ("gas", "plyn"),
    "molten": ("molten material", "roztavený materiál"),
    "radioactive": ("radioactive fluid", "radioaktivní kapalina"),
    "oil": ("oil", "olej"),
}
PIPES = [
    # id, en, cs, family, radius, colour, flange, bracket
    ("water_pipe", "Water Pipe", "Vodovodní potrubí", "water", 3, "#4f6d8a", True, False),
    ("water_pipe_thin", "Thin Wall Water Pipe", "Tenké nástěnné vodovodní potrubí", "water", 1.5, "#6b8099", False, True),
    ("gas_pipe", "Gas Pipe", "Plynové potrubí", "gas", 3, "#c9a227", True, False),
    ("lab_pipe", "Laboratory Gas Pipe", "Laboratorní plynové potrubí", "gas", 2, "#d8dcd8", True, False),
    ("molten_pipe", "Molten Material Pipe", "Potrubí na roztavený materiál", "molten", 3.5, "#a3471f", True, False),
    ("radioactive_pipe", "Radioactive Fluid Pipe", "Potrubí na radioaktivní kapalinu", "radioactive", 3, "#5b8a2c", True, False),
    ("industrial_pipe", "Industrial Oil Pipe", "Průmyslové olejové potrubí", "oil", 4, "#3d3a35", True, False),
]
for pid, en, cs, fam, r, col, fl, br in PIPES:
    t = tex(pid, lambda n, c=col, f=fam: (lambda tt: (tt.rect(0, 6, 16, 3, "#e0a800") if f == "radioactive" else None, tt)[1])(
        T.Tex(n, base=c).noise(7).hline(0, "#202020").hline(15, "#202020")))
    block(pid, en, cs, cat="construction", model=("pipe", r, fl, br), tex={"*": t, "detail": S["steel_dark"]},
          sound="metal", hardness=1.0, kind="pipe", meta={"family": fam, "cost": 1}, mapc=col,
          states={f"{NS}:{s}": [False, True] for s in ("n", "s", "e", "w", "u", "d", "joint")},
          tags=["metal", "radiousti:industrial"], render="opaque")

VALVES = [
    ("water_valve", "Water Valve", "Vodovodní ventil", "water", "#4f6d8a"),
    ("gas_valve", "Gas Valve", "Plynový ventil", "gas", "#c9a227"),
    ("molten_valve", "Molten Material Valve", "Ventil roztaveného materiálu", "molten", "#a3471f"),
    ("radioactive_valve", "Radioactive Fluid Valve", "Ventil radioaktivní kapaliny", "radioactive", "#5b8a2c"),
    ("oil_valve", "Industrial Oil Valve", "Ventil průmyslového oleje", "oil", "#3d3a35"),
]
for vid, en, cs, fam, col in VALVES:
    t = tex(vid, lambda n, c=col: T.Tex(n, base=c).noise(7))
    block(vid, en, cs, model=("valve", 3), tex={"*": t, "detail": S["steel"], "wheel": tex(vid + "_wheel", lambda n: T.Tex(n, base="#b3170f").noise(6)),
                                                 "lamp_green": S["lamp_green"], "lamp_red": S["lamp_red"]},
          sound="metal", hardness=1.0, kind="valve", meta={"family": fam, "cost": 1}, mapc=col,
          states={**{f"{NS}:{s}": [False, True] for s in ("n", "s", "e", "w", "u", "d")}, f"{NS}:open": [True, False]},
          comps=[f"{NS}:valve"], tags=["metal", "radiousti:industrial"])

CABLES = [
    # id, en, cs, family, radius, colour, cost
    ("electrical_cable", "Electrical Cable", "Elektrický kabel", "power", 1, "#262626", 1),
    ("high_voltage_cable", "High-Voltage Cable", "Vysokonapěťový kabel", "power", 2, "#c4631d", 0.25),
    ("lab_cable", "Laboratory Cable", "Laboratorní kabel", "power", 1, "#cfd3cf", 1),
    ("emergency_cable", "Emergency Power Cable", "Kabel nouzového napájení", "power", 1, "#a52a2a", 1),
    ("damaged_cable", "Damaged Cable", "Poškozený kabel", "power", 1, "#2b2622", -1),
    ("network_cable", "Computer Network Cable", "Počítačový síťový kabel", "data", 1, "#2c5aa0", 1),
]
for cid, en, cs, fam, r, col, cost in CABLES:
    def paint(n, c=col, dmg=(cid == "damaged_cable")):
        t = T.Tex(n, base=c).noise(5)
        if dmg:
            t.blobs(["#b87333", "#d4924a"], 6, 1)
        return t
    t = tex(cid, paint)
    block(cid, en, cs, model=("pipe", r, False, False), tex={"*": t, "detail": t}, sound="cloth", hardness=0.3,
          kind="cable", meta={"family": fam, "cost": cost, "damaged": cid == "damaged_cable"}, mapc=col,
          states={f"{NS}:{s}": [False, True] for s in ("n", "s", "e", "w", "u", "d", "joint")},
          collision="auto", render="opaque")

# ---- multiblock generators ----------------------------------------------------
GEN = [
    # id, en, cs, model kind, size (x,y,z), body colour, machine meta
    ("generator_standard", "Standard Generator", "Standardní generátor", "standard", (2, 2, 2), "#5e6f55",
     {"role": "generator", "output": 20, "fuel": ["coal", "oil_industrial"], "demand": 0}),
    ("generator_industrial", "Industrial Generator", "Průmyslový generátor", "industrial", (2, 2, 2), "#6c6f73",
     {"role": "generator", "output": 50, "fuel": ["gas", "molten"], "demand": 0}),
    ("generator_nuclear", "Nuclear Generator", "Jaderný generátor", "nuclear", (2, 2, 2), "#c7c3b4",
     {"role": "generator", "output": 120, "fuel": ["reactor"], "demand": 0}),
    ("generator_backup", "Backup Generator", "Záložní generátor", "backup", (2, 1, 2), "#a3471f",
     {"role": "generator", "output": 15, "fuel": ["coal"], "backup": True, "demand": 0}),
    ("lab_power_unit", "Laboratory Power Unit", "Laboratorní napájecí jednotka", "lab", (2, 1, 2), "#d8dcd8",
     {"role": "battery", "capacity": 2000, "rate": 20, "fuel": ["redstone"], "demand": 0}),
    ("server_power_unit", "Server Power Unit", "Serverová napájecí jednotka (UPS)", "server", (2, 1, 2), "#2a2b2d",
     {"role": "battery", "capacity": 4000, "rate": 30, "fuel": [], "demand": 0}),
]
for gid, en, cs, mk, size, col, meta in GEN:
    body = tex(gid, lambda n, c=col: T.metal(n, c, rust=3))
    offs = [(x, y, z) for y in range(size[1]) for z in range(size[2]) for x in range(size[0])]
    block(gid, en, cs, cat="equipment", model=("multi", mk, offs),
          tex={"*": body, "detail": S["steel_dark"], "screen": S["screen_off"], "hazard": S["hazard"]},
          tex_active={"screen": S["screen_terminal"] if mk != "server" else S["screen_leds"]},
          sound="metal", hardness=4, resist=12, rot="cardinal", kind="machine",
          states={f"{NS}:part": list(range(len(offs))), f"{NS}:active": [False, True]},
          meta={**meta, "multiblock": offs}, loot="empty", mapc=col, placer_icon=("gen_icon", col),
          tags=["metal", "radiousti:industrial"])

# ---- reactor -----------------------------------------------------------------
casing = tex("reactor_casing", lambda n: (lambda t: (t.rect(0, 12, 16, 4, P["hazard"]), t.rect(0, 12, 2, 4, P["black"]),
                                                      t.rect(6, 12, 2, 4, P["black"]), t.rect(12, 12, 2, 4, P["black"]), t)[-1])(T.metal(n, "#9a9d96")))
block("reactor_casing", "Reactor Casing", "Plášť reaktoru", cat="equipment", tex={"*": casing}, sound="metal", hardness=5,
      resist=30, kind="reactor_shell", mapc="#9a9d96", tags=["metal", "radiousti:industrial"])
block("reactor_glass", "Reactor Viewing Glass", "Průhledové sklo reaktoru", cat="equipment",
      tex={"*": tex("reactor_glass", lambda n: T.glass(n, "reactor"))}, render="blend", sound="glass", hardness=3, resist=30,
      kind="reactor_shell", model=("full_clear",), mapc="#5dd6c9")
for pid, en, cs, col, fam in (("reactor_port_coolant", "Reactor Coolant Port", "Chladicí port reaktoru", "#4f6d8a", "water"),
                              ("reactor_port_power", "Reactor Power Port", "Energetický port reaktoru", "#c4631d", "power"),
                              ("reactor_port_waste", "Reactor Waste Port", "Odpadní port reaktoru", "#5b8a2c", "radioactive")):
    t = tex(pid, lambda n, c=col: (lambda tt: (tt.rect(4, 4, 8, 8, c), tt.rect(6, 6, 4, 4, "#1d1d1d"), tt)[-1])(T.metal(n, "#9a9d96")))
    block(pid, en, cs, cat="equipment", tex={"*": t}, sound="metal", hardness=5, resist=30, kind="reactor_port",
          meta={"family": fam, "port": True}, mapc=col, tags=["metal", "radiousti:industrial"])
core_t = tex("reactor_core", lambda n: (lambda t: (t.rect(3, 3, 10, 10, "#2c4a3a"), t.rect(5, 5, 6, 6, "#6dff8a"), t)[-1])(T.metal(n, "#3c4246")))
core_on = tex("reactor_core_on", lambda n: (lambda t: (t.rect(3, 3, 10, 10, "#3c8a5a"), t.rect(4, 4, 8, 8, "#b8ffc8"), t)[-1])(T.metal(n, "#3c4246")))
block("reactor_core", "Reactor Core", "Jádro reaktoru", cat="equipment", tex={"*": core_t}, tex_active={"*": core_on},
      light_active=10, sound="metal", hardness=8, resist=60, kind="machine", states={f"{NS}:active": [False, True]},
      meta={"role": "reactor", "demand": 0}, mapc="#3c4246", tags=["metal", "radiousti:industrial"])
panel_body = tex("reactor_panel", lambda n: T.metal(n, "#c9bfa4"))
block("reactor_control_panel", "Reactor Control Panel", "Řídicí panel reaktoru", cat="equipment",
      model=("faces_full", {"north": "screen"}), tex={"*": panel_body, "screen": S["screen_dial"]}, rot="cardinal",
      sound="metal", hardness=5, resist=30, kind="reactor_shell", meta={"panel": True}, comps=[f"{NS}:reactor_panel"],
      mapc="#c9bfa4", tags=["metal", "radiousti:industrial"])
block("reactor_cooling_unit", "Reactor Cooling Unit", "Chladicí jednotka reaktoru", cat="equipment", model=("cooling_unit",),
      tex={"*": tex("cooling_unit", lambda n: T.metal(n, "#7d93a3")), "screen": S["screen_fan"], "detail": S["steel_dark"]}, rot="cardinal",
      sound="metal", hardness=4, kind="machine", meta={"role": "cooler", "family": "water", "demand": 0}, mapc="#7d93a3",
      tags=["metal", "radiousti:industrial"])
block("emergency_shutdown_button", "Emergency Shutdown Button", "Tlačítko nouzového odstavení", cat="equipment",
      model=("button",), tex={"*": S["hazard"], "detail": S["steel_dark"], "glow": S["glow_red"]}, sound="metal",
      hardness=2, kind="control", comps=[f"{NS}:scram_button"], collision="auto", mapc="#e0a800")
block("radiation_indicator", "Radiation Indicator", "Indikátor radiace", cat="equipment", model=("indicator",),
      rot="cardinal", tex={"*": S["cabinet_beige"], "screen": S["screen_dial"], "glow": S["lamp_green"]},
      states={f"{NS}:level": [0, 1, 2, 3]},
      level_tex={0: S["lamp_green"], 1: S["glow_yellow"], 2: S["glow_orange"], 3: S["glow_red"]},
      sound="metal", hardness=1.5, kind="indicator", comps=[f"{NS}:indicator"], mapc="#c9bfa4")
block("water_pump", "Water Pump", "Vodní čerpadlo", cat="equipment", model=("pump",), rot="cardinal",
      tex={"*": tex("pump", lambda n: T.metal(n, "#3f6e8f")), "detail": S["steel_dark"]}, sound="metal", hardness=3,
      kind="machine", meta={"role": "source", "family": "water", "demand": 0}, mapc="#3f6e8f", tags=["metal", "radiousti:industrial"])
block("gas_tank", "Gas Tank", "Plynová nádrž", cat="equipment", model=("tank",), rot="cardinal",
      tex={"*": tex("gas_tank", lambda n: T.metal(n, "#c9a227")), "detail": S["steel_dark"], "screen": S["screen_gauge"]},
      sound="metal", hardness=3, kind="machine", meta={"role": "tank", "family": "gas", "capacity": 1000, "demand": 0},
      mapc="#c9a227", tags=["metal", "radiousti:industrial"])
block("radioactive_waste_container", "Radioactive Waste Container", "Kontejner na radioaktivní odpad", cat="equipment",
      model=("waste_container",), rot="cardinal",
      tex={"*": tex("waste_container", lambda n: (lambda t: (t.rect(5, 5, 6, 6, P["hazard"]), t.rect(7, 7, 2, 2, P["black"]), t)[-1])(T.metal(n, "#5e6f55"))),
           "detail": S["steel_dark"], "screen": S["screen_gauge"]},
      sound="metal", hardness=4, resist=30, kind="machine",
      meta={"role": "waste_sink", "family": "radioactive", "capacity": 200, "demand": 0}, mapc="#5e6f55",
      tags=["metal", "radiousti:industrial"])

OILS = [
    # key, en, cs, colour, purpose_en, purpose_cs
    ("industrial", "Industrial Oil", "Průmyslový olej", "#c08a2a", "Fuel for the Standard Generator.", "Palivo pro standardní generátor."),
    ("black", "Black Machine Oil", "Černý strojní olej", "#151515", "Lubricant ingredient for generators, pumps and heavy doors.", "Mazivo – surovina pro generátory, čerpadla a těžké dveře."),
    ("hydraulic", "Yellow Hydraulic Oil", "Žlutý hydraulický olej", "#e3c52a", "Ingredient for containment doors and the reactor control panel.", "Surovina pro kontejnmentové dveře a řídicí panel reaktoru."),
    ("lab", "Red Laboratory Oil", "Červený laboratorní olej", "#b3241c", "Reagent charges for the Chemical Analysis Table.", "Náplň činidel pro stůl chemické analýzy."),
    ("contaminated", "Green Contaminated Oil", "Zelený kontaminovaný olej", "#5f8f2a", "Hazardous; decontaminate it at the Contamination Testing Station.", "Nebezpečný; dekontaminuje se na stanici testování kontaminace."),
    ("radioactive", "Radioactive Oil", "Radioaktivní olej", "#7dff3a", "Needed to make uranium fuel rods at the Nuclear Research Table.", "Potřebný k výrobě palivových tyčí na stole jaderného výzkumu."),
]
for key, en, cs, col, pen, pcs in OILS:
    t = tex(f"barrel_{key}", lambda n, c=col: (lambda tt: (tt.rect(3, 6, 10, 4, "#e8e0c8"), tt.rect(5, 7, 6, 2, c), tt)[-1])(T.metal(n, c if c != "#151515" else "#2a2a2a")))
    block(f"oil_barrel_{key}", f"{en} Barrel", f"Sud – {cs.lower()}", cat="equipment", model=("barrel",),
          tex={"*": t, "detail": S["steel_dark"]}, sound="metal", hardness=2.5, kind="machine",
          meta={"role": "tank", "family": "oil", "oil": key, "capacity": 16, "demand": 0}, mapc=col,
          tags=["metal", "radiousti:industrial"])

# ---- computers & server -------------------------------------------------------
PCS = [
    ("old_pc", "Old PC", "Starý počítač", "old", "#cbc3a8", S["screen_longhorn"]),
    ("office_pc", "Office Computer", "Kancelářský počítač", "office", "#bdb8a8", S["screen_longhorn"]),
    ("lab_pc", "Laboratory PC", "Laboratorní počítač", "lab", "#e4e6e2", S["screen_longhorn"]),
    ("industrial_terminal", "Industrial Terminal", "Průmyslový terminál", "terminal", "#5e6f55", S["screen_terminal"]),
]
for pid, en, cs, var, col, on in PCS:
    body = tex(pid, lambda n, c=col: T.Tex(n, base=c).noise(4).frame("#8f866d"))
    block(pid, en, cs, cat="equipment", model=("pc", var), rot="cardinal",
          tex={"*": body, "screen": S["screen_off"], "keys": S["keys"], "detail": S["steel_dark"]}, tex_active={"screen": on}, light_active=4,
          states={f"{NS}:active": [False, True]}, sound="metal", hardness=2, kind="machine",
          meta={"role": "computer", "demand": 2, "variant": var}, comps=[f"{NS}:computer"], mapc=col)
block("server_rack", "Server Rack", "Serverový rack", cat="equipment", model=("server",), rot="cardinal",
      tex={"*": tex("server_rack", lambda n: T.metal(n, "#2a2b2d")), "screen": S["screen_off"], "detail": S["steel"]},
      tex_active={"screen": S["screen_leds"]}, light_active=3, states={f"{NS}:active": [False, True]},
      sound="metal", hardness=3, kind="machine", meta={"role": "server", "demand": 5}, comps=[f"{NS}:server"], mapc="#2a2b2d",
      tags=["metal", "radiousti:industrial"])

# ---- laboratory tables --------------------------------------------------------
LAB = [
    ("lab_table", "Laboratory Table", "Laboratorní stůl", "standard", S["lab_top"], S["cabinet_beige"], {"craft": "radiousti_lab"}),
    ("chemical_analysis_table", "Chemical Analysis Table", "Stůl chemické analýzy", "chemical", S["lab_top_black"], S["cabinet_green"],
     {"station": "chemical", "demand": 3, "needs_gas": True}),
    ("biological_research_table", "Biological Research Table", "Stůl biologického výzkumu", "bio", S["lab_top"], S["cabinet_beige"],
     {"station": "bio", "demand": 3}),
    ("nuclear_research_table", "Nuclear Research Table", "Stůl jaderného výzkumu", "nuclear", S["lab_top_black"], S["steel"],
     {"station": "nuclear", "demand": 5}),
    ("contamination_testing_station", "Contamination Testing Station", "Stanice testování kontaminace", "contamination", S["lab_top"], S["cabinet_green"],
     {"station": "contamination", "demand": 3}),
    ("sample_preparation_table", "Sample Preparation Table", "Stůl přípravy vzorků", "prep", S["lab_top"], S["cabinet_beige"],
     {"station": "prep", "demand": 0}),
    ("industrial_workbench", "Industrial Workbench", "Průmyslový ponk", "industrial", S["wood_dark"], S["steel_rusty"],
     {"craft": "radiousti_industrial"}),
    ("computer_workstation", "Computer Workstation", "Počítačová pracovní stanice", "workstation", S["lab_top"], S["cabinet_beige"],
     {"role": "computer", "demand": 2, "variant": "workstation"}),
]
for lid, en, cs, kit, top, body, meta in LAB:
    extra = {}
    comps = []
    states = {}
    kind = "station"
    if "craft" in meta:
        extra["crafting"] = meta["craft"]
        kind = "craft_table"
    elif meta.get("role") == "computer":
        comps = [f"{NS}:computer"]
        states = {f"{NS}:active": [False, True]}
        extra["tex_active"] = {"screen": S["screen_longhorn"]}
        extra["light_active"] = 4
        kind = "machine"
    else:
        comps = [f"{NS}:lab_station"]
        kind = "machine"
        meta = {**meta, "role": "station"}
    block(lid, en, cs, cat="equipment", model=("lab", kit), rot="cardinal",
          tex={"*": body, "top": top, "glass": S["glass_solid"], "detail": S["steel_dark"], "screen": S["screen_terminal"] if kit != "workstation" else S["screen_off"],
               "keys": S["keys"]},
          sound="wood" if kit == "industrial" else "metal", hardness=2.5, kind=kind, meta=meta, comps=comps, states=states,
          mapc="#e9ece8", **extra)

# ---- lights & alarms ----------------------------------------------------------
LIGHTS = [
    # id, en, cs, model, placement, glow_on, light
    ("industrial_light", "Old Industrial Light", "Stará průmyslová lampa", "lamp_hanging", None, S["glow_warm"], 14),
    ("wall_light", "Wall-Mounted Light", "Nástěnné světlo", "lamp_wall", "face", S["glow_warm"], 13),
    ("ceiling_light", "Ceiling Light", "Stropní světlo", "lamp_ceiling", None, S["glow_cold"], 15),
    ("lab_light", "Laboratory Light", "Laboratorní světlo", "lamp_ceiling", None, S["glow_cold"], 15),
    ("emergency_light", "Emergency Light", "Nouzové světlo", "lamp_wall", "face", S["glow_red"], 10),
    ("warning_beacon", "Warning Beacon", "Výstražný maják", "lamp_floor_beacon", None, S["glow_orange"], 12),
]
for lid, en, cs, mdl, plc, on, lvl in LIGHTS:
    body = S["steel_dark"] if lid != "lab_light" else S["lab_top"]
    block(lid, en, cs, cat="items", model=(mdl,), rot=plc, tex={"*": body, "detail": S["steel"], "glow": S["glow_off"]},
          tex_lit={"glow": on}, light_lit=lvl, states={f"{NS}:lit": [False, True]}, sound="metal", hardness=1,
          kind="light", comps=[f"{NS}:light_switch"], mapc="#ffe29a",
          meta={"auto": "reactor_warning" if lid == "warning_beacon" else ("power_loss" if lid == "emergency_light" else None)})
old_light = tex("old_light_block", lambda n: (lambda t: (t.rect(2, 2, 12, 12, "#d8d0b0"), t.rect(3, 3, 10, 10, "#b8ae8c"), t)[-1])(T.metal(n, "#6f6c65")))
old_light_on = tex("old_light_block_on", lambda n: (lambda t: (t.rect(2, 2, 12, 12, "#fff3c4"), t.rect(3, 3, 10, 10, "#ffe58a"), t)[-1])(T.metal(n, "#6f6c65")))
block("old_light_block", "Old Light Block", "Starý světelný blok", cat="construction", tex={"*": old_light},
      tex_lit={"*": old_light_on}, light_lit=15, states={f"{NS}:lit": [False, True]}, sound="glass", hardness=1,
      kind="light", comps=[f"{NS}:light_switch"], mapc="#d8d0b0")
for aid, en, cs, col, trig in (("alarm", "Alarm", "Poplachová siréna", "#b3170f", "any"),
                               ("radiation_alarm", "Radiation Warning Alarm", "Radiační výstražný alarm", "#e0a800", "radiation")):
    block(aid, en, cs, cat="items", model=("alarm",), rot="face",
          tex={"*": tex(aid, lambda n, c=col: T.metal(n, c)), "detail": S["steel_dark"], "glow": S["glow_off"]},
          tex_lit={"glow": S["glow_red"] if aid == "alarm" else S["glow_yellow"]}, light_lit=8,
          states={f"{NS}:lit": [False, True]}, sound="metal", hardness=1.5, kind="alarm", meta={"trigger": trig},
          comps=[f"{NS}:alarm"], mapc=col)

# ---- doors --------------------------------------------------------------------
DOORS = [
    ("lab_door", "Laboratory Door", "Laboratorní dveře", "#e4e6e2", True),
    ("industrial_door", "Industrial Door", "Průmyslové dveře", "#5e6f55", False),
    ("containment_door", "Containment Door", "Kontejnmentové dveře", "#c9a227", False),
    ("fortress_door", "Fortress Door", "Dveře pevnosti", "#5e4528", False),
]
for did, en, cs, col, window in DOORS:
    def dtex(n, c=col, top=True, win=window, wood=(did == "fortress_door"), haz=(did == "containment_door")):
        t = T.wood(n, c) if wood else T.metal(n, c, rivet=True)
        if top and win:
            t.rect(4, 3, 8, 8, "#9fc4c9", 200); t.rect(4, 3, 8, 1, "#3c4246")
        if top and haz:
            t.rect(0, 0, 16, 3, P["hazard"]); t.rect(3, 0, 2, 3, P["black"]); t.rect(9, 0, 2, 3, P["black"])
            t.rect(5, 6, 6, 6, "#1d1d1d"); t.rect(7, 8, 2, 2, P["hazard"])
        if not top:
            t.rect(12, 1, 2, 3, "#e0a800" if not wood else "#2a2a2a")
            if haz:
                t.rect(0, 13, 16, 3, P["hazard"]); t.rect(3, 13, 2, 3, P["black"]); t.rect(9, 13, 2, 3, P["black"])
        return t
    top = tex(did + "_top", lambda n, f=dtex: f(n, top=True))
    bot = tex(did + "_bottom", lambda n, f=dtex: f(n, top=False))
    block(did, en, cs, cat="construction", model=("door",), rot="cardinal", tex={"*": bot, "detail": S["steel_dark"] if did != "fortress_door" else S["wood_dark"]},
          tex_upper={"*": top},
          states={f"{NS}:upper": [False, True], f"{NS}:open": [False, True]}, sound="wood" if did == "fortress_door" else "metal",
          hardness=3, resist=10 if did != "containment_door" else 40, kind="door", comps=[f"{NS}:door"], loot="empty",
          mapc=col, placer_icon=("door_icon", col))

# ---- uranium, contamination ---------------------------------------------------
block("uranium_ore", "Uranium Ore", "Uranová ruda", cat="nature", tex={"*": tex("uranium_ore", lambda n: T.ore(n, P["stone"], P["uranium"]))},
      light=3, hardness=3, resist=3, kind="radioactive", meta={"rad": 1}, loot="loot_tables/blocks/uranium_ore.json",
      tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#5fd14a")
block("deepslate_uranium_ore", "Deepslate Uranium Ore", "Hlubinná uranová ruda", cat="nature",
      tex={"*": tex("deepslate_uranium_ore", lambda n: T.ore(n, "#4a4a50", P["uranium"]))}, light=3, hardness=4.5, resist=3,
      kind="radioactive", meta={"rad": 1}, loot="loot_tables/blocks/uranium_ore.json", tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#4a4a50")
block("uranium_block", "Block of Uranium", "Blok uranu", cat="construction",
      tex={"*": tex("uranium_block", lambda n: T.Tex(n, base="#4fbf3a").noise(10).frame("#2a6a20").rivets("#c8ffb0"))},
      light=7, hardness=5, kind="radioactive", meta={"rad": 4}, tags=["metal", "minecraft:is_pickaxe_item_destructible"], mapc="#4fbf3a")
block("raw_uranium_block", "Block of Raw Uranium", "Blok surového uranu", cat="construction",
      tex={"*": tex("raw_uranium_block", lambda n: T.Tex(n, base="#3f8a2e").noise(20).blobs(["#7dff5a", "#2a5a20"], 10, 2))},
      light=5, hardness=5, kind="radioactive", meta={"rad": 3}, tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#3f8a2e")
block("contaminated_dirt", "Contaminated Dirt", "Kontaminovaná hlína", cat="nature",
      tex={"*": tex("contaminated_dirt", lambda n: T.contaminated(n, "dirt"))}, sound="gravel", hardness=0.6, kind="radioactive",
      meta={"rad": 1, "clean": "minecraft:dirt"}, mapc="#5e5134", tags=["dirt"])
block("contaminated_grass", "Contaminated Grass", "Kontaminovaná tráva", cat="nature",
      tex={"*": tex("contaminated_grass_side", lambda n: T.contaminated(n, "grass_side")),
           "up": tex("contaminated_grass_top", lambda n: T.contaminated(n, "grass_top")), "down": "radiousti_contaminated_dirt"},
      sound="grass", hardness=0.7, kind="radioactive", meta={"rad": 1, "clean": "minecraft:grass_block"}, mapc="#6f7d2f",
      loot="loot_tables/blocks/contaminated_grass.json", tags=["dirt", "grass"])
block("contaminated_stone", "Contaminated Stone", "Kontaminovaný kámen", cat="nature",
      tex={"*": tex("contaminated_stone", lambda n: T.contaminated(n, "stone"))}, hardness=1.5, kind="radioactive",
      meta={"rad": 1, "clean": "minecraft:stone"}, mapc="#6f7468", tags=["stone", "minecraft:is_pickaxe_item_destructible"])
block("radioactive_waste", "Radioactive Waste", "Radioaktivní odpad", cat="nature",
      tex={"*": tex("radioactive_waste", lambda n: T.contaminated(n, "waste"))}, light=6, sound="slime", hardness=1.0,
      kind="radioactive", meta={"rad": 5, "spreads": True}, comps=[f"{NS}:waste_spread"], tick=(600, 1200), mapc="#3b4a1f")
block("damaged_reactor_core", "Damaged Reactor Core", "Poškozené jádro reaktoru", cat="nature",
      tex={"*": tex("damaged_core", lambda n: T.Tex(n, base="#2a2a22").noise(20).blobs(["#7dff3a", "#a3471f", "#111"], 12, 2))},
      light=9, hardness=10, resist=60, kind="radioactive", meta={"rad": 10}, mapc="#2a2a22", tags=["metal"])
for sid, en, cs, pk in (("radiation_sign", "Radiation Warning Sign", "Výstražná cedule – radiace", "radiation"),
                        ("biohazard_sign", "Biohazard Sign", "Cedule – biologické nebezpečí", "bio"),
                        ("zed_warning_sign", "ZED ZONE Warning Sign", "Výstražná cedule ZÓNA ZED", "zed")):
    def sign(n, k=pk):
        t = T.Tex(n, base=P["hazard"] if k != "zed" else "#d9cfb3").frame("#1d1d1d")
        if k == "radiation":
            t.rect(7, 7, 2, 2, "#1d1d1d"); t.rect(6, 2, 4, 4, "#1d1d1d"); t.rect(2, 9, 4, 4, "#1d1d1d"); t.rect(10, 9, 4, 4, "#1d1d1d")
        elif k == "bio":
            t.rect(6, 2, 4, 3, "#1d1d1d"); t.rect(2, 9, 3, 4, "#1d1d1d"); t.rect(11, 9, 3, 4, "#1d1d1d"); t.rect(6, 6, 4, 4, "#1d1d1d"); t.rect(7, 7, 2, 2, P["hazard"])
        else:
            t.text("ZED", 3, 2, "#8f1d18"); t.text("ZONE", 1, 9, "#1d1d1d")
        return t
    block(sid, en, cs, cat="items", model=("flat_wall",), rot="face", tex={"*": tex(sid, sign)}, render="alpha_test",
          sound="metal", hardness=0.8, collision=False, kind="decor", mapc="#e0a800")
block("warning_stripes", "Warning Stripe Block", "Blok s výstražnými pruhy", tex={"*": S["hazard"]}, hardness=1.5, mapc="#e0a800",
      tags=["stone", "minecraft:is_pickaxe_item_destructible"])

# ---- retro Czechoslovak construction ------------------------------------------
CON = [
    ("cement_block", "Block of Cement", "Blok cementu", lambda n: T.concrete(n), "#8d8a82"),
    ("yellow_old_cement", "Yellow Old Cement Block", "Žlutý starý cementový blok", lambda n: T.concrete(n, P["yellow_cement"]), "#c7b26a"),
    ("old_brick", "Old Brick Block", "Starý cihlový blok", lambda n: T.Tex(n).bricks(P["brick_old"], P["mortar"]).noise(6), "#7a4a3a"),
    ("czechoslovak_industrial_wall", "Czechoslovak Industrial Wall", "Československá průmyslová stěna",
     lambda n: (lambda t: (t.rect(0, 0, 16, 9, "#a09a84"), t.rect(0, 9, 16, 1, "#5f5a4c"), t.rect(0, 10, 16, 6, "#6b7a5a"),
                           t.speckle(["#5f5a4c", "#8f8a74"], 14), t)[-1])(T.Tex(n, base="#a09a84").noise(8)), "#a09a84"),
    ("house_block", "Block of House", "Blok domu (panelák)",
     lambda n: (lambda t: (t.rect(3, 3, 10, 8, "#3a4c5c"), t.rect(3, 3, 10, 1, "#e6e1d0"), t.rect(7, 3, 1, 8, "#e6e1d0"),
                           t.rect(2, 11, 12, 1, "#5f5c56"), t.hline(15, "#6f6c65"), t)[-1])(T.concrete(n, "#b9b3a1", cracks=False)), "#b9b3a1"),
    ("industrial_vent", "Industrial Ventilation Block", "Průmyslový větrací blok",
     lambda n: (lambda t: ([t.hline(y, "#2a2e30") for y in range(3, 14, 2)], t)[-1])(T.metal(n, "#6c6f73")), "#6c6f73"),
    ("fuse_box", "Fuse Box", "Pojistková skříň",
     lambda n: (lambda t: (t.rect(3, 3, 10, 10, "#8f9a8a"), t.rect(5, 5, 2, 6, "#1d1d1d"), t.rect(9, 5, 2, 6, "#1d1d1d"),
                           t.rect(11, 2, 3, 2, P["hazard"]), t)[-1])(T.metal(n, "#5e6f55")), "#5e6f55"),
    ("blood_stained_concrete", "Blood-Stained Concrete", "Zakrvácený beton",
     lambda n: T.concrete(n).blobs([P["blood"], P["blood_d"]], 6, 2), "#8d8a82"),
    ("burnt_planks", "Burnt Planks", "Spálená prkna", lambda n: T.wood(n, "#3a2c1c").speckle(["#111", "#5a3a1a"], 20), "#3a2c1c"),
    ("fortress_stone", "Fortress Stone", "Kámen pevnosti", lambda n: T.Tex(n).bricks(P["fort"], "#5f5a50", h=8, w=8, var=10).noise(10), "#8a8478"),
    ("fortress_stone_cracked", "Cracked Fortress Stone", "Popraskaný kámen pevnosti",
     lambda n: T.Tex(n).bricks("#7d776b", "#4f4a42", h=8, w=8, var=10).noise(12).speckle(["#3a3630"], 16), "#7d776b"),
    ("fortress_stone_mossy", "Overgrown Fortress Stone", "Zarostlý kámen pevnosti",
     lambda n: T.Tex(n).bricks(P["fort"], "#5f5a50", h=8, w=8, var=10).noise(10).blobs(["#4f6b32", "#3a5226"], 7, 2), "#6f7a5a"),
    ("castle_side", "Castle Side Block", "Boční blok hradu",
     lambda n: (lambda t: (t.rect(6, 4, 4, 8, "#2a2622"), t.rect(7, 3, 2, 1, "#2a2622"), t)[-1])(T.Tex(n).bricks("#948d7f", "#615b51", h=4, w=8, var=8).noise(8)), "#948d7f"),
]
for cid, en, cs, fn, mc in CON:
    tg = ["stone", "minecraft:is_pickaxe_item_destructible"]
    snd = "stone"
    if cid == "burnt_planks":
        tg, snd = ["wood", "minecraft:is_axe_item_destructible"], "wood"
    if cid in ("industrial_vent", "fuse_box"):
        tg, snd = ["metal", "radiousti:industrial"], "metal"
    if cid in ("cement_block", "yellow_old_cement", "house_block", "czechoslovak_industrial_wall"):
        tg = tg + ["radiousti:industrial"]
    block(cid, en, cs, tex={"*": tex(cid, fn)}, hardness=2, sound=snd, tags=tg, mapc=mc)
block("old_brick_wall", "Old Brick Wall", "Stará cihlová zeď", model=("slab_wall", 8), rot="cardinal",
      tex={"*": "radiousti_old_brick"}, hardness=2, tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#7a4a3a")
block("old_glass", "Old Glass Block", "Starý skleněný blok (luxfery)", tex={"*": tex("old_glass", lambda n: T.glass(n, "old"))},
      model=("full_clear",), render="blend", sound="glass", hardness=0.6, mapc="#b8d6d9")
block("help_glass", "HELP Glass", "Sklo s nápisem HELP", tex={"*": tex("help_glass", lambda n: T.glass(n, "help"))},
      model=("full_clear",), render="blend", sound="glass", hardness=0.6, mapc="#9fc4c9")
block("castle_bars", "Castle Bars", "Hradní mříže", model=("bars",), rot="cardinal",
      tex={"*": tex("castle_bars", lambda n: T.Tex(n, base="#3a3a3c").noise(8))}, sound="metal", hardness=3, mapc="#3a3a3c")
block("storage_boxes", "Storage Boxes", "Skladové bedny", model=("crates",), rot="cardinal",
      tex={"*": tex("storage_boxes", lambda n: (lambda t: (t.frame("#4a3820"), t.rect(0, 7, 16, 2, "#4a3820"), t)[-1])(T.wood(n, "#9a7a4a")))},
      sound="wood", hardness=1.5, tags=["wood", "minecraft:is_axe_item_destructible"], mapc="#9a7a4a")
block("fortress_battlement", "Fortress Battlement", "Cimbuří pevnosti", model=("battlement",), rot="cardinal",
      tex={"*": "radiousti_fortress_stone"}, hardness=2, tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#8a8478")
block("barricade", "Wooden Barricade", "Dřevěná barikáda", model=("barricade",), rot="cardinal",
      tex={"*": "radiousti_burnt_planks", "detail": S["wood"]}, sound="wood", hardness=1.5, tags=["wood"], mapc="#5e4528")
block("barbed_wire", "Barbed Wire", "Ostnatý drát", model=("barbed",), tex={"*": S["steel_rusty"], "detail": S["wood_dark"]},
      render="opaque", sound="metal", hardness=1, collision=False, comps=[f"{NS}:barbed_wire"], mapc="#7a6f66", kind="decor")
block("sandbags", "Sandbags", "Pytle s pískem", model=("sandbags",), rot="cardinal",
      tex={"*": tex("sandbag", lambda n: T.Tex(n, base="#a8986a").noise(10).hline(0, "#7a6e4c").hline(15, "#7a6e4c"))},
      sound="sand", hardness=1, mapc="#a8986a")
block("wooden_spikes", "Wooden Spike Trap", "Dřevěné bodce", model=("spikes",), tex={"*": S["wood"], "detail": S["wood_dark"]},
      sound="wood", hardness=1, comps=[f"{NS}:spikes"], mapc="#8a6a43")
block("rubble", "Rubble", "Suť", model=("rubble",), tex={"*": "radiousti_cement_block"}, hardness=1, mapc="#8d8a82",
      tags=["stone", "minecraft:is_pickaxe_item_destructible"])

# ---- furniture & hospital -----------------------------------------------------
FURN = [
    ("wooden_table", "Wooden Table", "Dřevěný stůl", ("table",), {"*": S["wood"]}, "wood"),
    ("metal_table", "Metal Table", "Kovový stůl", ("table", 14, 2, 0, 1.5), {"*": S["steel"]}, "metal"),
    ("office_desk", "Office Desk", "Kancelářský stůl", ("desk",), {"*": S["wood_dark"], "detail": S["cabinet_beige"]}, "wood"),
    ("wooden_chair", "Wooden Chair", "Dřevěná židle", ("chair",), {"*": S["wood"]}, "wood"),
    ("metal_chair", "Metal Chair", "Kovová židle", ("chair",), {"*": S["steel"]}, "metal"),
    ("office_chair", "Rotating Office Chair", "Otočná kancelářská židle", ("office_chair",), {"*": S["steel_dark"], "detail": S["steel"], "fabric": S["fabric_black"]}, "cloth"),
    ("lab_chair", "Laboratory Chair", "Laboratorní židle", ("stool",), {"*": S["steel"], "detail": S["steel_dark"], "fabric": S["fabric_blue"]}, "metal"),
    ("exam_table", "Medical Examination Table", "Vyšetřovací lehátko", ("exam",), {"*": S["fabric_green"], "frame": S["steel"]}, "cloth"),
    ("iv_stand", "IV Drip Stand", "Infuzní stojan", ("iv",), {"*": S["steel"], "detail": S["steel"], "fill": S["iv_fill"]}, "metal"),
    ("medical_monitor", "Medical Monitor", "Lékařský monitor", ("med_monitor",), {"*": S["cabinet_beige"], "detail": S["steel"], "screen": S["screen_medical"]}, "metal"),
    ("medical_cabinet", "Medical Cabinet", "Lékárnička – skříň", ("cabinet",), {"*": tex("medical_cabinet", lambda n: (lambda t: (t.rect(6, 3, 4, 10, "#b3170f"), t.rect(3, 6, 10, 4, "#b3170f"), t)[-1])(T.Tex(n, base="#e6e6e2").noise(3).frame("#a6a6a2"))), "detail": S["steel"]}, "metal"),
    ("filing_cabinet", "Filing Cabinet", "Kartotéka", ("cabinet",), {"*": S["cabinet_green"], "detail": S["steel"]}, "metal"),
    ("locker", "Old Locker", "Stará šatní skříňka", ("cabinet", 16, False), {"*": tex("locker", lambda n: (lambda t: ([t.rect(3, y, 10, 1, "#2a2e30") for y in (2, 4, 6)], t.rect(11, 9, 2, 1, "#c0c7cc"), t)[-1])(T.metal(n, "#5f7d8c")))}, "metal"),
    ("medical_container", "Medical Supply Container", "Kontejner zdravotnického materiálu", ("crates",), {"*": tex("med_container", lambda n: (lambda t: (t.rect(6, 4, 4, 8, "#b3170f"), t.rect(4, 6, 8, 4, "#b3170f"), t)[-1])(T.Tex(n, base="#dcdcd4").noise(4).frame("#9a9a92")))}, "metal"),
]
for fid, en, cs, mdl, tx, snd in FURN:
    comps, kind, meta = [], "furniture", {}
    if fid == "office_chair":
        comps = [f"{NS}:rotate_on_use"]
    block(fid, en, cs, cat="items", model=mdl, rot="cardinal", tex=tx, sound=snd, hardness=1.5, comps=comps, kind=kind,
          tags=["wood", "minecraft:is_axe_item_destructible"] if snd == "wood" else ["metal"], mapc="#8a6a43")
for bid, en, cs, mk in (("hospital_bed", "Hospital Bed", "Nemocniční lůžko", "bed"), ("operating_table", "Operating Table", "Operační stůl", "optable")):
    block(bid, en, cs, cat="items", model=("multi", mk, [(0, 0, 0), (0, 0, 1)]), rot="cardinal",
          tex={"*": S["fabric_white"] if mk == "bed" else S["fabric_green"], "frame": S["steel"], "fabric": S["fabric_white"]},
          states={f"{NS}:part": [0, 1]}, sound="metal", hardness=1.5, kind="furniture",
          meta={"multiblock": [(0, 0, 0), (0, 0, 1)], "bed": mk == "bed"}, comps=[f"{NS}:bed"] if mk == "bed" else [],
          loot="empty", mapc="#dfe3e3", placer_icon=("bed_icon", "#dfe3e3"))

# ---- documents, posters, clock ------------------------------------------------
POSTERS = [
    ("poster_outbreak_2072", "Poster: RadioÚstí Outbreak 2072", "Plakát: Nákaza RadioÚstí 2072", "outbreak"),
    ("poster_evacuation", "Poster: Evacuation Order", "Plakát: Evakuační příkaz", "evacuation"),
    ("poster_radiation", "Poster: Radiation Alert 2072", "Plakát: Radiační poplach 2072", "radiation"),
    ("poster_zeds_world", "Poster: Welcome to Zéd's World", "Plakát: Vítejte v Zédově světě", "zedsworld"),
    ("poster_collapse", "Poster: The Collapse", "Plakát: Kolaps", "collapse"),
    ("poster_fortress", "Poster: RadioÚstí Fortress 1472", "Plakát: Pevnost RadioÚstí 1472", "fortress"),
]
for pid, en, cs, k in POSTERS:
    block(pid, en, cs, cat="items", model=("flat_wall",), rot="face", tex={"*": tex(pid, lambda n, kk=k: T.poster(n, kk))},
          render="alpha_test", sound="cloth", hardness=0.3, collision=False, kind="document", meta={"doc": pid}, mapc="#d9cfb3",
          comps=[f"{NS}:readable"])
for i in range(4):
    tex(f"papers_{i}", lambda n, k=i: T.paper(n, k))
block("scattered_papers", "Scattered Papers", "Rozházené papíry", cat="items", model=("flat_floor",),
      tex={"*": "radiousti_papers_0"}, variant_tex={i: f"radiousti_papers_{i}" for i in range(4)}, states={f"{NS}:variant": [0, 1, 2, 3]},
      render="alpha_test", sound="cloth", hardness=0.1, collision=False, kind="document", meta={"doc": "scattered_papers"},
      comps=[f"{NS}:papers"], mapc="#e8e0c8")
block("wall_notice", "Wall Notice", "Nástěnné oznámení", cat="items", model=("flat_wall",), rot="face",
      tex={"*": "radiousti_papers_1"}, render="alpha_test", sound="cloth", hardness=0.2, collision=False, kind="document",
      meta={"doc": "wall_notice"}, comps=[f"{NS}:readable"], mapc="#e8e0c8")
block("document_pile", "Pile of Documents", "Hromada dokumentů", cat="items", model=("doc_pile",),
      tex={"*": "radiousti_papers_2", "detail": "radiousti_papers_0"}, sound="cloth", hardness=0.3, kind="document",
      meta={"doc": "document_pile"}, comps=[f"{NS}:readable"], mapc="#e8e0c8")
block("wall_clock", "Wall Clock", "Nástěnné hodiny", cat="items", model=("clock",), rot="face",
      tex={"*": S["wood_dark"], "screen": S["screen_clock"]}, sound="wood", hardness=0.5, collision=False, kind="clock",
      comps=[f"{NS}:clock"], mapc="#5e4528")
block("photo_frame", "Historical Photograph", "Historická fotografie", cat="items", model=("flat_wall",), rot="face",
      tex={"*": tex("photo_frame", lambda n: (lambda t: (t.rect(2, 2, 12, 12, "#7a7465"), t.rect(4, 6, 3, 8, "#4c473d"), t.rect(9, 4, 4, 10, "#5c574c"),
                                                         t.rect(2, 2, 12, 2, "#9a9483"), t)[-1])(T.Tex(n, base="#5e4528").noise(5)))},
      render="alpha_test", sound="wood", hardness=0.3, collision=False, kind="document", meta={"doc": "photo_frame"},
      comps=[f"{NS}:readable"], mapc="#5e4528")

# ---- laboratory horror --------------------------------------------------------
block("specimen_jar", "Specimen Jar", "Preparátová nádoba", cat="items", model=("jar",),
      tex={"*": S["glass_clear"], "detail": S["steel_dark"], "fill": S["empty_fill"]},
      fill_tex={0: S["empty_fill"], 1: S["blood_fill"], 2: S["flesh_fill"], 3: S["soul_fill"]},
      states={f"{NS}:fill": [0, 1, 2, 3]}, render="blend", sound="glass", hardness=0.5, kind="jar", comps=[f"{NS}:jar"],
      mapc="#cfe8ee")
block("flask_set", "Laboratory Flask Set", "Sada laboratorních baněk", cat="items", model=("flask_set",),
      tex={"*": tex("flask_glass", lambda n: (lambda t: (t.rect(0, 9, 16, 7, "#6fbf4a", 200), t)[-1])(T.Tex(n, base="#cfe8ee", alpha=120)))},
      render="blend", sound="glass", hardness=0.3, collision=False, mapc="#cfe8ee")
block("test_tube_rack", "Test Tube Rack", "Stojan na zkumavky", cat="items", model=("tube_rack",),
      tex={"*": tex("tube_glass", lambda n: (lambda t: (t.rect(0, 8, 16, 8, P["blood"], 220), t)[-1])(T.Tex(n, base="#d6eef2", alpha=130))),
           "detail": S["wood"]}, render="blend", sound="glass", hardness=0.3, collision=False, mapc="#d6eef2")
block("flesh_block", "Flesh Block", "Blok masa", cat="nature", tex={"*": tex("flesh_block", lambda n: T.flesh(n, 0))}, sound="slime",
      hardness=0.8, kind="organic", mapc="#b25a5a")
block("flesh_block_veiny", "Veiny Flesh Block", "Prožilkovaný blok masa", cat="nature", tex={"*": tex("flesh_veiny", lambda n: T.flesh(n, 1))},
      sound="slime", hardness=0.8, kind="organic", mapc="#b25a5a")
block("flesh_block_eyes", "Watching Flesh Block", "Pozorující blok masa", cat="nature", tex={"*": tex("flesh_eyes", lambda n: T.flesh(n, 2))},
      sound="slime", hardness=0.8, kind="organic", mapc="#b25a5a")
block("flesh_growth", "Flesh Growth", "Masový výrůstek", cat="nature", model=("growth",), tex={"*": "radiousti_flesh_veiny"},
      sound="slime", hardness=0.5, kind="organic", mapc="#b25a5a")
block("lab_waste_bin", "Laboratory Waste Bin", "Koš na laboratorní odpad", cat="items", model=("bin",),
      tex={"*": tex("waste_bin", lambda n: (lambda t: (t.rect(5, 5, 6, 6, P["hazard"]), t)[-1])(T.metal(n, "#b3170f"))), "detail": S["steel_dark"]},
      sound="metal", hardness=1, mapc="#b3170f")
block("blood_puddle", "Blood Puddle", "Kaluž krve", cat="nature", model=("flat_floor",),
      tex={"*": tex("blood_puddle", lambda n: (lambda t: (t.blobs([P["blood"], P["blood_d"]], 10, 3), t)[-1])(T.Tex(n, base="#000000", alpha=0)))},
      render="alpha_test", sound="slime", hardness=0.1, collision=False, mapc="#7a0e12")
block("soul_block", "Soul-Infused Stone", "Duší prostoupený kámen", cat="nature", tex={"*": tex("soul_block", lambda n: T.soul(n, 0))},
      light=5, hardness=2, kind="soul", mapc="#2a2338", tags=["stone", "minecraft:is_pickaxe_item_destructible"])
block("soul_crystal", "Soul Crystal", "Krystal duše", cat="nature", model=("crystal",),
      tex={"*": tex("soul_crystal", lambda n: T.Tex(n, base=P["soul"], alpha=220).noise(16))}, render="blend", light=9,
      sound="glass", hardness=1.5, kind="soul", mapc="#5ae3e6")

# ----------------------------------------------------------------- items
ITEMS = []


def item(id, en, cs, icon, cat="items", stack=64, comps=None, kind="item", meta=None, desc_cs="", desc_en=""):
    ITEMS.append(dict(id=id, en=en, cs=cs, icon=icon, cat=cat, stack=stack, comps=comps or {}, kind=kind, meta=meta or {},
                      desc_cs=desc_cs, desc_en=desc_en))


def ic(name, kind, color="#888888"):
    return itex(name, lambda n, k=kind, c=color: T.item(n, k, c))


item("system_analyzer", "RadioÚstí System Analyzer", "Systémový analyzátor RadioÚstí", ic("system_analyzer", "scanner"), cat="equipment", stack=1,
     kind="analyzer", comps={"minecraft:hand_equipped": True})
item("experiment_registry", "Experiment Registry – Projekt Apokalypsa", "Registr experimentů – Projekt Apokalypsa",
     ic("experiment_registry", "book", "#8f1d18"), cat="items", stack=1, kind="registry")
item("handbook", "RadioÚstí Handbook", "Příručka RadioÚstí", ic("handbook", "book", "#5e6f55"), cat="items", stack=1, kind="handbook")
item("realistic_pickaxe", "Realistic Pickaxe", "Realistický krumpáč", ic("realistic_pickaxe", "pickaxe", "#9aa3a8"), cat="equipment", stack=1,
     kind="pickaxe",
     comps={"minecraft:hand_equipped": True, "minecraft:durability": {"max_durability": 900},
            "minecraft:tags": {"tags": ["minecraft:is_pickaxe", "minecraft:iron_tier", "minecraft:is_tool"]},
            "minecraft:enchantable": {"value": 14, "slot": "pickaxe"},
            "minecraft:repairable": {"repair_items": [{"items": ["minecraft:iron_ingot", f"{NS}:uranium_ingot"], "repair_amount": 225}]},
            "minecraft:digger": {"use_efficiency": True, "destroy_speeds": [
                {"block": {"tags": "q.any_tag('radiousti:industrial')"}, "speed": 14},
                {"block": {"tags": "q.any_tag('stone', 'metal', 'minecraft:is_pickaxe_item_destructible')"}, "speed": 5}]}})
item("raw_uranium", "Raw Uranium", "Surový uran", ic("raw_uranium", "raw", "#4fbf3a"), kind="radioactive", meta={"rad": 0.3})
item("uranium_ingot", "Uranium Ingot", "Uranový ingot", ic("uranium_ingot", "ingot", "#5fd14a"), kind="radioactive", meta={"rad": 0.3})
item("uranium_fuel_rod", "Uranium Fuel Rod", "Uranová palivová tyč", ic("uranium_fuel_rod", "rod", "#5fd14a"), stack=4, kind="radioactive", meta={"rad": 0.5})
item("empty_canister", "Empty Canister", "Prázdný kanystr", ic("empty_canister", "canister", "#7c848a"), stack=16)
for key, en, cs, col, pen, pcs in OILS:
    item(f"canister_{key}_oil", f"Canister of {en}", f"Kanystr – {cs.lower()}", ic(f"canister_{key}", "canister", col), stack=16,
         kind="oil", meta={"oil": key, "rad": 0.4 if key == "radioactive" else 0}, desc_en=pen, desc_cs=pcs)
item("gas_canister", "Gas Canister", "Plynová bomba", ic("gas_canister", "gascan", "#c9a227"), stack=16, kind="gas")
item("empty_jar", "Empty Laboratory Jar", "Prázdná laboratorní nádoba", ic("empty_jar", "jar", None))
item("blood_jar", "Blood Jar", "Nádoba s krví", ic("blood_jar", "jar", P["blood"]))
item("blood_bottle", "Blood-Filled Bottle", "Láhev plná krve", ic("blood_bottle", "bottle", P["blood"]))
item("empty_test_tube", "Empty Test Tube", "Prázdná zkumavka", ic("empty_test_tube", "tube", None))
item("blood_sample", "Blood Sample", "Vzorek krve", ic("blood_sample", "tube", P["blood"]))
item("sample_container", "Sample Container", "Vzorkovnice", ic("sample_container", "container", "#3a6aa0"))
item("tissue_sample", "Tissue Sample", "Vzorek tkáně", ic("tissue_sample", "container", P["flesh"]))
item("soil_sample", "Contaminated Soil Sample", "Vzorek kontaminované půdy", ic("soil_sample", "container", "#6f7d2f"), kind="radioactive", meta={"rad": 0.2})
item("empty_flask", "Erlenmeyer Flask", "Erlenmeyerova baňka", ic("empty_flask", "flask", None))
item("reagent_flask_red", "Red Reagent Flask", "Baňka s červeným činidlem", ic("reagent_red", "flask", "#c23b22"))
item("reagent_flask_green", "Green Reagent Flask", "Baňka se zeleným činidlem", ic("reagent_green", "flask", "#5f8f2a"))
item("reagent_flask_blue", "Blue Reagent Flask", "Baňka s modrým činidlem", ic("reagent_blue", "flask", "#2f6d9e"))
item("infected_flesh", "Infected Flesh", "Infikované maso", ic("infected_flesh", "chunk", P["flesh"]))
item("meat_piece", "Piece of Meat", "Kus masa", ic("meat_piece", "meat", "#a84a4a"),
     comps={"minecraft:food": {"nutrition": 3, "saturation_modifier": 0.3, "can_always_eat": False},
            "minecraft:use_animation": "eat", "minecraft:use_modifiers": {"use_duration": 1.6, "movement_modifier": 0.35}})
item("organic_material", "Organic Material", "Organický materiál", ic("organic_material", "chunk", "#7d5a3a"))
item("lab_waste", "Laboratory Waste", "Laboratorní odpad", ic("lab_waste", "waste"))
item("soul_essence", "Soul Essence", "Esence duše", ic("soul_essence", "essence", P["soul"]))
item("anti_radiation_pills", "Anti-Radiation Pills", "Antiradiační tablety", ic("anti_radiation_pills", "pills", "#e0a800"), stack=16, kind="consumable",
     comps={"minecraft:food": {"nutrition": 0, "saturation_modifier": 0, "can_always_eat": True},
            "minecraft:use_animation": "eat", "minecraft:use_modifiers": {"use_duration": 0.8, "movement_modifier": 1.0}})
item("zed_serum", "Zed Antibody Serum", "Sérum s protilátkami Zed", ic("zed_serum", "serum", "#5ae3e6"), stack=16, kind="consumable",
     comps={"minecraft:food": {"nutrition": 0, "saturation_modifier": 0, "can_always_eat": True},
            "minecraft:use_animation": "drink", "minecraft:use_modifiers": {"use_duration": 1.2, "movement_modifier": 0.5}})
item("decontamination_kit", "Decontamination Kit", "Dekontaminační souprava", ic("decontamination_kit", "kit", "#2f8f5a"), stack=1, kind="tool",
     comps={"minecraft:durability": {"max_durability": 32}})
item("gas_mask", "Gas Mask", "Plynová maska", ic("gas_mask", "mask"), cat="equipment", stack=1, kind="armor",
     comps={"minecraft:wearable": {"slot": "slot.armor.head", "protection": 1}, "minecraft:durability": {"max_durability": 200},
            "minecraft:enchantable": {"value": 5, "slot": "armor_head"}})
item("hazmat_suit", "Hazmat Suit", "Ochranný oblek (hazmat)", ic("hazmat_suit", "suit", "#d4b62a"), cat="equipment", stack=1, kind="armor",
     comps={"minecraft:wearable": {"slot": "slot.armor.chest", "protection": 3}, "minecraft:durability": {"max_durability": 300},
            "minecraft:enchantable": {"value": 5, "slot": "armor_torso"}})
DOCS = [
    ("document_lab_report", "Laboratory Report", "Laboratorní zpráva", "#3a6aa0"),
    ("document_evacuation", "Evacuation Order 2072", "Evakuační příkaz 2072", "#b3170f"),
    ("document_research_record", "Research Record", "Záznam z výzkumu", "#5e6f55"),
    ("document_emergency_instructions", "Emergency Instructions", "Pokyny pro případ nouze", "#e0a800"),
    ("document_printout", "Computer Printout", "Počítačový výpis", "#2c5aa0"),
    ("document_contamination_report", "Contamination Report", "Zpráva o kontaminaci", "#6f7d2f"),
]
for did, en, cs, col in DOCS:
    item(did, en, cs, ic(did, "doc", col), stack=16, kind="document")
item("document_bundle", "Document Bundle", "Svazek dokumentů", ic("document_bundle", "bundle", "#8f1d18"), stack=16, kind="document")
item("historical_photo", "Historical Photograph", "Historická fotografie", ic("historical_photo", "photo"), stack=16, kind="document")
item("vhs_radiousti", "VHS Tape: RadioÚstí 2072", "VHS kazeta: RadioÚstí 2072", ic("vhs_radiousti", "vhs", "#b3170f"), stack=1, kind="vhs")


# ----------------------------------------------------------------- placeable glassware (v1.1)
# Each glassware ITEM gets minecraft:block_placer -> its block; the block drops the item back.
S["fill_red"] = tex("fill_red", lambda n: T.Tex(n, base="#c23b22", alpha=225).noise(8))
S["fill_green"] = tex("fill_green", lambda n: T.Tex(n, base="#5f8f2a", alpha=225).noise(8))
S["fill_blue"] = tex("fill_blue", lambda n: T.Tex(n, base="#2f6d9e", alpha=225).noise(8))
S["glass_flask"] = tex("glass_flask", lambda n: T.Tex(n, base="#d6eef2", alpha=95).frame("#a9c8ce", a=150))
GLASSWARE = [
    # block id, item id, en, cs, model, fill texture (None = empty)
    ("flask_empty_block", "empty_flask", "Erlenmeyer Flask (placed)", "Erlenmeyerova baňka (položená)", "erlenmeyer", None),
    ("flask_red_block", "reagent_flask_red", "Red Reagent Flask (placed)", "Baňka s červeným činidlem (položená)", "erlenmeyer", S["fill_red"]),
    ("flask_green_block", "reagent_flask_green", "Green Reagent Flask (placed)", "Baňka se zeleným činidlem (položená)", "round_flask", S["fill_green"]),
    ("flask_blue_block", "reagent_flask_blue", "Blue Reagent Flask (placed)", "Baňka s modrým činidlem (položená)", "round_flask", S["fill_blue"]),
    ("test_tube_block", "empty_test_tube", "Test Tube (placed)", "Zkumavka (položená)", "tube_stand", None),
    ("blood_sample_block", "blood_sample", "Blood Sample (placed)", "Vzorek krve (položený)", "tube_stand", S["blood_fill"]),
    ("blood_bottle_block", "blood_bottle", "Blood-Filled Bottle (placed)", "Láhev plná krve (položená)", "bottle", S["blood_fill"]),
    ("empty_jar_block", "empty_jar", "Empty Laboratory Jar (placed)", "Prázdná laboratorní nádoba (položená)", "jar_small", None),
    ("blood_jar_block", "blood_jar", "Blood Jar (placed)", "Nádoba s krví (položená)", "jar_small", S["blood_fill"]),
]
for bid, iid, en, cs, mdl, fill in GLASSWARE:
    tx = {"*": S["glass_flask"], "detail": S["wood"] if mdl == "tube_stand" else S["brass"], "fill": fill or S["empty_fill"]}
    block(bid, en, cs, cat="none", model=(mdl, fill is not None), tex=tx, render="blend", sound="glass", hardness=0.2,
          resist=0.5, kind="glassware", meta={"item": f"{NS}:{iid}"}, loot=f"loot_tables/blocks/glassware/{bid}.json",
          collision="auto", mapc="#d6eef2")
    for it in ITEMS:
        if it["id"] == iid:
            it["comps"]["minecraft:block_placer"] = {"block": f"{NS}:{bid}"}


# ----------------------------------------------------------------- Liverocrystal & biogenic serum (v1.3)
LC = "#2d8fd6"
tex("lc_ore", lambda n: T.Tex(n, base=P["stone"]).noise(14).blobs([LC, "#8fdcff", "#1b5c99"], 6, 2))
tex("lc_crystal", lambda n: T.Tex(n, base="#3aa7f0", alpha=225).noise(18).speckle(["#d6f3ff", "#1b5c99"], 18))
tex("lc_metal", lambda n: (lambda t: (t.speckle(["#9fe0ff"], 10), t)[-1])(T.metal(n, "#3f6f99")))
tex("lc_armor", lambda n: (lambda t: (t.rect(3, 3, 10, 10, "#2f5577"), t.frame("#16283a", 2), t.rivets("#bfe8ff", 1), t.rivets("#bfe8ff", 4), t)[-1])(T.metal(n, "#355f86")))
tex("lc_gas_tank", lambda n: (lambda t: (t.rect(0, 6, 16, 3, P["hazard"]), t.rect(3, 6, 2, 3, P["black"]), t.rect(9, 6, 2, 3, P["black"]), t)[-1])(T.metal(n, "#2a78bf")))
tex("serum_fill", lambda n: T.Tex(n, base="#d36fa8", alpha=215).noise(10).speckle(["#9be86a", "#f2b6d6"], 14))
block("liverocrystal_ore", "Liverocrystal Ore", "Liverocrystalová ruda", cat="nature", tex={"*": "radiousti_lc_ore"}, light=4,
      hardness=4, resist=6, kind="toxic", meta={"toxic": 1}, loot="loot_tables/blocks/liverocrystal_ore.json",
      tags=["stone", "minecraft:is_pickaxe_item_destructible"], mapc="#2d8fd6")
block("liverocrystal_cluster", "Liverocrystal Cluster", "Shluk Liverocrystalu", cat="nature", model=("crystal",),
      tex={"*": "radiousti_lc_crystal"}, render="blend", light=9, sound="glass", hardness=1.5, kind="toxic", meta={"toxic": 1},
      mapc="#3aa7f0")
block("liverocrystal_metal_block", "Block of Liverocrystal Metal", "Blok Liverocrystal Metal", tex={"*": "radiousti_lc_metal"},
      sound="metal", hardness=8, resist=60, mapc="#3f6f99", tags=["metal", "radiousti:industrial", "minecraft:is_pickaxe_item_destructible"])
block("liverocrystal_armor_plate", "Liverocrystal Armour Plate", "Pancéřová deska z Liverocrystal Metal", tex={"*": "radiousti_lc_armor"},
      sound="metal", hardness=15, resist=1200, mapc="#355f86", tags=["metal", "minecraft:is_pickaxe_item_destructible"])
block("liverocrystal_gas_tank", "Liverocrystal Gas Tank (Blue Gasoline)", "Nádrž Liverocrystal Gas (Blue Gasoline)", cat="equipment",
      model=("tank",), rot="cardinal", tex={"*": "radiousti_lc_gas_tank", "detail": S["steel_dark"], "screen": S["screen_gauge"]},
      light=3, sound="metal", hardness=3, kind="machine", meta={"role": "tank", "family": "gas", "capacity": 3000, "demand": 0, "toxic": 2},
      mapc="#2a78bf", tags=["metal", "radiousti:industrial"])
block("biogenic_serum_vat", "Biogenic Serum Vat", "Kádě s biogenním sérem", cat="equipment", model=("vat",),
      tex={"*": S["glass_flask"], "detail": S["steel_dark"], "fill": "radiousti_serum_fill"}, render="blend", light=5, sound="glass",
      hardness=2, mapc="#d36fa8")
item("liverocrystal_shard", "Liverocrystal Shard", "Úlomek Liverocrystalu", ic("liverocrystal_shard", "essence", LC), kind="toxic", meta={"toxic": 0.3})
item("liverocrystal_metal_ingot", "Liverocrystal Metal Ingot", "Ingot Liverocrystal Metal", ic("liverocrystal_metal_ingot", "ingot", "#3f6f99"))
item("liverocrystal_gas_canister", "Liverocrystal Gas Canister", "Kanystr Liverocrystal Gas", ic("liverocrystal_gas_canister", "gascan", LC), stack=16, kind="gas")
item("biogenic_serum", "Biogenic Serum (B-9)", "Biogenní sérum (B-9)", ic("biogenic_serum", "serum", "#d36fa8"), stack=16, kind="consumable",
     comps={"minecraft:food": {"nutrition": 0, "saturation_modifier": 0, "can_always_eat": True},
            "minecraft:use_animation": "drink", "minecraft:use_modifiers": {"use_duration": 1.2, "movement_modifier": 0.5}})
block("serum_vial_block", "Biogenic Serum Vial (placed)", "Ampule biogenního séra (položená)", cat="none", model=("tube_stand", True),
      tex={"*": S["glass_flask"], "detail": S["steel_dark"], "fill": "radiousti_serum_fill"}, render="blend", sound="glass", hardness=0.2,
      resist=0.5, kind="glassware", meta={"item": f"{NS}:biogenic_serum"}, loot="loot_tables/blocks/glassware/serum_vial_block.json", mapc="#d36fa8")
for it in ITEMS:
    if it["id"] == "biogenic_serum":
        it["comps"]["minecraft:block_placer"] = {"block": f"{NS}:serum_vial_block"}

# ----------------------------------------------------------------- pseudo-liquids (v1.3)
# Bedrock add-ons cannot define real fluids; these are script-flowing blocks with 5 surface levels.
LIQUIDS = [
    # key, en, cs, colour, alpha, light, effect, rad
    ("blood", "Blood", "Krev", "#7a0e12", 230, 0, "nausea", 0),
    ("industrial_oil", "Industrial Oil", "Průmyslový olej", "#c08a2a", 220, 0, "slowness", 0),
    ("black_oil", "Black Machine Oil", "Černý strojní olej", "#151515", 245, 0, "blindness", 0),
    ("hydraulic_oil", "Hydraulic Oil", "Hydraulický olej", "#e3c52a", 215, 0, "slowness", 0),
    ("lab_oil", "Laboratory Oil", "Laboratorní olej", "#b3241c", 220, 0, "weakness", 0),
    ("contaminated_oil", "Contaminated Oil", "Kontaminovaný olej", "#5f8f2a", 220, 3, "poison", 0),
    ("radioactive_oil", "Radioactive Oil", "Radioaktivní olej", "#7dff3a", 210, 8, "radiation", 2),
    ("radioactive_sludge", "Radioactive Sludge", "Radioaktivní kal", "#4f6b1f", 235, 5, "radiation", 3),
    ("liverocrystal_gas", "Liquid Liverocrystal (Blue Gasoline)", "Tekutý Liverocrystal (Blue Gasoline)", "#2d8fd6", 200, 9, "liverocrystal", 0),
]
for key, en, cs, col, al, lt, eff, rad in LIQUIDS:
    t = tex(f"liquid_{key}", lambda n, c=col, a=al: T.Tex(n, base=c, alpha=a).noise(10).speckle(["#ffffff"], 3))
    meta = {"liquid": key, "effect": eff, "bucket": f"{NS}:{key}_bucket"}
    if rad:
        meta["rad"] = rad
    block(f"{key}_liquid", en, cs, cat="none", model=("liquid_levels",), tex={"*": t}, render="blend", light=lt, sound="slime",
          hardness=100, resist=100, kind="liquid", meta=meta, states={f"{NS}:level": [0, 1, 2, 3, 4]}, collision=False,
          comps=[f"{NS}:liquid"], tick=(10, 10), loot="empty", mapc=col)
    item(f"{key}_bucket", f"Bucket of {en}", f"Kbelík – {cs.lower()}", ic(f"{key}_bucket", "bucket", col), stack=1, kind="liquid_bucket",
         meta={"liquid": f"{NS}:{key}_liquid"})


# ----------------------------------------------------------------- locations (v1.4)
# Pennov Theater, CWT, School, Canteen (Jídelna), Showers; RadioÚstí Laboratory, Fortress, Nuclear Power Plant
VEL = tex("velvet_red", lambda n: (lambda t: ([t.vline(x, "#5a0f14") for x in (3, 8, 13)], t)[-1])(T.Tex(n, base="#8f1d24").noise(8)))
VEL_D = tex("velvet_dusty", lambda n: (lambda t: ([t.vline(x, "#3f1a14") for x in (3, 8, 13)], t.speckle(["#7a7a5a", "#9a9a7a"], 18), t)[-1])(T.Tex(n, base="#6e2a22").noise(10)))
GOLD = tex("theater_gold", lambda n: T.Tex(n, base="#b08d3a").noise(10).frame("#6e5520"))
CRYS = tex("blue_crystal_residue", lambda n: (lambda t: (t.blobs(["#2d8fd6", "#8fdcff", "#1b5c99"], 9, 2), t)[-1])(T.Tex(n, base="#000000", alpha=0)))
STATIC = tex("tv_static", lambda n: T.Tex(n, base="#7a7a7a").noise(70))
TILE_W = tex("tiles_white", lambda n: (lambda t: ([t.hline(y, "#b9c0c0") for y in (0, 4, 8, 12)], [t.vline(x, "#b9c0c0") for x in (0, 4, 8, 12)], t)[-1])(T.Tex(n, base="#e8eeee").noise(3)))
TILE_D = tex("tiles_dirty", lambda n: (lambda t: ([t.hline(y, "#8a8f80") for y in (0, 4, 8, 12)], [t.vline(x, "#8a8f80") for x in (0, 4, 8, 12)],
                                                  t.blobs(["#7a6a3a", "#5f6a3a", "#8a3a2a"], 7, 2), t)[-1])(T.Tex(n, base="#c9cfc4").noise(8)))
TILE_B = tex("tiles_blue", lambda n: (lambda t: ([t.hline(y, "#2f5f7a") for y in (0, 8)], [t.vline(x, "#2f5f7a") for x in (0, 8)], t)[-1])(T.Tex(n, base="#5f9ab8").noise(5)))
CHALK = tex("chalkboard", lambda n: (lambda t: (t.rect(2, 3, 9, 1, "#e6e6dc"), t.rect(2, 6, 6, 1, "#e6e6dc"), t.rect(2, 9, 11, 1, "#e6e6dc"), t.text("ABC", 2, 11, "#d8d8cc"), t)[-1])(T.Tex(n, base="#243a2c").noise(5)))
LEAD = tex("lead_wall", lambda n: (lambda t: (t.rect(0, 7, 16, 2, "#3a3e44"), t)[-1])(T.metal(n, "#585e66", rivet=True)))
HERM = tex("hermetic_glass", lambda n: (lambda t: (t.frame("#3a3e44", 2), t.rect(7, 2, 2, 12, "#3a3e44"), t.rect(5, 5, 6, 6, "#e0a800", 60), t)[-1])(T.Tex(n, base="#8fd0c0", alpha=110)))
TOWER = tex("cooling_tower_concrete", lambda n: (lambda t: ([t.hline(y, "#7d7a72") for y in (3, 7, 11, 15)], t.blobs(["#6a7a4a"], 3, 2), t)[-1])(T.concrete(n, "#a39f96", cracks=True)))
FLOOR_W = tex("npp_floor_warning", lambda n: (lambda t: (t.rect(0, 0, 16, 4, P["hazard"]), t.rect(3, 0, 3, 4, P["black"]), t.rect(11, 0, 3, 4, P["black"]), t)[-1])(T.concrete(n, "#7f7c75", cracks=False)))
MESH = tex("chainlink", lambda n: (lambda t: ([t.px(x, (x + k) % 16, "#9aa3a8") for k in range(0, 16, 4) for x in range(16)],
                                               [t.px(x, (k - x) % 16, "#9aa3a8") for k in range(0, 16, 4) for x in range(16)], t)[-1])(T.Tex(n, base="#000000", alpha=0)))
FOOD = tex("canteen_food", lambda n: T.Tex(n, base="#c9a26a").noise(18).speckle(["#e8d8a0", "#7a5a2a", "#8aa04a"], 14))
GOODS = tex("shop_goods", lambda n: (lambda t: (t.rect(0, 0, 8, 8, "#c23b22"), t.rect(8, 0, 8, 8, "#2f6d9e"), t.rect(0, 8, 8, 8, "#e0a800"), t.rect(8, 8, 8, 8, "#5f8f2a"), t)[-1])(T.Tex(n, base="#888888")))
TRAY = tex("tray_metal", lambda n: T.Tex(n, base="#aab1b5").noise(5).frame("#7c848a"))

LOC = [
    # id, en, cs, model, rot, tex, extra
    ("theater_seat", "Theater Seat", "Divadelní sedadlo", ("theater_seat",), "cardinal", {"*": VEL, "detail": GOLD}, dict(sound="cloth")),
    ("theater_seat_dusty", "Dusty Theater Seat", "Zaprášené divadelní sedadlo", ("theater_seat",), "cardinal", {"*": VEL_D, "detail": S["steel_rusty"]}, dict(sound="cloth")),
    ("stage_curtain", "Stage Curtain", "Jevištní opona", ("curtain",), "cardinal", {"*": VEL, "detail": GOLD}, dict(sound="cloth", collision=False)),
    ("stage_spotlight", "Stage Spotlight", "Jevištní reflektor", ("spotlight",), "cardinal",
     {"*": S["steel_dark"], "detail": S["steel"], "glow": S["glow_off"]}, dict(kind="light", tex_lit={"glow": S["glow_warm"]}, light_lit=15,
                                                                              states={f"{NS}:lit": [False, True]}, comps=[f"{NS}:light_switch"], cat="items")),
    ("blue_crystal_residue", "Blue Crystal Residue", "Modré krystalické usazeniny", ("flat_floor",), None, {"*": CRYS},
     dict(render="alpha_test", collision=False, light=4, cat="nature", sound="glass")),
    ("crt_tv", "CWT Television", "Televizor CWT", ("crt_tv",), "cardinal", {"*": S["wood_dark"], "detail": S["steel_dark"], "screen": S["screen_off"]},
     dict(kind="light", tex_lit={"screen": STATIC}, light_lit=6, states={f"{NS}:lit": [False, True]}, comps=[f"{NS}:light_switch"], cat="items")),
    ("broadcast_antenna", "CWT Broadcast Antenna", "Vysílací anténa CWT", ("antenna",), "cardinal",
     {"*": S["steel"], "detail": S["steel_dark"], "glow": S["glow_red"]}, dict(light=6, collision=False, sound="metal")),
    ("shop_shelf", "CWT Shop Shelf", "Regál obchodního domu CWT", ("shop_shelf",), "cardinal", {"*": S["steel"], "detail": S["cabinet_beige"], "goods": GOODS}, dict(sound="metal")),
    ("cash_register", "Cash Register", "Pokladna", ("cash_register",), "cardinal", {"*": S["cabinet_beige"], "detail": S["steel_dark"], "keys": S["keys"], "screen": S["screen_terminal"]}, dict(sound="metal")),
    ("school_desk", "School Desk", "Školní lavice", ("school_desk",), "cardinal", {"*": S["wood"], "detail": S["steel"]}, dict(sound="wood")),
    ("chalkboard", "Chalkboard", "Školní tabule", ("chalkboard",), "face", {"*": S["wood_dark"], "detail": S["wood"], "screen": CHALK},
     dict(sound="wood", collision=False, comps=[f"{NS}:readable"], kind="document", meta={"doc": "chalkboard"})),
    ("canteen_table", "Canteen Table", "Jídelní stůl s lavicemi", ("canteen_table",), "cardinal", {"*": S["lab_top"], "detail": S["steel"]}, dict(sound="metal")),
    ("lunch_tray", "Lunch Tray", "Tác s jídlem", ("lunch_tray",), "cardinal", {"*": TRAY, "detail": S["steel"], "fill": FOOD}, dict(sound="metal", collision=False)),
    ("serving_counter", "Serving Counter", "Výdejní pult", ("serving_counter",), "cardinal",
     {"*": S["steel"], "detail": S["steel_dark"], "glass": S["glass_solid"], "fill": FOOD}, dict(sound="metal")),
    ("kitchen_pot", "Kitchen Pot", "Kuchyňský kotel", ("kitchen_pot",), None, {"*": S["steel"], "detail": S["steel_dark"], "fill": FOOD}, dict(sound="metal")),
    ("shower_tiles", "Shower Tiles", "Obklad sprch", None, None, {"*": TILE_W}, dict()),
    ("shower_tiles_dirty", "Dirty Shower Tiles", "Špinavý obklad sprch", None, None, {"*": TILE_D}, dict()),
    ("shower_tiles_blue", "Blue Tiles", "Modrý obklad", None, None, {"*": TILE_B}, dict()),
    ("shower_head", "Shower", "Sprcha", ("shower_head",), "cardinal", {"*": S["steel"], "detail": S["steel"], "glow": S["steel_dark"]},
     dict(kind="light", tex_lit={"glow": S["glow_cold"]}, states={f"{NS}:lit": [False, True]}, comps=[f"{NS}:light_switch", f"{NS}:shower"], tick=(10, 10),
          collision=False, sound="metal", cat="items")),
    ("floor_drain", "Floor Drain", "Podlahová vpust", ("floor_drain",), None, {"*": S["steel_dark"], "detail": S["steel"]}, dict(collision=False, sound="metal")),
    ("lead_wall", "Lead-Lined Wall", "Olověná stěna", None, None, {"*": LEAD}, dict(sound="metal", hardness=5, resist=40, tags=["metal", "radiousti:industrial"])),
    ("hermetic_glass", "Hermetic Chamber Glass", "Sklo hermetické komory", ("full_clear",), None, {"*": HERM}, dict(render="blend", sound="glass", hardness=3, resist=30)),
    ("lab_sink", "Laboratory Sink", "Laboratorní dřez", ("lab_sink",), "cardinal", {"*": S["cabinet_beige"], "detail": S["steel"]}, dict(sound="metal")),
    ("fortress_brazier", "Fortress Brazier", "Ohniště pevnosti", ("brazier",), None, {"*": S["steel_dark"], "detail": S["steel_rusty"], "glow": S["glow_orange"]},
     dict(light=14, comps=[f"{NS}:brazier"], tick=(20, 20), sound="metal")),
    ("fortress_pillar", "Fortress Pillar", "Sloup pevnosti", ("pillar",), None, {"*": "radiousti_fortress_stone"}, dict(tags=["stone", "minecraft:is_pickaxe_item_destructible"])),
    ("cooling_tower_concrete", "Cooling Tower Concrete", "Beton chladicí věže", None, None, {"*": TOWER}, dict(tags=["stone", "radiousti:industrial", "minecraft:is_pickaxe_item_destructible"])),
    ("npp_floor_warning", "Power Plant Warning Floor", "Výstražná podlaha elektrárny", None, None, {"*": FLOOR_W}, dict(tags=["stone", "radiousti:industrial"])),
    ("chainlink_fence", "Chain-Link Fence", "Pletivový plot", ("chainlink",), "cardinal", {"*": MESH, "detail": S["steel"]}, dict(render="alpha_test", sound="metal")),
    ("steam_vent", "Steam Vent", "Výpusť páry", ("steam_vent",), None, {"*": S["steel_rusty"], "detail": S["steel_dark"], "glow": S["glow_off"]},
     dict(comps=[f"{NS}:steam_vent"], tick=(15, 15), sound="metal")),
    ("control_console", "Control Room Console", "Pult velínu", ("console",), "cardinal", {"*": S["cabinet_beige"], "detail": S["steel_dark"], "screen": S["screen_dial"], "keys": S["keys"]}, dict(sound="metal")),
]
for lid, en, cs, mdl, rot, tx, ex in LOC:
    kw = dict(cat="construction", model=mdl, rot=rot, tex=tx, hardness=1.5, mapc="#8d8a82")
    kw.update(ex)
    block(lid, en, cs, **kw)


# ----------------------------------------------------------------- 3D ore models (v1.4)
tex("uranium_crystal", lambda n: T.Tex(n, base="#5fd14a", alpha=255).noise(18).speckle(["#c8ffb0", "#2a6a20"], 16))
tex("lc_crystal_solid", lambda n: T.Tex(n, base="#3aa7f0").noise(18).speckle(["#d6f3ff", "#1b5c99"], 16))
tex("stone_plain", lambda n: T.Tex(n, base=P["stone"]).noise(14))
tex("deepslate_plain", lambda n: T.Tex(n, base="#4a4a50").noise(12).speckle(["#3a3a40"], 20))
for b in BLOCKS:
    if b["id"] in ("uranium_ore", "deepslate_uranium_ore", "liverocrystal_ore"):
        stone = "radiousti_deepslate_plain" if b["id"].startswith("deepslate") else "radiousti_stone_plain"
        crystal = "radiousti_lc_crystal_solid" if b["id"].startswith("liverocrystal") else "radiousti_uranium_crystal"
        b["model"] = ("ore", {"uranium_ore": 3, "deepslate_uranium_ore": 7, "liverocrystal_ore": 11}[b["id"]])
        b["tex"] = {"*": stone, "crystal": crystal}
        b["collision"] = "full"


# ----------------------------------------------------------------- v1.6: full hazmat set, spreading contamination
item("hazmat_pants", "Hazmat Trousers", "Kalhoty ochranného obleku", ic("hazmat_pants", "suit", "#c9aa2a"), cat="equipment", stack=1, kind="armor",
     comps={"minecraft:wearable": {"slot": "slot.armor.legs", "protection": 2}, "minecraft:durability": {"max_durability": 300},
            "minecraft:enchantable": {"value": 5, "slot": "armor_legs"}})
item("hazmat_boots", "Hazmat Boots", "Boty ochranného obleku", ic("hazmat_boots", "bucket", "#2b2b2b"), cat="equipment", stack=1, kind="armor",
     comps={"minecraft:wearable": {"slot": "slot.armor.feet", "protection": 1}, "minecraft:durability": {"max_durability": 300},
            "minecraft:enchantable": {"value": 5, "slot": "armor_feet"}})
for b in BLOCKS:
    if b["id"] in ("contaminated_grass", "contaminated_dirt", "contaminated_stone"):
        b["comps"] = list(b["comps"]) + [f"{NS}:contamination_spread"]
        b["tick"] = (1200, 2400)
    if b["id"] == "liverocrystal_gas_liquid":
        b["meta"]["toxic"] = 2


# ----------------------------------------------------------------- v1.7: security, barricades, curtains, Zed infection
STRIPS = tex("decon_strips", lambda n: (lambda t: ([t.vline(x, "#9fc4c9") for x in (0, 4, 8, 12)], t)[-1])(T.Tex(n, base="#cfe8ee", alpha=150).noise(4)))
SHUT = tex("security_shutter", lambda n: (lambda t: ([t.hline(y, "#3a3f43") for y in (3, 7, 11, 15)], t.rect(0, 0, 16, 2, P["hazard"]), t)[-1])(T.metal(n, "#6c747a", rivet=False)))
BARD_TOP = tex("barricaded_door_top", lambda n: (lambda t: (t.rect(0, 3, 16, 3, "#6b4d2a"), t.rect(0, 10, 16, 3, "#6b4d2a"), t.rect(2, 1, 12, 1, "#2a2a2a"), t)[-1])(T.wood(n, "#4a3a28")))
BARD_BOT = tex("barricaded_door_bottom", lambda n: (lambda t: (t.rect(0, 2, 16, 3, "#6b4d2a"), t.rect(0, 9, 16, 3, "#6b4d2a"), t.rect(5, 0, 3, 16, "#5a4024"), t.rect(12, 7, 2, 2, "#c0c7cc"), t)[-1])(T.wood(n, "#4a3a28")))
for did, en, cs, style, tx, txu, extra in (
        ("security_door", "Security Shutter Door", "Bezpečnostní roletové dveře", "shutter", SHUT, SHUT,
         dict(meta={"security": True}, resist=60, hardness=8)),
        ("decontamination_curtain", "Decontamination Curtain", "Dekontaminační plášť", "curtain", STRIPS, STRIPS,
         dict(meta={"decon": True}, render="blend", collision=False, sound="cloth", hardness=1)),
        ("barricaded_door", "Barricaded Door", "Zabarikádované dveře", "swing", BARD_BOT, BARD_TOP,
         dict(meta={"barricaded": True, "security": True}, resist=80, hardness=10, sound="wood"))):
    kw = dict(cat="construction", model=("door",), rot="cardinal", tex={"*": tx, "detail": S["steel_dark"]}, tex_upper={"*": txu},
              states={f"{NS}:upper": [False, True], f"{NS}:open": [False, True]}, sound="metal", hardness=3, resist=10,
              kind="door", comps=[f"{NS}:door"], loot="empty", mapc="#6c747a", placer_icon=("door_icon", "#6c747a"), door_style=style)
    kw.update(extra)
    kw["meta"] = {**kw["meta"]}
    block(did, en, cs, **kw)
block("window_barricade", "Window Barricade", "Okenní barikáda", cat="construction", model=("window_barricade",), rot="face",
      tex={"*": "radiousti_burnt_planks", "detail": S["wood"]}, sound="wood", hardness=2, resist=20, kind="barricade",
      tags=["wood"], mapc="#5e4528")
block("security_camera", "Security Camera", "Bezpečnostní kamera", cat="items", model=("security_camera",), rot="face",
      tex={"*": S["cabinet_beige"], "detail": S["steel_dark"], "glow": S["glow_red"]}, sound="metal", hardness=1.5, kind="camera",
      comps=[f"{NS}:camera"], collision=False, light=2, mapc="#cbc3a8")
block("door_control_button", "Door Control Button", "Tlačítko ovládání dveří", cat="items", model=("door_button",), rot="face",
      tex={"*": S["steel"], "detail": S["steel_dark"], "glow": S["glow_green"]}, sound="metal", hardness=1, kind="control",
      comps=[f"{NS}:door_button"], collision=False, mapc="#7c848a")
item("security_tablet", "Security Tablet", "Bezpečnostní tablet", ic("security_tablet", "scanner"), cat="equipment", stack=1, kind="tablet",
     comps={"minecraft:hand_equipped": False})
