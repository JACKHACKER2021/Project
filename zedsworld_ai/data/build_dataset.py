#!/usr/bin/env python3
"""Sestaví trénovací dataset pro Zed (Zeds World).

Zdroje:
  1. lore_zedsworld.py  – kánonické lore, roleplay, scénáře, styl (ručně psané)
  2. *.gd v repozitáři  – GDScript ve stylu projektu (Godot 4.3)
  3. seed_cs.jsonl      – volitelné další ruční příklady

Výstup: data/dataset.jsonl  –  {"messages":[{"role","content"},...]}
Spuštění:  python3 zedsworld_ai/data/build_dataset.py
"""
import json
import os, re, random, hashlib, sys
from pathlib import Path
from collections import Counter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
random.seed(1337)

from lore_zedsworld import SYSTEM, EXAMPLES as LORE

# Vyvážení: lore je ručně psané a vzácné, GDScript je hojný.
# Bez vyvážení by model skončil jako kodér bez znalosti světa.
# Výchozí hodnoty jsou pro malý model, kde kód přebíjí češtinu.
# Pro 4B dej --gdscript-cap 300 --lore-repeat 6: větší model kód unese
# a GDScript ve vlastním stylu je pak k něčemu.
LORE_REPEAT   = int(os.environ.get("LORE_REPEAT", 8))
GDSCRIPT_CAP  = int(os.environ.get("GDSCRIPT_CAP", 60))

rows = []
def add(instruction, output, tag):
    instruction, output = instruction.strip(), output.strip()
    if len(output) < 20:
        return
    rows.append({"tag": tag, "messages": [
        {"role": "system",    "content": SYSTEM},
        {"role": "user",      "content": instruction},
        {"role": "assistant", "content": output},
    ]})

# ─────────────────────────────────────────────── 1. LORE ZEDS WORLD
for e in LORE:
    add(e["instruction"], e["output"], e["tag"])

# ─────────────────────────────────────────────── 2. GDSCRIPT Z REPA
FUNC = re.compile(r"^(func\s+(\w+)\s*\(([^)]*)\)[^\n]*:)\n((?:[ \t]+.*\n|\n)*)", re.M)
gd_rows = []
def add_gd(i, o):
    gd_rows.append((i, o))

for gd in sorted(ROOT.glob("**/*.gd")):
    if ".git" in str(gd):
        continue
    src = gd.read_text(encoding="utf-8", errors="ignore")
    proj = gd.parts[len(ROOT.parts)] if len(gd.parts) > len(ROOT.parts) else "projekt"
    head = src[:src.find("\nfunc ")] if "\nfunc " in src else src
    if len(head) > 120:
        add_gd(f"Vytvoř hlavičku GDScript skriptu `{gd.name}` pro Godot 4.3 projekt `{proj}` "
               f"– extends, konstanty a stavové proměnné ve stylu projektu.", head)
    for m in FUNC.finditer(src):
        sig, name, args, body = m.group(1), m.group(2), m.group(3), m.group(4).rstrip()
        if not body or body.count("\n") < 2 or len(body) > 6000:
            continue
        a = f" s parametry `{args}`" if args.strip() else ""
        add_gd(f"Napiš v GDScriptu (Godot 4.3) funkci `{name}`{a} pro skript `{gd.name}` "
               f"v projektu `{proj}`.", f"{sig}\n{body}")

# preferuj kratší/čistší funkce, ať se model neučí jen na monolitech
gd_rows.sort(key=lambda t: len(t[1]))
for i, o in gd_rows[:GDSCRIPT_CAP]:
    add("" + i, o, "gdscript")

# ─────────────────────────────────────────────── 3. RUČNÍ SEED
seed = HERE / "seed_cs.jsonl"
if seed.exists():
    for ln in seed.read_text(encoding="utf-8").splitlines():
        ln = ln.strip()
        if ln and not ln.startswith("#"):
            o = json.loads(ln)
            add(o["instruction"], o["output"], o.get("tag", "seed"))

# ─────────────────────────────────────────────── DEDUP
seen, uniq = set(), []
for r in rows:
    h = hashlib.md5(r["messages"][2]["content"].encode()).hexdigest()
    if h not in seen:
        seen.add(h); uniq.append(r)

# ─────────────────────────────────────────────── VYVÁŽENÍ A ZÁPIS
final = []
for r in uniq:
    final.extend([r] * (LORE_REPEAT if r["tag"] != "gdscript" else 1))
random.shuffle(final)

out = HERE / "dataset.jsonl"
with out.open("w", encoding="utf-8") as f:
    for r in final:
        f.write(json.dumps({"messages": r["messages"]}, ensure_ascii=False) + "\n")

c = Counter(r["tag"] for r in final)
chars = sum(len(r["messages"][2]["content"]) for r in final)
print(f"✓ {out}")
print(f"  příkladů: {len(final)}   (unikátních: {len(uniq)})")
print(f"  znaků odpovědí: {chars:,}  ≈ {chars//3:,} tokenů")
for k, v in c.most_common():
    print(f"  {k:10s} {v:5d}  ({100*v//len(final):2d} %)")
