#!/usr/bin/env python3
# -*- coding: utf-8 -*-
## Renderiza el bucle de música del juego (art/music). Tareas 63 y 79.
##   python tools/render_music.py                  -> loop_main.wav (completo)
##   python tools/render_music.py --base loop_base.wav  -> mezcla sin percusión
##   python tools/render_music.py --out ruta.wav    -> destino alternativo
## Semilla fija: dos ejecuciones producen bits idénticos, y la completa y la
## base quedan MUESTRA A MUESTRA sincronizadas (misma longitud, mismo eco).
import argparse
import wave

import numpy as np

MIX = 22050
BPM = 132.0
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 40
TOTAL = int(BAR * BARS * MIX)
RNG = 20261003


def build(base_only: bool) -> np.ndarray:
    rng = np.random.default_rng(RNG)

    def env(n, a=0.004, r=0.12):
        t = np.arange(n) / MIX
        return np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-t / r)

    def place(buf, x, sig):
        i = int(x * MIX)
        if i >= len(buf):
            return
        n = min(len(sig), len(buf) - i)
        buf[i:i + n] += sig[:n]

    def bass_note(f, dur):
        n = int(dur * MIX)
        t = np.arange(n) / MIX
        ph = 2 * np.pi * f * t
        s = 0.6 * np.where(np.mod(ph, 2 * np.pi) < np.pi, 1.0, -1.0) + 0.4 * np.sin(ph)
        return s * env(n, 0.003, dur * 0.7) * 0.30

    def lead_note(f, dur, vib=5.0):
        n = int(dur * MIX)
        t = np.arange(n) / MIX
        ph = 2 * np.pi * f * t + 0.5 * np.sin(2 * np.pi * vib * t)
        return (0.5 * np.sign(np.sin(ph)) + 0.5 * np.sin(ph)) * env(n, 0.006, dur * 0.9) * 0.16

    def arp_note(f, dur):
        n = int(dur * MIX)
        t = np.arange(n) / MIX
        s = np.where(np.mod(2 * np.pi * f * t, 2 * np.pi) < np.pi / 2, 1.0, -1.0)
        return s * env(n, 0.002, dur * 1.2) * 0.05

    kick_n = [int(0.13 * MIX)]
    snare_n = [int(0.09 * MIX)]
    hat_n = [int(0.028 * MIX)]

    def kick():
        n = kick_n[0]
        t = np.arange(n) / MIX
        f = 105 * np.exp(-t * 22) + 38
        return np.sin(2 * np.pi * np.cumsum(f) / MIX) * env(n, 0.001, 0.055) * 0.5

    def snare():
        n = snare_n[0]
        t = np.arange(n) / MIX
        return (rng.uniform(-1, 1, n) * 0.55 + np.sin(2 * np.pi * 185 * t) * 0.3) * env(n, 0.001, 0.030) * 0.5

    def hat(open_=False):
        n = int((0.06 if open_ else 0.028) * MIX)
        nz = rng.uniform(-1, 1, n)
        return np.diff(nz, prepend=0.0) * env(n, 0.001, 0.012 if open_ else 0.006) * 0.16

    buf = np.zeros(TOTAL, dtype=np.float64)
    E2, G2, A2, B2, C3, D3 = 82.41, 98.0, 110.0, 123.47, 130.81, 146.83
    E4, G4, A4, B4, C5, D5, E5, Fs4 = 329.63, 392.0, 440.0, 493.88, 523.25, 587.33, 659.26, 369.99
    roots = [E2] * 4 + [C3] * 2 + [D3] * 2 + [E2] * 4 + [A2] * 2 + [B2] * 2 \
        + [E2] * 4 + [C3] * 2 + [D3] * 2 + [E2] * 4 + [G2] * 2 + [B2] * 2 + [E2] * 4 + [C3] * 2 + [B2] * 2
    roots = (roots + roots[:BARS])[:BARS]

    for bar in range(BARS):
        x0 = bar * BAR
        root = roots[bar]
        fifth = root * 1.5 if root < 100 else root * 1.5 / 2
        section = bar // 8
        for k, f in enumerate([root, 0, root, 0, fifth, 0, root, root]):
            if f > 0:
                place(buf, x0 + k * BEAT / 2, bass_note(f, BEAT / 2 * 0.92))
        if not base_only:
            place(buf, x0, kick())
            if section >= 1:
                place(buf, x0 + 2 * BEAT, kick())
                place(buf, x0 + BEAT, snare())
                place(buf, x0 + 3 * BEAT, snare())
            step = BEAT / 4 if section == 3 else BEAT / 2
            k, xx = 0, x0
            while xx < x0 + BAR - 1e-6:
                place(buf, xx, hat(open_=(section >= 1 and k % 4 == 2)))
                xx += step
                k += 1
        if section in (1, 3):
            tones = [root * 2, root * 3, root * 4, root * 3]
            for k in range(16):
                place(buf, x0 + k * BEAT / 4, arp_note(tones[k % 4], BEAT / 4 * 0.9))
        if section == 1 and bar % 2 == 0:
            seq = [(E4, 0), (G4, 1), (B4, 1.5), (A4, 2.5)] if bar % 4 == 0 else [(B4, 0), (G4, 1), (E4, 1.5), (Fs4, 2.5)]
            for f, b in seq:
                place(buf, x0 + b * BEAT, lead_note(f, BEAT * 0.9))
        if section == 3 and bar % 2 == 0:
            seq = [(E5, 0), (D5, 0.5), (B4, 1), (G4, 1.5), (A4, 2), (B4, 2.5)] if bar % 4 == 0 else [(C5, 0), (B4, 0.5), (A4, 1), (G4, 1.5), (Fs4, 2), (E4, 2.5)]
            for f, b in seq:
                place(buf, x0 + b * BEAT, lead_note(f, BEAT * 0.45))

    # eco circular (loop perfecto) común a ambas mezclas: quedan sincronizadas
    d = int(BEAT * 0.75 * MIX)
    echo = buf.copy()
    buf += 0.30 * np.roll(echo, d) + 0.14 * np.roll(echo, 2 * d)
    buf = np.tanh(buf * 1.1)
    buf *= 0.55 / np.max(np.abs(buf))
    return buf


def main():
    ap = argparse.ArgumentParser(description="Render del bucle musical (tareas 63/79)")
    ap.add_argument("--base", nargs="?", const="loop_base.wav", metavar="OUT", help="mezcla SIN percusión (para el crossfade de la 79)")
    ap.add_argument("--out", default=None, help="fichero de destino (por defecto el de --base o loop_main.wav)")
    args = ap.parse_args()
    if args.base:
        out, base = args.out or args.base, True
    else:
        out, base = args.out or "art/music/loop_main.wav", False
    pcm = (build(base) * 32000).astype("<i2").tobytes()
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(MIX)
        w.writeframes(pcm)
    print("%s: %d compases, %.1f s, %.2f MB%s" % (out, BARS, TOTAL / MIX, len(pcm) / 1e6, " (base)" if base else ""))


if __name__ == "__main__":
    main()
