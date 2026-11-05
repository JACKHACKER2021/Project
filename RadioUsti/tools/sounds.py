"""Procedurally synthesised retro-industrial sounds (mono .ogg via ffmpeg, fallback .wav)."""
import os
import shutil
import subprocess
import tempfile
import wave

import numpy as np

SR = 22050
SOUNDS = {}  # id -> (filename, category, volume)


def _env(n, a=0.01, r=0.1):
    e = np.ones(n)
    ai, ri = int(a * SR), int(r * SR)
    if ai:
        e[:ai] = np.linspace(0, 1, ai)
    if ri:
        e[-ri:] = np.linspace(1, 0, ri)
    return e


def tone(f, d, kind="sine"):
    t = np.arange(int(d * SR)) / SR
    if kind == "square":
        return np.sign(np.sin(2 * np.pi * f * t))
    if kind == "saw":
        return 2 * (t * f - np.floor(0.5 + t * f))
    return np.sin(2 * np.pi * f * t)


def noise(d, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(round(d * SR)))


def lowpass(x, k=8):
    return np.convolve(x, np.ones(k) / k, mode="same")


def make():
    s = {}
    # alarm: two-tone siren
    s["alarm"] = np.concatenate([tone(660, 0.35, "square") * 0.5, tone(880, 0.35, "square") * 0.5]) * _env(int(0.7 * SR), 0.01, 0.05)
    # air-raid siren: slow rising and falling wail
    t = np.arange(int(4.0 * SR)) / SR
    f = 330 + 260 * (0.5 - 0.5 * np.cos(2 * np.pi * t / 4.0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    s["siren"] = (np.sin(ph) * 0.45 + np.sign(np.sin(ph * 2)) * 0.12) * _env(len(t), 0.3, 0.6)
    s["nuke_blast"] = lowpass(noise(3.0, 77), 60) * np.exp(-np.arange(int(3.0 * SR)) / SR * 1.2) * 1.4
    # radiation alarm: fast beeps
    beep = np.concatenate([tone(1200, 0.08, "square") * 0.5, np.zeros(int(0.07 * SR))])
    s["radiation_alarm"] = np.tile(beep, 4)
    # geiger clicks
    g = np.zeros(int(0.5 * SR))
    rng = np.random.default_rng(7)
    for p in rng.integers(0, len(g) - 80, 9):
        g[p:p + 60] += noise(60 / SR, int(p)) * np.linspace(1, 0, 60)
    s["geiger"] = g * 0.8
    # valve: squeaky turn + hiss
    t = np.arange(int(0.45 * SR)) / SR
    squeak = np.sin(2 * np.pi * (300 + 500 * t) * t) * 0.3
    s["valve"] = (squeak + lowpass(noise(0.45, 3), 3) * 0.25) * _env(len(t), 0.02, 0.2)
    # pc boot: rising chord
    s["pc_boot"] = np.concatenate([tone(f, 0.18) * 0.35 * _env(int(0.18 * SR), 0.01, 0.08) for f in (392, 523, 659, 784)])
    s["pc_click"] = tone(1800, 0.03, "square") * 0.3 * _env(int(0.03 * SR), 0.001, 0.02)
    s["pc_error"] = np.concatenate([tone(220, 0.15, "square") * 0.4, tone(165, 0.25, "square") * 0.4])
    # generator hum
    t = np.arange(int(1.0 * SR)) / SR
    hum = np.sin(2 * np.pi * 55 * t) * 0.4 + np.sin(2 * np.pi * 110 * t) * 0.2 + lowpass(noise(1.0, 5), 30) * 0.3
    s["generator_hum"] = hum * _env(len(t), 0.1, 0.2)
    s["generator_start"] = np.concatenate([lowpass(noise(0.3, 9), 6) * 0.5, hum[: int(0.6 * SR)]]) * _env(int(0.9 * SR), 0.01, 0.2)
    # reactor
    s["reactor_start"] = (np.sin(2 * np.pi * (80 + 120 * t) * t) * 0.4 + lowpass(noise(1.0, 11), 20) * 0.2) * _env(len(t), 0.2, 0.3)
    s["reactor_scram"] = np.concatenate([tone(440, 0.2, "saw") * 0.4, tone(330, 0.2, "saw") * 0.4, tone(220, 0.4, "saw") * 0.4])
    # door
    s["door_open"] = (lowpass(noise(0.5, 13), 12) * 0.5 + tone(90, 0.5) * 0.3) * _env(int(0.5 * SR), 0.05, 0.2)
    tail = lowpass(noise(0.15, 15), 3)
    s["door_close"] = np.concatenate([lowpass(noise(0.3, 14), 12) * 0.4, tail * 0.9 * np.linspace(1, 0, len(tail))])
    # scanner
    s["scanner_beep"] = np.concatenate([tone(1500, 0.06) * 0.4, np.zeros(int(0.04 * SR)), tone(2000, 0.08) * 0.4])
    click = lowpass(noise(0.04, 21), 2)
    s["light_switch"] = click * 0.8 * np.linspace(1, 0, len(click))
    s["lab_process"] = (tone(600, 0.6) * 0.2 + lowpass(noise(0.6, 23), 4) * 0.2) * _env(int(0.6 * SR), 0.05, 0.3)
    # VHS / record: short lo-fi theme ("RadioÚstí 2072")
    notes = [220, 262, 247, 196, 220, 330, 294, 262, 220, 196, 175, 220]
    mel = np.concatenate([(tone(n, 0.5, "saw") * 0.2 + tone(n / 2, 0.5) * 0.2) * _env(int(0.5 * SR), 0.02, 0.2) for n in notes * 2])
    wob = 1 + 0.004 * np.sin(2 * np.pi * 0.7 * np.arange(len(mel)) / SR)
    s["record_radiousti"] = lowpass(mel * wob, 4) + lowpass(noise(len(mel) / SR, 31), 40) * 0.05
    return s


CATS = {"siren": ("block", 1.0), "nuke_blast": ("weather", 1.0), "generator_hum": ("block", 0.6), "record_radiousti": ("record", 1.0), "geiger": ("player", 0.7)}


def emit(sound_dir, wjson):
    out = os.path.join(sound_dir, "radiousti")
    os.makedirs(out, exist_ok=True)
    have_ffmpeg = shutil.which("ffmpeg") is not None
    defs = {}
    for name, data in make().items():
        data = np.clip(data, -1, 1)
        pcm = (data * 32767 * 0.9).astype(np.int16)
        with tempfile.TemporaryDirectory() as td:
            wav = os.path.join(td, name + ".wav")
            with wave.open(wav, "wb") as w:
                w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
            if have_ffmpeg:
                dst = os.path.join(out, name + ".ogg")
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", dst], check=True)
            else:
                shutil.copy(wav, os.path.join(out, name + ".wav"))
        cat, vol = CATS.get(name, ("block", 1.0))
        entry = {"category": cat, "sounds": [{"name": f"sounds/radiousti/{name}", "volume": vol}]}
        if name == "record_radiousti":
            entry["sounds"][0]["stream"] = True
            entry["max_distance"] = 64
        elif name in ("siren", "nuke_blast"):
            entry["max_distance"] = 160
        else:
            entry["max_distance"] = 24
        defs[f"radiousti.{name}"] = entry
        SOUNDS[f"radiousti.{name}"] = (name, cat, vol)
    wjson(os.path.join(sound_dir, "sound_definitions.json"), {"format_version": "1.20.20", "sound_definitions": defs})
