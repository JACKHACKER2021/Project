# Zed's World: Panelák

Godot 4.3, Android. **5. 1. 2072, Mladá Boleslav — čtvrtý den Zédovy apokalypsy.**
Kánon Zeds World, protokol S-2084, Edice 2.5. Podrobnosti v [KANON.md](KANON.md).

Probudíš se ve svém bytě ve dvanáctém podlaží. Venku jsou růžové mraky a prší.
Z rádia mluví náhradní směna MladoboleslavRadia — Pan Rozhlasník je čtvrtý den
po smrti. Prezident Monderez nasadil armádu a technika se obrátila proti
posádkám. Pak slyšíš, jak sousedi utíkají. Pak Monderez vypne síť.

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
| `scripts/props.gd`, `prop_alive.gd` | technika oživlá slovem ALIVER (lednice, televize, pračka, rádio) |
| `scripts/weather.gd` | růžové mraky, mlha, déšť |
| `scripts/lamps.gd` | pouliční lampy — pravidlo kužele světla, a lampy, co ti zhasínají nad hlavou |
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

## Intro

`intro_silvestr_2071.mp4` (47 s) — Silvestr 31. 12. 2071 v bytě, pivo,
ohňostroj za oknem, půlnoc, usnutí. Pak **pět dní spánku**: za oknem se
střídá den a noc, obloha růžoví, televize chcípne, rádio dohraje. Probuzení
5. 1. 2072 na dunění, rachotící okno a sousedy, co utíkají po chodbě.
Obraz i zvuk jsou generované, hudba žádná není — jen to, co je v bytě slyšet.

## Sestavení APK

```
godot --headless --import
godot --headless --export-debug "Android" export/ZedsWorldPanelak.apk
```

Potřebuje Godot 4.3, export templates 4.3.stable, JDK 21 a Android SDK
(build-tools 34.0.0, platforms;android-34, platform-tools). Cesta k SDK a
debug keystore se nastaví v `~/.config/godot/editor_settings-4.3.tres`.

**Pozor:** Android s Mobile rendererem vyžaduje
`textures/vram_compression/import_etc2_astc=true` v `project.godot`, jinak
export spadne na "configuration errors" bez bližšího vysvětlení.

Hotové APK: `export/ZedsWorldPanelak.apk` — 34 MB, `cz.zed.panelak`,
targetSdk 34, minSdk 21, arm64-v8a, podepsané debug klíčem.
Instalace: `adb install -r export/ZedsWorldPanelak.apk`, nebo soubor přenést
do telefonu a povolit instalaci z neznámých zdrojů.

## Co ještě chybí

- Hra **proběhla jen headless** (500 snímků bez chyby skriptů). Na skutečném
  telefonu odzkoušená není — výkon ani ovládání neumím odsud ověřit.
- Dveře bytů zatím nejdou otevírat (otvory v kolizích jsou, interakce ne).
- Ikony pro Android (192×192 a adaptivní) nejsou vygenerované, APK má výchozí.
- Zédův hlas je syntéza, ne namluvený.
