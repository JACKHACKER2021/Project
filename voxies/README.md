# Night at Voxie's

Hororová hra o nočním hlídači ve zrušené herně **Voxie's Fun Factory** (1997).
3D verze: `www/index.html` (three.js je přibalený v `www/lib`, běží offline). Původní 2D verze: `www/classic.html`.
Vlastní animatronik: v menu „📂 Vlastní model .glb“ – model se uloží jen v zařízení (IndexedDB), do repozitáře ani APK se nepřibaluje.

## Hraní v prohlížeči
Otevři `www/index.html` (na mobilu otoč na šířku).
Ovládání: dotyk na tlačítka, nebo `A`/`D` dveře, `Q`/`E` světla, mezerník kamery, `1`–`0` výběr kamery.

## APK pro Android
APK se sestaví samo na GitHubu: **Actions → „Night at Voxie's – APK“** → poslední běh → *Artifacts* → `night-at-voxies-apk`.
Stáhni ZIP, rozbal `app-debug.apk` a nainstaluj ho do telefonu (povol instalaci z neznámých zdrojů).

Lokálně (potřebuješ Android Studio / Android SDK):
```
cd voxies
npm install
npx cap add android
npx cap sync android
cd android && ./gradlew assembleDebug
```

## Co je hotové (MVP)
- Kancelář: 2 dveře, 2 světla, větrák, telefon, plakáty a noviny, které se každou noc mění
- Tablet s 10 kamerami a mapou budovy
- Proud a spotřeba, výpadek proudu s hrací skříňkou
- Hodiny 0:00–6:00 (cca 7 minut), noci 1–5, ukládání postupu
- Voxie Bear: trasa Pódium → Herna → (Toalety) → Pizzerie → Levá chodba → dveře.
  Světlo 1–3,5 s a zhasnout = odejde; zírání déle = útok. Zavřené dveře = odejde.
- Telefonáty bývalého hlídače (noci 1–5), jumpscare, výhra v 6:00, normální konec
- Zvuky syntetizované přes WebAudio (kroky panované vlevo/vpravo, klepání, smích…)

## Další kroky
Pixel (bludiště + ventil), DJ Rewind (hudba přes tablet), Glitch (šum kamer),
Kapitán Ticket (lístky), noc 6 a vlastní noc, minihry, tajný a špatný konec.
