"""Crafting, workbench and furnace recipes for RadioÚstí.

Tables:  CT = vanilla crafting table, IW = Industrial Workbench (radiousti_industrial),
         LT = Laboratory Table (radiousti_lab).
Machine-processing (lab stations) is script driven - see scripts/systems/lab.js.
"""
COUNT = [0]
RECIPES = []

CT, IW, LT = "crafting_table", "radiousti_industrial", "radiousti_lab"


def _i(x):
    if x.startswith("#"):
        return {"tag": x[1:]}
    if ":" not in x:
        x = "radiousti:" + x
    return {"item": x}


def shaped(out, pattern, key, n=1, table=CT):
    RECIPES.append(("shaped", out, pattern, key, n, table))


def shapeless(out, ings, n=1, table=CT):
    RECIPES.append(("shapeless", out, ings, None, n, table))


def furnace(inp, out):
    RECIPES.append(("furnace", out, inp, None, 1, None))


M = "minecraft:"
IRON, COPPER, RS, GLASS, PANE = M + "iron_ingot", M + "copper_ingot", M + "redstone", M + "glass", M + "glass_pane"
NUG, COAL, PLANK, STICK = M + "iron_nugget", "#minecraft:coals", "#minecraft:planks", M + "stick"
CEM = "cement_block"

# --- basic tools & materials (vanilla crafting table)
shaped("system_analyzer", [" R ", "IPI", "ICI"], {"R": RS, "I": IRON, "P": PANE, "C": COPPER})
shapeless("handbook", [M + "book", M + "yellow_dye"])
shapeless("experiment_registry", [M + "book", M + "red_dye", M + "ink_sac"])
shaped("realistic_pickaxe", ["ICI", " S ", " S "], {"I": IRON, "C": COPPER, "S": STICK})
shaped("industrial_workbench", ["III", "CTC", "P P"], {"I": IRON, "C": COPPER, "T": M + "crafting_table", "P": PLANK})
shaped("lab_table", ["WWW", "ITI", "I I"], {"W": M + "white_concrete", "I": IRON, "T": M + "crafting_table"})
shaped("empty_canister", [" I ", "I I", "III"], {"I": IRON}, 2)
shaped(CEM, ["SG", "GS"], {"S": M + "sand", "G": M + "gravel"}, 4)
shapeless("yellow_old_cement", [CEM, M + "yellow_dye"])
shapeless("old_brick", [M + "brick_block", M + "gravel"])
shaped("old_brick_wall", ["OOO", "OOO"], {"O": "old_brick"}, 6)
shapeless("czechoslovak_industrial_wall", [CEM, M + "green_dye"], 1)
shaped("house_block", ["CCC", "CPC", "CCC"], {"C": CEM, "P": PANE}, 8)
shaped("old_glass", ["GG", "GG"], {"G": GLASS}, 4)
shapeless("help_glass", ["old_glass", M + "red_dye"])
shapeless("castle_bars", [M + "iron_bars", M + "cobblestone"], 2)
shapeless("storage_boxes", [M + "chest", PLANK])
shaped("old_light_block", ["IGI", "GLG", "IGI"], {"I": NUG, "G": GLASS, "L": M + "glowstone"}, 2)
shapeless("warning_stripes", [CEM, M + "yellow_dye", M + "black_dye"], 2)
shapeless("blood_stained_concrete", [CEM, "blood_bottle"], 2)
shapeless("burnt_planks", [PLANK, COAL])
shaped("fortress_stone", ["SS", "SS"], {"S": M + "stone_bricks"}, 4)
shapeless("fortress_stone_cracked", ["fortress_stone", M + "gravel"])
shapeless("fortress_stone_mossy", ["fortress_stone", M + "vine"])
shapeless("castle_side", ["fortress_stone", M + "iron_bars"])
shaped("fortress_battlement", ["S S", "SSS"], {"S": "fortress_stone"}, 4)
shaped("barricade", ["PSP", "PSP"], {"P": PLANK, "S": STICK}, 2)
shaped("barbed_wire", ["N N", " N ", "N N"], {"N": NUG}, 3)
shaped("sandbags", ["LSL"], {"L": M + "leather", "S": M + "sand"}, 2)
shaped("wooden_spikes", ["S S", "SPS"], {"S": STICK, "P": PLANK}, 2)
shapeless("rubble", [M + "gravel", M + "cobblestone", CEM], 3)
shaped("uranium_block", ["UUU", "UUU", "UUU"], {"U": "uranium_ingot"})
shapeless("uranium_ingot", ["uranium_block"], 9)
shaped("raw_uranium_block", ["UUU", "UUU", "UUU"], {"U": "raw_uranium"})
shapeless("raw_uranium", ["raw_uranium_block"], 9)
shaped("radiation_sign", ["YBY"], {"Y": M + "yellow_dye", "B": M + "black_dye"}, 1)
shapeless("biohazard_sign", ["radiation_sign", M + "red_dye"])
shapeless("zed_warning_sign", ["radiation_sign", "infected_flesh"])
shaped("gas_mask", ["LIL", "GSG", " C "], {"L": M + "leather", "I": IRON, "G": PANE, "S": M + "string", "C": M + "charcoal"})
shaped("hazmat_suit", ["Y Y", "YIY", "YYY"], {"Y": M + "yellow_wool", "I": IRON})
shapeless("decontamination_kit", [IRON, "reagent_flask_green", M + "white_wool"])

