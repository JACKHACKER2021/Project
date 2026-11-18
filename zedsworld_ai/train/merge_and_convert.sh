#!/usr/bin/env bash
# Spojí LoRA adaptér se základním modelem a vyrobí GGUF.
#
#   ./merge_and_convert.sh <adapter_dir> <llama_cpp_dir> <out.gguf> [kvantizace]
set -euo pipefail

ADAPTER="${1:?adapter dir}"
LLAMA="${2:?llama.cpp dir}"
OUT="${3:?výstupní .gguf}"
QUANT="${4:-Q8_0}"      # malé modely: Q8_0; 4B a víc: Q4_K_M

MERGED="$(dirname "$OUT")/merged-hf"
mkdir -p "$(dirname "$OUT")"

echo "→ spojuji adaptér se základním modelem"
python3 - "$ADAPTER" "$MERGED" <<'PY'
import sys, torch
from peft import AutoPeftModelForCausalLM
from transformers import AutoTokenizer
adapter, out = sys.argv[1], sys.argv[2]
m = AutoPeftModelForCausalLM.from_pretrained(adapter, torch_dtype=torch.float32)
m = m.merge_and_unload()
m.save_pretrained(out, safe_serialization=True)
AutoTokenizer.from_pretrained(adapter).save_pretrained(out)
print("✓ spojeno")
PY

echo "→ konverze do GGUF (f16)"
python3 "$LLAMA/convert_hf_to_gguf.py" "$MERGED" \
        --outfile "${OUT%.gguf}-f16.gguf" --outtype f16

echo "→ kvantizace na $QUANT"
"$LLAMA/build/bin/llama-quantize" "${OUT%.gguf}-f16.gguf" "$OUT" "$QUANT"

rm -f "${OUT%.gguf}-f16.gguf"
rm -rf "$MERGED"
ls -lh "$OUT"
