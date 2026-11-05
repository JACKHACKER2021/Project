# RadioÚstí – stav funkcí

Stavy: **implementováno** · **staticky ověřeno** (JSON schémata, křížové odkazy, typová kontrola skriptů, simulace geometrie) · **otestováno ve hře** · **neúplné** · **nepodporováno**

Verze 1.0.0 byla podle autora otestovaná ve hře a funguje („Otestováno a cool“). Podrobný výsledek jednotlivých bodů zatím nemáme, proto sloupec „Ve hře“ zůstává prázdný, dokud autor nepotvrdí konkrétní funkce. Novinky 1.1 (G1, G2) zatím ve hře otestované nejsou.

| # | Funkce | Stav | Ve hře | Poznámka |
|---|---|---|---|---|
| A1 | Manifesty BP/RP, UUID, závislost BP→RP, Script API 2.0.0 | staticky ověřeno | – | UUID ze starteru zachovány |
| A2 | pack_icon.png (BP i RP) | staticky ověřeno | – | 256×256 pixel art |
| A3 | Struktura složek, generátor obsahu | staticky ověřeno | – | `tools/build.py` |
| B1 | 7 typů potrubí, 5 ventilů, 6 kabelů – vlastní geometrie, 6 směrů | staticky ověřeno | – | `bone_visibility` s Molang `q.block_state` |
| B2 | Varianty: rovné, koleno, T, kříž, svislé, příruby, nástěnný držák | staticky ověřeno | – | vybírá skript podle skutečných sousedů |
| B3 | Multibloky 2×2 / 2×2×2 (6 generátorů), lůžko a operační stůl 1×2 | staticky ověřeno | – | skládání dílů ověřeno simulací ve všech 4 směrech |
| B4 | Počítače (4 + pracovní stanice), serverový rack | staticky ověřeno | – | stav obrazovky `active` |
| B5 | Nábytek, nemocnice, laboratorní stoly (8), světla, alarmy | staticky ověřeno | – | kolizní a výběrové boxy z geometrie |
| B6 | Dvoublokové dveře (4 typy) – otevřené a zavřené, otáčení | staticky ověřeno | – | |
| C1 | Systémový analyzátor – sdílený registr, všechny bloky | staticky ověřeno | – | `beforeEvents.playerInteractWithBlock` (zrušení interakce) |
| C2 | ÚstíOS Longhorn Edition – 12 funkčních sekcí | staticky ověřeno | – | stabilní formuláře, bez JSON UI |
| C3 | Ventily otevřít/zavřít, vliv na síť a stroje | staticky ověřeno | – | |
| C4 | Vypínatelná světla se skutečnou změnou světla | staticky ověřeno | – | `light_emission` v permutaci |
| C5 | Alarmy (reaktor, radiace), ztlumení, test, historie | staticky ověřeno | – | |
| C6 | Stavba a bourání multibloků, úklid poškozených | staticky ověřeno | – | rozbití výbuchem se dořeší při dalším cyklu |
| D1 | Energetická síť (výroba/spotřeba, baterie, záložní generátor) | staticky ověřeno | – | cyklus 2 s |
| D2 | Kapalinové sítě: plyn, olej (podle typu), voda, láva, radioaktivní odpad | staticky ověřeno | – | zjednodušená síť, kapaliny se nezobrazují |
| D3 | Datová síť (síťový kabel) a dosah serveru | staticky ověřeno | – | |
| D4 | Reaktor: struktura 3×3×3, palivo, chlazení, teplota, odpad, SCRAM, ochrana, tavení | staticky ověřeno | – | fiktivní mechanika |
| D5 | Radiace: dávka, efekty, ochrana, léčba, nastavení přes `/scriptevent` | staticky ověřeno | – | `dimension.getBlocks` (stabilní 2.0.0) |
| D6 | Kontaminace terénu, šíření odpadu, dekontaminace | staticky ověřeno | – | |
| D7 | Generování uranové rudy ve světě | staticky ověřeno | – | feature + feature rule |
| E1 | Retro československé stavební bloky, HELP sklo, luxfery | staticky ověřeno | – | |
| E2 | 6 plakátů z roku 2072, papíry, dokumenty, hodiny, fotografie (čitelné) | staticky ověřeno | – | |
| E3 | Pevnost a apokalypsa: kámen, mříže, cimbuří, barikády, ostnatý drát, bodce | staticky ověřeno | – | ostnatý drát a bodce zraňují při šlápnutí |
| E4 | Příručka ve hře (13 kapitol) | staticky ověřeno | – | text odpovídá implementaci |
| E5 | Krev, maso, nádoby, baňky, zkumavky, duše, oleje (6 funkcí) | staticky ověřeno | – | |
| E6 | Laboratorní stanice – 5 procesních stolů + 2 pracovní stoly | staticky ověřeno | – | |
| E7 | Realistický krumpáč | staticky ověřeno | – | výdrž snižuje skript (riziko dvojího opotřebení – ověřit) |
| E8 | Zvuky (17), VHS kazeta | staticky ověřeno | – | .ogg (Vorbis) generované, přehrávání neověřeno |
| E9 | Plynová maska a ochranný oblek (zbroj + ochrana proti radiaci) | neúplné | – | vzhled na hráči je jen jednoduchá textura vanilla geometrie |
| G1 | Redstone jako zdroj: blok ruditu (10), rudit / pochodeň / páka / opakovač / komparátor (signál ÷ 3, max 5) | staticky ověřeno | – | `Block.getRedstonePower()` (stabilní 2.0.0); kabely se napojují i vizuálně |
| G2 | Pokládané laboratorní sklo – 9 bloků s modely (baňky, zkumavky, láhev, nádoby) | staticky ověřeno | – | předmět → `minecraft:block_placer`, blok vrací předmět |
| G3 | Registr experimentů – kniha postav Projektu Apokalypsa (13 kapitol), i v ÚstíOS | staticky ověřeno | – | |
| G4 | Liverocrystal (ruda + worldgen, kov, pancíř, plyn, nádrž), toxické výpary | staticky ověřeno | – | |
| G5 | Biogenní sérum B-9, kádě | staticky ověřeno | – | |
| G6 | Tekutiny: krev + 6 olejů, tečení, kbelíky, efekty | staticky ověřeno | – | skriptová náhrada, Bedrock nemá vlastní tekutiny |
| G7 | Vylepšené modely a vzhled (PC, server, dveře, nádrže, čerpadlo, chlazení, generátory, ikony) | staticky ověřeno | – | |
| G8 | Prostředí: zelená obloha, mlha podle času, Vibrant Visuals atmosféra, smog, radioaktivní déšť | staticky ověřeno | – | `/fog` přes `player.runCommand` |
| G9 | 30 bloků pro lokace Pennov a RadioÚstí, částice | staticky ověřeno | – | ID částic ověřena proti vanilla RP |
| G10 | 3D modely rud s krystalky | staticky ověřeno | – | |
| G11 | Oprava názvů (`item.…` místo jména) | staticky ověřeno | – | nahlášeno autorem, ověřit ve hře |
| G12 | Efekt Radiace I–IV (hráči), radiační zásahy | staticky ověřeno | – | skriptový efekt, Bedrock nepovoluje vlastní efekty |
| G13 | Radiace u zvířat a tvorů (déšť, zamořená země, tekutiny) | staticky ověřeno | – | |
| G14 | Struktura `reaktor` – kompletní elektrárna | staticky ověřeno | – | NBT ověřeno zpětným načtením |
| G15 | Ozářený Zed (spawn i ve dne, radiační zásah) | staticky ověřeno | – | založeno na vanilla zombie 1.26.50 |
| G16 | Denní radiace, částečky radiace, šíření kontaminace | staticky ověřeno | – | |
| G17 | Kompletní ochranný oblek = imunita | staticky ověřeno | – | |
| B1b | Oprava napojení kabelů/potrubí (permutace místo Molang) | staticky ověřeno | – | nahlášeno autorem, ověřit ve hře |
| G18 | Zedi rozbíjejí skla, okenní barikády je chrání | staticky ověřeno | – | |
| G19 | Bezpečnostní roletové dveře, zabarikádované dveře, dekontaminační plášť | staticky ověřeno | – | |
| G20 | Kamery + bezpečnostní tablet + tlačítko ovládání dveří | staticky ověřeno | – | `player.camera.setCamera("minecraft:free")` |
| G21 | Zéd nákaza (3 fáze, sérum, povstání) | staticky ověřeno | – | |
| G22 | Radiakova zombie | staticky ověřeno | – | |
| G23 | Atomová bomba + událost atomových útoků + příkaz `/radiousti:atomic_bomb` | staticky ověřeno | – | Script API 2.10.0 |
| G24 | Siréna (blok), ruční siréna | staticky ověřeno | – | |
| G25 | Postavy: pošťák, starosta, technik, Radiak (dekorace s popisem) | staticky ověřeno | – | |
| G26 | Radiakův reaktorový sliz | staticky ověřeno | – | |
| G27 | Muzeum: bloky + struktura `muzeum` | staticky ověřeno | – | |
| G28 | Častější déšť | staticky ověřeno | – | |
| G29 | Kontaminovaná sféra: uzavřené dimenze + zásobovací bedna | staticky ověřeno | – | |
| G30 | Bunkr: bloky odolné atomovce, úkryt před radiací, struktura `bunkr` | staticky ověřeno | – | |
| F1 | Validace JSON, geometrií, skriptů, ID, textur | staticky ověřeno | – | `tools/validate.py`: 0 chyb; komunitní JSON schémata: 0 nálezů |
| F2 | Export .mcaddon + .mcpack | staticky ověřeno | – | `tools/package.py`, kontrola integrity ZIP |
| F3 | Test v Minecraftu Bedrock 1.26.50 | 1.0.0 načteno a hratelné | ✓ (1.0.0, obecně) | 1.1 čeká na test |
| X1 | Sezení na židlích | nepodporováno | – | vyžadovalo by vlastní entitu; místo toho se kancelářská židle otáčí |
| X2 | Zobrazení tekoucích kapalin v potrubí; opravdové vlastní tekutiny (plavání) | nepodporováno | – | stabilní API to neumožňuje, náhradou je zjednodušená síť |
| X3 | Vlastní hudební disk | nepodporováno | – | náhradou je VHS v ÚstíOS |
| X4 | Plnohodnotná „plocha“ přes JSON UI | nepoužito | – | rozhodnutí autora: stabilní formuláře |

## Co nejdřív otestovat ve hře
1. Načtení balíčků bez chyb v Content Logu.
2. Položení potrubí do kříže: mění se tvar? Funguje ventil?
3. Postavení standardního generátoru 2×2×2 ve všech 4 směrech a jeho rozbití.
4. Počítač, kabel a generátor s uhlím: ÚstíOS se otevře a ukáže napájení.
5. Reaktor podle README: start, stav, SCRAM.
6. Analyzátor na potrubí, generátoru a reaktoru.
7. Plynová maska na hlavě: vzhled.
8. Realistický krumpáč: snižuje se výdrž o 1, nebo o 2?
