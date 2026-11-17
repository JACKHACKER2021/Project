# 3D modely budov (low-poly, GLB)

Stylizované pohádkové low-poly budovy pro mobilní hru. Každý model je
samostatný, bez terénu.

## Konvence
- **Formát:** GLB (glTF 2.0), ploché normály, jeden flat PBR materiál na barvu
  (žádné textury → malé soubory, snadné přebarvení v enginu).
- **Osy:** Y nahoru, model vycentrovaný na XZ, spodek na `y = 0`.
- **Vchod směřuje na +Z** (dopředu).
- **Měřítko:** 1 jednotka = 1 metr.
- **Polygony:** všechny modely výrazně pod limitem 15 000 trojúhelníků
  (max ~5 600 u vlaku).

## Generování
```bash
pip install trimesh numpy
cd tools/models3d
python3 b_radnice.py        # jeden model
ROOF=0 python3 b_vezeni.py  # věznice bez střechy
python3 check.py            # kontrola polygonů, vycentrování, dosedu na zem
node shot.js                # náhledy do prev/ (vyžaduje playwright + chromium)
```
`lib3d.py` obsahuje paletu pastelových barev a stavební prvky
(kvádr, válec, sedlová střecha, jehlan, okno s rámem, schody, plot).

## Modely (`out/`)
| soubor | popis |
|---|---|
| radnice | dvoupatrová radnice, hodinová věžička, široké schody, prapory, sklepní dveře vzadu |
| nemocnice | bílá třípatrová, červený kříž, jedna strana poškozená (rozbitá okna, oprýskaná omítka, skvrny) |
| vezeni / vezeni_bez_strechy | kámen, mřížované okno, kovové dveře, chodba a 3 cely, díra v zadní stěně cely, plot s ostnatým drátem |
| soud | sloupový portikus, schody, štít s nápisem SOUD |
| obchod_sladkosti | tmavý dub, výloha se sladkostmi, pruhovaná markýza, cedule-lízátko, schody do skladu |
| kouzelnicin_dum | křivé okenice, kulaté okno v podkroví, fialový kouř, bylinky, zarostlá zahrádka |
| dum_kovarikovi / _zniceny | rodinný domek se žlutými okny a verandou + zničená verze |
| restaurace_zlata_vidlicka | zlatý vidličkový štít, velká okna se stoly, nazelenalé světlo z kuchyně |
| myslivna | srubová chata, mechová střecha, veranda, komín, dveře se závorou |
| strazni_vez | tmavá věž s reflektorem, schody kolem, plošina se zábradlím |
| hrbitov (+ _brana, _zed, _kriz, _nahrobky) | brána, částečně rozbitá zeď, hliněný kříž, sada náhrobků |
| kasna | kulatá kašna se sochou, tekoucí voda, lavičky, modré mozaiky |
| pomnik_u_koleji | dva kameny (modrý Leox, červený Nelea), svíčky, květiny, kousek kolejí |
| vlak_regionova | tři žlutozelené vagony, kulatá čela, rudé reflektory |
| zavodni_draha | startovní brána z lízátek, startovní čára, tribuna, vlajky |
| lapisovy_portal | obsidiánový rám, modrá zářící výplň, páka |
| plazova_lehatka | tři pruhovaná lehátka, dva slunečníky, stolek |

Náhledy: `prev/` (dva pohledy na model), přehled v `prev/_sheet.png`.
