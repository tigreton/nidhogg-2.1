#!/usr/bin/env python3
"""B0 - Pipeline de arte del Track B (magenta -> alfa, autocrop, escala, QA).

Contrato (docs/ART_PROMPTS.md sec. 7):
  py -3 tools/img_pipeline.py --in art_raw/nacho/idle_v1.png
      --out godot/art/sprites/player_idle_p1.png --height 56
  py -3 tools/img_pipeline.py --qa godot/art/sprites   ->  "QA: n/n OK"
  py -3 tools/img_pipeline.py --selftest               ->  smoke test de B0

Si no se pasan --height/--width, el tamano objetivo se busca en MANIFEST usando
el nombre del archivo de salida (clave del sprite_registry).
Requiere Python 3 + pillow + numpy.
"""

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image

# --- Constantes fijas del pipeline -----------------------------------------
MAGENTA = (255, 0, 255)
TOL_FULL = 110.0   # distancia RGB <= TOL_FULL  -> alfa 0
TOL_EDGE = 190.0   # distancia RGB <= TOL_EDGE  -> alfa parcial (borde)
DIM_TOL = 0.20     # QA: +/-20% sobre las dimensiones del manifiesto
RATIO_TOL = 0.25   # QA: +/-25% sobre el ratio de aspecto
MIN_FILL = 0.01    # QA: al menos 1% de pixeles opacos (contenido no vacio)

POSES = {
    "idle": 56, "run_0": 56, "run_1": 56, "run_2": 56, "run_3": 56,
    "jump": 56, "fall": 56, "crouch": 40, "slide": 30, "divekick": 48,
    "attack_high": 56, "attack_mid": 56, "attack_low": 44, "throw": 56,
    "downed": 30, "dead": 28,
}

# clave -> (ancho, alto). None = libre (se deriva del ratio del recorte).
MANIFEST = {}
for _pose, _h in POSES.items():
    for _p in ("p1", "p2"):
        MANIFEST["player_%s_%s" % (_pose, _p)] = (None, _h)
MANIFEST.update({
    "weapon_rapier": (90, 8),
    "weapon_longsword": (120, 10),
    "weapon_dagger": (55, 7),
    "weapon_bow": (40, 70),
    "weapon_arrow": (28, 6),
    "tile_floor": (48, 48),
    "tile_wall": (48, 48),
    "pit_edge": (48, 48),
    "bg_layer0": (960, 540),
    "bg_layer1": (960, 540),
    "arrow_neutral": (64, 40),
    "pip_hollow": (26, 26),
    "pip_filled": (26, 26),
    "blood_0": (24, 24),
    "blood_1": (40, 24),
    "blood_2": (64, 32),
    "bg_title": (960, 540),
    "worm_body": (300, 120),
    "stomp_burst": (48, 48),   # opcional
})

# Estos NO llevan fondo magenta ni alfa: son opacos a proposito.
OPAQUE = {"bg_layer0", "bg_layer1", "bg_title", "tile_floor", "tile_wall"}
OPTIONAL = {"stomp_burst"}
REQUIRED = sorted(k for k in MANIFEST if k not in OPTIONAL)

RESAMPLE = {
    "nearest": Image.NEAREST,
    "box": Image.BOX,
    "lanczos": Image.LANCZOS,
}


# --- Etapas del pipeline ----------------------------------------------------
def key_of(path):
    return os.path.splitext(os.path.basename(path))[0]


