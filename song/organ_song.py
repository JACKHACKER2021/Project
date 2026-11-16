#!/usr/bin/env python3
"""
organ_song.py - vygeneruje 5minutovou varhanni skladbu (aditivni synteza) do WAV.

Pouziti:
    python3 organ_song.py [vystup.wav]

Zavislosti: numpy (vystup pres stdlib modul wave).
"""

import sys
import wave

import numpy as np

SR = 44100            # vzorkovaci frekvence
BPM = 66              # tempo
BEAT = 60.0 / BPM     # delka doby
BAR = 4 * BEAT        # takt 4/4
TARGET = 300.0        # cilova delka ~5 minut

# ----------------------------------------------------------------------------
# noty
# ----------------------------------------------------------------------------
NAMES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
         "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(note):
    """'A4' -> 440.0"""
    name, octave = note[:-1], int(note[-1])
    midi = 12 * (octave + 1) + NAMES[name]
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# ----------------------------------------------------------------------------
# varhanni rejstriky: (nasobek zakladni frekvence, amplituda)
# inspirovano taznymi registry (drawbars) elektromagnetickych varhan
# ----------------------------------------------------------------------------
REGISTRATIONS = {
    # jemny flauto pro intro
    "flute":   [(0.5, 0.10), (1, 1.00), (2, 0.30), (3, 0.08), (4, 0.06)],
    # zakladni principal
    "princ":   [(0.5, 0.18), (1, 1.00), (2, 0.55), (3, 0.28), (4, 0.22),
                (6, 0.10), (8, 0.07)],
    # plne plenum pro vrchol
    "plenum":  [(0.5, 0.25), (1, 1.00), (2, 0.70), (3, 0.45), (4, 0.38),
                (5, 0.18), (6, 0.22), (8, 0.16), (10, 0.09), (12, 0.08)],
    # pedal / bas
    "pedal":   [(0.5, 0.55), (1, 1.00), (2, 0.40), (3, 0.12), (4, 0.09)],
    # solovy hlas melodie
    "solo":    [(1, 1.00), (2, 0.45), (3, 0.30), (4, 0.16), (5, 0.12),
                (6, 0.08)],
}


