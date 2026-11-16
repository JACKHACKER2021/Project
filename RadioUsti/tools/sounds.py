"""Procedurally synthesised retro-industrial sounds (mono .ogg via ffmpeg, fallback .wav)."""
import os
import shutil
import subprocess
import tempfile
import wave
import zlib

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


# ---------------------------------------------------------------- creature voices (v2.3)
def formant(x, peaks, bw=120):
    """Shape a source with vowel formants (frequency-domain gaussian peaks)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    g = np.zeros_like(f)
    for fc, amp in peaks:
        g += amp * np.exp(-0.5 * ((f - fc) / bw) ** 2)
    return np.fft.irfft(X * g, len(x))


def groan_source(d, f0, f1, seed, rough=0.35):
    """Glottal-like sawtooth with pitch glide, jitter and breathy noise."""
    rng = np.random.default_rng(seed)
    n = int(d * SR)
    t = np.arange(n) / SR
    f = np.linspace(f0, f1, n) * (1 + 0.04 * np.sin(2 * np.pi * 5.5 * t)) * (1 + rough * 0.06 * rng.standard_normal(n).cumsum() / np.sqrt(n))
    ph = 2 * np.pi * np.cumsum(f) / SR
    saw = 2 * ((ph / (2 * np.pi)) % 1) - 1
    return saw + rng.uniform(-1, 1, n) * rough


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


VOWELS = {"uh": [(520, 1.0), (920, 0.7), (2400, 0.25)], "oh": [(450, 1.0), (800, 0.8), (2600, 0.2)],
          "ah": [(700, 1.0), (1150, 0.7), (2500, 0.25)], "eh": [(500, 0.9), (1700, 0.6), (2500, 0.3)]}


def creature_sounds():
    """id -> list of (file name, samples)."""
    out = {}

    def zed(kind, i, low=1.0):
        seed = zlib.crc32(f"{kind}{i}{low}".encode()) % 10000
        if kind == "ambient":
            d = 1.2 + 0.3 * i
            x = formant(groan_source(d, 105 * low - i * 6, 82 * low, seed), VOWELS[["uh", "oh", "ah"][i % 3]])
            return norm(x * _env(len(x), 0.25, 0.45)) * 0.8
        if kind == "hurt":
            x = formant(groan_source(0.35, 150 * low + i * 10, 110 * low, seed, 0.6), VOWELS[["ah", "eh"][i % 2]], 160)
            return norm(x * _env(len(x), 0.01, 0.15))
        if kind == "death":
            x = formant(groan_source(2.0, 120 * low, 55 * low, seed, 0.45), VOWELS["oh"])
            x = x * np.linspace(1, 0.2, len(x))
            return norm(x * _env(len(x), 0.05, 0.8))
        if kind == "step":
            n = int(0.16 * SR)
            x = lowpass(noise(0.16, seed), 14) * np.exp(-np.arange(n) / SR * 30)
            return norm(x) * 0.6
        if kind == "attack":
            x = formant(groan_source(0.28, 170 * low, 130 * low, seed, 0.8), VOWELS["ah"], 200)
            return norm(x * _env(len(x), 0.005, 0.1))
        raise ValueError(kind)

    def radiak_fx(x, seed):
        """Geiger crackle + electric suit buzz on top of a voice."""
        rng = np.random.default_rng(seed)
        n = len(x)
        t = np.arange(n) / SR
        buzz = np.sign(np.sin(2 * np.pi * 120 * t)) * 0.12
        crack = np.zeros(n)
        for p in rng.integers(0, max(1, n - 60), max(3, n // 1800)):
            crack[p:p + 40] += rng.uniform(-1, 1, 40) * np.linspace(1, 0, 40)
        return norm(x + buzz * np.abs(x).max() * 0.6 + crack * 0.5)

    for kind, n in (("ambient", 3), ("hurt", 2), ("death", 1), ("step", 2), ("attack", 2)):
        out[f"zed.{kind}"] = [(f"zed_{kind}_{i + 1}", zed(kind, i)) for i in range(n)]
        out[f"radiak_zombie.{kind}"] = [(f"radiak_zombie_{kind}_{i + 1}", radiak_fx(zed(kind, i, 0.75), i + 50) if kind != "step" else zed(kind, i))
                                        for i in range(n)]
    # Radiak's reactor slime: wet squelches
    def squelch(d, f0, seed):
        n = int(d * SR)
        t = np.arange(n) / SR
        x = np.sin(2 * np.pi * (f0 + 60 * np.sin(2 * np.pi * 9 * t)) * t) * 0.6 + lowpass(noise(d, seed), 5) * 0.5
        return norm(x * _env(n, 0.01, d * 0.6))
    out["radiak_slime.squish"] = [(f"slime_squish_{i + 1}", squelch(0.25 + 0.05 * i, 140 + 30 * i, 900 + i)) for i in range(3)]
    out["radiak_slime.hurt"] = [(f"slime_hurt_{i + 1}", squelch(0.2, 260 + 40 * i, 910 + i)) for i in range(2)]
    out["radiak_slime.death"] = [("slime_death_1", squelch(0.6, 110, 920))]
    return out


ENTITY_SOUNDS = {
    "radiousti:irradiated_zed": {"ambient": "zed.ambient", "hurt": "zed.hurt", "death": "zed.death", "step": "zed.step", "attack": "zed.attack"},
    "radiousti:radiak_zombie": {"ambient": "radiak_zombie.ambient", "hurt": "radiak_zombie.hurt", "death": "radiak_zombie.death",
                                "step": "radiak_zombie.step", "attack": "radiak_zombie.attack"},
    "radiousti:radiak_slime": {"ambient": "radiak_slime.squish", "hurt": "radiak_slime.hurt", "death": "radiak_slime.death",
                               "step": "radiak_slime.squish", "jump": "radiak_slime.squish"},
}


def _write(out, name, data, have_ffmpeg):
    data = np.clip(data, -1, 1)
    pcm = (data * 32767 * 0.9).astype(np.int16)
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, name + ".wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
        if have_ffmpeg:
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", os.path.join(out, name + ".ogg")], check=True)
        else:
            shutil.copy(wav, os.path.join(out, name + ".wav"))


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
    # creature voices with several variants each
    for sid, variants in creature_sounds().items():
        for fname, data in variants:
            _write(out, fname, data, have_ffmpeg)
        cat = "hostile"
        defs[f"radiousti.{sid}"] = {"category": cat, "max_distance": 16 if sid.endswith("step") else 24,
                                    "sounds": [{"name": f"sounds/radiousti/{f}", "volume": 1.0} for f, _ in variants]}
        SOUNDS[f"radiousti.{sid}"] = (variants[0][0], cat, 1.0)
    wjson(os.path.join(sound_dir, "sound_definitions.json"), {"format_version": "1.20.20", "sound_definitions": defs})
    # map entity events -> sounds (RP/sounds.json)
    ents = {}
    for ident, ev in ENTITY_SOUNDS.items():
        events = {}
        for e, sid in ev.items():
            events[e] = {"sound": f"radiousti.{sid}", "volume": 0.35 if e == "step" else 1.0} if e == "step" else f"radiousti.{sid}"
        ents[ident] = {"volume": 1.0, "pitch": [0.85, 1.15], "events": events}
    wjson(os.path.join(os.path.dirname(sound_dir), "sounds.json"), {"entity_sounds": {"entities": ents}})
