#!/usr/bin/env python3
"""Track B - driver de generacion de arte (B1-B6) sobre el CLI `bl`.

Tabla de prompts de docs/ART_PROMPTS.md. Para cada clave: genera N variantes con
`bl`, las pasa por tools/img_pipeline.py, hace QA y copia la mejor a
godot/art/sprites/<clave>.png.

  py -3 tools/art_gen.py --group weapons            # B3
  py -3 tools/art_gen.py --group nacho --vision     # B1 (con desempate VL)
  py -3 tools/art_gen.py --key blood_2 --variants 2
  py -3 tools/art_gen.py --group all --only-missing --dry-run
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import img_pipeline as P   # noqa: E402

SPRITES = os.path.join("art", "sprites")
RAW = "art_raw"
MODEL = "wan2.7-image"   # retirado del catalogo: los lotes nuevos fijan "model"

STYLE = ("pixel art game sprite, side view, full body, grotesque colorful cartoon "
         "style like Nidhogg 2, thick black outline, limited color palette, flat "
         "shading, crisp pixel edges")
BG = ("solid pure magenta background #FF00FF, no other background elements, no text, "
      "no watermark, no border")
# Para HUD/UI el {STYLE} completo ("game sprite, side view, full body, ... Nidhogg 2")
# arrastra al modelo a dibujar personajes: los pips salieron como guerreros. Se usa
# un estilo de icono plano (misma excepcion que el manual hace con los tiles).
STYLE_UI = ("flat pixel art UI icon, no characters, no people, no scene, thick black "
            "outline, limited color palette, flat shading, crisp pixel edges")
MONO = "strictly monochrome, one single flat color plus black outline, no other colors"

NACHO = ("Nacho: 10 year old slender boy fencer, dark brown mop-top haircut, "
         "rectangular glasses with transparent lenses and visible eyes, serious "
         "focused expression, electric blue tunic over white long-sleeve shirt, beige "
         "shorts, blue sneakers, brown fencing glove, exact same character as the "
         "reference image")
RODRIGO = ("Rodrigo: 8 year old boy fencer, slightly compact build, round cheeks, "
           "blond hair with straight bangs, big happy smile, red and orange tunic "
           "with brown leather belt, khaki cargo shorts, dark blue sneakers, small "
           "leather shoulder pad, exact same character as the reference image")

# pose -> (descriptor, canvas)  ('sq' cuadrado, 'wide' apaisado)
POSES = {
    "idle": ("standing fencing en garde stance, knees bent, sword held forward at "
             "chest height", "sq"),
    "run_0": ("running, contact pose: right leg extended forward heel down, left leg "
              "trailing back, arms pumping", "sq"),
    "run_1": ("running, passing pose: legs crossing mid-air under the body", "sq"),
    "run_2": ("running, push-off pose: left leg driving behind, body leaning forward",
              "sq"),
    "run_3": ("running, recovery pose: front knee lifted high, arms swinging opposite",
              "sq"),
    "jump": ("rising jump, legs tucked up, arms raised", "sq"),
    "fall": ("falling down, arms up, legs apart", "sq"),
    "crouch": ("crouching low on one knee, weapon pointing forward at knee height",
               "sq"),
    "slide": ("feet-first ground slide, body leaning back low, one hand on the floor",
              "wide"),
    "divekick": ("diving kick diagonally down towards the right at 45 degrees, one leg "
                 "fully extended, arms back", "sq"),
    "attack_high": ("deep fencing lunge, weapon thrust raised above head height", "sq"),
    "attack_mid": ("deep fencing lunge, weapon thrust straight at chest height, back "
                   "leg extended", "sq"),
    "attack_low": ("kneeling low thrust, weapon pointing at ankle height", "sq"),
    "throw": ("throwing pose, throwing arm fully extended forward, hand open, body "
              "twisted", "sq"),
    "downed": ("lying flat on his back on the ground, stunned, stars around head",
               "wide"),
    "dead": ("ragdoll lying limp on the ground, limbs loose, eyes as X marks", "wide"),
}

# Poses desarmadas (tarea 61): mismas composiciones sin arma. Solo las que el
# renderer necesita al ir sin espada o con el arco (idle/correr/saltar/caer/
# agacharse); ataques, dead y downed no llevan variante.
NOARME_POSES = {
    "idle": ("standing fencing en garde stance, knees bent, empty hands relaxed",
             "sq"),
    "run_0": ("running, contact pose: right leg extended forward heel down, left "
              "leg trailing back, arms pumping", "sq"),
    "run_1": ("running, passing pose: legs crossing mid-air under the body", "sq"),
    "run_2": ("running, push-off pose: left leg driving behind, body leaning "
              "forward", "sq"),
    "run_3": ("running, recovery pose: front knee lifted high, arms swinging "
              "opposite", "sq"),
    "jump": ("rising jump, legs tucked up, arms raised", "sq"),
    "fall": ("falling down, arms up, legs apart", "sq"),
    "crouch": ("crouching low on one knee, open empty hand extended forward at "
               "knee height", "sq"),
    "throw": ("throwing pose, throwing arm fully extended forward, hand open, "
              "body twisted", "sq"),
}
NOARME_EXTRA = ("EMPTY HANDS with open relaxed fists, no weapon, no sword, no bow, "
                "holding nothing, completely unarmed")

SIZES = {"sq": "1024*1024", "wide": "1664*928", "tall": "928*1664",
         "strip": "2048*512", "long": "2048*768"}

# Refuerzo de silueta fina: el manifiesto pide armas tipo Nidhogg (ratios 7:1 a
# 12:1). Sin esto el modelo dibuja guardas gruesas y el QA marca distorsion.
SLIM = ("very long thin narrow straight blade, tiny short straight crossguard, "
        "extremely slim horizontal silhouette, the whole weapon is at least 11 times "
        "longer than it is tall, hair-thin profile, no wide pommel")

WEAPONS = {
    "weapon_rapier": ("thin fencing rapier with a tiny small bell guard, " + SLIM,
                      "strip"),
    "weapon_longsword": ("two-handed broadsword with a very long straight blade, "
                         + SLIM, "strip"),
    "weapon_dagger": ("short fighting dagger, " + SLIM, "wide"),
    "weapon_bow": ("wooden recurve bow held VERTICAL, string facing left", "tall"),
    "weapon_arrow": ("single arrow with a straight shaft, a pointed head and small "
                     "fletching feathers at the back, about 5 times longer than it "
                     "is tall, entirely inside the frame with margins", "wide"),
}

# clave -> (prompt sin {STYLE}/{BG}, canvas, usa_style, opaco)
OTHERS = {
    "tile_floor": ("seamless tileable pixel art texture of grey stone flagstones, "
                   "irregular carved stone slabs of a castle floor with dark mortar "
                   "joints, top-down flat view, muted brown and gray stone, no wood, "
                   "pixel art, seamless tileable, full-bleed texture filling the "
                   "whole frame, no border, no text", "sq", False, True),
    "tile_wall": ("seamless tileable pixel art stone brick wall texture, large gray "
                  "blocks with dark mortar, pixel art, seamless tileable, full-bleed "
                  "texture filling the whole frame, no border, no text",
                  "sq", False, True),
    "pit_edge": ("pixel art broken stone floor edge piece, top-down, cracked rim",
                 "sq", True, False),
    "bg_layer0": ("pixel art parallax background, far silhouettes of a dark gothic "
                  "castle interior, very dark muted purples, no characters, wide "
                  "horizontal composition, full-bleed background, no transparency, "
                  "no text, no border", "wide", False, True),
    "bg_layer1": ("pixel art parallax background layer, mid-distance castle columns, "
                  "banners and torches, muted colors, no characters, full-bleed "
                  "background, no transparency, no text, no border", "wide", False,
                  True),
    "arrow_neutral": ("hand-drawn crayon style big arrow pointing RIGHT, chunky "
                      "outline, PURE WHITE fill, flat, wide horizontal shape, " + MONO,
                      "wide", "ui", False),
    "pip_hollow": ("a single empty square outline, hollow square frame, thick WHITE "
                   "border, completely empty transparent interior, slightly rounded "
                   "corners, flat, geometric, centered, " + MONO, "sq", "ui", False),
    "pip_filled": ("a single solid filled square, LIGHT GRAY fill, slightly rounded "
                   "corners, flat, geometric, centered, " + MONO, "sq", "ui", False),
    "blood_0": ("small blood splat decal blob, LIGHT GRAY, irregular round shape, "
                + MONO, "sq", "ui", False),
    "blood_1": ("medium blood splat decal seen from above, LIGHT GRAY, irregular "
                "splash stretched sideways, clearly much wider than tall, flat "
                "horizontal smear, " + MONO, "wide", "ui", False),
    "blood_2": ("large blood splat decal seen from above, LIGHT GRAY, irregular "
                "splash with droplets sprayed sideways, flat wide horizontal streak, "
                "clearly twice as wide as tall, " + MONO, "wide", "ui", False),
    "worm_body": ("pixel art giant green cartoon serpent worm, huge open jaws with "
                  "teeth facing LEFT, grotesque friendly monster, long stretched "
                  "body about 2.5 times longer than it is tall, whole creature "
                  "completely inside the frame with wide empty margins on all sides, "
                  "nothing cropped or touching the frame edges", "long", True, False),
}

COPIES = {"bg_title": os.path.join("media", "personajes", "duelo_versus.png")}
REFS = {"p1": os.path.join("media", "personajes", "nacho_hoja.png"),
        "p2": os.path.join("media", "personajes", "rodrigo_hoja.png")}


def build_specs():
    """clave -> spec completo (mode, prompt, size, group, ref, opaque)."""
    specs = {}
    for who, block, group in (("p1", NACHO, "nacho"), ("p2", RODRIGO, "rodrigo")):
        for pose, (desc, canvas) in POSES.items():
            specs["player_%s_%s" % (pose, who)] = {
                "mode": "edit", "ref": REFS[who], "group": group, "size": SIZES[canvas],
                "prompt": "%s, %s, facing RIGHT, single character alone, one figure "
                          "only, whole body and whole weapon completely inside the "
                          "frame with wide empty margins on all sides, nothing "
                          "cropped or touching the frame edges. %s, %s"
                          % (block, desc, STYLE, BG),
            }
    for who, block in (("p1", NACHO), ("p2", RODRIGO)):
        for pose, (desc, canvas) in NOARME_POSES.items():
            specs["player_%s_noarme_%s" % (pose, who)] = {
                "mode": "edit", "ref": REFS[who], "group": "noarme",
                "size": SIZES[canvas], "model": "qwen-image-edit-plus",
                "prompt": "%s, %s, %s, facing RIGHT, single character alone, one "
                          "figure only, whole body completely inside the frame "
                          "with wide empty margins on all sides, nothing cropped "
                          "or touching the frame edges. %s, %s"
                          % (block, desc, NOARME_EXTRA, STYLE, BG),
            }
    for key, (desc, canvas) in WEAPONS.items():
        specs[key] = {
            "mode": "generate", "group": "weapons", "size": SIZES[canvas],
            "prompt": "%s, horizontal, hilt on the LEFT side pointing the blade to the "
                      "RIGHT, no hand, %s, %s" % (desc, STYLE, BG),
        }
    for key, (desc, canvas, use_style, opaque) in OTHERS.items():
        group = "worm" if key == "worm_body" else (
            "hud" if key.startswith(("arrow", "pip", "blood")) else "scenery")
        prompt = desc + {True: ", " + STYLE, "ui": ", " + STYLE_UI,
                         False: ""}[use_style]
        if not opaque:
            prompt += ", " + BG
        specs[key] = {"mode": "generate", "group": group, "size": SIZES[canvas],
                      "prompt": prompt, "opaque": opaque}
    for key, src in COPIES.items():
        specs[key] = {"mode": "copy", "src": src, "group": "scenery", "opaque": True}
    return specs


SPECS = build_specs()
GROUPS = {"nacho": [], "rodrigo": [], "weapons": [], "scenery": [], "hud": [],
          "worm": [], "noarme": []}
for _k, _s in SPECS.items():
    GROUPS[_s["group"]].append(_k)
for _g in GROUPS:
    GROUPS[_g].sort()


#  En Windows `bl` es un shim .cmd: CreateProcess no lo encuentra sin extension.
BL = shutil.which("bl") or "bl"


def run(cmd, dry=False):
    print("  $ " + " ".join(('"%s"' % c if " " in c else c) for c in cmd))
    if dry:
        return ""
    cmd = [BL if c == "bl" else c for c in cmd]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                         errors="replace")
    if res.returncode != 0:
        raise RuntimeError("fallo (%d): %s" % (res.returncode,
                                               (res.stderr or res.stdout)[-600:]))
    return res.stdout


def raws_of(key, group):
    out_dir = os.path.join(RAW, group)
    if not os.path.isdir(out_dir):
        return []
    return sorted(os.path.join(out_dir, f) for f in os.listdir(out_dir)
                  if f.startswith(key + "_") and f.endswith(".png"))


def generate(key, spec, variants, dry=False, reuse=False):
    """Lanza `bl` y devuelve las rutas de las variantes brutas."""
    out_dir = os.path.join(RAW, spec["group"])
    os.makedirs(out_dir, exist_ok=True)
    if reuse:
        have = raws_of(key, spec["group"])
        if have:
            print("  reutilizando %d variante(s) ya descargada(s)" % len(have))
            return have
    for old in os.listdir(out_dir):
        if old.startswith(key + "_") and old.endswith(".png"):
            os.remove(os.path.join(out_dir, old))

    cmd = ["bl", "image", spec["mode"], "--model", spec.get("model", MODEL),
           "--prompt", spec["prompt"], "--size", spec["size"],
           "--watermark", "false", "--prompt-extend", "false",
           "--n", str(variants), "--out-dir", out_dir, "--out-prefix", key]
    if spec["mode"] == "edit":
        cmd[3:3] = ["--image", spec["ref"]]
    run(cmd, dry)
    return [] if dry else raws_of(key, spec["group"])


def vision_ok(path, question):
    try:
        out = run(["bl", "vision", "describe", "--image", path, "--prompt", question,
                   "--quiet"])
    except RuntimeError as exc:
        return None, str(exc)
    text = out.strip().replace("\n", " ")[:300]
    return ("YES" in text.upper()[:40]), text


def score(rep):
    """Menor es mejor. Penaliza QA fallido y desviacion de ratio."""
    penalty = 0.0 if rep["ok"] else 100.0
    mw, mh = P.MANIFEST.get(rep["key"], (None, None))
    if mw and mh:
        cw, ch = rep.get("crop", rep["out_size"])
        penalty += abs((cw / ch) / (mw / mh) - 1.0)
    return penalty


def do_key(key, spec, variants, dry, vision, report, reuse=False):
    print("\n[%s] %s" % (spec["group"], key))
    dst = os.path.join(SPRITES, key + ".png")

    if spec["mode"] == "copy":
        print("  copia de " + spec["src"])
        if not dry:
            rep = P.process(spec["src"], dst, opaque=spec.get("opaque"))
            print("  -> %dx%d %s" % (rep["out_size"][0], rep["out_size"][1],
                                     "OK" if rep["ok"] else "FAIL: %s" % rep["issues"]))
            report[key] = rep
        return

    raws = generate(key, spec, variants, dry, reuse)
    if dry:
        return

    cands = []
    proc_dir = os.path.join(RAW, spec["group"], "proc")
    os.makedirs(proc_dir, exist_ok=True)
    for i, raw in enumerate(raws, 1):
        tmp = os.path.join(proc_dir, "%s_v%d.png" % (key, i))
        # Nombre temporal con la clave real para que el pipeline aplique su manifiesto.
        staged = os.path.join(proc_dir, key + ".png")
        rep = P.process(raw, staged, opaque=spec.get("opaque"))
        with Image.open(raw) as im:
            crop = P.autocrop(P.dechroma(im.convert("RGBA"))).size \
                if not spec.get("opaque") else im.size
        rep["crop"] = list(crop)
        rep["variant"] = i
        shutil.move(staged, tmp)
        rep["proc"] = tmp
        cands.append(rep)
        print("  v%d %s -> %dx%d (recorte %dx%d) %s"
              % (i, os.path.basename(raw), rep["out_size"][0], rep["out_size"][1],
                 crop[0], crop[1], "OK" if rep["ok"] else "FAIL: %s"
                 % "; ".join(rep["issues"])))

    if vision and len(cands) > 1:
        q = ("Does this image show exactly one subject on a magenta background, "
             "clearly matching: %s? Answer YES or NO first, then issues." % key)
        for c in cands:
            ok, txt = vision_ok(c["src"], q)
            c["vision"] = txt
            if ok is False:
                c["ok"] = False
                c["issues"] = c["issues"] + ["vision: NO"]
            print("     VL v%d: %s" % (c["variant"], (txt or "")[:120]))

    best = min(cands, key=score)
    shutil.copyfile(best["proc"], dst)
    best["dst"] = dst
    report[key] = best
    print("  ELEGIDA v%d -> %s  %s" % (best["variant"], dst,
                                       "OK" if best["ok"] else "CON FALLOS"))


def main(argv=None):
    ap = argparse.ArgumentParser(description="Generador de arte Track B")
    ap.add_argument("--group", action="append", default=[],
                    choices=sorted(GROUPS) + ["all"])
    ap.add_argument("--key", action="append", default=[])
    ap.add_argument("--variants", type=int, default=2)
    ap.add_argument("--vision", action="store_true", help="desempate con qwen-vl")
    ap.add_argument("--only-missing", action="store_true")
    ap.add_argument("--reuse-raw", action="store_true",
                    help="no regenerar si ya hay variantes descargadas")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--report", default=os.path.join(RAW, "report.json"),
                    help="fichero de informe (uno por lote para correr en paralelo)")
    args = ap.parse_args(argv)

    keys = list(args.key)
    for g in args.group:
        keys += sorted(SPECS) if g == "all" else GROUPS[g]
    if not keys:
        ap.error("indica --group o --key")
    seen, ordered = set(), []
    for k in keys:
        if k in SPECS and k not in seen:
            seen.add(k)
            ordered.append(k)
    if args.only_missing:
        ordered = [k for k in ordered
                   if not os.path.exists(os.path.join(SPRITES, k + ".png"))]

    os.makedirs(SPRITES, exist_ok=True)
    report_path = args.report
    report = {}
    if os.path.exists(report_path):
        with open(report_path, encoding="utf-8") as fh:
            report = json.load(fh)

    print("Claves a procesar: %d" % len(ordered))
    failed = []
    for key in ordered:
        try:
            do_key(key, SPECS[key], args.variants, args.dry_run, args.vision,
                   report, args.reuse_raw)
        except Exception as exc:                      # noqa: BLE001
            print("  ERROR: %s" % exc)
            failed.append(key)
            report[key] = {"key": key, "ok": False, "issues": ["error: %s" % exc]}
        if not args.dry_run:
            with open(report_path, "w", encoding="utf-8") as fh:
                json.dump(report, fh, ensure_ascii=False, indent=1)

    if not args.dry_run:
        ok_n = sum(1 for k in ordered if report.get(k, {}).get("ok"))
        print("\nResumen: %d/%d OK%s" % (ok_n, len(ordered),
                                         ("; errores: " + ", ".join(failed))
                                         if failed else ""))
        return 0 if ok_n == len(ordered) else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
