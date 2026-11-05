# Changelog

## 1.5.0 – efekt Radiace a oprava názvů (2026-11-05)
**Přidáno**
- Efekt Radiace I–IV (řízený skriptem): ukazatel na obrazovce, zelené částice, slabost a zpomalení, radiační zásahy (1 a 3 HP / 2 s).
- Radiace zasahuje i zvířata a ostatní tvory do 32 bloků od hráče (déšť, zamořená země, radioaktivní tekutiny). Nemrtví jsou imunní. Nastavení `mobradiation`.

**Změněno**
- Otrava a wither při vysoké dávce nahrazeny radiačními zásahy.

**Opraveno**
- Názvy předmětů: jazykové soubory obsahují všechny tvary klíčů (`item.radiousti:id`, `item.radiousti:id.name`, `tile.radiousti:id.name`).
- Verze balíčků 1.4.0 → 1.5.0.

## 1.4.0 – prostředí, lokace a 3D rudy (2026-11-05)
**Přidáno**
- Systém prostředí: trvale nazelenalá obloha (client biomy založené na vanilla souborech z Mojang/bedrock-samples), mlha podle denní doby (zelená, načervenalá, rudá), atmosféra pro Vibrant Visuals, náhodný smog, radioaktivní déšť (dávka pod otevřeným nebem, kontaminace trávy).
- 30 bloků pro lokace Pennov Theater, CWT, School, Jídelna, Showers, RadioÚstí Laboratory, Fortress a Nuclear Power Plant. Sprcha, výpusť páry a ohniště mají částice.
- Tekutina radioaktivní kal s kbelíkem.
- 3D modely rud s krystalky (uran, hlubinný uran, Liverocrystal).

**Opraveno**
- Bloky a předměty ukazovaly místo názvu klíč `item.…` / `tile.…`. Názvy jsou teď doslovně v `minecraft:display_name`.

**Změněno**
- Verze balíčků 1.3.0 → 1.4.0.

## 1.3.0 – vzhled, Liverocrystal, sérum a tekutiny (2026-11-05)
**Přidáno**
- Liverocrystal: ruda (generuje se y −60 až −10), úlomek, ingot, blok, pancéřová deska, shluk, kanystr a nádrž Liverocrystal Gas (3000 jednotek plynu). Toxické výpary bez plynové masky.
- Biogenní sérum B-9 (pitelné a pokládané), kádě se sérem.
- 7 tekutin (krev a 6 olejů) jako skriptem tekoucí bloky s 5 úrovněmi hladiny, 7 kbelíků, efekty při pobytu v tekutině.

**Vylepšeno**
- Nové modely: 4 počítače, serverový rack, dveře (horní a dolní polovina, klika, rám), plynová nádrž, vodní čerpadlo, chladicí jednotka, generátory.
- Kovové textury se zkosením, ikony předmětů s obrysem a odleskem.
- Plynové nádrže fungují obecně (každá nádrž s rodinou „plyn“).

**Změněno**
- Verze balíčků 1.2.0 → 1.3.0.

## 1.2.0 – Registr experimentů (2026-11-05)
**Přidáno**
- Předmět a kniha *Registr experimentů – Projekt Apokalypsa* se 13 kapitolami o postavách, materiálech a místech Zeds World. Je dostupná také v ÚstíOS → Dokumenty.
- Recept: kniha + červená barva + inkoustový váček.

**Změněno**
- Verze balíčků 1.1.0 → 1.2.0.

## 1.1.0 – redstone a laboratorní sklo (2026-11-05)
**Přidáno**
- Redstone jako zdroj energie: blok ruditu (10 jednotek) a rudit, redstone pochodeň, páka, opakovač a komparátor, když vedou signál (signál ÷ 3, max 5). Napájí kabely i stroje, které se ho přímo dotýkají. Kabely se k redstonu vizuálně napojí.
- Analyzátor a ÚstíOS ukazují energii z redstonu.
- 9 bloků laboratorního skla s vlastními modely: Erlenmeyerova baňka, baňky s činidly (červená, zelená, modrá), zkumavka, vzorek krve, láhev krve, prázdná nádoba a nádoba s krví. Pokládají se svými předměty a po rozbití je vrátí.

**Změněno**
- Verze balíčků 1.0.0 → 1.1.0, aby Minecraft při importu nahradil starou verzi.

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
