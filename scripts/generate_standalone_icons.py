"""Generates 1024x1024 app icons for the 5 standalone single-game apps
(Paddle Bounce reuses the existing racket+ball icon from the arcade app)."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
OUT = "/Users/nasir/Documents/kids-games-90s/scripts/standalone_icons"
import os
os.makedirs(OUT, exist_ok=True)


def gradient_bg(draw, top, bottom):
    for y in range(SIZE):
        t = y / SIZE
        r = round(top[0] + (bottom[0] - top[0]) * t)
        g = round(top[1] + (bottom[1] - top[1]) * t)
        b = round(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))


def star_pts(cx, cy, r_outer, r_inner, rot=0, points=5):
    pts = []
    n = points * 2
    for i in range(n):
        ang = math.radians(i * (360 / n) - 90 + rot)
        r = r_outer if i % 2 == 0 else r_inner
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


# ---------- Apple Muncher (green) ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (30, 140, 60), (90, 200, 110))
# Curled snake body made of overlapping rounded segments.
segs = [(300, 620), (360, 520), (460, 470), (570, 500), (640, 590), (620, 700), (520, 740)]
for i, (x, y) in enumerate(segs):
    r = 78 if i < len(segs) - 1 else 68
    color = (255, 221, 60) if i == 0 else (20, 110, 45)
    draw.ellipse([x - r, y - r, x + r, y + r], fill=color)
# Eyes on head segment.
hx, hy = segs[0]
draw.ellipse([hx - 34, hy - 20, hx - 14, hy], fill=(30, 20, 10))
draw.ellipse([hx - 6, hy - 20, hx + 14, hy], fill=(30, 20, 10))
# Apple.
ax, ay, ar = 740, 340, 92
draw.ellipse([ax - ar, ay - ar + 10, ax + ar, ay + ar + 10], fill=(220, 40, 45))
draw.ellipse([ax - ar + 18, ay - ar + 22, ax - 10, ay + 10], fill=(255, 255, 255, 60))
draw.line([(ax, ay - ar + 6), (ax + 18, ay - ar - 34)], fill=(90, 60, 30), width=12)
draw.ellipse([ax + 6, ay - ar - 44, ax + 56, ay - ar - 10], fill=(60, 160, 70))
img.save(f"{OUT}/apple_muncher.png")

# ---------- Brick Blast (red) ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (170, 30, 40), (230, 90, 60))
brick_colors = [(255, 70, 70), (255, 150, 50), (255, 230, 60), (90, 210, 110)]
bw, bh, gap = 190, 90, 14
top = 250
for row, color in enumerate(brick_colors):
    y = top + row * (bh + gap)
    offset = 60 if row % 2 else 0
    for col in range(4):
        x = 90 + offset + col * (bw + gap)
        if x + bw > SIZE - 60:
            continue
        draw.rounded_rectangle([x, y, x + bw, y + bh], radius=14, fill=color)
draw.ellipse([452, 700, 572, 820], fill=(255, 255, 255))
img.save(f"{OUT}/brick_blast.png")

# ---------- Mole Bash (orange/brown) ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (200, 120, 20), (255, 180, 60))
# Dirt hole.
draw.ellipse([220, 620, 804, 860], fill=(90, 55, 25))
draw.ellipse([260, 600, 764, 760], fill=(50, 30, 15))
# Mole peeking out.
draw.ellipse([362, 380, 662, 660], fill=(120, 85, 60))
draw.ellipse([400, 460, 470, 530], fill=(30, 20, 15))
draw.ellipse([554, 460, 624, 530], fill=(30, 20, 15))
draw.ellipse([470, 540, 554, 610], fill=(80, 55, 40))
draw.ellipse([300, 420, 380, 490], fill=(120, 85, 60))
draw.ellipse([644, 420, 724, 490], fill=(120, 85, 60))
# Mallet.
draw.rounded_rectangle([680, 160, 730, 420], radius=18, fill=(140, 90, 50))
draw.rounded_rectangle([620, 120, 860, 240], radius=24, fill=(200, 60, 50))
img.save(f"{OUT}/mole_bash.png")

# ---------- Memory Match (blue/purple) ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (50, 30, 130), (110, 70, 210))
card_w, card_h = 300, 400
draw.rounded_rectangle([160, 300, 160 + card_w, 300 + card_h], radius=28, fill=(255, 255, 255))
draw.rounded_rectangle([564, 300, 564 + card_w, 300 + card_h], radius=28, fill=(255, 255, 255))
# Matching paw prints.
def paw(cx, cy, scale, color):
    draw.ellipse([cx - 60*scale, cy - 20*scale, cx + 60*scale, cy + 100*scale], fill=color)
    for dx, dy in [(-55, -70), (-18, -95), (18, -95), (55, -70)]:
        draw.ellipse([cx+dx*scale-26*scale, cy+dy*scale-26*scale, cx+dx*scale+26*scale, cy+dy*scale+26*scale], fill=color)

paw(310, 500, 1.0, (255, 140, 60))
paw(714, 500, 1.0, (255, 140, 60))
img.save(f"{OUT}/memory_match.png")

# ---------- Bee Bop (honey gold) ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (255, 214, 100), (255, 170, 40))
# Wings.
draw.ellipse([340, 260, 560, 440], fill=(255, 255, 255))
draw.ellipse([560, 260, 780, 440], fill=(255, 255, 255))
# Body stripes.
draw.rounded_rectangle([392, 380, 712, 700], radius=140, fill=(40, 30, 15))
for i, y in enumerate(range(430, 680, 90)):
    if i % 2 == 0:
        draw.rectangle([392, y, 712, y + 60], fill=(255, 210, 40))
draw.rounded_rectangle([392, 380, 712, 700], radius=140, outline=(40, 30, 15), width=0)
# Face.
draw.ellipse([440, 400, 500, 460], fill=(255, 255, 255))
draw.ellipse([604, 400, 664, 460], fill=(255, 255, 255))
draw.ellipse([458, 418, 482, 442], fill=(20, 15, 10))
draw.ellipse([622, 418, 646, 442], fill=(20, 15, 10))
draw.arc([490, 430, 614, 500], start=20, end=160, fill=(20, 15, 10), width=10)
# Antennae.
draw.line([(470, 380), (430, 300)], fill=(40, 30, 15), width=10)
draw.line([(634, 380), (674, 300)], fill=(40, 30, 15), width=10)
draw.ellipse([410, 280, 450, 320], fill=(40, 30, 15))
draw.ellipse([654, 280, 694, 320], fill=(40, 30, 15))
img.save(f"{OUT}/bee_bop.png")

print("saved all 5 icons")
