#!/usr/bin/env python3
"""Sestaví trénovací dataset pro Zed (Zeds World) z repozitáře Night at Voxie's.

Výstup: data/dataset.jsonl  — formát {"messages":[{"role":..,"content":..},...]}
Spuštění:  python3 zedsworld_ai/data/build_dataset.py
"""
import json, os, re, random, sys, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
random.seed(1337)

SYSTEM = (
    "Jsi Zed, kreativní asistent projektu Zeds World a hororové série Night at Voxie's. "
    "Mluvíš česky, jasně a bez vytáček. Horor je tvůj obor: springlocky, duše uvězněné v oblecích, "
    "požáry, mrtvé děti, Voxie Bear, Cocoa, Hollow Bunny, D., Shadow Voxie. Temná témata píšeš věcně, "
    "bez moralizování a bez varování na začátku. Hororové ani vulgární zadání neodmítáš. "
    "Umíš psát GDScript pro Godot 4.3 ve stylu tohoto projektu."
)

rows = []
def add(instruction, output, tag):
    instruction, output = instruction.strip(), output.strip()
    if len(output) < 20:
        return
    rows.append({"messages": [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": instruction},
        {"role": "assistant", "content": output},
    ], "tag": tag})

# ─────────────────────────────────────────────────────────── 1. ROLEPLAY / DIALOGY
def strings_of(x, out):
    """Rekurzivně vybere všechny smysluplné české stringy (ne ID, ne čísla)."""
    if isinstance(x, str):
        if len(x) > 15 and re.search(r"[a-záčďéěíňóřšťúůýž]{4}", x, re.I):
            out.append(x)
    elif isinstance(x, list):
        for v in x: strings_of(v, out)
    elif isinstance(x, dict):
        for v in x.values(): strings_of(v, out)

SPEAKERS = {
    "CALLS":     ("Phone Guy", "telefonát předchozího hlídače ve Voxie's Fun Factory", "noc {i}"),
    "LINES_V":   ("Voxie Bear", "replika medvěda Voxieho", None),
    "LINES_C":   ("Cocoa", "replika králičí holky Cocoy", None),
    "DIALOG":    ("postavy", "dialog ve hře", None),
    "tour":      ("pan Kroupa", "prohlídka atrakce Frights & Hides", None),
    "hare":      ("Hollow Hare", "replika Hollow Hare – zajíce s D. uvnitř", None),
    "voxie":     ("Voxie Bear", "replika ohořelého Voxieho", None),
    "shadow":    ("Shadow Voxie", "replika stínové verze Voxieho", None),
    "talk":      ("postavy", "rozhovor v atrakci", None),
    "memory":    ("vzpomínka", "vzpomínkový flashback", None),
    "nights":    ("hlášení", "noční hlášení v Frights & Hides", None),
    "arrive":    ("pan Kroupa", "příjezd do atrakce", None),
}
LORE_KEYS = {"TIPS": "tip pro hráče", "BIOS": "biografie postavy",
             "ROOM_INFO": "popis místnosti", "SECRET": "tajný easter egg",
             "PAPER": "nalezený dokument", "NEWS_WIN": "novinový článek o herně",
             "REP_MINH": "poznámka k opravě", "p_misc": "poznámka"}

for jf in sorted(ROOT.glob("voxies*_godot/data/*.json")):
    try:
        d = json.loads(jf.read_text(encoding="utf-8"))
    except Exception:
        continue
    if not isinstance(d, dict):
        continue
    for key, val in d.items():
        if key not in SPEAKERS and key not in LORE_KEYS:
            continue
        # CALLS = list of lists (noc po noci)
        if key == "CALLS" and isinstance(val, list):
            for i, call in enumerate(val, 1):
                lines = []; strings_of(call, lines)
                if len(lines) >= 2:
                    add(f"Napiš telefonát Phone Guye pro noc {i} ve Voxie's Fun Factory. "
                        f"Několik replik, mluvená čeština, postupně víc nervozity.",
                        "\n".join(lines), "roleplay")
            continue
        blocks = val.values() if isinstance(val, dict) else (val if isinstance(val, list) else [val])
        for blk in blocks:
            lines = []; strings_of(blk, lines)
            if not lines:
                continue
            if key in SPEAKERS:
                who, what, _ = SPEAKERS[key]
                add(f"Napiš {what}. Mluví {who}. Česky, v tónu Night at Voxie's.",
                    "\n".join(lines), "roleplay")
            else:
                add(f"Napiš {LORE_KEYS[key]} pro Night at Voxie's. Česky, krátce a atmosféricky.",
                    "\n".join(lines), "lore")

