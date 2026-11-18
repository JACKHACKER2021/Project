# -*- coding: utf-8 -*-
"""
Pustí zkoušku na GGUF modelu přes llama-cli a výstup uloží do souboru.

    python3 zedsworld_ai/eval/run_eval.py <model.gguf> [výstup.md]
"""
import subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "eval"))
sys.path.insert(0, str(ROOT / "data"))

from questions import CATEGORIES          # noqa: E402
from lore_zedsworld import SYSTEM         # noqa: E402

CLI = "/home/user/llama.cpp-new/build/bin/llama-cli"


def ask(model: str, question: str, n: int = 220) -> str:
    out = subprocess.run(
        [CLI, "-m", model, "-sys", SYSTEM, "-p", question,
         "-n", str(n), "-t", "4", "--temp", "0.7", "--single-turn", "--no-warmup"],
        capture_output=True, text=True, timeout=900,
    ).stdout
    # llama-cli vypíše banner a pak "> otázka\nodpověď"; bereme, co je za otázkou.
    if "> " + question in out:
        out = out.split("> " + question, 1)[1]
    for cut in ("[ Prompt:", "Exiting"):
        out = out.split(cut)[0]
    return out.strip()


def main() -> None:
    model = sys.argv[1]
    dest = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ROOT / "eval" / "vysledek.md")
    lines = [f"# Zkouška modelu\n\n`{model}`\n"]
    for name, weight, questions in CATEGORIES:
        print(f"→ {name}", flush=True)
        lines.append(f"\n## {name} ({weight} %)\n")
        for q in questions:
            print(f"   {q[:50]}", flush=True)
            lines.append(f"\n**{q}**\n\n{ask(model, q)}\n")
    dest.write_text("\n".join(lines), encoding="utf-8")
    print("✓", dest)


if __name__ == "__main__":
    main()
