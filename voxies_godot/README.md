# Night at Voxie's – Godot 4 port

Port 1. dílu z webové verze (three.js, `voxies/`) do Godotu 4.3.

## Co je hotové
- Mapa herny (`models/building.glb`), kancelář s rozhlížením, dvoje dveře (rolety) a světla do chodeb.
- 10 kamer se šumem a scanlines, proud a spotřeba, výpadek proudu.
- Voxie (levé dveře, stavěný v `scripts/voxie.gd`) a Cocoa (pravé dveře, `models/cocoa.glb`) se stejnou AI a obtížností nocí jako originál.
- Noci 1–5, vlastní noc (0–20), lekačka, smrt, výhra v 6:00, ukládání postupu.
- Hudba v menu (`audio/menu.mp3`), zvuky v `sfx/`.

## Modely (nejsou v gitu)
Před otevřením zkopíruj do `models/`:
- `building.glb` z `voxies2r/www/models/building.glb`
- `cocoa.glb` z `voxies/www/models/cocoa.glb`

## Otevření a spuštění
1. Stáhni Godot 4.3 (standard): https://godotengine.org/download
2. *Import* → vyber `project.godot` v této složce → *Run* (F5).

Ovládání: táhnutí = rozhlížení, A/D dveře, Q/E světla, mezerník kamery (na mobilu tlačítka).

## Sestavení Android APK
1. V Godotu: *Editor → Manage Export Templates → Download* (4.3).
2. *Editor Settings → Export → Android*: cesta k Android SDK, Java (JDK 17+) a debug keystore.
3. *Project → Export → Android → Export Project* (předvolba je v `export_presets.cfg`, ID `cz.voxies.nightatvoxies.godot`).

Z příkazové řádky: `godot --headless --path . --export-debug "Android" export/NightAtVoxies-Godot.apk`

Test se screenshoty: `godot --path . -- --shots` (uloží `shot_*.png` do uživatelské složky Godotu).