# --- documents, posters, clock
for poster, dye in (("poster_outbreak_2072", "red_dye"), ("poster_evacuation", "yellow_dye"), ("poster_radiation", "lime_dye"),
                    ("poster_zeds_world", "green_dye"), ("poster_collapse", "gray_dye"), ("poster_fortress", "light_blue_dye")):
    shapeless(poster, [M + "paper", M + "paper", M + dye, M + "black_dye"])
shapeless("scattered_papers", [M + "paper", M + "paper"], 2)
shapeless("wall_notice", [M + "paper", M + "black_dye", NUG])
shapeless("document_pile", [M + "paper", M + "paper", M + "paper", M + "book"])
shapeless("wall_clock", [M + "clock", PLANK])
shapeless("photo_frame", ["historical_photo", M + "frame"])
shapeless("historical_photo", [M + "paper", M + "ink_sac", M + "gray_dye"])
for doc, dye in (("document_lab_report", "blue_dye"), ("document_evacuation", "red_dye"), ("document_research_record", "green_dye"),
                 ("document_emergency_instructions", "yellow_dye"), ("document_printout", "light_blue_dye"),
                 ("document_contamination_report", "lime_dye")):
    shapeless(doc, [M + "paper", M + "ink_sac", M + dye])
shapeless("document_bundle", ["document_lab_report", "document_research_record", "document_printout", M + "string"])

# --- furniture & hospital
shaped("wooden_table", ["PPP", "S S"], {"P": PLANK, "S": STICK}, 2)
shaped("metal_table", ["III", "N N"], {"I": IRON, "N": NUG}, 2)
shaped("office_desk", ["PPP", "C P"], {"P": PLANK, "C": M + "chest"})
shaped("wooden_chair", ["P  ", "PPP", "S S"], {"P": PLANK, "S": STICK}, 2)
shaped("metal_chair", ["N  ", "NNN", "N N"], {"N": NUG}, 2)
shaped("office_chair", [" W ", "WWW", " I "], {"W": M + "black_wool", "I": IRON})
shaped("lab_chair", ["WWW", " I ", "NIN"], {"W": M + "blue_wool", "I": IRON, "N": NUG})
shaped("hospital_bed", ["WWW", "III"], {"W": M + "white_wool", "I": IRON})
shaped("operating_table", ["GGG", "III", "I I"], {"G": M + "green_wool", "I": IRON})
shaped("exam_table", ["GG", "II"], {"G": M + "green_wool", "I": IRON})
shaped("iv_stand", ["NBN", " I ", "NIN"], {"N": NUG, "B": M + "glass_bottle", "I": IRON})
shaped("medical_monitor", ["IPI", "IRI", " I "], {"I": IRON, "P": PANE, "R": RS})
shaped("medical_cabinet", ["III", "IRI", "III"], {"I": IRON, "R": M + "red_dye"})
shaped("filing_cabinet", ["III", "PPP", "III"], {"I": IRON, "P": M + "paper"})
shaped("locker", ["II", "II", "II"], {"I": IRON})
shaped("medical_container", ["IRI", "ICI"], {"I": IRON, "R": M + "red_dye", "C": M + "chest"})

