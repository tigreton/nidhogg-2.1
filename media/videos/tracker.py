"""Tracker de jugadores para gameplay de Nidhogg 2 (576x360@30fps).

Fondo = mediana de 9 frames submuestreados de una ventana de 60 (cámara fija
en duelos); diff RGB; blobs con scipy.ndimage.label. Solo el strip de juego.
Salida CSV: frame,t,x0,y0,x1,y1,px (coords 576x360).
"""
import sys, os, glob, csv
import numpy as np
from PIL import Image
from scipy import ndimage


def load(file, y0, y1):
    return np.asarray(Image.open(file).convert("RGB"), dtype=np.float32)[y0:y1, :]


def label_blobs(diff, thresh, min_px=40):
    mask = diff.max(axis=2) > thresh
    lab, n = ndimage.label(mask)
    blobs = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if len(ys) >= min_px:
            blobs.append((int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()), len(ys)))
    return blobs


def main(frames_dir, out_csv, win=60, y0f=0.18, y1f=0.95, thresh=34):
    files = sorted(glob.glob(os.path.join(frames_dir, "*.jpg")))
    n = len(files)
    y0, y1 = int(360 * y0f), int(360 * y1f)
    rows = []
    for start in range(0, n, win):
        end = min(n, start + win)
        sub = list(range(start, end, max(1, (end - start) // 9)))[:9]
        bg = np.median(np.stack([load(files[i], y0, y1) for i in sub]), axis=0)
        for i in range(start, end):
            blobs = label_blobs(np.abs(load(files[i], y0, y1) - bg), thresh)
            for (x0, yy0, x1, yy1, px) in blobs:
                rows.append([i + 1, (i + 1) / 30.0, x0, yy0 + y0, x1, yy1 + y0, px])
    with open(out_csv, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["frame", "t", "x0", "y0", "x1", "y1", "px"])
        w.writerows(rows)
    print("frames:", n, "blob-rows:", len(rows))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
