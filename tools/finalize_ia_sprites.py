# -*- coding: utf-8 -*-
"""PUERTA 4 — post-proceso final de los sprites generados con Bailian.

Toma los PNG grandes de art_raw/redesign_ia/poses/ (fondo gris plano), recorta
el fondo, escala cada pose a la altura del contrato del juego (pies al borde
inferior, canvas = bbox del personaje, como hacía el pipeline original) y
sobrescribe art/sprites/ con los nombres oficiales. La hoja weapons.png se
segmenta en 5 armas por clusters de columnas y se clasifica por geometría.

Sin coste de API. Uso:  python tools/finalize_ia_sprites.py [--dry]
"""

import os
import sys

from PIL import Image, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_raw", "redesign_ia", "poses")
DST = os.path.join(ROOT, "art", "sprites")
TOL = 30          # umbral de diferencia L para el chroma-key del fondo

# altura objetivo (px) por pose — contrato del juego (player.gd)
TARGET_H = {"idle": 56, "run_0": 56, "run_1": 56, "run_2": 56, "run_3": 56,
            "jump": 56, "fall": 56, "crouch": 40, "slide": 30, "throw": 56,
            "attack_high": 56, "attack_mid": 56, "attack_low": 44,
            "divekick": 48, "dead": 28, "downed": 30}

ARMED = ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch",
         "slide", "attack_high", "attack_mid", "attack_low", "throw", "divekick",
         "dead", "downed"]
NOARME = ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch", "throw"]

WEAPON_BOX = {"rapier": (90, 9), "longsword": (120, 9), "dagger": (55, 8),
              "bow": (38, 70), "arrow": (28, 6)}


def bg_color(im):
    w, h = im.size
    px = []
    for box in ((0, 0, 24, 24), (w - 24, 0, w, 24), (0, h - 24, 24, h), (w - 24, h - 24, w, h)):
        px.extend(im.crop(box).convert("RGB").getdata())
    px.sort()
    return px[len(px) // 2]


def cutout(path):
    """Chroma-key del fondo gris → RGBA recortado al bbox del personaje."""
    im = Image.open(path).convert("RGB")
    bg = Image.new("RGB", im.size, bg_color(im))
    diff = ImageChops.difference(im, bg).convert("L")
    mask = diff.point(lambda v: 0 if v <= TOL else 255)
    if mask.histogram()[255] < im.size[0] * im.size[1] * 0.02:
        raise RuntimeError("recorte vacio: %s (¿fondo no gris?)" % path)
    rgba = im.convert("RGBA")
    rgba.putalpha(mask)
    bbox = mask.getbbox()
    return rgba.crop(bbox)


def scale_to(rgba, target_h):
    w, h = rgba.size
    im = rgba.resize((max(1, round(w * target_h / h)), target_h), Image.LANCZOS)
    a = im.getchannel("A").point(lambda v: 255 if v >= 140 else 0)
    im.putalpha(a)
    return im


def process_characters(dry):
    made = []
    for side in ("p1", "p2"):
        for pose in ARMED:
            made.append(("%s_%s" % (side, pose), "player_%s_%s.png" % (pose, side), TARGET_H[pose]))
        for pose in NOARME:
            made.append(("%s_%s_noarme" % (side, pose), "player_%s_noarme_%s.png" % (pose, side), TARGET_H[pose]))
    for src, dst, th in made:
        out = scale_to(cutout(os.path.join(SRC, src + ".png")), th)
        if not dry:
            out.save(os.path.join(DST, dst))
        print("  %-30s -> %-34s %dx%d" % (src, dst, out.width, out.height))
    return len(made)


def segment_weapons():
    """Clusteriza weapons.png en columnas y clasifica por geometría."""
    im = cutout(os.path.join(SRC, "weapons.png"))
    mask = im.getchannel("A")
    w, h = mask.size
    cols = []
    px = mask.load()
    for x in range(w):
        cols.append(sum(1 for y in range(0, h, 4) if px[x, y] > 0))
    thr = max(cols) // 20
    clusters, start = [], None
    for x, c in enumerate(cols):
        if c > thr and start is None:
            start = x
        elif c <= thr and start is not None:
            if x - start > w // 40:
                clusters.append((start, x))
            start = None
    if start is not None:
        clusters.append((start, w))
    out = []
    for (x0, x1) in clusters:
        c = im.crop((x0, 0, x1, h))
        b = c.getchannel("A").getbbox()
        out.append(c.crop(b))
    return out


def classify(pieces):
    """Fila de izquierda a derecha en el orden del prompt; hojas arriba→derecha."""
    if len(pieces) != 5:
        for i, p in enumerate(pieces):
            print("  pieza %d: %dx%d" % (i, p.width, p.height))
        raise RuntimeError("esperaba 5 armas, salieron %d" % len(pieces))
    order = ["rapier", "longsword", "dagger", "bow", "arrow"]
    named = {}
    for name, piece in zip(order, pieces):
        if name != "bow" and piece.height > piece.width:
            piece = piece.rotate(-90, expand=True)   # apuntaba arriba → derecha
        named[name] = piece
    return named


def process_weapons(dry):
    named = classify(segment_weapons())
    for name, piece in named.items():
        bw, bh = WEAPON_BOX[name]
        s = min(bw / piece.width, bh / piece.height)
        im = piece.resize((max(1, round(piece.width * s)), max(1, round(piece.height * s))), Image.LANCZOS)
        a = im.getchannel("A").point(lambda v: 255 if v >= 140 else 0)
        im.putalpha(a)
        canvas = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((bw - im.width) // 2, (bh - im.height) // 2))
        if not dry:
            canvas.save(os.path.join(DST, "weapon_%s.png" % name))
        print("  weapon_%-10s %dx%d (pieza %dx%d)" % (name, bw, bh, piece.width, piece.height))


def main():
    dry = "--dry" in sys.argv
    if dry:
        print("=== DRY RUN (no sobrescribe) ===")
    print("personajes:")
    n = process_characters(dry)
    print("armas:")
    process_weapons(dry)
    print("total: %d personajes + 5 armas %s" % (n, "(dry)" if dry else "escritos en art/sprites/"))


if __name__ == "__main__":
    main()