# --- laboratory glassware (Laboratory Table)
shaped("empty_jar", ["G G", "G G", "GGG"], {"G": GLASS}, 3, LT)
shaped("empty_test_tube", ["G", "G", "G"], {"G": GLASS}, 4, LT)
shaped("empty_flask", [" G ", "G G", "GGG"], {"G": GLASS}, 2, LT)
shaped("sample_container", ["NGN", "G G", "GGG"], {"N": NUG, "G": GLASS}, 4, LT)
shapeless("reagent_flask_red", ["empty_flask", M + "red_dye", RS], 1, LT)
shapeless("reagent_flask_green", ["empty_flask", M + "green_dye", M + "slime_ball"], 1, LT)
shapeless("reagent_flask_blue", ["empty_flask", M + "lapis_lazuli", M + "sugar"], 1, LT)
shapeless("blood_jar", ["empty_jar", "blood_bottle", "blood_bottle"], 1, LT)
shapeless("specimen_jar", ["empty_jar", NUG], 1, LT)
shapeless("flask_set", ["empty_flask", "empty_flask", "empty_flask"], 1, LT)
shaped("test_tube_rack", ["TTT", "PPP"], {"T": "empty_test_tube", "P": PLANK}, 1, LT)
shapeless("soul_essence", [M + "soul_sand", "empty_flask"], 1, LT)
shapeless("soul_essence", [M + "soul_soil", "empty_flask"], 1, LT)
shapeless("soul_block", [M + "stone", "soul_essence"], 2, LT)
shapeless("soul_crystal", ["soul_essence", "soul_essence", M + "amethyst_shard"], 1, LT)
shaped("flesh_block", ["FFF", "FFF", "FFF"], {"F": "infected_flesh"}, 1, LT)
shapeless("infected_flesh", ["flesh_block"], 9, LT)
shapeless("flesh_block_veiny", ["flesh_block", "blood_bottle"], 1, LT)
shapeless("flesh_block_eyes", ["flesh_block", M + "spider_eye", M + "spider_eye"], 1, LT)
shapeless("flesh_growth", ["flesh_block", "organic_material"], 2, LT)
shaped("lab_waste_bin", ["I I", "IWI", "III"], {"I": IRON, "W": "lab_waste"}, 1, LT)
shapeless("blood_puddle", ["blood_bottle"], 2, LT)
for st, extra in (("chemical_analysis_table", "reagent_flask_red"), ("biological_research_table", "reagent_flask_blue"),
                  ("nuclear_research_table", "uranium_ingot"), ("contamination_testing_station", "soil_sample"),
                  ("sample_preparation_table", "empty_test_tube")):
    shapeless(st, ["lab_table", extra, RS], 1, LT)
shapeless("computer_workstation", ["lab_table", "old_pc"], 1, LT)

# --- industrial (Industrial Workbench)
for pid, ings, n in (("water_pipe", [COPPER, COPPER, COPPER, IRON], 6), ("water_pipe_thin", [COPPER, NUG, NUG], 8),
                     ("gas_pipe", [IRON, IRON, IRON, M + "yellow_dye"], 6), ("lab_pipe", [GLASS, IRON, M + "white_dye"], 8),
                     ("molten_pipe", [IRON, IRON, M + "nether_brick", M + "nether_brick"], 4),
                     ("radioactive_pipe", [IRON, IRON, "uranium_ingot", M + "lime_dye"], 6),
                     ("industrial_pipe", [IRON, IRON, IRON, "canister_black_oil"], 8)):
    shapeless(pid, ings, n, IW)
