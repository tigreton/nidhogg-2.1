"""Analiza los blobs del tracker: filtra jugadores, arma pistas y mide.

Entrada: castle30_blobs.csv (frame,t,x0,y0,x1,y1,px)
Salida: pistas por frame + estadisticas (velocidades, alturas de blob,
arcos de salto) normalizadas a la altura tipica del personaje.
"""
import sys
import csv
import numpy as np
from collections import defaultdict

FLOOR_Y = 310.0     # linea del suelo (castle, aprox)
MIN_H, MAX_H = 28, 80
MIN_W, MAX_W = 8, 110


def load(path):
    rows = []
    with open(path) as f:
        for r in csv.DictReader(f):
            b = dict(frame=int(r["frame"]), t=float(r["t"]),
                     x0=float(r["x0"]), y0=float(r["y0"]),
                     x1=float(r["x1"]), y1=float(r["y1"]), px=int(r["px"]))
            b["w"] = b["x1"] - b["x0"] + 1
            b["h"] = b["y1"] - b["y0"] + 1
            b["cx"] = (b["x0"] + b["x1"]) / 2
            b["cy"] = (b["y0"] + b["y1"]) / 2
            rows.append(b)
    return rows


def plausible(b):
    return MIN_H <= b["h"] <= MAX_H and MIN_W <= b["w"] <= MAX_W \
        and 150 <= b["cy"] <= 340 and b["y1"] <= FLOOR_Y + 40


def build_tracks(rows, max_jump=60):
    by_frame = defaultdict(list)
    for b in rows:
        if plausible(b):
            by_frame[b["frame"]].append(b)
    frames = sorted(by_frame)
    tracks = []          # list of lists of blobs
    ended = []           # (last_blob, track)
    for fr in frames:
        blobs = by_frame[fr]
        used = [False] * len(blobs)
        # extender pista mas cercana
        for tr in tracks:
            if fr - tr[-1]["frame"] > 3:
                continue
            last = tr[-1]
            best, bi = 1e9, -1
            for i, b in enumerate(blobs):
                if used[i]:
                    continue
                d = abs(b["cx"] - last["cx"]) + abs(b["cy"] - last["cy"]) * 0.5
                if d < best:
                    best, bi = d, i
            if bi >= 0 and best <= max_jump:
                tr.append(blobs[bi])
                used[bi] = True
        for i, b in enumerate(blobs):
            if not used[i]:
                tracks.append([b])
    # conservar pistas largas
    return [t for t in tracks if len(t) >= 25]


def main(path):
    rows = load(path)
    tracks = build_tracks(rows)
    print("pistas:", len(tracks), [len(t) for t in tracks])
    heights = []
    for t in tracks:
        hs = [b["h"] for b in t]
        heights += hs
    H = np.median(heights)
    print("altura tipica de blob (mediana): %.1f px" % H)

    for ti, t in enumerate(tracks):
        xs = np.array([b["cx"] for b in t])
        ys = np.array([b["cy"] for b in t])
        frr = np.array([b["frame"] for b in t])
        # suelo propio de la pista: cuantil 65 de cy (mayoria del tiempo en suelo)
        base = np.quantile(ys, 0.65)
        # velocidad horizontal entre frames consecutivos (30fps)
        vx = []
        for k in range(1, len(t)):
            if frr[k] - frr[k - 1] == 1:
                vx.append((xs[k] - xs[k - 1]) * 30.0)
        vx = np.array(vx)
        ground = ys > base - H * 0.5
        vground = np.array([vx[i] for i in range(len(vx))
                            if ground[i] and ground[i + 1]])
        mv = np.abs(vground)
        mv = mv[mv > 40]
        if len(mv) >= 8:
            print("pista %d: %d frames base=%.0f vx_ground mediana=%.0f p85=%.0f max=%.0f px/s (%.2f/%.2f alturas/s)" % (
                ti, len(t), base, np.median(mv), np.percentile(mv, 85), mv.max(),
                np.median(mv) / H, np.percentile(mv, 85) / H))
        # arcos: y baja del suelo propio y vuelve
        air = ys < base - H * 0.7
        k = 0
        while k < len(t):
            if air[k]:
                j = k
                while j < len(t) and air[j]:
                    j += 1
                seg = t[k:j]
                if len(seg) >= 4:
                    dys = base - np.array([b["cy"] for b in seg])
                    dur = (seg[-1]["frame"] - seg[0]["frame"] + 1) / 30.0
                    dxs = seg[-1]["cx"] - seg[0]["cx"]
                    wh = np.mean([b["w"] for b in seg]) / np.mean([b["h"] for b in seg])
                    print("  vuelo t=%.2f dur=%.2fs altura_max=%.1fpx (%.2f H) dx=%.0fpx (%.1f H) forma w/h=%.2f" % (
                        seg[0]["t"], dur, dys.max(), dys.max() / H, dxs, dxs / H, wh))
                k = j
            else:
                k += 1


if __name__ == "__main__":
    main(sys.argv[1])