def dechroma(img):
    """Magenta -> alfa, con borde suave y despill en los pixeles del borde."""
    arr = np.asarray(img.convert("RGBA"), dtype=np.float32)
    rgb = arr[..., :3].copy()
    dist = np.sqrt(((rgb - np.array(MAGENTA, dtype=np.float32)) ** 2).sum(axis=-1))
    alpha = np.clip((dist - TOL_FULL) / (TOL_EDGE - TOL_FULL), 0.0, 1.0)
    alpha *= arr[..., 3] / 255.0            # respeta el alfa que ya trajera

    # Despill solo en el borde: quita el tinte magenta residual (R y B altos, G bajo).
    edge = (alpha > 0.0) & (alpha < 1.0)
    if edge.any():
        r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
        spill = np.minimum(r, b) - g
        m = edge & (spill > 0)
        rgb[..., 0] = np.where(m, r - spill * 0.8, r)
        rgb[..., 2] = np.where(m, b - spill * 0.8, b)

    out = np.concatenate([np.clip(rgb, 0, 255), (alpha * 255.0)[..., None]], axis=-1)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def content_bbox(img, speck=3, pad=2):
    """Caja del contenido, ignorando motas sueltas del fondo.

    El keying deja algun pixel aislado en los bordes (degradado del generador);
    un getbbox() directo devolveria entonces el lienzo entero. Se erosiona la
    mascara para matar las motas y luego se devuelve el margen.
    """
    from PIL import ImageFilter

    mask = img.split()[-1].point(lambda v: 255 if v > 8 else 0)
    bbox = mask.filter(ImageFilter.MinFilter(speck)).getbbox() or mask.getbbox()
    if not bbox:
        return None
    x0, y0, x1, y1 = bbox
    return (max(0, x0 - pad), max(0, y0 - pad),
            min(img.width, x1 + pad), min(img.height, y1 + pad))


def edges_touched(img, bbox):
    """Bordes del lienzo que el contenido toca (sprite cortado por el marco)."""
    if not bbox:
        return []
    names = ("izquierdo", "superior", "derecho", "inferior")
    hits = (bbox[0] <= 1, bbox[1] <= 1, bbox[2] >= img.width - 1,
            bbox[3] >= img.height - 1)
    return [n for n, hit in zip(names, hits) if hit]


def autocrop(img, speck=3, pad=2):
    bbox = content_bbox(img, speck, pad)
    return img.crop(bbox) if bbox else img


def target_size(src, want_w, want_h):
    w, h = src.size
    if want_w and want_h:
        return want_w, want_h
    if want_h:
        return max(1, round(w * want_h / h)), want_h
    if want_w:
        return want_w, max(1, round(h * want_w / w))
    return w, h


def process(src_path, dst_path, want_w=None, want_h=None, resample="box",
            opaque=None, keep_magenta=False):
    key = key_of(dst_path)
    if opaque is None:
        opaque = key in OPAQUE
    if want_w is None and want_h is None and key in MANIFEST:
        want_w, want_h = MANIFEST[key]
        # Manual sec.7: se escala por UNA dimension ("--height 56 o --width para
        # armas/bg") y la otra sale del arte; forzar las dos deformaria el sprite.
        # En los opacos no hay recorte, asi que ahi si valen las dos.
        if want_w and want_h and not opaque:
            if want_w >= want_h:
                want_h = None
            else:
                want_w = None

    img = Image.open(src_path).convert("RGBA")
    src_size = img.size
    cut = []
    if not (opaque or keep_magenta):
        img = dechroma(img)
        bbox = content_bbox(img)
        cut = edges_touched(img, bbox)
        img = img.crop(bbox) if bbox else img
    crop_size = img.size
    tw, th = target_size(img, want_w, want_h)
    img = img.resize((tw, th), RESAMPLE[resample])
    if opaque:
        img = img.convert("RGB")

    parent = os.path.dirname(os.path.abspath(dst_path))
    os.makedirs(parent, exist_ok=True)
    img.save(dst_path)
    ok, issues = qa_file(dst_path)

    # Dos defectos que el QA del archivo final no puede ver (se escala al tamano
    # exacto y ya no hay lienzo): la distorsion de ratio y el corte por el marco.
    if not opaque and want_w and want_h:
        exp, got = tw / th, crop_size[0] / crop_size[1]
        if abs(got / exp - 1.0) > RATIO_TOL:
            ok = False
            issues = issues + ["distorsion: recorte %dx%d (ratio %.2f) forzado a "
                               "ratio %.2f" % (crop_size[0], crop_size[1], got, exp)]
    if cut:
        ok = False
        issues = issues + ["cortado por el marco (%s)" % ", ".join(cut)]

    return {
        "key": key, "src": src_path, "dst": dst_path,
        "src_size": list(src_size), "out_size": [tw, th], "crop": list(crop_size),
        "cut": cut, "resample": resample, "opaque": opaque,
        "ok": ok, "issues": issues,
    }


