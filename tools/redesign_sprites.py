# -*- coding: utf-8 -*-
"""Rediseño de personajes y armas "estilo original" para Nidhogg 2.1.

Rig paramétrico de pixel art: redibuja los 32 sprites de pose armados,
los 18 desarmados (noarme) y las 5 armas con un lenguaje visual unificado
inspirado en el look del juego original (dibujo original propio, sin copiar
pixels de assets ajenos):

  - proporción cabezona ~1:4 (cabeza grande, cuerpo compacto)
  - extremidades gruesas (4-5 px), silueta con contorno oscuro
  - halo de separación de 1 px entre piezas (brazos/torso, hoja/cuerpo…)
  - colores planos con 2 tonos (luz arriba/frente, sombra abajo/atrás)
  - hoja metálica con núcleo claro y filo inferior oscuro

Contrato respetado (cero cambios de código):
  - mismos nombres de fichero en art/sprites/
  - pies tocando el borde inferior del canvas (el px más bajo del pose)
  - eje del cuerpo centrado horizontalmente (el renderer centra el canvas)
  - arma en mano horneada = florete; el arco se dibuja aparte (noarme)
  - weapon_arrow 28x6 apuntando a la derecha; weapon_bow 38x70 con las
    puntas de las palas en y=10 e y=60 (el juego ancla ahí la cuerda)

Salidas extra (art_raw/redesign/): hoja de contactos, comparativa viejo↔nuevo.
Uso:  python tools/redesign_sprites.py [--only sprites|sheets|compare]
"""

import math
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES_DIR = os.path.join(ROOT, "art", "sprites")
SHEETS_DIR = os.path.join(ROOT, "art_raw", "redesign")

OUTLINE = (26, 18, 38, 255)          # contorno oscuro morado
STEEL = {"light": (238, 244, 250, 255), "base": (194, 204, 216, 255), "dark": (138, 150, 168, 255)}
BRASS = {"light": (232, 200, 96, 255), "base": (201, 162, 58, 255), "dark": (138, 106, 30, 255)}
GRIP = (90, 58, 36, 255)

PALETTES = {
    "p1": {  # azul — pelo castaño oscuro
        "jacket": (58, 102, 200, 255), "jacket_l": (92, 138, 232, 255), "jacket_d": (36, 68, 140, 255),
        "breech": (230, 220, 196, 255), "breech_l": (246, 239, 220, 255), "breech_d": (184, 174, 148, 255),
        "boot": (106, 70, 48, 255), "boot_d": (70, 41, 26, 255),
        "skin": (240, 192, 144, 255), "skin_d": (200, 144, 102, 255),
        "hair": (82, 53, 31, 255), "hair_l": (109, 74, 42, 255), "hair_d": (58, 37, 21, 255),
        "belt": (42, 35, 48, 255), "buckle": BRASS["base"],
    },
    "p2": {  # rojo — rubio
        "jacket": (200, 70, 50, 255), "jacket_l": (232, 112, 80, 255), "jacket_d": (140, 40, 32, 255),
        "breech": (230, 220, 196, 255), "breech_l": (246, 239, 220, 255), "breech_d": (184, 174, 148, 255),
        "boot": (85, 52, 31, 255), "boot_d": (56, 32, 18, 255),
        "skin": (240, 192, 144, 255), "skin_d": (200, 144, 102, 255),
        "hair": (224, 168, 60, 255), "hair_l": (240, 200, 96, 255), "hair_d": (168, 118, 38, 255),
        "belt": (42, 35, 48, 255), "buckle": BRASS["base"],
    },
}

# partes con bisel automático: luz arriba/frente, sombra abajo/atrás
SHADED = {"jacket": ("jacket_l", "jacket_d"), "breech": ("breech_l", "breech_d"),
          "boot": (None, "boot_d"), "hair": ("hair_l", None), "skin": (None, "skin_d")}


