"""Detecta pans de camara (transiciones de pantalla) en un video 360p.

Para cada par de frames consecutivos estima el desplazamiento horizontal
del fondo por correlacion de columnas (banda superior, sobre el suelo, fuera
del HUD): desplaza una imagen -32..32 px y busca el offset con menor SSE.
Un pan real = offset no nulo sostenido varios frames. Imprime segmentos.
"""
import sys
import numpy as np
import cv2


def main(path, t0=0.0, t1=1e9, band=(0.10, 0.42)):
    cap = cv2.VideoCapture(path)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    prev = None
    offsets = []
    i = 0
    while True:
        ok, fr = cap.read()
        if not ok:
            break
        t = i / fps
        i += 1
        if t < t0 or t > t1:
            continue
        g = cv2.cvtColor(fr, cv2.COLOR_BGR2GRAY).astype(np.float32)
        h, w = g.shape
        y0, y1 = int(h * band[0]), int(h * band[1])
        strip = g[y0:y1, :]
        if prev is not None:
            best, bestdx = 1e18, 0
            for dx in range(-40, 41, 2):
                a = strip[:, 40:w - 40]
                b = prev[:, 40 + dx:w - 40 + dx]
                sse = float(((a - b) ** 2).mean())
                if sse < best:
                    best, bestdx = sse, dx
            offsets.append((t, bestdx, best))
        prev = strip
    # agrupar en eventos: >=3 frames consecutivos con |dx|>=6 en el mismo signo
    run = []
    for k, (t, dx, err) in enumerate(offsets):
        if abs(dx) >= 6:
            run.append((t, dx))
        else:
            if len(run) >= 3:
                ts = [r[0] for r in run]
                dxs = [r[1] for r in run]
                print("PAN %.2f-%.2fs dir=%s avg_dx=%.1f px/frame" % (
                    ts[0], ts[-1], "+" if np.mean(dxs) > 0 else "-", abs(np.mean(dxs))))
            run = []
    if len(run) >= 3:
        ts = [r[0] for r in run]
        dxs = [r[1] for r in run]
        print("PAN %.2f-%.2fs dir=%s avg_dx=%.1f px/frame" % (
            ts[0], ts[-1], "+" if np.mean(dxs) > 0 else "-", abs(np.mean(dxs))))
    print("total frames analizados:", len(offsets))


if __name__ == "__main__":
    main(sys.argv[1], float(sys.argv[2]) if len(sys.argv) > 2 else 0.0,
         float(sys.argv[3]) if len(sys.argv) > 3 else 1e9)