# --- QA ---------------------------------------------------------------------
def qa_file(path):
    """Devuelve (ok, [problemas]) para un PNG ya procesado."""
    key = key_of(path)
    issues = []
    try:
        img = Image.open(path)
        img.load()
    except Exception as exc:                       # noqa: BLE001
        return False, ["no se puede abrir: %s" % exc]

    w, h = img.size
    opaque = key in OPAQUE

    if opaque:
        if img.mode not in ("RGB", "RGBA"):
            issues.append("modo %s (se esperaba RGB opaco)" % img.mode)
    else:
        if "A" not in img.getbands():
            issues.append("sin canal alfa")
        else:
            arr = np.asarray(img.convert("RGBA")).astype(np.float32)
            fill = float((arr[..., 3] > 8).mean())
            if fill < MIN_FILL:
                issues.append("contenido vacio (%.2f%% opaco)" % (fill * 100.0))
            dist = np.sqrt(((arr[..., :3] - np.array(MAGENTA, dtype=np.float32)) ** 2)
                           .sum(axis=-1))
            left = float(((dist <= TOL_EDGE) & (arr[..., 3] > 8)).mean())
            if left > 0.02:
                issues.append("magenta sin quitar (%.1f%% de la imagen)" % (left * 100.0))

    if key in MANIFEST:
        mw, mh = MANIFEST[key]
        if mw and abs(w - mw) > mw * DIM_TOL:
            issues.append("ancho %d fuera de %d +/-20%%" % (w, mw))
        if mh and abs(h - mh) > mh * DIM_TOL:
            issues.append("alto %d fuera de %d +/-20%%" % (h, mh))
        if mw and mh:
            exp, got = mw / mh, w / h
            if abs(got / exp - 1.0) > RATIO_TOL:
                issues.append("ratio %.2f fuera de %.2f +/-25%%" % (got, exp))
    else:
        issues.append("clave desconocida (no esta en el manifiesto)")

    return not issues, issues


def qa_dir(directory, strict=False):
    found = sorted(f for f in os.listdir(directory) if f.lower().endswith(".png"))
    total, ok_n = 0, 0
    for name in found:
        total += 1
        ok, issues = qa_file(os.path.join(directory, name))
        ok_n += 1 if ok else 0
        print("  %-26s %s" % (name, "OK" if ok else "FAIL: " + "; ".join(issues)))
    missing = [k for k in REQUIRED
               if not os.path.exists(os.path.join(directory, k + ".png"))]
    if missing:
        print("  faltan %d/%d del manifiesto: %s"
              % (len(missing), len(REQUIRED), ", ".join(missing)))
    print("QA: %d/%d OK" % (ok_n, total))
    if strict:
        return 0 if (ok_n == total and not missing) else 1
    return 0 if ok_n == total else 1