for vid, pipe in (("water_valve", "water_pipe"), ("gas_valve", "gas_pipe"), ("molten_valve", "molten_pipe"),
                  ("radioactive_valve", "radioactive_pipe"), ("oil_valve", "industrial_pipe")):
    shapeless(vid, [pipe, IRON, M + "red_dye", M + "lever"], 1, IW)
for cid, ings, n in (("electrical_cable", [COPPER, COPPER, M + "black_wool"], 8),
                     ("high_voltage_cable", [COPPER, COPPER, COPPER, IRON, M + "orange_dye"], 6),
                     ("lab_cable", [COPPER, COPPER, M + "white_wool"], 8),
                     ("emergency_cable", [COPPER, COPPER, M + "red_wool"], 8),
                     ("network_cable", [COPPER, RS, M + "blue_dye"], 8),
                     ("damaged_cable", ["electrical_cable", M + "flint"], 1)):
    shapeless(cid, ings, n, IW)
shapeless("gas_canister", ["empty_canister", COAL, COAL, COAL, COAL], 1, IW)
shapeless("canister_industrial_oil", ["empty_canister", M + "dried_kelp", M + "dried_kelp", M + "dried_kelp", COAL], 1, IW)
shapeless("canister_black_oil", ["canister_industrial_oil", M + "ink_sac"], 1, IW)
shapeless("canister_hydraulic_oil", ["canister_industrial_oil", M + "yellow_dye", M + "slime_ball"], 1, IW)
shapeless("canister_lab_oil", ["canister_industrial_oil", RS, M + "red_dye"], 1, IW)
shapeless("canister_contaminated_oil", ["canister_industrial_oil", "contaminated_dirt"], 1, IW)
shapeless("canister_radioactive_oil", ["canister_industrial_oil", "raw_uranium", "raw_uranium"], 1, IW)
shaped("generator_standard", ["IBI", "FRF", "ICI"], {"I": M + "iron_block", "B": "canister_black_oil", "F": M + "furnace",
                                                     "R": M + "redstone_block", "C": M + "copper_block"}, 1, IW)
shaped("generator_industrial", ["IBI", "GRG", "ICI"], {"I": M + "iron_block", "B": "canister_black_oil", "G": "generator_standard",
                                                       "R": M + "redstone_block", "C": M + "copper_block"}, 1, IW)
shaped("generator_nuclear", ["IHI", "URU", "ICI"], {"I": M + "iron_block", "H": "high_voltage_cable", "U": "uranium_ingot",
                                                    "R": M + "redstone_block", "C": M + "copper_block"}, 1, IW)
