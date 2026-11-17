Sem patří natrénovaný model z Colabu:

    zed-4b-q4_k_m.gguf

Postup:
  1. Z notebooku train/colab_qlora.ipynb stáhni GGUF (Q4_K_M, ~2,5 GB)
  2. Nakopíruj ho do tohoto adresáře pod přesně tímto názvem
  3. gradle assembleRelease

Při prvním spuštění aplikace model jednorázově rozbalí do interního
úložiště (llama.cpp potřebuje běžný soubor, z APK ho mmapovat nelze).
Počítej proto s dvojnásobkem místa: 2,5 GB v APK + 2,5 GB rozbalené.

Když tady model není, aplikace ho nabídne ke stažení z URL
v ModelRepository.DEFAULT_URL — appka tedy jde postavit i bez něj.
