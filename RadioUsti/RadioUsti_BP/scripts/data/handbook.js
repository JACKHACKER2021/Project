// In-game handbook (Czech). Must stay in sync with the implementation and README.md.
export const HANDBOOK = [
  {
    title: "1. Úvod a katalog",
    text:
      "RadioÚstí přidává do světa Zeds World potrubí, kabely, generátory, fiktivní reaktor, počítače ÚstíOS, laboratoř, kontaminaci a stavební bloky.\n\n" +
      "Kategorie v kreativním inventáři:\n• Stavba – cement, cihly, panelák, luxfery, HELP sklo, pevnost, potrubí, kabely, dveře.\n• Vybavení – generátory, reaktor, počítače, laboratorní stoly, nádrže, analyzátor, krumpáč, ochranné vybavení.\n• Předměty – světla, alarmy, nábytek, nemocnice, plakáty, dokumenty, laboratorní sklo.\n• Příroda – uranová ruda, kontaminovaný terén, maso, duše.\n\nVšechny recepty najdete v receptové knize. Laboratorní stůl a Průmyslový ponk jsou vlastní pracovní stoly.",
  },
  {
    title: "2. Potrubí a ventily",
    text:
      "Rodiny potrubí: voda (vodovodní + tenké nástěnné), plyn (plynové + laboratorní), roztavený materiál, radioaktivní kapalina, průmyslový olej.\n\n" +
      "Potrubí se samo napojí na sousední potrubí STEJNÉ rodiny a na stroje, které danou látku přijímají – ve všech 6 směrech. Tvar (rovné, koleno, T, kříž, svislé, příruby) se vybere automaticky.\n\n" +
      "Ventil: klepněte (použití) na ventil. Zelená kontrolka = otevřeno, červená = zavřeno. Zavřený ventil přeruší síť – stroje za ním přestanou dostávat látku (např. chlazení reaktoru).\n\n" +
      "Potrubí NEZOBRAZUJE tekoucí kapalinu: přenos je zjednodušený – stroje si berou jednotky ze zdrojů v propojené síti každé 2 sekundy.",
  },
  {
    title: "3. Kabely a napájení",
    text:
      "Elektrické, vysokonapěťové, laboratorní a nouzové kabely tvoří jednu energetickou síť. Vysokonapěťový kabel se do délky sítě počítá jen čtvrtinou (dlouhé trasy). Maximální délka sítě je 160 bodů.\n" +
      "Poškozený kabel se napojí, ale energii NEPŘENÁŠÍ – analyzátor ho nahlásí.\n" +
      "Síťový (modrý) kabel přenáší jen data: spojuje počítače, servery a stroje kvůli monitorování.\n\n" +
      "REDSTONE: blok ruditu vedle kabelu nebo stroje dodává stále 10 jednotek. Rudit (redstone prach), pochodeň, páka, opakovač a komparátor dodávají jen když vedou signál: síla signálu / 3 (max 5 jednotek). Kabely se k nim samy napojí.\n\n" +
      "Spotřeba: počítač 2, server 5, laboratorní stoly 3 (jaderný 5). Napájeno = výroba ≥ spotřeba. Baterie (laboratorní jednotka 2000, serverová UPS 4000) se nabíjejí přebytkem a kryjí výpadky.",
  },
  {
    title: "4. Generátory (multibloky)",
    text:
      "Generátory zabírají 2×2 bloky (standardní, průmyslový, jaderný jsou 2×2×2). Postavte je na volné místo – rozšiřují se směrem od vás a doleva. Chybí-li místo, stavba se zruší a předmět se vrátí. Zničením libovolné části se rozebere celý stroj a vypadne jeden předmět.\n\n" +
      "• Standardní (20): uhlí/dřevěné uhlí (klepnutím), kanystr průmyslového oleje, nebo automaticky ze sudu průmyslového oleje přes průmyslové potrubí.\n" +
      "• Průmyslový (50): roztavený materiál (potrubí na roztavený materiál napojené na lávu) nebo plyn z plynové nádrže přes plynové potrubí.\n" +
      "• Jaderný (120): běží, když je ve stejné energetické síti běžící reaktor (kabel z energetického portu).\n" +
      "• Záložní (15): uhlí; zapne se jen když síť nestačí.\n" +
      "Klepnutím s prázdnou rukou otevřete panel stroje (stav, palivo, zapnout/vypnout).",
  },
  {
    title: "5. Stavba reaktoru",
    text:
      "Reaktor je FIKTIVNÍ herní mechanika.\n\n" +
      "1) Položte Jádro reaktoru.\n2) Obklopte ho kostkou 3×3×3: všech 26 okolních bloků musí být Plášť reaktoru, Průhledové sklo, porty nebo Řídicí panel.\n" +
      "3) Do pláště zapojte aspoň: 1× Chladicí port, 1× Energetický port, 1× Odpadní port a 1× Řídicí panel.\n" +
      "4) Chladicí port → vodovodní potrubí → Chladicí jednotka reaktoru a zdroj vody (Vodní čerpadlo položené u vody, nebo potrubí končící ve vodě). Ventily musí být otevřené.\n" +
      "5) Energetický port → kabel → Jaderný generátor → kabely ke spotřebičům.\n" +
      "6) Odpadní port → potrubí na radioaktivní kapalinu → Kontejner na radioaktivní odpad.\n" +
      "7) Vyrobte Uranovou palivovou tyč (stůl jaderného výzkumu) a vložte ji klepnutím do řídicího panelu.",
  },
  {
    title: "5b. Hotová elektrárna: /structure load reaktor",
    text:
      "Operátor může napsat do chatu: /structure load reaktor ~ ~ ~\nNačte se celá funkční elektrárna 15×6×12 bloků: reaktor 3×3×3, chladicí okruh s ventilem, chladicí jednotkou, čerpadlem a vodou, jaderný generátor na vysokonapěťovém kabelu, Starý počítač napojený kabelem i síťovým kabelem k řídicímu panelu, odpadní potrubí s kontejnerem, tlačítko SCRAM, indikátor radiace, majáky, alarm a truhla s palivem, analyzátorem a kompletním ochranným oblekem.\n" +
      "Postup: otevřete truhlu, vložte palivové tyče do řídicího panelu a stiskněte START.",
  },
  {
    title: "6. Provoz a odstavení reaktoru",
    text:
      "Řídicí panel: Start, SCRAM, Reset, vložení paliva, automatická ochrana.\n\n" +
      "• Jedna palivová tyč vydrží 5 minut, zásobník pojme 4 tyče.\n• S chlazením se teplota ustálí kolem 55 % (každá další chladicí jednotka −10 %).\n" +
      "• Bez chlazení teplota roste o 4 % za 2 s. 75 % = VAROVÁNÍ, 90 % = KRITICKÝ STAV, 95 % = automatický SCRAM (lze vypnout), 100 % = TAVENÍ JÁDRA: jádro se zničí, okolí se zamoří.\n" +
      "• Běh vytváří odpad – bez kontejneru se hromadí a od 10 jednotek uniká do okolí.\n" +
      "Odstavení: tlačítko SCRAM na panelu, v ÚstíOS, nebo Tlačítko nouzového odstavení (do 24 bloků). Po vychladnutí pod 30 % stiskněte Reset.",
  },
  {
    title: "7. Old PC, ÚstíOS a server",
    text:
      "Počítač potřebuje napájení (2). Klepnutím otevřete ÚstíOS Longhorn Edition: stav systému, napájení, připojené stroje, dohled reaktoru, diagnostika sítí, historie alarmů, dokumenty, laboratorní záznamy, kontaminace, síť/server, přehrávač VHS, vypnutí/restart.\n\n" +
      "Počítač vidí stroje do 8 bloků a všechno připojené síťovým kabelem. Je-li ve stejné datové síti napájený Serverový rack, vidí počítač všechny stroje do 64 bloků.\n" +
      "Funkce, které nejsou dostupné (např. bez serveru), jsou v nabídce označené jako nedostupné.",
  },
  {
    title: "8. Systémový analyzátor",
    text:
      "Držte analyzátor a klepněte na libovolný blok. Ukáže název, typ, stav, napájení, propojení potrubí/kabelů, stav ventilu, generátoru, reaktoru, kontaminaci, příslušnost k multibloku a chybějící části nebo problémy.\n" +
      "Analyzátor nic nemění – klepnutí s ním na ventil ventil nepřepne.",
  },
  {
    title: "9. Laboratoř",
    text:
      "Laboratorní stůl = pracovní stůl na laboratorní sklo. Průmyslový ponk = stroje, potrubí, kabely.\n\n" +
      "• Příprava vzorků (bez proudu): láhev krve + 2 zkumavky → 2 vzorky krve; infikované maso + vzorkovnice → vzorek tkáně; kontaminovaná hlína + vzorkovnice → vzorek půdy.\n" +
      "• Biologický výzkum: vzorek + modré činidlo → záznam z výzkumu (30 % šance na sérum Zed).\n" +
      "• Chemická analýza (proud + plyn + náplň červeného oleje): antiradiační tablety, chemická analýza krve.\n" +
      "• Jaderný výzkum: 2 uranové ingoty + kanystr radioaktivního oleje → palivová tyč.\n" +
      "• Testování kontaminace: test půdy, dekontaminace oleje, dekontaminace osoby.\n" +
      "Laboratorní sklo jde položit: baňky (prázdná, červená, zelená, modrá), zkumavka, vzorek krve, láhev krve a nádoby se pokládají jako bloky s vlastním modelem. Po rozbití vrátí stejný předmět.\n" +
      "Krev a maso: zombie (a jejich varianty) občas upustí infikované maso a láhev krve. Infikované maso v peci → kus masa.",
  },
  {
    title: "10. Radiace a kontaminace",
    text:
      "Zdroje: uranová ruda a bloky, kontaminovaný terén, radioaktivní odpad, běžící nebo unikající reaktor, radioaktivní předměty v inventáři.\n" +
      "Dávka se zobrazuje nad lištou. Efekt RADIACE: I (dávka 25) nevolnost, II (50) slabost, zpomalení, hlad, III (75) radiační zásahy 1 HP / 2 s, IV (100) smrtelné zásahy 3 HP / 2 s. Mimo zdroje dávka pomalu klesá.\nRadiaci dostávají i zvířata a další tvorové venku v radioaktivním dešti nebo na zamořené zemi – při stupni III a IV umírají. Nemrtví (zombie, kostlivci) jsou imunní.\n" +
      "Ochrana: plynová maska −30 %, ochranný oblek −50 % (spolu −65 %). Léčba: antiradiační tablety (−40), sérum Zed (−10 + regenerace), dekontaminace osoby.\n" +
      "Radioaktivní odpad pomalu zamořuje okolí (okruh 2). Dekontaminační souprava vyčistí kontaminovanou hlínu, trávu a kámen.\n" +
      "Nastavení (operátor): /scriptevent radiousti:config radiation off | on, multiplier 0.5, wastespread off.",
  },
  {
    title: "10b. Liverocrystal, sérum a tekutiny",
    text:
      "LIVEROCRYSTAL: ruda hluboko pod zemí (y −60 až −10) dává úlomky. 4 úlomky + železný ingot = ingot Liverocrystal Metal (průmyslový ponk). Z ingotů vyrobíte blok, pancéřovou desku (téměř nezničitelná, odolnost proti výbuchu 1200) a nádrž Liverocrystal Gas.\n" +
      "Kanystr Liverocrystal Gas (prázdný kanystr + 3 úlomky) doplní nádrž Liverocrystal Gas o 300 jednotek plynu – nádrž funguje jako plynová nádrž pro průmyslový generátor a chemickou analýzu.\n" +
      "POZOR: ruda, shluky a nádrž vydávají výpary – bez plynové masky do 3 bloků otrava a nevolnost.\n\n" +
      "BIOGENNÍ SÉRUM B-9 (baňka + organický materiál + esence duše): vypití = regenerace a krátká nevolnost; jde i položit jako ampuli.\n\n" +
      "TEKUTINY: krev a 6 olejů jsou tekuté bloky, které stékají dolů a rozlévají se do 4 bloků. Kbelík + kanystr oleje (nebo nádoba s krví) = plný kbelík. Prázdným kbelíkem nabíráte zdroj. Ve tekutině jste zpomaleni; krev způsobuje nevolnost, černý olej slepotu, laboratorní slabost, kontaminovaný otravu, radioaktivní ozáření.",
  },
  {
    title: "10c. Obloha, smog a radioaktivní déšť",
    text:
      "Obloha nad RadioÚstí je trvale nazelenalá. Mlha se mění s časem: ve dne zelená, večer a za úsvitu načervenalá, v noci rudá. S grafikou Vibrant Visuals se barví i celé nebe.\n" +
      "SMOG: občas se nad krajem převalí hustý smog (2–5 minut) a dohlednost klesne na pár desítek bloků.\n" +
      "RADIOAKTIVNÍ DÉŠŤ: kdo stojí v dešti pod otevřeným nebem, dostává dávku radiace (maska a oblek ji snižují). Déšť pomalu zamořuje trávu kolem hráčů.\n" +
      "DENNÍ RADIACE: pod otevřeným nebem radiace během dne stále roste – od úsvitu nulová, k západu slunce nejvyšší, v noci nic. Každým dalším dnem světa je silnější (až dvojnásobek po 40 dnech). Pod střechou jste v bezpečí.\n" +
      "V ovzduší se vznášejí drobné zelené částečky radiace.\n" +
      "KONTAMINACE se šíří jako sculk: kontaminovaná tráva, hlína a kámen postupně zamořují sousední bloky. Na podlahy se usazuje RADIOAKTIVNÍ PRACH, který proniká do budov každým otvorem (chybějící nebo otevřené dveře a okna). Zavřené dveře a skla ho zastaví. Prach vyčistí dekontaminační souprava.\n" +
      "NETĚSNÁ BUDOVA: má-li místnost otvor ven, proniká dovnitř polovina radioaktivního deště a část denní radiace. Utěsněná budova (zavřené dveře, zasklená okna) chrání úplně.\n" +
      "OCHRANA: kompletní ochranný oblek (plynová maska, oblek, kalhoty, boty) = úplná imunita vůči radiaci z okolí i zásahům Zedů.\n" +
      "OZÁŘENÝ ZED: nový zombie z RadioÚstí, objevuje se i ve dne, na slunci nehoří, každý jeho zásah ozáří (+8 dávky).\n" +
      "Nastavení: /scriptevent radiousti:config environment off | rainradiation off | dayradiation off | spread off | smog 3",
  },
  {
    title: "10d. Bezpečnost, kamery a Zéd nákaza",
    text:
      "ZEDI ROZBÍJEJÍ SKLA: Ozářený Zed a Radiakova zombie rozbijí nechráněné sklo vedle sebe (obyčejní zombie jen občas). Sklo je chráněné, když sousedí s Okenní barikádou, dřevěnou barikádou nebo Zabarikádovanými dveřmi. Okenní barikádu položte přímo na sklo.\n" +
      "ZABARIKÁDOVANÉ DVEŘE odrážejí Zedy, kteří k nim přijdou. BEZPEČNOSTNÍ ROLETOVÉ DVEŘE se otevírají vysunutím nahoru. TLAČÍTKO OVLÁDÁNÍ DVEŘÍ otevře/zavře všechny bezpečnostní a zabarikádované dveře do 8 bloků.\n" +
      "DEKONTAMINAČNÍ PLÁŠŤ: dveře z pásů – průchodem se dekontaminujete (−6 dávky každé 2 s) a zpomalí se Zéd nákaza.\n" +
      "KAMERY: položte Bezpečnostní kameru na zeď, klepnutím ji pojmenujte. BEZPEČNOSTNÍ TABLET: seznam kamer, pohled z kamery, otevření/zavření dveří do 32 bloků. Plížení + tablet = konec sledování. Při zranění se kamera sama vypne.\n" +
      "ZÉD NÁKAZA: kousnutí zombie může nakazit (Ozářený Zed 25 %, Radiakova zombie 40 %, ostatní 10 %). Fáze I nevolnost, II (po 3 min) slabost a zpomalení, III (po 6 min) zranění. Kdo zemře nakažený, povstane jako Zed. Léčba: Sérum s protilátkami Zed. Kompletní ochranný oblek chrání.\n" +
      "RADIAKOVA ZOMBIE: oběť kousnutí Radiaka – svítí zeleně, vyzařuje radiaci do 4 bloků, kousnutí +15 dávky, 34 HP, útok 6.",
  },
  {
    title: "10e. Atomová bomba, sirény, muzeum",
    text:
      "ATOMOVÁ BOMBA: klepnutím ji aktivujete (30 s odpočet se sirénami a odpočtem na obrazovce). Výbuch zničí okolí, zamoří okruh 32 bloků, ozáří okolí do 64 bloků a spustí déšť a smog. Během odpočtu ji lze klepnutím deaktivovat.\n" +
      "ATOMOVÉ ÚTOKY (operátor): /radiousti:atomic_bomb on [minuty] – z nebe občas spadne atomovka (letecký poplach 20 s, všechny sirény houkají); off – vypnout; strike – útok hned; status.\n" +
      "SIRÉNA (blok) houká při leteckém poplachu a poplachu reaktoru. RUČNÍ SIRÉNA (předmět) varuje hráče do 96 bloků.\n" +
      "ČASTĚJŠÍ DÉŠŤ: za suchého počasí zhruba každých 10 minut začne pršet (radioaktivně).\n" +
      "RADIAKŮV REAKTOROVÝ SLIZ: svítivý sliz, který ozařuje každého do 2,5 bloku.\n" +
      "KONTAMINOVANÁ SFÉRA: Nether, End i všechny další dimenze jsou uzavřené – portál nejde zapálit ani naplnit očima. Kdo se do jiné dimenze dostane, vrátí se do overworldu. Při prvním pokusu dostanete zásobovací bednu Zeds Corp s věcmi z Netheru a Endu (blaze rody, ender perly, nether wart, glowstone, quartz, ghast tear, netherite scrap, shulker shelly, elytru…). Otevření dimenzí (operátor): /scriptevent radiousti:config dimensions on\n" +
      "BUNKR: beton bunkru, vyztužená stěna, pancéřové okno a pancéřové dveře mají odolnost proti výbuchu jako podloží – atomovka je nezničí. Uvnitř bunkru (strop a aspoň 3 stěny z bunkrových bloků) vás nezasáhne radiace z výbuchu ani z okolí. Hotový bunkr: /structure load bunkr ~ ~ ~\n" +
      "MUZEUM: /structure load muzeum ~ ~ ~ – expozice s Radiakem v obleku, mrtvolami starosty, pošťáka a technika, vitrínami a plakáty.",
  },
  {
    title: "10f. Survival 2.0: města, osady, jídlo",
    text:
      "VE SVĚTĚ SE GENERUJÍ: rozpadlé paneláky, kusy silnic s vraky aut a lampami, rozpadlé městské bloky (křižovatka, panelák, obchod, cihlový dům, ordinace), opevněné osady přeživších, ruiny pevností a laboratoře. V truhlách je loot.\n" +
      "OSADA PŘEŽIVŠÍCH: zdi s cimbuřím, strážní věže s reflektory a sirénami, brána s bezpečnostními dveřmi a dekontaminačním pláštěm, domy se zabarikádovanými okny a zvon osady, u kterého vždy čeká Přeživší obchodník.\n" +
      "PŘEŽIVŠÍ OBCHODNÍK: za nalezené věci (shnilé maso, kosti, železo, měď, uran, uhlí, papír, provázky…) prodává bunkrové bloky, ochranný oblek, konzervy, MRE, tablety, sérum, kamery a tablet.\n" +
      "STARTOVNÍ BALÍČEK: při prvním připojení dostanete masku, radiační senzor, jídlo, vodu, tablety a příručku. Znovu: /radiousti:starter_kit. Radiační senzor v ruce stále ukazuje radiaci a dávku.\n" +
      "JÍDLO: obyčejné jídlo je kontaminované (+5 dávky, někdy nevolnost). Čisté jídlo: Konzerva Zeds Corp, Vojenská dávka MRE, Filtrovaná voda (−5 dávky), Dekontaminovaný chléb, Jódová polévka (−15 dávky).\n" +
      "Voda je nazelenalá. Zvířata a tvorové dostávají od radiace skutečná zranění a umírají.\n" +
      "ATOMOVKY: /radiousti:atomic_bomb on 1 = útok každou minutu. Padá 3–5 bomb z nebe na různá místa, každá udělá kráter, atomový hřib a oslnivý záblesk.",
  },
  {
    title: "11. Světla, alarmy, dveře",
    text:
      "Světla zapínáte klepnutím. Výstražný maják se sám rozsvítí při poplachu reaktoru do 32 bloků, nouzové světlo při výpadku napájení do 16 bloků.\n" +
      "Alarm spustí reaktor ve VAROVÁNÍ/KRITICKÉM STAVU do 32 bloků nebo radiace v okolí. Klepnutím na znějící alarm ho ztlumíte na 60 s, na tichý alarm – test.\n" +
      "Dveře jsou dva bloky vysoké, otevírají se klepnutím na kteroukoli polovinu; zničením jedné poloviny zmizí obě.",
  },
  {
    title: "12. Nábytek, nemocnice, dokumenty",
    text:
      "Nemocniční lůžko a operační stůl jsou dva bloky dlouhé. Klepnutím na nemocniční lůžko si nastavíte bod oživení.\nOtočná kancelářská židle se po klepnutí otočí o 90°.\n" +
      "Registr experimentů – Projekt Apokalypsa (kniha + červená barva + inkoust): kniha postav a experimentů Zeds World ve 13 kapitolách. Najdete ho i v ÚstíOS v Dokumentech.\n" +
      "Plakáty, oznámení, rozházené papíry, hromady dokumentů a fotografie si přečtete klepnutím. Dokumenty v inventáři přečtete použitím. Nástěnné hodiny ukážou herní čas.",
  },
  {
    title: "13. Řešení problémů a omezení",
    text:
      "• Stroj nefunguje → použijte analyzátor, ukáže chybějící palivo, napájení nebo zavřený ventil.\n• Reaktor nejde spustit → panel vypíše přesný důvod.\n• Multiblok zmizel → byl poškozen (výbuch, píst); vypadl předmět, postavte ho znovu.\n" +
      "Omezení: kapaliny se nezobrazují, potrubí přenáší jednotky; na židlích nelze sedět; ochranné vybavení se kreslí jednoduchou texturou; stroje rozbité výbuchem nebo příkazem mohou vypadnout bez předmětu; vlastní hudební disk není – VHS se přehrává v ÚstíOS.",
  },
];
