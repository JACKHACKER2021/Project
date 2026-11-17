# Zeds World AI — „Zed"

Vlastní chatbot pro multivesmír **Zeds World** (autor: Jackhack):
fine-tune malého open-source modelu, převod do GGUF a Android aplikace,
ve které model běží **offline přímo v telefonu**.

## Stav

| fáze | co | stav |
|---|---|---|
| 1 | dataset (lore + GDScript) | ✅ hotovo |
| 2 | QLoRA trénink (Colab, T4) | ✅ notebook hotový |
| 3 | převod do GGUF Q4_K_M | ✅ součást notebooku |
| 4 | Android APK (llama.cpp) | ✅ sestaveno, 8,4 MB |
| 5 | OCR skenů + Python (Chaquopy) | ⬜ čeká |

**Cílová konfigurace:** Qwen3 4B → Q4_K_M (~2,5 GB), telefon s 8 GB RAM.

## 1. Dataset

```bash
python3 zedsworld_ai/data/build_dataset.py
```

Vytvoří `data/dataset.jsonl` ve formátu `{"messages":[...]}`.

Zdroje:

| zdroj | co obsahuje |
|---|---|
| `data/lore_zedsworld.py` | kánon Zeds World — lore, roleplay, scénáře, styl. Ručně psané. |
| `**/*.gd` v repozitáři | GDScript funkce a hlavičky skriptů → kódovací styl projektu |
| `data/seed_cs.jsonl` | volitelné další ruční příklady (`instruction`, `output`, `tag`) |

Lore příklady se opakují `LORE_REPEAT`× a GDScript je zastropovaný
na `GDSCRIPT_CAP` — bez toho by kód převážil a vznikl by kodér
bez znalosti světa.

**Nejlepší investice do kvality je přidat další záznamy do
`lore_zedsworld.py`.** Čím víc ručně psaných odpovědí ve správném tónu,
tím lepší model. Cíl je 150–300 lore příkladů.

## 2.–3. Trénink a GGUF

Otevři `train/colab_qlora.ipynb` v Google Colabu
(**Runtime → Change runtime type → T4 GPU**) a spusť buňky odshora dolů.
Trvá 1–2 h. Notebook na konci vyrobí `zed-4b-q4_k_m.gguf` a uloží
ho na Google Drive.

Ladicí tabulka (co dělat, když výsledek nesedí) je na konci notebooku.

## 4. Android aplikace

```bash
cd zedsworld_ai/android
ANDROID_HOME=<cesta k SDK> gradle assembleRelease
# → app/build/outputs/apk/release/app-release.apk
```

Potřebuje Android SDK 35, build-tools 35.0.0, NDK 27 a CMake 3.22.
`llama.cpp` si stáhne CMake sám (FetchContent, tag `b4585`).

**Co aplikace umí**

| | |
|---|---|
| Chat s Zedem | offline, model běží na CPU telefonu |
| Roleplay | přepínač v liště; model vede scénu a hraje za svět |
| Dílna | projekty na disku; kód z odpovědí se ukládá jako soubory |
| Náhled | HTML, three.js a SVG se zobrazí hned ve WebView |
| Godot | vygeneruje platný projekt 4.3 a zabalí ho do ZIPu |
| PDF dovnitř | PdfBox vytáhne text a předá ho modelu do kontextu |
| PDF naven | export přes systémový tiskový dialog |

**Model v APK není.** Má 2,5 GB a Google Play má limit 150 MB, takže se
stahuje při prvním spuštění do interního úložiště. Stahování jde přerušit
a pokračovat. URL se nastavuje v `ModelRepository.DEFAULT_URL` — teď míří
na základní Qwen3 4B, takže aplikace jde vyzkoušet ještě před fine-tunem.
Po fázi 3 tam patří odkaz na vlastní `zed-4b-q4_k_m.gguf`.

**Co aplikace nedělá a proč**

- **Nesestaví APK.** To musí udělat Godot, ne model. Aplikace projekt
  připraví a předá; export na telefonu zvládne **Godot Android editor**
  (4.2+): Project → Export → Android.
- **Negeneruje obrázky ani videa.** Jazykový model neumí kreslit. Reálně
  z něj dostaneš SVG a procedurální grafiku v kódu. Opravdový obrázkový
  generátor je druhý model a vedle 4B se do 8 GB RAM nevejde.
- **Nečte skenovaná PDF.** Bez textové vrstvy je potřeba OCR — fáze 5.

## 5. Co zbývá

- **OCR** pro skenovaná PDF (ML Kit; přidá do APK ~60 MB)
- **Python** přes Chaquopy — skutečný CPython v APK, aby šel spouštět
  vygenerovaný kód
- **Víc lore příkladů** v `lore_zedsworld.py`; 90 je na solidní fine-tune
  pořád málo, cíl je 150–300
