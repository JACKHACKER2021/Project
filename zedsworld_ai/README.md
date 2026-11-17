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
| 4 | Android APK (llama.cpp) | ⬜ čeká |

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

## 4. Android APK

Zatím nepostaveno. Plán: Kotlin + `llama.cpp` přes JNI, model se stahuje
při prvním spuštění (do APK se 2,5 GB nevejde, Google Play má limit 150 MB).

Poznámka k rozsahu: model umí psát GDScript, ale APK z Godot projektu
nesestaví — to musí udělat Godot. Na telefonu to jde přes **Godot Android
editor** (od verze 4.2), který export APK zvládne přímo na zařízení.
