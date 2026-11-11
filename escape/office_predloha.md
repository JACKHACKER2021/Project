# Předloha: OFFICE – Escape hra (stará budova s funkčním výtahem)

> Stav: **PŘEDLOHA** – jen návrh místnosti, žádná implementace.
> Cíl místnosti: hráč se probudí v kanceláři ve 3. patře staré budovy a musí zprovoznit starý výtah, aby utekl.

---

## 1. Atmosféra a budova
- **Budova:** činžovní/úřední dům z ~30. let, později kanceláře (poslední nájemce odešel v 90. letech).
- **Materiály:** dřevěné obložení do výšky pasu, oprýskaná zelenkavá omítka, parkety se skřípajícími místy, mosazné kliky, žárovky v opálových koulích.
- **Světlo:** šero, jediná funkční stolní lampa + blikající zářivka na chodbě; měsíc za špinavým oknem.
- **Zvuky (ambient):** tikání nástěnných hodin, kapání vody, vzdálené vrzání lan ve výtahové šachtě, občasné cvaknutí relé.
- **Paleta:** hnědá (dřevo), olivově zelená (zdi), mosaz, žlutavé světlo, studená modrá (měsíc).

## 2. Půdorys (pohled shora, 1 znak ≈ 0,5 m)

```
 ┌──────────────────────────────┐
 │ [OKNO]          [REGÁL]       │
 │                               │
 │  [STŮL]+[LAMPA]   [SEJF]      │
 │  [ŽIDLE]                      │
 │                   [KARTOTÉKA] │
 │ [HODINY]                      │
 │  [VĚŠÁK]   [KOBEREC]          │
 ├────┬──[DVEŘE]──┬──────────────┤
 │ WC │  CHODBA   │ [VÝTAH]      │
 │    │ [POJISTKY]│ [OVLÁDACÍ    │
 │    │           │  PANEL]      │
 └────┴───────────┴──────────────┘
```
- Kancelář cca 6 × 5 m, výška stropu 3,2 m.
- Dveře kanceláře → chodba; na konci chodby **výtah s nůžkovou mřížkou**.
- Schodiště je zavalené (trámy) → jediná cesta je výtah.

## 3. Výtah (funkční)
| Vlastnost | Hodnota |
|---|---|
| Typ | Starý lanový výtah, kabina s dřevěným obložením |
| Dveře | Ruční **nůžková mříž** (kabina) + plechové šachetní dveře |
| Patra | 3 (start) → 2 → 1 → přízemí (únik) / suterén (bonus) |
| Ovládání | Mosazný panel s tlačítky P, 1, 2, 3, S + **klíčový spínač** |
| Indikátor | Ručička nad dveřmi (půlkruhová stupnice pater) |
| Stavy | `BEZ_PROUDU` → `PROUD_OK` → `ODEMČENO` → `JEDE` → `CÍL` |

**Pravidla chování:**
- Bez proudu: tlačítka nesvítí, mříž nejde zavřít „na doraz“.
- Jede jen při **zavřené mříži** (bezpečnostní kontakt) – jinak cvakne a nic.
- Jízda: ~4 s/patro, otřesy kamery, vrzání lan, ručička indikátoru se posouvá.
- Volitelně: v polovině jízdy výtah zastaví (výpadek) → hráč musí znovu nahodit jistič z kabiny (servisní poklop).

## 4. Hádanky (řetěz)
1. **Lampa / pojistky** – v chodbě je pojistková skříň, chybí jedna pojistka. Pojistka je v šuplíku stolu (šuplík zamčen → klíček v kapse kabátu na věšáku).
2. **Hodiny** – nástěnné hodiny stojí na **4:17**. Kombinace sejfu = `0417`.
3. **Sejf** – obsahuje **klíč k výtahu** + útržek dopisu („Správce jezdil vždy přes 2. patro…“).
4. **Kartotéka** – složka „Revize výtahu 1987“ s pořadím pater pro servisní režim: `3 → 2 → P`.
5. **Výtah** – vložit klíč, zavřít mříž, zmáčknout patra ve správném pořadí → jede do přízemí = **ÚNIK**.
   - Špatné pořadí → výtah sjede do suterénu (bonus/špatný konec nebo jumpscare).

## 5. Interaktivní objekty
| ID | Objekt | Akce | Výsledek |
|---|---|---|---|
| `coat` | Kabát na věšáku | prohledat | `key_drawer` |
| `desk_drawer` | Šuplík stolu | odemknout (`key_drawer`) | `fuse` |
| `fuse_box` | Pojistková skříň | vložit `fuse` | proud v budově |
| `clock` | Nástěnné hodiny | prohlédnout | nápověda 4:17 |
| `safe` | Sejf | zadat kód | `key_elevator`, `note_letter` |
| `cabinet` | Kartotéka | otevřít | `note_revision` |
| `lamp` | Stolní lampa | zap/vyp | odhalí UV nápis na koberci (volitelné) |
| `window` | Okno | prohlédnout | zatlučené – flavour |
| `elevator_gate` | Nůžková mříž | otevřít/zavřít | bezpečnostní kontakt |
| `elevator_panel` | Panel | klíč + tlačítka | jízda |

## 6. Inventář (sloty)
`key_drawer`, `fuse`, `key_elevator`, `note_letter`, `note_revision` (max 6 slotů).

## 7. Assety k přípravě
- Modely: stůl, židle, lampa, sejf, kartotéka, věšák + kabát, nástěnné hodiny, regál, pojistková skříň, kabina výtahu, nůžková mříž, panel s tlačítky, indikátor pater.
- Textury: dřevěné obložení, oprýskaná omítka, parkety, mosaz, rezavý plech.
- Zvuky: tikání, vrzání lan, cvaknutí relé, skřípění mříže, „ding“ příjezdu, bzučení zářivky.
- UI: číselník sejfu, zoom na hodiny, zoom na dokumenty, panel výtahu.

## 8. Otevřené otázky (k rozhodnutí)
- Engine: Godot 4.3 (jako ostatní projekty) nebo web/three.js?
- Pohled: first-person 3D, nebo point-and-click?
- Patří místnost do světa *Night at Voxie's*, nebo samostatná hra?
- Časový limit / hororové prvky ano/ne?