# --- Hoja de contacto (QA visual de B6) -------------------------------------
def contact_sheet(directory, out_path, cell=132, cols=8, zoom=3):
    """Todos los sprites sobre fondo ajedrez, con etiqueta y estado de QA."""
    from PIL import ImageDraw

    names = sorted(f for f in os.listdir(directory) if f.lower().endswith(".png"))
    if not names:
        print("hoja de contacto: no hay PNG en " + directory)
        return 1
    rows = (len(names) + cols - 1) // cols
    label_h = 16
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + label_h)), (24, 24, 28, 255))
    draw = ImageDraw.Draw(sheet)

    for i, name in enumerate(names):
        cx, cy = (i % cols) * cell, (i // cols) * (cell + label_h)
        for yy in range(0, cell, 8):                       # ajedrez
            for xx in range(0, cell, 8):
                shade = 90 if ((xx // 8 + yy // 8) % 2) else 130
                draw.rectangle([cx + xx, cy + yy, cx + xx + 7, cy + yy + 7],
                               fill=(shade, shade, shade, 255))
        with Image.open(os.path.join(directory, name)) as im:
            im = im.convert("RGBA")
            scale = min(zoom, (cell - 8) / max(im.width, 1), (cell - 8) / max(im.height, 1))
            scale = max(scale, (cell - 8) / max(im.width, im.height, 1)) if max(
                im.width, im.height) > cell - 8 else scale
            w, h = max(1, int(im.width * scale)), max(1, int(im.height * scale))
            sheet.alpha_composite(im.resize((w, h), Image.NEAREST),
                                  (cx + (cell - w) // 2, cy + (cell - h) // 2))
        ok, _ = qa_file(os.path.join(directory, name))
        draw.rectangle([cx, cy + cell, cx + cell - 1, cy + cell + label_h - 1],
                       fill=(20, 90, 40, 255) if ok else (130, 30, 30, 255))
        draw.text((cx + 3, cy + cell + 3), name[:-4][:22], fill=(235, 235, 235, 255))

    sheet.convert("RGB").save(out_path)
    print("hoja de contacto: %s (%d sprites, %dx%d)"
          % (out_path, len(names), sheet.width, sheet.height))
    return 0


# --- Smoke test de B0 -------------------------------------------------------
def selftest():
    tmp = os.path.join("art_raw", "tmp")
    os.makedirs(tmp, exist_ok=True)
    src = os.path.join(tmp, "selftest_src.png")
    dst = os.path.join(tmp, "weapon_dagger.png")

    # "daga" sintetica de 400x51 (ratio 7.84 ~= el 55x7 del manifiesto) con la
    # punta afilada a la derecha: al recortar deja esquinas transparentes, asi
    # el smoke test comprueba alfa real y ausencia de distorsion.
    canvas = Image.new("RGBA", (512, 512), MAGENTA + (255,))
    for y in range(231, 282):
        for x in range(56, 456):
            taper = (x - 356) / 100.0 * 25.0       # ultimos 100 px: punta
            if taper > 0 and abs(y - 256) > 25 - taper:
                continue
            canvas.putpixel((x, y), (180, 180, 190, 255))
    canvas.save(src)

    rep = process(src, dst)
    print(json.dumps(rep, ensure_ascii=False))
    print("QA: %d/%d OK" % (1 if rep["ok"] else 0, 1))
    if not rep["ok"]:
        return 1
    with Image.open(dst) as out:
        assert out.mode == "RGBA", out.mode
        assert out.size == (55, 7), out.size
        alpha = np.asarray(out)[..., 3]
        assert alpha.max() == 255 and alpha.min() == 0, "no hay alfa real"
    print("selftest B0: OK (magenta->alfa, autocrop, escala, QA)")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Pipeline de arte Track B (B0)")
    ap.add_argument("--in", dest="src", help="PNG bruto de entrada")
    ap.add_argument("--out", dest="dst", help="PNG final (godot/art/sprites/<clave>.png)")
    ap.add_argument("--height", type=int, help="alto objetivo en px")
    ap.add_argument("--width", type=int, help="ancho objetivo en px")
    ap.add_argument("--resample", choices=sorted(RESAMPLE), default="box")
    ap.add_argument("--opaque", action="store_true", help="forzar salida opaca sin alfa")
    ap.add_argument("--keep-magenta", action="store_true", help="no aplicar el chroma key")
    ap.add_argument("--qa", metavar="DIR", help="pasar QA sobre un directorio")
    ap.add_argument("--strict", action="store_true", help="con --qa: fallar si faltan archivos")
    ap.add_argument("--selftest", action="store_true", help="smoke test de B0")
    args = ap.parse_args(argv)

    if args.selftest:
        return selftest()
    if args.qa:
        return qa_dir(args.qa, strict=args.strict)
    if not (args.src and args.dst):
        ap.error("hacen falta --in y --out (o --qa DIR, o --selftest)")

    rep = process(args.src, args.dst, args.width, args.height, args.resample,
                  opaque=True if args.opaque else None,
                  keep_magenta=args.keep_magenta)
    status = "OK" if rep["ok"] else "FAIL: " + "; ".join(rep["issues"])
    print("%s -> %s  %dx%d  %s" % (rep["src"], rep["dst"],
                                   rep["out_size"][0], rep["out_size"][1], status))
    return 0 if rep["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
