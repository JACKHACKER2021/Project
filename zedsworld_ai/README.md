# Zeds World AI

Vlastní chatbot pro Zeds World: fine-tune malého open-source modelu (QLoRA),
převod do GGUF a Android APK, ve které model běží offline v telefonu.

## Stav

| fáze | co | stav |
|---|---|---|
| 1 | dataset builder | rozpracováno |
| 2 | QLoRA trénink (Colab) | čeká |
| 3 | převod do GGUF Q4_K_M | čeká |
| 4 | Android APK (llama.cpp) | čeká |

Cílová konfigurace: Qwen3 4B, Q4_K_M (~2,5 GB), telefon s 8 GB RAM.

## Dataset

```
python3 zedsworld_ai/data/build_dataset.py
```

Vytvoří `data/dataset.jsonl` (formát `{"messages":[...]}`).

Zdroje:

- **GDScript** – funkce a hlavičky skriptů z `*.gd` v tomto repozitáři.
  Učí model psát Godot 4.3 kód ve stylu projektu. Funkční.
- **Lore a roleplay Zeds World** – zatím chybí. Builder momentálně čte
  dialogy z Night at Voxie's, což **není** lore Zeds World a bude vyměněno,
  až budou k dispozici vlastní texty.
- **`data/seed_cs.jsonl`** – ruční příklady (jeden JSON na řádek,
  klíče `instruction`, `output`, volitelně `tag`). Volitelný soubor.
