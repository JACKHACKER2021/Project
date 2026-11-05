# Changelog

## 1.0.0 – první úplná verze (2026-11-05)
Postaveno nad starter projektem *RadioUsti_Starter*. Zachované zůstaly UUID manifestů, závislost BP→RP, cílová verze 1.26.50, moduly Script API 2.0.0 a vstupní bod `scripts/main.js`.

**Přidáno**
- Generátor obsahu (`tools/build.py`) s jediným registrem bloků, předmětů a textur (`tools/content.py`).
- 144 bloků a 57 předmětů: potrubí, ventily, kabely, 6 multiblokových generátorů, reaktor, počítače, server, laboratoř, světla, alarmy, dveře, stavební bloky, pevnost, nábytek, nemocnice, plakáty, dokumenty, horor a duše.
- 488 geometrií (rotace se počítají v Pythonu, multibloky se rozřezávají na díly), 161 textur bloků a 57 ikon v pixel-art stylu, 17 zvuků.
- 175 receptů včetně dvou vlastních pracovních stolů (Laboratorní stůl, Průmyslový ponk), z toho 2 recepty do pece.
- Skripty: detekce propojení, energetické, kapalinové a datové sítě, reaktor, radiace a kontaminace, alarmy a automatická světla, laboratorní stanice, ÚstíOS, systémový analyzátor, příručka, čitelné dokumenty, dvoublokové dveře, multibloky, nastavení přes `/scriptevent`.
- Generování uranové rudy (feature + feature rule).
- Validace (`tools/validate.py`), balení (`tools/package.py`), dokumentace (README, FEATURES, docs/CATALOG.md, docs/RECIPES.md).

**Změněno oproti starteru**
- `README.md` ze starteru nahrazen úplným návodem (původní pokyny jsou v historii gitu a v `docs/CLAUDE_TASK.md`).
- Zástupné `README.txt` ve složkách, které teď mají obsah, se při buildu odstraní. Prázdné složky (entities, functions, structures, particles, ui, …) je mají dál.
- `pack_icon.png` nahrazeny novou ikonou.
- Lang soubory (`en_US`, `cs_CZ`) se generují.

**Opraveno během validace**
- ID vanilla předmětů v receptech: `chain` → `iron_chain`, `note_block` → `noteblock`, `item_frame` → `frame`.
- Geometrie židlí a chladicí jednotky přesahovala blok.
