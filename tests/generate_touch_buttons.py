"""Punto 1: genera las texturas de los botones tactiles (assets/ui/touch/).

Circulos semitransparentes con icono blanco y contorno oscuro, en version
normal y apretada. Se corre una sola vez: python tests/generate_touch_buttons.py
"""
from PIL import Image, ImageDraw, ImageFont

OUT = "assets/ui/touch/"
SS = 4  # supersampling para bordes suaves
FONT = "C:/Windows/Fonts/arialbd.ttf"

def base(size, pressed):
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    fill = (255, 214, 110, 150) if pressed else (20, 24, 40, 105)
    d.ellipse([6 * SS, 6 * SS, s - 6 * SS, s - 6 * SS], fill=fill,
              outline=(255, 255, 255, 215), width=7 * SS)
    return im, d, s

def poly(d, pts, s, outline=True):
    pts = [(x * s, y * s) for x, y in pts]
    if outline:
        d.line(pts + [pts[0]], fill=(10, 10, 20, 230), width=int(s * 0.045), joint="curve")
    d.polygon(pts, fill=(255, 255, 255, 240))

def text(d, s, label, y, size_frac):
    f = ImageFont.truetype(FONT, int(s * size_frac))
    w = d.textlength(label, font=f)
    d.text(((s - w) / 2, y * s), label, font=f, fill=(255, 255, 255, 245),
           stroke_width=int(s * 0.018), stroke_fill=(10, 10, 20, 230))

def arrow(direction):
    pts = [(0.30, 0.50), (0.55, 0.27), (0.55, 0.40), (0.72, 0.40),
           (0.72, 0.60), (0.55, 0.60), (0.55, 0.73)]
    if direction > 0:
        pts = [(1.0 - x, y) for x, y in pts]
    return pts

def paw(d, s):
    w = (255, 255, 255, 240)
    o = (10, 10, 20, 230)
    def blob(cx, cy, rx, ry):
        e = s * 0.02
        d.ellipse([(cx - rx) * s - e, (cy - ry) * s - e, (cx + rx) * s + e, (cy + ry) * s + e], fill=o)
        d.ellipse([(cx - rx) * s, (cy - ry) * s, (cx + rx) * s, (cy + ry) * s], fill=w)
    blob(0.50, 0.50, 0.15, 0.12)
    for cx, cy in ((0.33, 0.36), (0.44, 0.26), (0.56, 0.26), (0.67, 0.36)):
        blob(cx, cy, 0.06, 0.075)

def make(name, size, draw_fn):
    for pressed in (False, True):
        im, d, s = base(size, pressed)
        draw_fn(d, s)
        im = im.resize((size, size), Image.LANCZOS)
        im.save(OUT + name + ("_pressed" if pressed else "") + ".png")

make("left", 240, lambda d, s: poly(d, arrow(-1), s))
make("right", 240, lambda d, s: poly(d, arrow(1), s))
def jump(d, s):
    poly(d, [(0.50, 0.17), (0.73, 0.42), (0.59, 0.42), (0.59, 0.60), (0.41, 0.60), (0.41, 0.42), (0.27, 0.42)], s)
    text(d, s, "SALTAR", 0.64, 0.13)
make("jump", 300, jump)
def attack(d, s):
    paw(d, s)
    text(d, s, "ATACAR", 0.65, 0.13)
make("attack", 250, attack)
def pause(d, s):
    poly(d, [(0.34, 0.30), (0.45, 0.30), (0.45, 0.70), (0.34, 0.70)], s)
    poly(d, [(0.55, 0.30), (0.66, 0.30), (0.66, 0.70), (0.55, 0.70)], s)
make("pause", 140, pause)
def run(d, s):
    # Doble flecha ">>" (rapido) + CORRER.
    for dx in (-0.10, 0.08):
        poly(d, [(0.36 + dx, 0.22), (0.56 + dx, 0.40), (0.36 + dx, 0.58), (0.36 + dx, 0.47), (0.44 + dx, 0.40), (0.36 + dx, 0.33)], s)
    text(d, s, "CORRER", 0.62, 0.15)
make("run", 170, run)