shaped("generator_backup", ["IBI", "IFI"], {"I": IRON, "B": "canister_black_oil", "F": M + "blast_furnace"}, 1, IW)
shaped("lab_power_unit", ["IRI", "RCR", "IRI"], {"I": IRON, "R": M + "redstone_block", "C": "lab_cable"}, 1, IW)
shaped("server_power_unit", ["IRI", "RNR", "IRI"], {"I": IRON, "R": M + "redstone_block", "N": "network_cable"}, 1, IW)
shaped("reactor_casing", ["ICI", "C C", "ICI"], {"I": IRON, "C": CEM}, 4, IW)
shapeless("reactor_glass", ["reactor_casing", GLASS], 1, IW)
shapeless("reactor_port_coolant", ["reactor_casing", "water_pipe"], 1, IW)
shapeless("reactor_port_power", ["reactor_casing", "high_voltage_cable"], 1, IW)
shapeless("reactor_port_waste", ["reactor_casing", "radioactive_pipe"], 1, IW)
shaped("reactor_core", ["UIU", "IRI", "UIU"], {"U": "uranium_block", "I": M + "iron_block", "R": M + "redstone_block"}, 1, IW)
shaped("reactor_control_panel", ["PRP", "HCH"], {"P": "old_pc", "R": RS, "H": "canister_hydraulic_oil", "C": "reactor_casing"}, 1, IW)
shaped("reactor_cooling_unit", ["IWI", "WBW", "IWI"], {"I": IRON, "W": "water_pipe", "B": "canister_black_oil"}, 1, IW)
shapeless("emergency_shutdown_button", [M + "stone_button", M + "red_dye", IRON], 1, IW)
shapeless("radiation_indicator", [COPPER, PANE, RS, "raw_uranium"], 1, IW)
shaped("water_pump", ["IPI", "WBW", "III"], {"I": IRON, "P": M + "piston", "W": "water_pipe", "B": "canister_black_oil"}, 1, IW)
shaped("gas_tank", ["III", "IGI", "III"], {"I": IRON, "G": "gas_canister"}, 1, IW)
shaped("radioactive_waste_container", ["ICI", "C C", "ICI"], {"I": M + "iron_block", "C": "reactor_casing"}, 1, IW)
for key in ("industrial", "black", "hydraulic", "lab", "contaminated", "radioactive"):
    shaped(f"oil_barrel_{key}", ["I I", "ICI", "III"], {"I": IRON, "C": f"canister_{key}_oil"}, 1, IW)
shaped("old_pc", ["IPI", "IRI", "CCC"], {"I": IRON, "P": PANE, "R": RS, "C": COPPER}, 1, IW)
shapeless("office_pc", ["old_pc", M + "white_dye"], 1, IW)
shapeless("lab_pc", ["old_pc", M + "light_gray_dye"], 1, IW)
shapeless("industrial_terminal", ["old_pc", M + "green_dye"], 1, IW)
shaped("server_rack", ["INI", "IPI", "INI"], {"I": IRON, "N": "network_cable", "P": "old_pc"}, 1, IW)
shaped("industrial_light", [" N ", "IGI"], {"N": M + "iron_chain", "I": IRON, "G": M + "glowstone"}, 2, IW)
shaped("wall_light", ["IG"], {"I": IRON, "G": M + "glowstone_dust"}, 2, IW)
shaped("ceiling_light", ["III", "GGG"], {"I": IRON, "G": M + "glowstone_dust"}, 2, IW)
shaped("lab_light", ["WWW", "GGG"], {"W": M + "white_concrete", "G": M + "glowstone_dust"}, 2, IW)
shapeless("emergency_light", ["wall_light", M + "red_dye"], 1, IW)
shaped("warning_beacon", [" G ", "IOI"], {"G": M + "glowstone", "I": IRON, "O": M + "orange_dye"}, 1, IW)
shaped("alarm", ["INI", "IRI"], {"I": IRON, "N": M + "noteblock", "R": RS}, 1, IW)
shapeless("radiation_alarm", ["alarm", "raw_uranium"], 1, IW)
shaped("lab_door", ["IG", "IG", "II"], {"I": IRON, "G": GLASS}, 1, IW)
shaped("industrial_door", ["II", "IB", "II"], {"I": IRON, "B": "canister_black_oil"}, 1, IW)
shaped("containment_door", ["IH", "II", "II"], {"I": M + "iron_block", "H": "canister_hydraulic_oil"}, 1, IW)
shaped("fortress_door", ["PP", "PI", "PP"], {"P": PLANK, "I": IRON}, 1, IW)
shaped("industrial_vent", ["III", "BBB", "III"], {"I": NUG, "B": M + "iron_bars"}, 4, IW)
shapeless("fuse_box", [IRON, RS, COPPER, COPPER], 1, IW)

