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
      "Krev a maso: zombie (a jejich varianty) občas upustí infikované maso a láhev krve. Infikované maso v peci → kus masa.",
  },
  {
    title: "10. Radiace a kontaminace",
    text:
      "Zdroje: uranová ruda a bloky, kontaminovaný terén, radioaktivní odpad, běžící nebo unikající reaktor, radioaktivní předměty v inventáři.\n" +
      "Dávka se zobrazuje nad lištou. 25 = nevolnost, 50 = slabost a hlad, 75 = otrava, 100 = wither. Mimo zdroje dávka pomalu klesá.\n" +
      "Ochrana: plynová maska −30 %, ochranný oblek −50 % (spolu −65 %). Léčba: antiradiační tablety (−40), sérum Zed (−10 + regenerace), dekontaminace osoby.\n" +
      "Radioaktivní odpad pomalu zamořuje okolí (okruh 2). Dekontaminační souprava vyčistí kontaminovanou hlínu, trávu a kámen.\n" +
      "Nastavení (operátor): /scriptevent radiousti:config radiation off | on, multiplier 0.5, wastespread off.",
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
      "Plakáty, oznámení, rozházené papíry, hromady dokumentů a fotografie si přečtete klepnutím. Dokumenty v inventáři přečtete použitím. Nástěnné hodiny ukážou herní čas.",
  },
  {
    title: "13. Řešení problémů a omezení",
    text:
      "• Stroj nefunguje → použijte analyzátor, ukáže chybějící palivo, napájení nebo zavřený ventil.\n• Reaktor nejde spustit → panel vypíše přesný důvod.\n• Multiblok zmizel → byl poškozen (výbuch, píst); vypadl předmět, postavte ho znovu.\n" +
      "Omezení: kapaliny se nezobrazují, potrubí přenáší jednotky; na židlích nelze sedět; ochranné vybavení se kreslí jednoduchou texturou; stroje rozbité výbuchem nebo příkazem mohou vypadnout bez předmětu; vlastní hudební disk není – VHS se přehrává v ÚstíOS.",
  },
];