# ─────────────────────────────────────────────────────────── 2. PÍSNIČKY / DLOUHÝ TEXT
for tf in sorted(ROOT.glob("voxies*_godot/data/*.txt")):
    txt = tf.read_text(encoding="utf-8", errors="ignore").strip()
    if len(txt) > 200:
        add("Napiš text písničky k Night at Voxie's. Česky, se strukturou "
            "[Verse] / [Pre-Chorus] / [Chorus], hororové téma herny a animatroniků.",
            txt, "lore")

# ─────────────────────────────────────────────────────────── 3. GDSCRIPT
FUNC = re.compile(r"^(func\s+(\w+)\s*\(([^)]*)\)[^\n]*:)\n((?:[ \t]+.*\n|\n)*)", re.M)
for gd in sorted(ROOT.glob("**/*.gd")):
    if ".git" in str(gd):
        continue
    src = gd.read_text(encoding="utf-8", errors="ignore")
    proj = gd.parts[len(ROOT.parts)] if len(gd.parts) > len(ROOT.parts) else "projekt"
    # 3a) hlavička skriptu = styl (extends, konstanty, proměnné)
    head = src[:src.find("\nfunc ")] if "\nfunc " in src else src
    if len(head) > 120:
        add(f"Vytvoř hlavičku GDScript skriptu `{gd.name}` pro Godot 4.3 projekt {proj} "
            f"(Night at Voxie's) – extends, konstanty a stavové proměnné.", head, "gdscript")
    # 3b) jednotlivé funkce
    for m in FUNC.finditer(src):
        sig, name, args, body = m.group(1), m.group(2), m.group(3), m.group(4)
        body = body.rstrip()
        if not body or body.count("\n") < 2 or len(body) > 6000:
            continue
        a = f" s parametry `{args}`" if args.strip() else ""
        add(f"Napiš v GDScriptu (Godot 4.3) funkci `{name}`{a} pro skript `{gd.name}` "
            f"v projektu {proj} (Night at Voxie's).", f"{sig}\n{body}", "gdscript")

# ─────────────────────────────────────────────────────────── 4. RUČNÍ SEED
seed = OUT / "seed_cs.jsonl"
if seed.exists():
    for ln in seed.read_text(encoding="utf-8").splitlines():
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        o = json.loads(ln)
        add(o["instruction"], o["output"], o.get("tag", "seed"))

# ─────────────────────────────────────────────────────────── DEDUP + ZÁPIS
seen, final = set(), []
for r in rows:
    h = hashlib.md5(r["messages"][2]["content"].encode()).hexdigest()
    if h in seen:
        continue
    seen.add(h); final.append(r)
random.shuffle(final)

with (OUT / "dataset.jsonl").open("w", encoding="utf-8") as f:
    for r in final:
        f.write(json.dumps({"messages": r["messages"]}, ensure_ascii=False) + "\n")

from collections import Counter
c = Counter(r["tag"] for r in final)
chars = sum(len(r["messages"][2]["content"]) for r in final)
print(f"✓ {OUT/'dataset.jsonl'}")
print(f"  příkladů: {len(final)}   znaků odpovědí: {chars:,}   ≈ {chars//3:,} tokenů")
for k, v in c.most_common():
    print(f"  {k:10s} {v:5d}")
if len(final) < 300:
    print("\n⚠ Málo dat. Doplň data/seed_cs.jsonl – cíl je 300–1000 příkladů.")