shapeless("vhs_radiousti", [M + "paper", M + "black_dye", "network_cable", RS], 1, IW)
# --- Liverocrystal & serum (v1.3)
shapeless("liverocrystal_metal_ingot", ["liverocrystal_shard", "liverocrystal_shard", "liverocrystal_shard", "liverocrystal_shard", IRON], 1, IW)
shaped("liverocrystal_metal_block", ["MMM", "MMM", "MMM"], {"M": "liverocrystal_metal_ingot"}, 1, IW)
shapeless("liverocrystal_metal_ingot", ["liverocrystal_metal_block"], 9, IW)
shaped("liverocrystal_armor_plate", ["MIM", "IMI", "MIM"], {"M": "liverocrystal_metal_ingot", "I": M + "iron_block"}, 2, IW)
shapeless("liverocrystal_gas_canister", ["empty_canister", "liverocrystal_shard", "liverocrystal_shard", "liverocrystal_shard"], 1, IW)
shaped("liverocrystal_gas_tank", ["MMM", "MGM", "MMM"], {"M": "liverocrystal_metal_ingot", "G": "liverocrystal_gas_canister"}, 1, IW)
shaped("liverocrystal_cluster", ["SS", "SS"], {"S": "liverocrystal_shard"}, 1, LT)
shapeless("biogenic_serum", ["empty_flask", "organic_material", "soul_essence"], 1, LT)
shaped("biogenic_serum_vat", ["MGM", "GSG", "MGM"], {"M": "liverocrystal_metal_ingot", "G": GLASS, "S": "biogenic_serum"}, 1, LT)
# --- liquid buckets (v1.3)
shapeless("blood_bucket", [M + "bucket", "blood_jar"], 1, LT)
for key in ("industrial", "black", "hydraulic", "lab", "contaminated", "radioactive"):
    shapeless(f"{key}_oil_bucket" if key != "black" else "black_oil_bucket", [M + "bucket", f"canister_{key}_oil"], 1, IW)
shaped("hazmat_pants", ["YYY", "Y Y", "Y Y"], {"Y": M + "yellow_wool"})
shaped("hazmat_boots", ["L L", "L L"], {"L": M + "leather"})
shapeless("liverocrystal_gas_bucket", [M + "bucket", "liverocrystal_gas_canister"], 1, IW)
shaped("window_barricade", ["P P", "SSS", "P P"], {"P": PLANK, "S": STICK}, 4)
shaped("security_door", ["II", "IR", "II"], {"I": M + "iron_block", "R": RS}, 1, IW)
shaped("decontamination_curtain", ["WW", "GG", "WW"], {"W": M + "white_wool", "G": "reagent_flask_green"}, 1, LT)
shaped("barricaded_door", ["PB", "PI", "PB"], {"P": "burnt_planks", "B": "window_barricade", "I": M + "iron_door"}, 1, IW)
shaped("security_camera", ["IPI", "IRI", " I "], {"I": IRON, "P": PANE, "R": RS}, 1, IW)
shapeless("door_control_button", [M + "stone_button", RS, IRON], 1, IW)
shaped("security_tablet", ["IPI", "IRI", "INI"], {"I": IRON, "P": PANE, "R": RS, "N": "network_cable"}, 1, IW)
shaped("museum_display_case", ["GGG", "G G", "PPP"], {"G": GLASS, "P": PLANK}, 1)
shaped("museum_pedestal", ["CCC", " C ", "CCC"], {"C": CEM}, 2)
shapeless("museum_plaque", [M + "gold_ingot", M + "paper"], 2)
shaped("museum_rope_barrier", ["GSG", "G G"], {"G": M + "gold_ingot", "S": M + "string"}, 2)
shaped("museum_bench", ["PPP", "I I"], {"P": PLANK, "I": NUG}, 2)
shaped("nuke_bomb", ["UTU", "TCT", "UTU"], {"U": "uranium_block", "T": M + "tnt", "C": "reactor_core"}, 1, IW)
shaped("siren", ["INI", " R ", " I "], {"I": IRON, "N": M + "noteblock", "R": RS}, 1, IW)
shaped("hand_siren", [" I ", "INI", " S "], {"I": IRON, "N": M + "noteblock", "S": STICK}, 1, IW)
shaped("bunker_concrete", ["CIC", "ILI", "CIC"], {"C": CEM, "I": IRON, "L": "lead_wall"}, 8, IW)
shaped("bunker_reinforced", ["BMB", "MBM", "BMB"], {"B": "bunker_concrete", "M": "liverocrystal_metal_ingot"}, 4, IW)
shaped("bunker_window", ["BHB", "HHH", "BHB"], {"B": "bunker_concrete", "H": "hermetic_glass"}, 4, IW)
shaped("bunker_door", ["RR", "RD", "RR"], {"R": "bunker_reinforced", "D": "security_door"}, 1, IW)
for meat in ("cooked_beef", "cooked_porkchop", "cooked_chicken", "cooked_mutton"):
    shapeless("canned_food", [NUG, NUG, M + meat], 2, IW)
