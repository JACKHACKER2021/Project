# RadioÚstí – add-on pro Minecraft Bedrock

**Zeds World • jaderný horor • ÚstíOS Longhorn Edition • zombie apokalypsa • středověká pevnost**
Autor projektu: **Jackhack2021** · Cíl: **Minecraft Bedrock 1.26.50** · Script API: `@minecraft/server` 2.0.0 a `@minecraft/server-ui` 2.0.0 (stabilní)

RadioÚstí přidává do světa Zeds World funkční potrubí a kabelové sítě, generátory 2×2, fiktivní jaderný reaktor, interaktivní počítače, systémový analyzátor, uran a kontaminaci, laboratoř, nemocnici a retro československé stavební bloky. Nechybí ani dokumenty a plakáty z roku 2072 a prvky středověké pevnosti.

> **Stav testování:** Všechno je **staticky ověřené**: JSON schémata, křížové odkazy, typová kontrola skriptů proti oficiálním typům API a skládání multibloků. **Ve hře zatím nic otestované není.** Seznam funkcí a jejich stav je v [FEATURES.md](FEATURES.md).

---

## Obsah
1. [Instalace](#instalace)
2. [Co add-on obsahuje](#co-add-on-obsahuje)
3. [Ovládání](#ovládání)
4. [Potrubí, ventily a kabely](#potrubí-ventily-a-kabely)
5. [Generátory a napájení](#generátory-a-napájení)
6. [Stavba a provoz reaktoru](#stavba-a-provoz-reaktoru)
7. [Počítače ÚstíOS a server](#počítače-ústíos-a-server)
8. [Systémový analyzátor](#systémový-analyzátor)
9. [Laboratoř, krev, maso, oleje](#laboratoř-krev-maso-oleje)
10. [Radiace a kontaminace](#radiace-a-kontaminace)
11. [Světla, alarmy, dveře, nábytek, dokumenty](#světla-alarmy-dveře-nábytek-dokumenty)
12. [Recepty a katalog](#recepty-a-katalog)
13. [Známá omezení](#známá-omezení)
14. [Vývoj (build, validace, balení)](#vývoj)

---

## Instalace

**Android / iOS:**
1. Stáhni `dist/RadioUsti.mcaddon`.
2. **Android:** otevři soubor (Soubory → klepnout → *Otevřít v Minecraftu*).
   **iOS:** aplikace Soubory → podržet soubor → *Sdílet* → *Minecraft*.
3. Minecraft naimportuje dva balíčky: *RadioÚstí — Behavior Pack* a *RadioÚstí — Resource Pack*.
4. Vytvoř nebo uprav svět → **Balíčky chování** → aktivuj *RadioÚstí — Behavior Pack* (resource pack se přidá sám jako závislost).
5. **Experimentální funkce nejsou potřeba.**
6. Doporučení pro testování: Nastavení → Tvůrce → zapni **Content Log**. Chyby se zobrazí přímo ve hře.

**Windows:** dvojklik na `RadioUsti.mcaddon`.

Pokud import celého `.mcaddon` selže, nainstaluj zvlášť `dist/RadioUsti_RP.mcpack` a `dist/RadioUsti_BP.mcpack`.

---

## Co add-on obsahuje

198 bloků a 70 předmětů (58 samostatných předmětů a 12 předmětů, kterými se pokládají multibloky a dveře; 10 bloků laboratorního skla se pokládá jeho předměty, 8 tekutin kbelíky). Úplný seznam s ID je v [docs/CATALOG.md](docs/CATALOG.md).

| Oblast | Obsah |
|---|---|
| **Potrubí** | vodovodní, tenké nástěnné, plynové, laboratorní plynové, na roztavený materiál, na radioaktivní kapalinu, průmyslové olejové + 5 ventilů |
| **Kabely** | elektrický, vysokonapěťový, laboratorní, nouzový, poškozený, počítačový síťový |
| **Generátory (multibloky)** | standardní, průmyslový, jaderný (2×2×2), záložní, laboratorní napájecí jednotka, serverová UPS (2×2) |
| **Reaktor** | jádro, plášť, průhledové sklo, chladicí, energetický a odpadní port, řídicí panel, chladicí jednotka, tlačítko nouzového odstavení, indikátor radiace, vodní čerpadlo, kontejner na odpad |
| **Počítače** | Starý počítač, kancelářský, laboratorní, průmyslový terminál, počítačová pracovní stanice, serverový rack |
| **Laboratoř** | pokládané baňky, zkumavky, láhve a nádoby (9 bloků), 8 stolů (laboratorní, chemická analýza, biologický výzkum, jaderný výzkum, testování kontaminace, příprava vzorků, průmyslový ponk, pracovní stanice), baňky, zkumavky, preparátové nádoby |
| **Uran a radiace** | uranová ruda (i hlubinná, generuje se ve světě), uranové bloky, kontaminovaná hlína, tráva a kámen, radioaktivní odpad, výstražné cedule |
| **Oleje** | průmyslový, černý strojní, žlutý hydraulický, červený laboratorní, zelený kontaminovaný, radioaktivní; každý má vlastní sud a kanystr |
| **Stavba** | blok cementu, žlutý starý cement, staré cihly a cihlová zeď, československá průmyslová stěna, blok domu (panelák), luxfery, HELP sklo, větrací blok, pojistková skříň |
| **Pevnost a apokalypsa** | kámen pevnosti (i popraskaný a zarostlý), boční blok hradu, hradní mříže, cimbuří, barikáda, ostnatý drát, pytle s pískem, bodce, suť, spálená prkna, zakrvácený beton |
| **Nábytek a nemocnice** | stoly, židle, otočná kancelářská židle, laboratorní židle, nemocniční lůžko a operační stůl (2 bloky), vyšetřovací lehátko, infuzní stojan, lékařský monitor, skříně |
| **Světla a alarmy** | průmyslová lampa, nástěnné, stropní, laboratorní a nouzové světlo, výstražný maják, starý světelný blok, alarm, radiační alarm |
| **Dveře** | laboratorní, průmyslové, kontejnmentové a dveře pevnosti (opravdu dva bloky vysoké) |
| **Lore** | 6 plakátů z roku 2072, rozházené papíry, oznámení, hromada dokumentů, nástěnné hodiny, historická fotografie, 8 čitelných dokumentů, VHS kazeta |
| **Horor** | krev, vzorky, maso, bloky masa, výrůstky, laboratorní odpad, esence duše, duší prostoupený kámen, krystal duše |
| **Nástroje** | systémový analyzátor, realistický krumpáč, dekontaminační souprava, plynová maska, ochranný oblek, příručka |

---

## Ovládání

| Akce | Jak |
|---|---|
| Otevřít stroj, počítač, panel nebo stůl | klepnutí / pravé tlačítko na blok |
| Položit blok k interaktivnímu bloku | **plížení** + položení (jinak se otevře rozhraní) |
| Ventil, světlo, dveře | klepnutí |
| Vložit palivo, plyn nebo olej | klepnout na stroj s předmětem v ruce |
| Prohlédnout blok | držet **Systémový analyzátor** a klepnout na blok |
| Číst dokument | použít předmět (podržet nebo klepnout do vzduchu); u plakátu klepnout na blok |
| Příručka | použít **Příručku RadioÚstí** |

---

## Potrubí, ventily a kabely
* Potrubí se při položení samo napojí ve všech 6 směrech na sousední potrubí **stejné rodiny** a na stroje, které danou látku přijímají. Tvar se vybírá automaticky: rovný kus, koleno, T-kus, kříž, svislý kus, příruby a u tenkého nástěnného potrubí i držák.
* Rodiny: **voda** (vodovodní a tenké nástěnné), **plyn** (plynové a laboratorní), **roztavený materiál**, **radioaktivní kapalina** a **olej** (průmyslové).
* **Ventil:** klepnutím ho otevřeš (zelená kontrolka) nebo zavřeš (červená). Zavřený ventil přeruší síť, takže stroje za ním přestanou látku dostávat.
* Kapaliny se **nezobrazují**. Simulace je zjednodušená: každé 2 s si stroje vezmou jednotky ze zdrojů v propojené síti.
* **Redstone jako zdroj energie (1.1):** **blok ruditu** položený vedle kabelu nebo přímo vedle stroje dodává do sítě stále **10 jednotek**. **Rudit (redstone prach)**, redstone pochodeň, páka, opakovač a komparátor dodávají jen tehdy, když vedou signál: **síla signálu ÷ 3, zaokrouhleno nahoru, max 5 jednotek** (plný signál 15 = 5 jednotek). Kabely se k těmto blokům samy napojí. Analyzátor i ÚstíOS ukazují, kolik energie jde z redstonu.
* **Kabely:** elektrický, vysokonapěťový, laboratorní a nouzový tvoří jednu energetickou síť. Délka sítě je omezená na 160 bodů, přičemž úsek vysokonapěťového kabelu se počítá jako 0,25 bodu. **Poškozený kabel** se sice napojí, ale energii nepřenáší. **Síťový kabel** přenáší jen data.

## Generátory a napájení
Generátory jsou multibloky. Rozšiřují se směrem od hráče a doleva. Když na ně není místo, stavba se zruší a předmět se vrátí. Když zničíš kteroukoli část, rozebere se celý stroj a vypadne jeden předmět.

| Stroj | Velikost | Výkon | Palivo |
|---|---|---|---|
| Standardní generátor | 2×2×2 | 20 | uhlí, dřevěné uhlí (40 cyklů), uhelný blok (360), kanystr průmyslového oleje (60); automaticky ze sudu průmyslového oleje přes průmyslové potrubí |
| Průmyslový generátor | 2×2×2 | 50 | láva přes potrubí na roztavený materiál, nebo 1 jednotka plynu za cyklus z plynové nádrže |
| Jaderný generátor | 2×2×2 | 120 | běžící reaktor ve stejné energetické síti |
| Záložní generátor | 2×2 | 15 | uhlí; spustí se jen tehdy, když ostatní zdroje nestačí |
| Laboratorní napájecí jednotka | 2×2 | baterie 2000 / ±20 | nabíjí se přebytkem sítě nebo ruditem (+50) a blokem ruditu (+450) |
| Serverová napájecí jednotka | 2×2 | baterie 4000 / ±30 | nabíjí se přebytkem sítě |

Jeden cyklus trvá 2 s. Spotřeba: počítač 2, server 5, laboratorní stanice 3 (jaderná 5). Síť je napájená, když výroba (včetně baterií) pokryje spotřebu.

## Stavba a provoz reaktoru
> Reaktor je **fiktivní herní mechanika**, nejde o návod na skutečné zařízení.

**Stavba (přesný postup, odpovídá kódu):**
1. Polož **Jádro reaktoru**.
2. Všech **26 bloků** kolem něj (kostka 3×3×3) musí tvořit plášť z těchto bloků: Plášť reaktoru, Průhledové sklo reaktoru, porty a Řídicí panel.
3. Do pláště zapoj alespoň **1× Chladicí port**, **1× Energetický port**, **1× Odpadní port** a **1× Řídicí panel**. Ostatní bloky pláště jsou Plášť nebo Sklo.
4. **Chlazení:** Chladicí port → vodovodní potrubí → **Chladicí jednotka reaktoru**. Do stejné vodní sítě připoj zdroj vody: **Vodní čerpadlo** položené vedle vodního bloku, nebo potrubí, které končí ve vodě. Ventily musí být otevřené. Stroje se připojují **přes potrubí**, nestačí je jen přiložit k sobě.
5. **Energie:** Energetický port → vysokonapěťový nebo elektrický kabel → **Jaderný generátor** → kabely ke spotřebičům.
6. **Odpad:** Odpadní port → potrubí na radioaktivní kapalinu → **Kontejner na radioaktivní odpad** (pojme 200 jednotek).
7. **Palivo:** na *Stole jaderného výzkumu* vyrob ze 2 uranových ingotů a kanystru radioaktivního oleje **Uranovou palivovou tyč**. Klepnutím s ní na Řídicí panel ji vložíš (vejdou se max. 4).

**Provoz:**
* **START** na řídicím panelu. Pokud reaktor nejde spustit, panel vypíše přesný důvod: neúplná stavba, chybí palivo, chlazení nebo zdroj vody, případně je jádro přehřáté nad 70 %.
* Jedna tyč vydrží 5 minut. S chlazením se teplota ustálí kolem 55 % a každá další chladicí jednotka ji sníží o 10 % (nejníž na 30 %).
* Bez chlazení teplota roste o 4 % za cyklus. Při **75 %** hlásí VAROVÁNÍ, při **90 %** KRITICKÝ STAV a při **95 %** se spustí automatický SCRAM, pokud je zapnutá ochrana. Při **100 %** dojde k **tavení jádra**: jádro se změní na *Poškozené jádro reaktoru*, okolí v okruhu 7 bloků se zamoří, objeví se radioaktivní odpad a nastane malý výbuch, který neničí bloky.
* Během provozu vzniká 1 jednotka odpadu každých 20 s. Když odpad nemá kam odtéct, hromadí se v reaktoru a od 10 jednotek uniká do okolí.
* **Odstavení:** SCRAM na řídicím panelu, v ÚstíOS (Dohled reaktoru), nebo **Tlačítkem nouzového odstavení**, které působí na reaktory do 24 bloků. Po vychladnutí pod 30 % stiskni **Reset**.

## Počítače ÚstíOS a server
Klepnutím na napájený počítač otevřeš **ÚstíOS Longhorn Edition**. Rozhraní je postavené na stabilních formulářích `@minecraft/server-ui` a nepoužívá žádná loga ani ochranné známky Microsoftu. Nabídka obsahuje:

Stav systému · Napájení · Připojené stroje · Dohled reaktoru (Start / SCRAM / Reset) · Diagnostika potrubí a kabelů · Historie alarmů · Dokumenty RadioÚstí (i tisk výpisu) · Laboratorní záznamy · Zprávy o kontaminaci · Síť a server · Přehrávač VHS · Vypnout / Restartovat

* Počítač vidí stroje do **8 bloků** a všechno, co je k němu připojené **síťovým kabelem**. Když je ve stejné datové síti napájený **Serverový rack**, vidí všechny stroje do **64 bloků**.
* Reaktor jde dálkově **spustit** jen přes datovou síť. **SCRAM** funguje vždy.
* Funkce, které zrovna nejsou k dispozici, mají v nabídce šedý popisek s vysvětlením.

## Systémový analyzátor
Drž analyzátor a klepni na libovolný blok. Analyzátor bloky nemění, například ventil s ním nepřepneš. Pro každý blok, i vanilla, ukáže podle sdíleného registru:
název, ID, typ, stav, napájení, propojení potrubí a kabelů včetně směrů a sousedů, souhrn sítě (úseky, stroje, zavřené ventily, poškozené kabely, zdroje), stav ventilu, generátoru, baterie, nádrže a reaktoru, příslušnost k multibloku a chybějící části, problémy (chybí palivo, napájení…) a radiaci v okolí.

## Laboratoř, krev, maso, oleje
* **Laboratorní stůl** je pracovní stůl na laboratorní sklo a vzorky, **Průmyslový ponk** je pracovní stůl na stroje, potrubí, kabely a oleje.
* **Zdroje:** zombie, husk, drowned a zombie vesničan po zabití hráčem upustí s 35% šancí *infikované maso* a s 15% šancí *láhev krve*. Infikované maso se v peci upeče na *kus masa* (jídlo). Esence duše vznikne z písku nebo hlíny duší a baňky.
* **Stanice** (ovládají se formulářem, mají skutečné vstupy a výstupy a kontrolují napájení i plyn):

| Stanice | Napájení | Procesy |
|---|---|---|
| Příprava vzorků | ne | láhev krve + 2 zkumavky → 2 vzorky krve (+ láhev) · infikované maso + vzorkovnice → vzorek tkáně · kontaminovaná hlína + vzorkovnice → vzorek půdy · nádoba s krví + 2 láhve → 2 láhve krve |
| Biologický výzkum | 3 | vzorek krve + modré činidlo → záznam z výzkumu (+ 30 % sérum Zed) · vzorek tkáně + modré činidlo → 2× organický materiál |
| Chemická analýza | 3 + plyn + náplň | zelené činidlo + 2 sušené chaluhy → 3 antiradiační tablety · vzorek krve + červené činidlo → laboratorní zpráva. Náplň doplníš kanystrem červeného oleje (+8). |
| Jaderný výzkum | 5 | 2 uranové ingoty + radioaktivní olej → palivová tyč · 4 surový uran + červený olej → 3 uranové ingoty · měření radiace |
| Testování kontaminace | 3 | vzorek půdy + červené činidlo → zpráva o kontaminaci · zelený olej + zelené činidlo → průmyslový olej · dekontaminace osoby (−25 dávky) |

* **Laboratorní sklo jako bloky (1.1):** Erlenmeyerova baňka, baňky s červeným, zeleným a modrým činidlem (kulaté dno), zkumavka, vzorek krve (zkumavka ve stojánku), láhev krve, prázdná nádoba a nádoba s krví se **pokládají jako bloky** s vlastním 3D modelem a průhledným sklem s viditelnou náplní. Polož je klepnutím předmětem na blok (na stůl nebo na zem). Po rozbití vrátí stejný předmět, takže je dál můžeš používat v receptech a na stanicích.
* **Preparátová nádoba:** naplníš ji klepnutím s lahví krve, infikovaným masem nebo esencí duše. Krev z ní vybereš skleněnou lahví.
* **Oleje mají každý jinou funkci:** průmyslový je palivo standardního generátoru · černý strojní je surovina pro generátory, čerpadla a těžké dveře · žlutý hydraulický je surovina pro kontejnmentové dveře a řídicí panel · červený laboratorní slouží jako náplň chemické analýzy a k obohacování uranu · zelený kontaminovaný se dekontaminuje na průmyslový · radioaktivní je potřeba na palivové tyče.

## Radiace a kontaminace
* **Zdroje:** uranová ruda a bloky, kontaminovaný terén, radioaktivní odpad, poškozené jádro, běžící nebo unikající reaktor a radioaktivní předměty v inventáři.
* Každé 2 s se dávka přičte podle zdrojů v okruhu 4 bloků. Nad lištou se zobrazí míra a dávka a ozve se Geigerův počítač. Mimo zdroje dávka pomalu klesá.
* **Efekt Radiace (1.5):** vlastní stav ve 4 stupních, zobrazený pod středem obrazovky jako „☢ Radiace I–IV“ a zelenými jiskrami kolem postižených:
  * **I** (dávka 25): nevolnost.
  * **II** (50): slabost, zpomalení a hlad.
  * **III** (75): radiační zásahy za 1 HP každé 2 s.
  * **IV** (100): smrtelné zásahy za 3 HP každé 2 s.
  * Maximum dávky je 150.
  * Bedrock add-ony neumí zaregistrovat vlastní efekt do seznamu efektů s ikonou, proto ho řídí skript.
* **Zvířata a tvorové (1.5):** všichni živí tvorové do 32 bloků od hráče (zvířata, vesničané, příšery kromě nemrtvých) sbírají dávku v radioaktivním dešti pod otevřeným nebem, na zamořené zemi a v radioaktivních tekutinách. Ve stupni III a IV dostávají zásahy a umírají. Nemrtví (zombie, kostlivci) jsou imunní, protože patří k Zedům. Vypnutí: `/scriptevent radiousti:config mobradiation off`.
* **Ochrana:** plynová maska −30 %, ochranný oblek −50 %, obojí dohromady −65 %. **Léčba:** antiradiační tablety (−40), sérum Zed (−10 a regenerace), dekontaminace osoby.
* **Šíření:** radioaktivní odpad zhruba každých 30–60 s zamoří náhodný blok v okruhu 2. Kontaminovanou hlínu, trávu a kámen vyčistí **dekontaminační souprava** (32 použití).
* **Nastavení** (příkazy jako operátor):
  `/scriptevent radiousti:config radiation off` nebo `on` · `… multiplier 0.5` · `… wastespread off` · `… explosion off` · `… zeddrops off` · `/scriptevent radiousti:status`

## Světla, alarmy, dveře, nábytek, dokumenty
* **Světla** se přepínají klepnutím a opravdu mění úroveň světla (stav `lit` s permutací `minecraft:light_emission`). **Výstražný maják** se sám rozsvítí při poplachu reaktoru do 32 bloků, **nouzové světlo** při výpadku napájení do 16 bloků.
* **Alarm** se spustí, když je reaktor do 32 bloků ve stavu VAROVÁNÍ, KRITICKÝ STAV nebo TAVENÍ, a také při radiaci v okolí nebo když je poblíž ozářený hráč. Klepnutím na znějící alarm ho ztlumíš na 60 s, klepnutím na tichý alarm spustíš test. Každé spuštění se zapíše do historie alarmů.
* **Dveře** jsou dva bloky vysoké. Otevřeš je klepnutím na kteroukoli polovinu. Když zničíš jednu polovinu, zmizí obě a vypadne jeden předmět.
* **Nemocniční lůžko** a **operační stůl** jsou dva bloky dlouhé. Klepnutím na lůžko si nastavíš bod oživení. **Otočná kancelářská židle** se po klepnutí otočí o 90°.
* **Plakáty, oznámení, papíry, hromada dokumentů a fotografie** si přečteš klepnutím. **Nástěnné hodiny** ukážou herní čas.

## Prostředí a nové lokace (1.4)
**Obloha a počasí**
* Obloha je ve všech biomech overworldu trvale **nazelenalá**. Na vanilla biomy se přidá jen barva oblohy a atmosféra RadioÚstí, hudba, zvuky a barva vody zůstávají.
* **Mlha podle denní doby** (příkaz `/fog`, který skript zadává každých 5 s): ve dne zelená, večer a za úsvitu načervenalá, v noci rudá.
* S grafikou **Vibrant Visuals** se podle času plynule barví i celé nebe: zelené ve dne, oranžovo-rudé při západu a východu slunce, krvavě rudé v noci.
* **Smog:** zhruba jednou za 20 minut se na 2–5 minut převalí hustý smog s dohledností asi 36 bloků.
* **Radioaktivní déšť:** v dešti pod otevřeným nebem dostáváš 0,6 mSv/s (maska a oblek to snižují) a nad lištou se objeví varování. Déšť navíc pomalu mění trávu v okolí hráčů na kontaminovanou.
* Nastavení: `/scriptevent radiousti:config environment off` · `… rainradiation off` · `… smog 3` (spustí smog na 3 minuty).

**Nové bloky pro lokace**
| Lokace | Bloky |
|---|---|
| Pennov Theater | divadelní sedadlo (i zaprášené), jevištní opona, jevištní reflektor (vypínací), modré krystalické usazeniny |
| Pennov CWT | televizor CWT (zapnutý ukazuje šum), vysílací anténa, regál obchodního domu, pokladna |
| Pennov School | školní lavice, školní tabule (čitelná) |
| Pennov Jídelna | jídelní stůl s lavicemi, tác s jídlem, výdejní pult, kuchyňský kotel |
| Pennov Showers | obklad sprch (bílý, špinavý, modrý), sprcha (zapnutá stříká vodu), podlahová vpust |
| RadioÚstí Laboratory | olověná stěna, sklo hermetické komory, laboratorní dřez, radioaktivní kal (tekutina) |
| RadioÚstí Fortress | ohniště pevnosti (hoří a svítí), sloup pevnosti |
| RadioÚstí Nuclear Power Plant | beton chladicí věže, výstražná podlaha, pletivový plot, výpusť páry (kouří), pult velínu |

**3D rudy:** uranová, hlubinná uranová a liverocrystalová ruda mají vlastní model s krystalky, které vystupují ze všech stran kamene.

**Oprava názvů (1.5):** jazykové soubory teď obsahují všechny tvary klíčů, které hra může použít (`item.radiousti:…`, `item.radiousti:….name`, `tile.radiousti:….name`), a k tomu je název zapsaný přímo v definici.

**Oprava názvů (1.4):** v 1.0–1.3 se u některých bloků a předmětů ukazovaly klíče typu `item.radiousti…`. Názvy jsou teď přímo v definicích (česky), takže se zobrazí vždy.

## Liverocrystal, biogenní sérum a tekutiny (1.3)
* **Liverocrystalová ruda** se generuje hluboko pod zemí (y −60 až −10, nahrazuje kámen, deepslate i tuff) a dává 1–2 **úlomky Liverocrystalu**.
* **Ingot Liverocrystal Metal** = 4 úlomky + železný ingot (Průmyslový ponk). Z ingotů vyrobíš **blok Liverocrystal Metal**, **pancéřovou desku** (odolnost proti výbuchu 1200, těžba 15 s) a **nádrž Liverocrystal Gas**.
* **Kanystr Liverocrystal Gas** (prázdný kanystr + 3 úlomky) přidá do nádrže Liverocrystal Gas 300 jednotek plynu. Nádrž pojme 3000 jednotek a funguje jako každá plynová nádrž: zásobuje průmyslový generátor a chemickou analýzu přes plynové potrubí.
* **Toxické výpary:** ruda, shluky Liverocrystalu a nádrž Liverocrystal Gas otráví každého hráče do 3 bloků, který nemá nasazenou **plynovou masku** (otrava + nevolnost, varování nad lištou).
* **Biogenní sérum B-9** (baňka + organický materiál + esence duše): vypití dá regeneraci II na 15 s a krátkou nevolnost. Sérum jde položit jako ampuli ve stojánku. Ke dekoraci slouží i **kádě s biogenním sérem**.
* **Tekutiny:** krev, průmyslový, černý, hydraulický, laboratorní, kontaminovaný a radioaktivní olej. Bedrock add-ony neumí vlastní opravdové tekutiny, takže jsou to **průhledné tekuté bloky**, které skript nechá stékat dolů a rozlévat se do stran až na 4 bloky s klesající hladinou. Když přívod zmizí, rozlitá tekutina vyschne.
  * **Kbelík:** vanilla kbelík + kanystr oleje (Průmyslový ponk), nebo + nádoba s krví (Laboratorní stůl). Plným kbelíkem tekutinu vyliješ, prázdným kbelíkem nabereš zdroj.
  * **Efekty:** ve tekutině jsi zpomalený. Krev způsobí nevolnost, černý olej slepotu, laboratorní olej slabost a kontaminovaný otravu. Radioaktivní olej svítí a ozařuje.
* **Vylepšený vzhled (1.3):** nové modely všech počítačů, serverového racku, dveří (rám, klika), plynové nádrže, vodního čerpadla, chladicí jednotky a generátorů (výfuky, potrubí, výstražné štítky). Kovové textury mají zkosené hrany a všechny ikony předmětů obrys a odlesk.

## Registr experimentů (1.2)
Kniha **Registr experimentů – Projekt Apokalypsa** (kniha + červená barva + inkoustový váček) obsahuje 13 kapitol o světě Zeds World:
úvod a časovou osu 2072–2084, první subjekty (Rogerovy děti Lazy Bunny a Softy), vedení (Roger Smith, Zedonar, Zeds Corp, Mike Jasday, FBI, Zéd), U256 Radiak, sérii EX-001 až EX-011, organické hračky, pennovské hrozby, absolutní mutanty, experimenty mimo Rogera, materiály (uran, biogenní sérum, Liverocrystal Gas a Metal), místa zkázy a uzavřené spisy.
Přečteš ji použitím předmětu, nebo v ÚstíOS → Dokumenty RadioÚstí. Spisy dětských subjektů a všechen intimní obsah z archivu do knihy nepatří a jsou vedené jen jako uzavřené.

## Recepty a katalog
* Všechny recepty: [docs/RECIPES.md](docs/RECIPES.md) (175 receptů, generuje se automaticky z kódu).
* Všechny bloky a předměty s ID: [docs/CATALOG.md](docs/CATALOG.md).
* Ve hře je k dispozici **Příručka RadioÚstí** (kniha + žlutá barva) se 13 kapitolami.

## Známá omezení
* **Nic zatím nebylo testováno ve hře.** Viz [FEATURES.md](FEATURES.md).
* V potrubí se kapaliny nezobrazují, potrubí přenáší jen jednotky (zjednodušená síť). Krev a oleje mimo potrubí jsou skriptové tekuté bloky, nedá se v nich plavat a netečou tak plynule jako voda.
* Na židlích nejde sedět, protože by to vyžadovalo vlastní entitu.
* Multibloky a dveře zničené výbuchem, pístem nebo příkazem neupustí předmět, protože skript ví jen o rozbití hráčem. U generátorů a napájecích jednotek se zbylé části při dalším cyklu (do 2 s) bezpečně odstraní a vypadne jeden předmět; u lůžka a operačního stolu zbylá část zůstane a stačí ji rozbít.
* Vlastní hudební disk by musel přepsat zvuk některého vanilla disku, proto se VHS kazeta přehrává v ÚstíOS (Přehrávač VHS).
* Plynová maska a oblek používají vanilla geometrii zbroje s jednoduchou texturou (vzhled zatím neověřený).
* Realistický krumpáč snižuje výdrž skriptem. Kdyby hra výdrž snižovala i sama, opotřebovával by se dvojnásobně (zatím neověřeno).
* Kontaminovaný terén se ve světě negeneruje přirozeně. Vzniká z reaktoru a odpadu, nebo ho položíš ručně. Uranová ruda se generuje (feature rule v podzemí overworldu, y −48 až 24).

---

## Vývoj
Obsah se generuje z jednoho registru `tools/content.py` (bloky, předměty, textury) + `tools/recipes.py` + `tools/geo.py` (geometrie) + `tools/sounds.py`. Herní logika je ručně psaná v `RadioUsti_BP/scripts/` (kromě `scripts/data/registry.js`).

```bash
python3 tools/build.py      # vygeneruje bloky, předměty, geometrie, textury, zvuky, lang, recepty, docs
python3 tools/validate.py   # statická validace (0 chyb = OK)
python3 tools/package.py    # build + validace + dist/RadioUsti.mcaddon (+ .mcpack)
```
Potřeba: Python 3.10+, Pillow, numpy, ffmpeg (zvuky .ogg; bez něj .wav), volitelně Node.js (kontrola syntaxe skriptů).

**Struktura:**
```
RadioUsti/
├─ RadioUsti_BP/   manifest, blocks/, items/, recipes/, loot_tables/, features/, feature_rules/, scripts/
├─ RadioUsti_RP/   manifest, models/blocks/, textures/, sounds/, texts/, attachables/, blocks.json
├─ tools/          build.py, validate.py, package.py, content.py, geo.py, textures.py, recipes.py, sounds.py
├─ docs/           CLAUDE_TASK.md (zadání ze starteru), CATALOG.md, RECIPES.md
├─ dist/           RadioUsti.mcaddon, RadioUsti_BP.mcpack, RadioUsti_RP.mcpack
├─ FEATURES.md     stav funkcí
└─ CHANGELOG.md
```