def pipe(freq, dur, reg="princ", amp=0.25, detune=0.0025, chiff=True):
    """Jeden varhanni ton: aditivni synteza + rozladene zdvojeni + nabeh vzduchu."""
    n = int(dur * SR)
    if n <= 0:
        return np.zeros(0, dtype=np.float32)
    t = np.arange(n, dtype=np.float32) / SR
    out = np.zeros(n, dtype=np.float32)

    for mult, level in REGISTRATIONS[reg]:
        f = freq * mult
        if f > SR * 0.45:
            continue
        # tri mirne rozladene pistaly -> zivy, dychajici zvuk
        phase = np.random.uniform(0, 2 * np.pi)
        for k, d in ((0, 0.0), (1, detune), (2, -detune * 1.7)):
            out += (level / 3.0) * np.sin(2 * np.pi * f * (1 + d) * t + phase + k)

    # tremolo / vetrny tlak
    out *= 1.0 + 0.012 * np.sin(2 * np.pi * 5.2 * t + np.random.uniform(0, 6))

    # obalka: varhany drzi konstantni hlasitost, jen nabeh a dozneni
    env = np.ones(n, dtype=np.float32)
    atk = min(int(0.045 * SR), n // 3)
    rel = min(int(0.12 * SR), n // 3)
    if atk:
        env[:atk] = np.linspace(0, 1, atk) ** 1.5
    if rel:
        env[-rel:] = np.linspace(1, 0, rel) ** 1.5
    out *= env

    # "chiff" - sykot vzduchu na zacatku tonu
    if chiff and atk:
        nb = int(0.03 * SR)
        noise = np.random.normal(0, 1, nb).astype(np.float32)
        noise *= np.linspace(1, 0, nb) ** 3
        out[:nb] += 0.02 * noise

    return (out * amp).astype(np.float32)


# ----------------------------------------------------------------------------
# harmonie - akordy jako seznam not
# ----------------------------------------------------------------------------
def chord(root, kind, octave=3):
    steps = {
        "min":   [0, 3, 7],
        "maj":   [0, 4, 7],
        "min7":  [0, 3, 7, 10],
        "maj7":  [0, 4, 7, 11],
        "dom7":  [0, 4, 7, 10],
        "sus4":  [0, 5, 7],
        "dim":   [0, 3, 6],
    }[kind]
    base = 12 * (octave + 1) + NAMES[root]
    return [440.0 * 2.0 ** ((base + s - 69) / 12.0) for s in steps]


# d-moll prubeh, kazdy akord = (root, typ, pocet taktu)
PROGRESSION = [
    ("D", "min",  2), ("A", "min7", 2), ("B", "maj",  2), ("F", "maj",  2),
    ("G", "min",  2), ("D", "min",  2), ("E", "dom7", 1), ("A", "min",  1),
    ("F", "maj7", 2), ("C", "maj",  2), ("G", "min7", 2), ("A", "dom7", 2),
]

# melodie pro stredni cast (nota, doby); None = pauza
MELODY = [
    ("D5", 2), ("F5", 1), ("E5", 1), ("D5", 2), ("A4", 2),
    ("C5", 2), ("D5", 1), ("E5", 1), ("F5", 3), (None, 1),
    ("G5", 2), ("F5", 1), ("E5", 1), ("D5", 4),
    ("A5", 2), ("G5", 1), ("F5", 1), ("E5", 2), ("D5", 2),
    ("F5", 1), ("G5", 1), ("A5", 2), ("D5", 4),
]


# ----------------------------------------------------------------------------
# dozvuk katedraly: Schroederuv kombinovany comb + allpass
# ----------------------------------------------------------------------------
def comb(x, delay_ms, gain):
    d = int(SR * delay_ms / 1000.0)
    y = np.copy(x)
    for i in range(d, len(y)):
        y[i] += gain * y[i - d]
    return y


def allpass(x, delay_ms, gain=0.7):
    d = int(SR * delay_ms / 1000.0)
    y = np.copy(x)
    for i in range(d, len(y)):
        y[i] = -gain * x[i] + x[i - d] + gain * y[i - d]
    return y


def reverb(x, wet=0.38):
    """Velky prostor. Combs pocitame vektorove pres IIR-aproximaci opakovanim."""
    tail = np.zeros(len(x) + int(3.5 * SR), dtype=np.float32)
    tail[:len(x)] = x
    acc = np.zeros_like(tail)
    for delay_ms, g in ((59.3, 0.84), (69.1, 0.82), (79.7, 0.80), (89.9, 0.78)):
        d = int(SR * delay_ms / 1000.0)
        buf = np.copy(tail)
        # opakovane zpozdene odrazy (ekvivalent comb filtru, bez python smycky)
        echo = np.copy(tail)
        for rep in range(1, 26):
            shift = d * rep
            if shift >= len(tail):
                break
            echo[shift:] += (g ** rep) * tail[:len(tail) - shift]
        acc += echo / 4.0
    # rozmazani fazi
    for delay_ms in (5.0, 1.7):
        d = int(SR * delay_ms / 1000.0)
        prev = np.copy(acc)
        acc[d:] = -0.7 * prev[d:] + prev[:-d]
    # jemne tlumeni vysokych frekvenci v dozvuku
    k = 24
    acc = np.convolve(acc, np.ones(k, dtype=np.float32) / k, mode="same")
    dry = np.zeros_like(acc)
    dry[:len(x)] = x
    return (1 - wet) * dry + wet * acc


# ----------------------------------------------------------------------------
# skladba
# ----------------------------------------------------------------------------
def build():
    total = int((TARGET + 6) * SR)
    L = np.zeros(total, dtype=np.float32)
    R = np.zeros(total, dtype=np.float32)

    def place(sig, start, pan=0.0):
        i = int(start * SR)
        j = min(i + len(sig), total)
        if i >= total:
            return
        s = sig[:j - i]
        gl = np.sqrt((1 - pan) / 2 + 0.5) if pan else 0.707
        gr = np.sqrt((1 + pan) / 2 + 0.5) if pan else 0.707
        L[i:j] += s * gl
        R[i:j] += s * gr

    # ----- struktura: intro / A / B (vrchol) / coda -----
    sections = [
        ("intro",  "flute",  0.55),
        ("A",      "princ",  0.85),
        ("B",      "plenum", 1.00),
        ("A2",     "princ",  0.80),
        ("coda",   "flute",  0.60),
    ]

    t = 0.0
    prog_i = 0
    mel_i = 0
    section_len = TARGET / len(sections)

    for name, reg, loud in sections:
        s_end = t + section_len
        while t < s_end:
            root, kind, bars = PROGRESSION[prog_i % len(PROGRESSION)]
            prog_i += 1
            dur = bars * BAR
            if t + dur > s_end + BAR:
                dur = max(BAR, s_end - t)

            # akordove manualy (dva rejstriky, mirne rozpanovane)
            notes = chord(root, kind, octave=3)
            for k, f in enumerate(notes):
                pan = -0.5 + k / max(1, len(notes) - 1)
                place(pipe(f, dur, reg, amp=0.085 * loud), t, pan * 0.6)
                if name in ("B",):
                    # oktavove zdvojeni ve vrcholu
                    place(pipe(f * 2, dur, reg, amp=0.045 * loud), t, -pan * 0.6)

            # pedal (bas) - zaklad a kvinta
            bass = chord(root, kind, octave=1)[0]
            place(pipe(bass, dur, "pedal", amp=0.14 * loud), t, 0.0)
            if name in ("A", "B", "A2") and dur >= 2 * BEAT:
                place(pipe(bass * 1.5, dur / 2, "pedal", amp=0.05 * loud),
                      t + dur / 2, 0.0)

            # melodie v castech A, B, A2
            if name in ("A", "B", "A2"):
                mt = t
                while mt < t + dur - 1e-6:
                    note, beats = MELODY[mel_i % len(MELODY)]
                    mel_i += 1
                    ndur = min(beats * BEAT, t + dur - mt)
                    if note is not None and ndur > 0.05:
                        f = hz(note)
                        if name == "A2":
                            f *= 0.5  # repriza o oktavu niz, v tenoru
                        place(pipe(f, ndur * 0.96, "solo",
                                   amp=0.10 * loud, detune=0.0015), mt, 0.25)
                    mt += ndur

            t += dur

    mix = np.vstack([L, R])

    # dozvuk + mirna komprese spicek
    print("  pridavam dozvuk...", flush=True)
    wetL = reverb(mix[0])
    wetR = reverb(mix[1])
    out = np.vstack([wetL, wetR])

    out = np.tanh(out * 1.4) * 0.9
    peak = np.max(np.abs(out)) or 1.0
    out = out / peak * 0.92

    # fade in/out
    fi, fo = int(2.0 * SR), int(4.0 * SR)
    out[:, :fi] *= np.linspace(0, 1, fi)
    out[:, -fo:] *= np.linspace(1, 0, fo)
    return out


def save(stereo, path):
    data = (np.clip(stereo.T, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "organ_song.wav"
    np.random.seed(7)
    print("Generuji varhanni skladbu (~5 min)...")
    audio = build()
    save(audio, path)
    print(f"Hotovo: {path}  ({audio.shape[1] / SR:.1f} s, {SR} Hz, stereo)")


if __name__ == "__main__":
    main()