shapeless("mre_ration", ["canned_food", M + "bread", M + "paper"], 1, IW)
shapeless("purified_water", [M + "glass_bottle", M + "charcoal", M + "sand"], 1, LT)
shapeless("decontaminated_bread", [M + "bread", M + "bread", M + "bread", M + "bread", "reagent_flask_green"], 4, LT)
shapeless("iodine_soup", [M + "bowl", M + "dried_kelp", "anti_radiation_pills"], 1, LT)
shapeless("asphalt", [M + "gravel", M + "gravel", COAL], 4)
shapeless("asphalt_line", ["asphalt", M + "yellow_dye"], 1)
shapeless("asphalt_cracked", ["asphalt", M + "flint"], 1)
shaped("sidewalk", ["CC", "CC"], {"C": CEM}, 4)
shaped("car_wreck", ["III", "GIG", "WIW"], {"I": M + "iron_block", "G": PANE, "W": M + "black_wool"}, 1, IW)
shaped("street_lamp", [" G ", " C ", " C "], {"G": M + "glowstone", "C": CEM}, 1)
shaped("village_bell", ["PPP", "GBG", "P P"], {"P": PLANK, "G": M + "gold_ingot", "B": M + "bell"}, 1)
shaped("dosimeter", ["IPI", "IRI", "IUI"], {"I": IRON, "P": PANE, "R": RS, "U": "raw_uranium"}, 1)
furnace("raw_uranium", "uranium_ingot")
furnace("infected_flesh", "meat_piece")


def emit(outdir, wjson, ns):
    seen = {}
    for kind, out, a, b, n, table in RECIPES:
        oid = out if ":" in out else f"{ns}:{out}"
        base = oid.split(":")[1]
        seen[base] = seen.get(base, 0) + 1
        rid = f"{ns}:{base}" + (f"_{seen[base]}" if seen[base] > 1 else "")
        rid_file = rid.split(":")[1]
        if kind == "furnace":
            data = {"format_version": "1.20.10", "minecraft:recipe_furnace": {
                "description": {"identifier": rid + "_smelt"}, "tags": ["furnace", "blast_furnace"],
                "input": _i(a)["item"], "output": oid}}
            wjson(f"{outdir}/{rid_file}_smelt.json", data)
        elif kind == "shaped":
            data = {"format_version": "1.20.10", "minecraft:recipe_shaped": {
                "description": {"identifier": rid}, "tags": [table], "pattern": a,
                "key": {k: _i(v) for k, v in b.items()}, "unlock": {"context": "AlwaysUnlocked"},
                "result": {"item": oid, "count": n}}}
            wjson(f"{outdir}/{rid_file}.json", data)
        else:
            merged = {}
            for x in a:
                merged[x] = merged.get(x, 0) + 1
            ings = []
            for x, c in merged.items():
                e = _i(x)
                if c > 1:
                    e["count"] = c
                ings.append(e)
            data = {"format_version": "1.20.10", "minecraft:recipe_shapeless": {
                "description": {"identifier": rid}, "tags": [table], "ingredients": ings,
                "unlock": {"context": "AlwaysUnlocked"}, "result": {"item": oid, "count": n}}}
            wjson(f"{outdir}/{rid_file}.json", data)
        COUNT[0] += 1
