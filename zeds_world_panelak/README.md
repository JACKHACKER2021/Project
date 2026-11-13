# Zed's World: Panelák

Godot 4.3, Android. **5. 1. 2072 — den, kdy přišla Zédova apokalypsa.**

Probudíš se ve svém bytě ve dvanáctém podlaží. Venku je růžová obloha a prší.
Něco je divně slyšet. Pak slyšíš, jak sousedi utíkají. Pak zhasne proud.

Zédové jsou tři sta metrů vysoké beznohé a bezruké entity. Chodí tak, že se
překlápějí z hrany na hranu, a je je slyšet na kilometr — zní to jako sekačka
a zemětřesení dohromady. Chodí kontrolovat domy a **rádi koukají do oken**.
Když tě za sklem uvidí, naštvou se a **telekinezí po domě hodí loď**.

Cílem není v domě přežít. Cílem je **dostat se ven dřív, než ho rozmlátí**.

## Spuštění

Otevři tuhle složku v Godotu 4.3+ a dej F5. Na počítači: WASD chůze, myš
rozhled, E ruka, F sekera, L baterka, Shift běh. Na telefonu: levý palec páčka,
pravá strana tah pro rozhled, tlačítka ✋ 🪓 🔦 vpravo dole.

## Co je hotové

| soubor | co dělá |
|---|---|
| `scripts/world.gd` | staví svět, intro, výpadek proudu |
| `scripts/config.gd` | rozměry domu — musí sedět s `build.py`, kterým vznikl model |
| `scripts/colliders.gd` | kolize se počítají z rozměrů, ne z modelu, a jen pro podlaží kolem hráče |
| `scripts/player.gd` | stamina, kulhání, zranění, baterka, sekera, ruka |
| `scripts/zed.gd` | hlídka, koukání do oken, telekinetický hod lodí |
| `scripts/elevator.gd` | výtah převzatý z `godot_vytah` — a je zlobivý |
| `scripts/house.gd` | stav domu v %, bourání po kusech, oheň, odpočet do zřícení |
| `scripts/blinds*.gd` | žaluzie — stahují se po lamelách, Zéd podle nich pozná, že tam někdo je |
| `scripts/props.gd`, `prop_alive.gd` | oživlé předměty (židle, lednice, televize, dveře) |
| `scripts/weather.gd` | růžová obloha, mlha, déšť |
| `scripts/hud.gd` | dotykové ovládání, stav domu, odpočet |

## Modely

- `panelak_zed_destrukce_mobil.glb` — dům, 403 k trojúhelníků, rozřezaný na 23
  bouracích kusů (`kus_BB_S`, `sklep_1..3`) plus `trosky_*`, `ohen_*`, `kour_*`, `lod`.
  Nadzemní část přesně 300 m, 99 obytných podlaží, 1584 bytů, sklepní bludiště.
- `zed_zedovsky_rig.glb` — Zéd s kostrou (7 kostí, bez nohou a rukou) a animacemi
  `Walk`, `Idle`, `PeekWindow`, `ThrowShip`.
- `props_zed.glb` — sekera a oživlé předměty.

## Zvuk

40 souborů OGG. Zédovy kroky jsou dvoutaktní motor kolem 170 Hz plus sub 8–34 Hz.
`zed_blizi_se_30s.ogg` je třicetisekundové přiblížení — nejdřív jen dunění, pak
motor, nakonec kroky. `intro_probuzeni.ogg` je zvuková osa úvodní scény.

## Co ještě chybí

- Skripty **nejsou spuštěné v Godotu** — v téhle session žádný Godot není, takže
  je ověřený jen jazyk a struktura, ne běh. Počítej s laděním při prvním F5.
- Dveře bytů zatím nejdou otevírat (otvory v kolizích jsou, interakce ne).
- Padající kusy jsou zatím jen schované, ne fyzikální `RigidBody3D`.
- Ikony pro Android (192×192 a adaptivní) nejsou vygenerované.
