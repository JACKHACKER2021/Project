#!/usr/bin/env python3
"""LoRA fine-tune malého modelu na CPU. Pro stroje bez GPU.

Colab verze (train/colab_qlora.ipynb) trénuje Qwen3 4B na GPU a je to
kvalitní cesta. Tenhle skript je nouzová varianta: Qwen3 0.6B na CPU,
řádově hodiny místo dní. Výsledek je slabší, ale skutečný.

Spuštění:
    python3 zedsworld_ai/train/train_cpu.py --epochs 2
"""
import argparse, json, os, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model",   default="Qwen/Qwen3-0.6B")
    ap.add_argument("--data",    default=str(ROOT / "data" / "dataset.jsonl"))
    ap.add_argument("--out",     default=str(ROOT / "out" / "zed-lora"))
    ap.add_argument("--epochs",  type=float, default=2.0)
    ap.add_argument("--seq",     type=int, default=1024)
    ap.add_argument("--lr",      type=float, default=2e-4)
    ap.add_argument("--rank",    type=int, default=16)
    ap.add_argument("--threads", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--max-steps", type=int, default=-1, help="jen pro zkoušku")
    args = ap.parse_args()

    import torch
    torch.set_num_threads(args.threads)

    from datasets import load_dataset
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import LoraConfig, get_peft_model
    from trl import SFTTrainer, SFTConfig

    print(f"→ {args.threads} vláken, CPU, float32")

    tok = AutoTokenizer.from_pretrained(args.model)

    # Plain ChatML bez <think> bloků – aplikace staví prompt stejně (ChatEngine.kt).
    def to_text(batch):
        out = []
        for msgs in batch["messages"]:
            s = ""
            for m in msgs:
                s += f"<|im_start|>{m['role']}\n{m['content']}<|im_end|>\n"
            out.append(s)
        return {"text": out}

    ds = load_dataset("json", data_files=args.data, split="train")
    ds = ds.map(to_text, batched=True, remove_columns=ds.column_names)

    n_tok = sum(len(tok(t).input_ids) for t in ds["text"])
    print(f"→ {len(ds)} vzorků, {n_tok:,} tokenů "
          f"(~{n_tok * args.epochs / 1000:.0f}k tokenů tréninku)")

    model = AutoModelForCausalLM.from_pretrained(
        args.model, torch_dtype=torch.float32, attn_implementation="eager",
    )
    model.config.use_cache = False
    # Gradient checkpointing tady nedává smysl: 0.6B se do 15 GB vejde snadno
    # a na CPU by to stálo ~30 % výkonu.

    model = get_peft_model(model, LoraConfig(
        r=args.rank, lora_alpha=args.rank * 2, lora_dropout=0.05, bias="none",
        task_type="CAUSAL_LM",
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                        "gate_proj", "up_proj", "down_proj"],
    ))
    model.print_trainable_parameters()

    trainer = SFTTrainer(
        model=model,
        train_dataset=ds,
        processing_class=tok,
        args=SFTConfig(
            output_dir=args.out,
            per_device_train_batch_size=1,
            gradient_accumulation_steps=8,
            num_train_epochs=args.epochs,
            max_steps=args.max_steps,
            learning_rate=args.lr,
            warmup_ratio=0.05,
            lr_scheduler_type="cosine",
            logging_steps=5,
            save_strategy="epoch",
            save_total_limit=1,
            optim="adamw_torch",
            weight_decay=0.01,
            max_seq_length=args.seq,
            dataset_text_field="text",
            packing=True,          # bez paddingu – na CPU klíčové
            report_to="none",
            seed=1337,
            use_cpu=True,
        ),
    )

    t0 = time.time()
    trainer.train()
    print(f"→ trénink hotov za {(time.time() - t0) / 60:.1f} min")

    trainer.model.save_pretrained(args.out)
    tok.save_pretrained(args.out)
    print(f"✓ adaptér uložen: {args.out}")

if __name__ == "__main__":
    main()