def _dist_seg(px, py, x0, y0, x1, y1):
    dx, dy = x1 - x0, y1 - y0
    if dx == 0 and dy == 0:
        return math.hypot(px - x0, py - y0)
    t = ((px - x0) * dx + (py - y0) * dy) / float(dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return math.hypot(px - (x0 + t * dx), py - (y0 + t * dy))


class Rig:
    """Lienzo virtual: eje del cuerpo en x=0, y=0 el punto más bajo (arriba = negativo)."""

    def __init__(self):
        self.px = {}      # (x,y) -> (color, part)

    def _paint(self, pixels, color, part, halo):
        """Pinta un conjunto de px; con halo, borde oscuro de 1 px alrededor."""
        if halo:
            for (x, y) in pixels:
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    self.px[(nx, ny)] = (OUTLINE, "outline")
        for p in pixels:
            self.px[p] = (color, part)

    def rect(self, x0, y0, x1, y1, color, part="", halo=False):
        xs = [p for p in range(int(round(min(x0, x1))), int(round(max(x0, x1))) + 1)
              for _ in range(1)]
        ys = list(range(int(round(min(y0, y1))), int(round(max(y0, y1))) + 1))
        pixels = [(x, y) for x in xs for y in ys]
        self._paint(pixels, color, part, halo)

    def limb(self, a, b, width, color, part="", halo=False):
        """Segmento grueso con caps redondeados (width = diámetro total)."""
        ax, ay, bx, by = a[0], a[1], b[0], b[1]
        r = width / 2.0
        pixels = []
        for x in range(int(math.floor(min(ax, bx) - r)) - 1, int(math.ceil(max(ax, bx) + r)) + 2):
            for y in range(int(math.floor(min(ay, by) - r)) - 1, int(math.ceil(max(ay, by) + r)) + 2):
                if _dist_seg(x, y, ax, ay, bx, by) <= r:
                    pixels.append((x, y))
        self._paint(pixels, color, part, halo)

    def shade(self, pal):
        """Bisel: luz arriba, sombra abajo, según la silueta rellena."""
        for (x, y), (c, part) in list(self.px.items()):
            if part not in SHADED:
                continue
            key_l, key_d = SHADED[part]
            above = (x, y - 1) in self.px
            below = (x, y + 1) in self.px
            front = (x + 1, y) in self.px      # miramos a +x: frente iluminado
            if not above and key_l:
                self.px[(x, y)] = (pal[key_l], part)
            elif not below and key_d:
                self.px[(x, y)] = (pal[key_d], part)
            elif not front and key_l and part in ("jacket", "breech"):
                self.px[(x, y)] = (pal[key_l], part)

    def outline(self):
        """Contorno oscuro alrededor de la silueta (1 px fuera)."""
        border = []
        for (x, y) in self.px:
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if (nx, ny) not in self.px:
                    border.append((nx, ny))
        for p in border:
            self.px[p] = (OUTLINE, "outline")

    # ---------- piezas del duelista (mirando a +x) ----------

    def head(self, c, pal, style, scale=1.0, dead=False, dazed=False):
        cx, cy = c
        rx, ry = 5.0 * scale, 5.5 * scale
        skull = [(x, y) for x in range(int(cx - rx) - 1, int(cx + rx) + 2)
                 for y in range(int(cy - ry) - 1, int(cy + ry) + 2)
                 if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1.0]
        self._paint(skull, pal["skin"], "skin", halo=True)
        # pelo (encima del cráneo, sin halo: misma pieza)
        htop = int(round(cy - ry))
        if style == "p1":       # castaño corto con mechón
            self.rect(cx - 5, htop, cx + 4, cy - 2, pal["hair"], "hair")
            self.rect(cx - 5, cy - 2, cx - 3, cy + 2, pal["hair"], "hair")
            self.set(cx + 4, htop, pal["hair"])
            self.set(cx + 3, htop - 1, pal["hair"])
        else:                   # rubio peinado atrás
            self.rect(cx - 5, htop, cx + 3, cy - 2, pal["hair"], "hair")
            self.rect(cx - 6, cy - 2, cx - 4, cy + 3, pal["hair"], "hair")
            self.set(cx + 4, cy - 3, pal["hair"])
            self.set(cx + 3, cy - 4, pal["hair"])
        # rostro
        if dead:
            for ox, oy in ((0, 0), (1, 1), (1, -1), (2, 0)):
                self.set(cx + 2 + ox, cy - 1 + oy, OUTLINE)
                self.set(cx + 2 + ox, cy + 2 + oy, OUTLINE)
        else:
            self.rect(cx + 1, cy - 1, cx + 2, cy, OUTLINE)                      # ojo
            self.set(cx + 2, cy - 1, (255, 255, 255, 255))                      # brillo
            self.rect(cx, cy - 3, cx + 2, cy - 3,
                      pal["hair_d"] if not dazed else OUTLINE)                  # ceja
            if dazed:
                self.set(cx + 1, cy + 2, OUTLINE)                               # espiral
        self.set(cx + 4, cy + 1, pal["skin_d"])       # nariz
        self.set(cx + 4, cy + 2, pal["skin_d"])
        self.rect(cx + 1, cy + 3, cx + 2, cy + 3, (150, 82, 70, 255))           # boca
        self.set(cx - 3, cy + 1, pal["skin_d"])       # oreja

    def set(self, x, y, color, part=""):
        self.px[(int(round(x)), int(round(y)))] = (color, part)

    def torso(self, hip, chest, pal, width=11):
        self.limb(hip, chest, width, pal["jacket"], "jacket")
        hx = int(round(hip[0]))
        by = int(round(hip[1])) - 1
        self.rect(hx - width // 2, by, hx + width // 2, by, pal["belt"], "belt")
        self.set(hx, by, pal["buckle"], "belt")

    def leg(self, hip, knee, ankle, toe_x, pal, back=False):
        self.limb(hip, knee, 5, pal["breech"], "breech", halo=True)
        self.limb(knee, ankle, 4, pal["breech"], "breech", halo=True)
        ay = int(round(ankle[1]))
        ax = int(round(ankle[0]))
        tx = int(round(toe_x))
        self.rect(ax - 1, ay - 1, tx, ay, pal["boot"], "boot", halo=True)
        self.rect(ax - 1, ay + 1, tx, ay + 1, pal["boot_d"], "boot")            # suela

    def arm(self, sh, elbow, hand, pal, cuff=True):
        self.limb(sh, elbow, 4, pal["jacket"], "jacket", halo=True)
        self.limb(elbow, hand, 4, pal["jacket"], "jacket", halo=True)
        hx, hy = int(round(hand[0])), int(round(hand[1]))
        self.rect(hx - 1, hy - 1, hx + 1, hy + 1, pal["skin"], "skin", halo=True)  # puño

    def sword(self, hand, angle_deg, length, pal):
        """Florete horneado: el guarda SOLAPA el puño para que nunca se despegue."""
        a = math.radians(angle_deg)
        dx, dy = math.cos(a), -math.sin(a)          # y arriba = negativo
        ux, uy = -dy, dx                            # perpendicular
        # hoja: celdas de 2 px (fila clara + fila base) desde el borde del guarda
        cells = []
        for i in range(int(length)):
            bx, by = hand[0] + dx * (2 + i), hand[1] + dy * (2 + i)
            cells.append((int(round(bx)), int(round(by))))
        # guarda: disco pegado al puño (solapa 1 px)
        gcx, gcy = hand[0] + dx * 1.5, hand[1] + dy * 1.5
        guard = []
        for ox in (-2, -1, 0, 1, 2):
            for oy in (-2, -1, 0, 1, 2):
                if abs(ox) + abs(oy) <= 4:
                    guard.append((int(round(gcx + ux * ox)), int(round(gcy + uy * oy))))
        # empuñadura y pomo por detrás del puño
        grip = []
        for i in range(6):
            gx, gy = hand[0] - dx * i, hand[1] + dy * i
            grip.append((int(round(gx)), int(round(gy))))
        pomo = (int(round(hand[0] - dx * 6)), int(round(hand[1] + dy * 6)))
        self._paint(grip, GRIP, "grip", halo=True)
        self._paint([pomo, (pomo[0] + 1, pomo[1])], BRASS["base"], "grip", halo=True)
        self._paint(guard, BRASS["base"], "grip", halo=True)
        # hoja: halo completo alrededor de las DOS filas, luego el relleno
        blade_pairs = []
        for (x, y) in cells:
            blade_pairs.append((x, y))
            if (x, y - 1) not in cells:
                blade_pairs.append((x, y - 1))
        bset = set(blade_pairs)
        for p in blade_pairs:
            for nx, ny in ((p[0] - 1, p[1]), (p[0] + 1, p[1]), (p[0], p[1] - 1), (p[0], p[1] + 1)):
                if (nx, ny) not in bset:
                    self.px[(nx, ny)] = (OUTLINE, "outline")
        for i, (x, y) in enumerate(cells):
            if i >= len(cells) - 2:
                self.px[(x, y)] = (STEEL["dark"], "blade")
            else:
                self.px[(x, y - 1)] = (STEEL["light"], "blade")
                self.px[(x, y)] = (STEEL["base"], "blade")
        # repintar el puño encima de la empuñadura
        hx, hy = int(round(hand[0])), int(round(hand[1]))
        for ox in (-1, 0, 1):
            for oy in (-1, 0, 1):
                self.px[(hx + ox, hy + oy)] = (pal["skin"], "skin")

    # ---------- ensamblado ----------

    def compose(self, target_h):
        """Recorta: el px más bajo del pose queda en la última fila del canvas."""
        # despeckle: suelta px de contorno sin vecino de relleno (artefactos de halo)
        for (x, y) in [p for p, (c, part) in self.px.items() if part == "outline"]:
            if not any((nx, ny) in self.px and self.px[(nx, ny)][1] != "outline"
                       for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))):
                del self.px[(x, y)]
        xs = [p[0] for p in self.px]
        ys = [p[1] for p in self.px]
        bottom = max(ys)
        miny = min(ys)
        reach = max(abs(min(xs)), abs(max(xs))) + 1   # +1: margen de aire en los bordes
        width = 2 * reach + 1                       # impar → eje en el centro exacto
        height = max(bottom - miny + 1, target_h)
        img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        top = bottom - height + 1
        for (x, y), (c, part) in self.px.items():
            img.putpixel((width // 2 + x, y - top), c)
        return img


def apply_shade(rig, pal):
    rig.shade(pal)
    rig.outline()


# =========================================================================
# POSES  (mirando a +x; y=0 el punto más bajo del pose)
# =========================================================================

def pose_idle(rig, pal, style, armed=True):
    rig.torso((0, -21), (0, -33), pal)
    rig.leg((1, -21), (5, -11), (3, -2), 9, pal)
    rig.leg((-2, -21), (-6, -11), (-7, -2), -2, pal, back=True)
    rig.arm((-3, -32), (-9, -29), (-11, -37), pal, cuff=False)   # brazo trasero en arco
    if armed:
        rig.arm((4, -31), (10, -26), (14, -29), pal)
        rig.sword((15, -29), 18, 23, pal)
    else:
        rig.arm((4, -31), (10, -26), (15, -28), pal)
    rig.head((2, -41), pal, style)


def pose_run(rig, pal, style, phase, armed=True):
    # fase 0 contacto A, 1 paso A, 2 contacto B, 3 paso B
    bob = -2 if phase in (1, 3) else 0
    rig.torso((0, -21 + bob), (2, -33 + bob), pal)
    if phase == 0:
        rig.leg((1, -21), (9, -14), (13, -2), 16, pal)
        rig.leg((-2, -21), (-8, -13), (-12, -5), -9, pal, back=True)
        fa = ((5, -32), (10, -27), (14, -29))
        ba = ((-3, -33), (-8, -30), (-9, -36))
    elif phase == 1:
        rig.leg((1, -22), (7, -16), (9, -10), 13, pal)
        rig.leg((-2, -22), (0, -14), (-3, -9), 2, pal, back=True)
        fa = ((5, -34), (11, -29), (15, -31))
        ba = ((-3, -34), (-7, -31), (-8, -37))
    elif phase == 2:
        rig.leg((-1, -21), (-8, -14), (-12, -5), -9, pal, back=True)
        rig.leg((2, -21), (6, -13), (8, -2), 12, pal)
        fa = ((5, -32), (10, -27), (14, -29))
        ba = ((-3, -33), (-8, -30), (-9, -36))
    else:
        rig.leg((-1, -22), (-4, -16), (-2, -9), 4, pal, back=True)
        rig.leg((2, -22), (5, -15), (9, -10), 14, pal)
        fa = ((5, -34), (11, -29), (15, -31))
        ba = ((-3, -34), (-7, -31), (-8, -37))
    rig.arm(*ba, pal=pal, cuff=False)
    if armed:
        rig.arm(fa[0], fa[1], fa[2], pal)
        rig.sword((fa[2][0] - 1, fa[2][1]), 8, 22, pal)
    else:
        rig.arm(fa[0], fa[1], (fa[2][0] + 1, fa[2][1] - 1), pal)
    rig.head((4, -41 + bob), pal, style)


def pose_jump(rig, pal, style, armed=True):
    rig.torso((0, -20), (1, -32), pal)
    rig.leg((1, -20), (7, -16), (10, -11), 13, pal)
    rig.leg((-2, -20), (0, -15), (-4, -10), 1, pal, back=True)
    rig.arm((-3, -31), (-8, -33), (-12, -27), pal, cuff=False)
    if armed:
        rig.arm((5, -30), (10, -33), (14, -38), pal)
        rig.sword((15, -38), 40, 22, pal)
    else:
        rig.arm((5, -30), (10, -33), (15, -37), pal)
    rig.head((2, -40), pal, style)


def pose_fall(rig, pal, style, armed=True):
    rig.torso((0, -21), (1, -33), pal)
    rig.leg((1, -21), (8, -15), (12, -7), 15, pal)
    rig.leg((-2, -21), (-6, -14), (-10, -8), -7, pal, back=True)
    rig.arm((-3, -32), (-9, -34), (-13, -29), pal, cuff=False)
    if armed:
        rig.arm((5, -31), (11, -28), (15, -26), pal)
        rig.sword((16, -26), -12, 22, pal)
    else:
        rig.arm((5, -31), (11, -28), (16, -26), pal)
    rig.head((2, -41), pal, style)


def pose_crouch(rig, pal, style, armed=True):
    rig.torso((0, -12), (1, -23), pal)
    rig.leg((1, -12), (8, -10), (5, -2), 11, pal)
    rig.leg((-2, -12), (-7, -10), (-5, -2), 1, pal, back=True)
    rig.arm((-2, -22), (-7, -19), (-8, -13), pal, cuff=False)
    if armed:
        rig.arm((4, -21), (9, -17), (13, -18), pal)
        rig.sword((14, -18), 5, 21, pal)
    else:
        rig.arm((4, -21), (9, -17), (14, -18), pal)
    rig.head((2, -30), pal, style, scale=0.9)


def pose_slide(rig, pal, style, armed=True):
    # deslizamiento: cuerpo echado atrás, pierna delantera estirada rasante
    rig.torso((-1, -10), (-4, -18), pal, width=9)
    rig.leg((1, -10), (9, -8), (15, -4), 18, pal)
    rig.leg((-3, -10), (-2, -8), (-6, -4), -1, pal, back=True)
    rig.arm((-5, -17), (-10, -13), (-12, -7), pal, cuff=False)
    if armed:
        rig.arm((0, -17), (5, -17), (9, -20), pal)
        rig.sword((10, -20), 25, 21, pal)
    else:
        rig.arm((0, -17), (5, -17), (10, -19), pal)
    rig.head((-3, -26), pal, style, scale=0.9)


def pose_attack_high(rig, pal, style):
    rig.torso((0, -21), (5, -32), pal)
    rig.leg((1, -21), (10, -16), (14, -2), 18, pal)
    rig.leg((-2, -21), (-9, -14), (-16, -4), -9, pal, back=True)
    rig.arm((0, -32), (-5, -28), (-9, -22), pal, cuff=False)
    rig.arm((7, -31), (13, -31), (19, -33), pal)
    rig.sword((20, -33), 32, 29, pal)
    rig.head((6, -41), pal, style)


def pose_attack_mid(rig, pal, style):
    rig.torso((0, -21), (5, -32), pal)
    rig.leg((1, -21), (11, -14), (12, -3), 17, pal)
    rig.leg((-2, -21), (-10, -13), (-18, -3), -11, pal, back=True)
    rig.arm((0, -32), (-6, -30), (-11, -29), pal, cuff=False)
    rig.arm((7, -31), (14, -30), (21, -31), pal)
    rig.sword((22, -31), 4, 33, pal)
    rig.head((6, -41), pal, style)


def pose_attack_low(rig, pal, style):
    rig.torso((0, -15), (4, -25), pal)
    rig.leg((1, -15), (10, -11), (11, -2), 16, pal)
    rig.leg((-2, -15), (-9, -11), (-15, -3), -8, pal, back=True)
    rig.arm((0, -25), (-5, -22), (-9, -17), pal, cuff=False)
    rig.arm((6, -24), (12, -22), (18, -21), pal)
    rig.sword((19, -21), 3, 31, pal)
    rig.head((5, -34), pal, style)


def pose_throw(rig, pal, style, armed=True):
    rig.torso((0, -21), (2, -33), pal)
    rig.leg((1, -21), (7, -12), (7, -2), 13, pal)
    rig.leg((-2, -21), (-7, -12), (-8, -2), 0, pal, back=True)
    rig.arm((-2, -32), (-8, -29), (-11, -24), pal, cuff=False)
    if armed:
        rig.arm((4, -31), (12, -30), (19, -30), pal)
        rig.sword((21, -30), 6, 28, pal)      # recién soltada, 2 px por delante
    else:
        rig.arm((4, -31), (12, -30), (20, -30), pal)
        # estela de suelta: 3 trazos descendentes tras la mano abierta
        for k in range(3):
            rig.set(16 - k * 2, -31 - k, (176, 176, 196, 255))
            rig.set(15 - k * 2, -31 - k, (140, 140, 164, 255))
    rig.head((3, -41), pal, style)


def pose_divekick(rig, pal, style, armed=True):
    # patada voladora: cuerpo diagonal, pierna que patea estirada abajo-delante
    rig.torso((-7, -22), (0, -28), pal)
    rig.leg((-5, -22), (2, -18), (9, -13), 15, pal)          # pierna que patea
    rig.leg((-9, -23), (-13, -26), (-17, -31), -12, pal, back=True)  # trasera recogida arriba
    rig.arm((-2, -27), (3, -31), (7, -35), pal, cuff=False)
    if armed:
        rig.arm((-4, -29), (-8, -31), (-11, -35), pal)
        rig.sword((-11, -35), 20, 22, pal)     # hoja plana hacia atrás, sin cruzar piernas
    else:
        rig.arm((-4, -29), (-8, -31), (-11, -35), pal)
    rig.head((4, -33), pal, style)


def pose_dead(rig, pal, style):
    # tendido de espaldas, cabeza atrás (a -x), pierna doblada
    rig.torso((-2, -6), (-9, -8), pal, width=9)
    rig.leg((0, -5), (5, -10), (8, -3), 12, pal)
    rig.leg((-4, -5), (-8, -8), (-11, -3), -6, pal, back=True)
    rig.arm((-8, -9), (-12, -7), (-15, -4), pal, cuff=False)
    rig.arm((0, -8), (3, -5), (7, -4), pal, cuff=False)
    rig.head((-14, -11), pal, style, scale=0.9, dead=True)
    rig.sword((7, -4), 4, 24, pal)   # florete caído en la mano


def pose_downed(rig, pal, style):
    # derribado: de espaldas con rodillas alzadas, apoyado en un codo
    rig.torso((0, -6), (-4, -14), pal, width=9)
    rig.leg((1, -6), (6, -14), (9, -5), 13, pal)             # rodilla alzada
    rig.leg((-2, -6), (1, -9), (4, -4), 8, pal, back=True)
    rig.arm((-6, -13), (-9, -9), (-9, -4), pal, cuff=False)  # codo de apoyo
    rig.arm((2, -12), (5, -9), (5, -5), pal, cuff=False)
    rig.head((-7, -21), pal, style, scale=0.9, dazed=True)
    rig.sword((5, -5), 3, 22, pal)


# =========================================================================
# ARMAS SUELTAS
# =========================================================================

def weapon_rapier():
    img = Image.new("RGBA", (90, 9), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y = 4
    d.rectangle((1, y - 1, 3, y + 1), fill=BRASS["base"])                 # pomo
    d.rectangle((4, y - 1, 11, y + 1), fill=GRIP)                          # empunadura
    for x in range(5, 11, 2):
        d.point((x, y - 1), fill=(120, 80, 52, 255))                       # trenzado
    d.rectangle((12, y - 3, 15, y + 3), fill=BRASS["base"])                # concha
    d.rectangle((13, y - 2, 15, y + 2), fill=BRASS["light"])
    for x in range(16, 86):                                                # hoja
        d.point((x, y - 1), fill=STEEL["light"])
        d.point((x, y), fill=STEEL["base"])
    d.point((86, y), fill=STEEL["dark"])
    d.point((87, y), fill=STEEL["dark"])
    d.point((88, y), fill=STEEL["dark"])
    return img


def weapon_longsword():
    img = Image.new("RGBA", (120, 9), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y = 4
    d.rectangle((1, y - 1, 4, y + 1), fill=BRASS["base"])                  # pomo
    d.rectangle((5, y - 1, 14, y + 1), fill=GRIP)
    for x in range(6, 14, 3):
        d.point((x, y - 1), fill=(120, 80, 52, 255))
    d.rectangle((15, y - 3, 18, y + 3), fill=BRASS["dark"])                # gola
    d.rectangle((16, y - 3, 17, y + 3), fill=BRASS["base"])
    for x in range(19, 114):                                               # hoja 3px
        d.point((x, y - 1), fill=STEEL["light"])
        d.point((x, y), fill=STEEL["base"])
        d.point((x, y + 1), fill=STEEL["dark"])
    d.point((114, y), fill=STEEL["base"])
    d.point((114, y + 1), fill=STEEL["dark"])
    d.point((115, y), fill=STEEL["dark"])
    d.point((116, y), fill=STEEL["dark"])
    d.point((117, y), fill=STEEL["dark"])
    return img


def weapon_dagger():
    img = Image.new("RGBA", (55, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y = 3
    d.rectangle((1, y - 1, 2, y + 1), fill=BRASS["base"])
    d.rectangle((3, y - 1, 9, y + 1), fill=GRIP)
    d.rectangle((10, y - 2, 12, y + 2), fill=BRASS["base"])
    for x in range(13, 50):
        d.point((x, y - 1), fill=STEEL["light"])
        d.point((x, y), fill=STEEL["base"])
    d.point((50, y), fill=STEEL["dark"])
    d.point((51, y), fill=STEEL["dark"])
    d.point((52, y), fill=STEEL["dark"])
    return img


def weapon_bow():
    """38x70 vertical; puntas de las palas EXACTAS en y=10 e y=60."""
    img = Image.new("RGBA", (38, 70), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wood = (122, 82, 48, 255)
    wood_l = (150, 104, 62, 255)
    upper = [(19, 34), (17, 29), (15, 24), (14, 19), (14, 15), (16, 11), (18, 10)]
    lower = [(19, 36), (17, 41), (15, 46), (14, 51), (14, 55), (16, 59), (18, 60)]
    for pts in (upper, lower):
        for i in range(len(pts) - 1):
            x0, y0 = pts[i]
            x1, y1 = pts[i + 1]
            steps = max(abs(x1 - x0), abs(y1 - y0)) * 2 + 1
            for s in range(steps + 1):
                t = s / float(steps)
                x = x0 + (x1 - x0) * t
                y = y0 + (y1 - y0) * t
                d.point((round(x), round(y)), fill=wood)
                d.point((round(x) + 1, round(y)), fill=wood)
                if i < 3:
                    d.point((round(x) - 1, round(y)), fill=wood_l)
    d.rectangle((17, 32, 20, 38), fill=(70, 46, 30, 255))                  # empuñadura
    d.rectangle((17, 32, 18, 38), fill=(96, 64, 40, 255))
    d.point((18, 10), fill=(200, 176, 120, 255))                           # nocks
    d.point((18, 60), fill=(200, 176, 120, 255))
    return img


def weapon_arrow():
    img = Image.new("RGBA", (28, 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y = 2
    for x in range(3, 22):                                                 # asta
        d.point((x, y), fill=(196, 150, 92, 255))
        d.point((x, y + 1), fill=(160, 118, 68, 255))
    d.point((2, y), fill=(160, 118, 68, 255))
    d.point((23, y), fill=STEEL["base"])                                   # punta
    d.point((24, y - 1), fill=STEEL["light"])
    d.point((24, y), fill=STEEL["light"])
    d.point((24, y + 1), fill=STEEL["dark"])
    for x in (25, 26, 27):
        d.point((x, y), fill=STEEL["dark"])
    for fy in (0, 1, 2):                                                   # plumas
        c = (226, 120, 60, 255) if fy != 1 else (180, 88, 44, 255)
        d.point((1, fy), fill=c)
        d.point((2, fy), fill=c)
    return img


# =========================================================================
# GENERACIÓN
# =========================================================================

POSE_TARGET_H = {"idle": 56, "run_0": 56, "run_1": 56, "run_2": 56, "run_3": 56,
                 "jump": 56, "fall": 56, "crouch": 40, "slide": 30,
                 "attack_high": 56, "attack_mid": 56, "attack_low": 44,
                 "throw": 56, "divekick": 48, "dead": 28, "downed": 30}

ARMED_POSES = ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch",
               "slide", "attack_high", "attack_mid", "attack_low", "throw", "divekick",
               "dead", "downed"]
NOARME_POSES = ["idle", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "crouch", "throw"]


def build_pose(pose, side, armed=True):
    pal = PALETTES[side]
    rig = Rig()
    style = side
    if pose == "idle":
        pose_idle(rig, pal, style, armed)
    elif pose.startswith("run_"):
        pose_run(rig, pal, style, int(pose[-1]), armed)
    elif pose == "jump":
        pose_jump(rig, pal, style, armed)
    elif pose == "fall":
        pose_fall(rig, pal, style, armed)
    elif pose == "crouch":
        pose_crouch(rig, pal, style, armed)
    elif pose == "slide":
        pose_slide(rig, pal, style, armed)
    elif pose == "attack_high":
        pose_attack_high(rig, pal, style)
    elif pose == "attack_mid":
        pose_attack_mid(rig, pal, style)
    elif pose == "attack_low":
        pose_attack_low(rig, pal, style)
    elif pose == "throw":
        pose_throw(rig, pal, style, armed)
    elif pose == "divekick":
        pose_divekick(rig, pal, style, armed)
    elif pose == "dead":
        pose_dead(rig, pal, style)
    elif pose == "downed":
        pose_downed(rig, pal, style)
    else:
        raise ValueError(pose)
    apply_shade(rig, pal)
    return rig.compose(POSE_TARGET_H[pose])


def generate_sprites():
    os.makedirs(SPRITES_DIR, exist_ok=True)
    made = []
    for side in ("p1", "p2"):
        for pose in ARMED_POSES:
            img = build_pose(pose, side, armed=True)
            name = "player_%s_%s.png" % (pose, side)
            img.save(os.path.join(SPRITES_DIR, name))
            made.append((name, img))
        for pose in NOARME_POSES:
            img = build_pose(pose, side, armed=False)
            name = "player_%s_noarme_%s.png" % (pose, side)
            img.save(os.path.join(SPRITES_DIR, name))
            made.append((name, img))
    for name, fn in (("weapon_rapier", weapon_rapier), ("weapon_longsword", weapon_longsword),
                     ("weapon_dagger", weapon_dagger), ("weapon_bow", weapon_bow),
                     ("weapon_arrow", weapon_arrow)):
        img = fn()
        img.save(os.path.join(SPRITES_DIR, name + ".png"))
        made.append((name + ".png", img))
    return made


# ---------- hojas de revisión ----------

SCALE = 3


def _cell(sheet, img, cx, cy, cell_w, cell_h, d, label=None):
    big = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
    sheet.alpha_composite(big, (cx + (cell_w - big.width) // 2, cy + (cell_h - big.height) // 2))
    if label:
        d.text((cx + 4, cy + cell_h - 14), label, fill=(230, 230, 240, 255))


def make_sheets(made):
    os.makedirs(SHEETS_DIR, exist_ok=True)
    lookup = dict(made)
    cell_w, cell_h = 400, 200
    for side, title in (("p1", "P1 AZUL"), ("p2", "P2 ROJO")):
        rows = ARMED_POSES + [p + "*" for p in NOARME_POSES]
        sheet = Image.new("RGBA", (cell_w * 6 + 20, cell_h * ((len(rows) + 5) // 6) + 30), (38, 34, 48, 255))
        d = ImageDraw.Draw(sheet)
        d.text((8, 6), title + "   (* = noarme)", fill=(240, 240, 250, 255))
        for i, pose in enumerate(rows):
            armed = not pose.endswith("*")
            key = pose.rstrip("*")
            name = "player_%s_%s.png" % (key, side) if armed else "player_%s_noarme_%s.png" % (key, side)
            img = lookup[name]
            cx = 10 + (i % 6) * cell_w
            cy = 26 + (i // 6) * cell_h
            _cell(sheet, img, cx, cy, cell_w, cell_h, d, "%s %dx%d" % (key, img.width, img.height))
        sheet.save(os.path.join(SHEETS_DIR, "sheet_%s.png" % side))
    # armas
    sheet = Image.new("RGBA", (700, 420), (38, 34, 48, 255))
    d = ImageDraw.Draw(sheet)
    d.text((8, 6), "ARMAS", fill=(240, 240, 250, 255))
    for i, wn in enumerate(("weapon_rapier", "weapon_longsword", "weapon_dagger", "weapon_bow", "weapon_arrow")):
        img = lookup[wn + ".png"]
        _cell(sheet, img, 10, 26 + i * 74, 640, 70, d, wn)
    sheet.save(os.path.join(SHEETS_DIR, "sheet_weapons.png"))


def make_compare():
    """Viejo (repo principal) vs nuevo, lado a lado, P1 y P2 armados."""
    main_sprites = os.path.normpath(os.path.join(ROOT, "..", "Nidhogg 2.1", "art", "sprites"))
    poses = ARMED_POSES
    cell_w, cell_h = 240, 130
    sheet = Image.new("RGBA", (cell_w * 4 + 30, cell_h * ((len(poses) + 3) // 4) * 2 + 60), (24, 22, 30, 255))
    d = ImageDraw.Draw(sheet)
    d.text((8, 6), "Fila superior = ANTERIOR (IA pictorico) | fila inferior = REDISENO pixel art", fill=(240, 240, 250, 255))
    for i, pose in enumerate(poses):
        for side_i, side in enumerate(("p1", "p2")):
            name = "player_%s_%s.png" % (pose, side)
            old_path = os.path.join(main_sprites, name)
            new_path = os.path.join(SPRITES_DIR, name)
            col = (i % 4) * 2 + side_i
            base_cx = 10 + col * (cell_w // 2 + 5)
            block = 26 + (i // 4) * (cell_h * 2 + 14)
            for row, path in enumerate((old_path, new_path)):
                if not os.path.isfile(path):
                    continue
                img = Image.open(path).convert("RGBA")
                big = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
                sheet.alpha_composite(big, (base_cx + (cell_w // 2 + 5 - big.width) // 2, block + row * cell_h))
            d.text((base_cx, block + cell_h * 2 - 4), pose, fill=(200, 200, 210, 255))
    sheet.save(os.path.join(SHEETS_DIR, "compare_old_vs_new.png"))


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("all", "sprites"):
        made = generate_sprites()
        print("sprites generados: %d" % len(made))
    if what in ("all", "sheets", "compare"):
        if what == "compare":
            make_compare()
            print("comparativa en art_raw/redesign/compare_old_vs_new.png")
        else:
            made = generate_sprites()
            make_sheets(made)
            make_compare()
            print("hojas en art_raw/redesign/")


if __name__ == "__main__":
    main()
