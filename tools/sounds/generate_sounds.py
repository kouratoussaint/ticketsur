#!/usr/bin/env python3
"""Génère les sons de l'interface TicketSûr (créations originales, synthèse).

Usage : python3 tools/sounds/generate_sounds.py apps/mobile/assets/sounds

Sons courts (WAV mono 16 bits, 32 kHz), attaque rapide, déclin exponentiel,
légère réverbération : lisibles dans le bruit d'une entrée, jamais agressifs.
"""
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 32_000


def note(freq, dur, *, partials=((1, 1.0), (2, 0.18), (3, 0.06)), decay=6.0,
         attack=0.004, shape="sine"):
    t = np.arange(int(RATE * dur)) / RATE
    if shape == "buzz":
        # Carré adouci : harmoniques impaires décroissantes.
        wave_ = sum(np.sin(2 * np.pi * freq * k * t) / k for k in (1, 3, 5, 7))
    else:
        wave_ = sum(a * np.sin(2 * np.pi * freq * m * t) for m, a in partials)
    env = np.minimum(t / attack, 1.0) * np.exp(-decay * t)
    return wave_ * env


def place(total, parts):
    out = np.zeros(int(RATE * total))
    for start, signal in parts:
        i = int(RATE * start)
        j = min(len(out), i + len(signal))
        out[i:j] += signal[: j - i]
    return out


def reverb(signal, delays=((0.045, 0.22), (0.083, 0.12), (0.131, 0.06))):
    out = signal.copy()
    for delay, gain in delays:
        k = int(RATE * delay)
        out[k:] += gain * signal[:-k]
    return out


def fade_out(signal, dur=0.02):
    n = int(RATE * dur)
    signal[-n:] *= np.linspace(1, 0, n)
    return signal


def write(path, signal, peak_db):
    signal = fade_out(signal)
    signal = signal / np.max(np.abs(signal)) * 10 ** (peak_db / 20)
    data = (signal * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    C6, E6, G6, A6, C7 = 1046.5, 1318.5, 1568.0, 1760.0, 2093.0
    A5, E5 = 880.0, 659.3

    # Clic doux de navigation (≈ 45 ms).
    tap = note(1900, 0.045, partials=((1, 1.0), (1.5, 0.25)), decay=90, attack=0.001)
    write(out / "tap.wav", tap, -14)

    # Réussite : deux notes montantes, timbre de marimba.
    marimba = ((1, 1.0), (4, 0.12), (10, 0.02))
    success = place(0.42, [
        (0.00, note(E6, 0.30, partials=marimba, decay=14)),
        (0.09, note(A6, 0.33, partials=marimba, decay=11)),
    ])
    write(out / "success.wav", reverb(success), -4)

    # Erreur : deux notes descendantes, plus rondes.
    error = place(0.42, [
        (0.00, note(A5, 0.20, decay=13)),
        (0.11, note(E5, 0.30, decay=10)),
    ])
    write(out / "error.wav", reverb(error), -5)

    # Entrée autorisée : arpège lumineux C-E-G-C, dernière note tenue.
    admitted = place(0.75, [
        (0.00, note(C6, 0.22, partials=marimba, decay=16)),
        (0.06, note(E6, 0.22, partials=marimba, decay=16)),
        (0.12, note(G6, 0.22, partials=marimba, decay=16)),
        (0.18, note(C7, 0.55, partials=marimba, decay=6)),
    ])
    write(out / "admitted.wav", reverb(admitted), -1)

    # Entrée refusée : deux impulsions graves et fermes.
    refused = place(0.46, [
        (0.00, note(196.0, 0.16, shape="buzz", decay=9, attack=0.003)),
        (0.22, note(196.0, 0.20, shape="buzz", decay=8, attack=0.003)),
    ])
    write(out / "refused.wav", refused, -1)

    # État à confirmer : deux notes neutres identiques.
    unsure = place(0.42, [
        (0.00, note(659.3, 0.16, decay=14)),
        (0.20, note(659.3, 0.20, decay=12)),
    ])
    write(out / "indeterminate.wav", reverb(unsure), -3)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "apps/mobile/assets/sounds")
