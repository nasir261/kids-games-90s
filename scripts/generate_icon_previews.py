"""Generates several alternative 1024x1024 kid-friendly app icon concepts."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
OUT_DIR = "/Users/nasir/Documents/kids-games-90s/scripts/icon_previews"

import os
os.makedirs(OUT_DIR, exist_ok=True)

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

# ---------- Concept A: Smiling star mascot ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (255, 154, 60), (255, 209, 92))
draw.polygon(star_pts(512, 512, 420, 175, rot=0), fill=(255, 221, 60))
draw.polygon(star_pts(512, 512, 420, 175, rot=0), outline=(255, 140, 20), width=14)
eye_r = 36
draw.ellipse([420 - eye_r, 470 - eye_r, 420 + eye_r, 470 + eye_r], fill=(60, 30, 10))
draw.ellipse([600 - eye_r, 470 - eye_r, 600 + eye_r, 470 + eye_r], fill=(60, 30, 10))
draw.ellipse([420 - 10 + 8, 470 - 10 - 8, 420 + 10 + 8, 470 + 10 - 8], fill=(255, 255, 255))
draw.ellipse([600 - 10 + 8, 470 - 10 - 8, 600 + 10 + 8, 470 + 10 - 8], fill=(255, 255, 255))
draw.pieslice([430, 520, 600, 640], 15, 165, fill=(60, 30, 10))
draw.pieslice([452, 520, 578, 610], 20, 160, fill=(255, 255, 255))
cheek = (255, 130, 110)
draw.ellipse([365, 545, 425, 585], fill=cheek)
draw.ellipse([600, 545, 660, 585], fill=cheek)
img.save(f"{OUT_DIR}/A_smiling_star.png")

# ---------- Concept B: Rainbow game-collection badge ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (86, 60, 200), (255, 92, 158))
draw.ellipse([132, 132, 892, 892], fill=(255, 255, 255))
draw.ellipse([172, 172, 852, 852], fill=(60, 40, 140))
# Small game glyphs arranged in a circle: joystick ball, brick, star, paddle.
glyphs = [
    ((512, 300), "\u25CF", (0, 210, 255)),   # ball
]
draw.ellipse([472, 260, 552, 340], fill=(0, 210, 255))  # ball
draw.rounded_rectangle([420, 470, 604, 560], radius=16, fill=(255, 90, 90))  # brick/paddle
draw.polygon(star_pts(512, 720, 95, 40, rot=0), fill=(255, 221, 60))  # star
draw.rounded_rectangle([300, 460, 360, 580], radius=14, fill=(120, 255, 140))  # side paddle
draw.rounded_rectangle([664, 460, 724, 580], radius=14, fill=(120, 255, 140))
img.save(f"{OUT_DIR}/B_rainbow_badge.png")

# ---------- Concept C: Happy robot mascot ----------
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)
gradient_bg(draw, (60, 200, 220), (110, 235, 170))
# Head
draw.rounded_rectangle([287, 300, 737, 680], radius=90, fill=(255, 255, 255))
draw.rounded_rectangle([287, 300, 737, 680], radius=90, outline=(60, 150, 170), width=14)
# Antenna
draw.line([(512, 300), (512, 220)], fill=(60, 150, 170), width=16)
draw.ellipse([482, 160, 542, 220], fill=(255, 221, 60))
# Eyes (screen)
draw.rounded_rectangle([355, 400, 669, 520], radius=40, fill=(40, 40, 60))
eye_r = 34
draw.ellipse([440 - eye_r, 460 - eye_r, 440 + eye_r, 460 + eye_r], fill=(120, 240, 255))
draw.ellipse([584 - eye_r, 460 - eye_r, 584 + eye_r, 460 + eye_r], fill=(120, 240, 255))
# Smile
draw.arc([420, 470, 604, 600], start=20, end=160, fill=(120, 240, 255), width=14)
# Cheeks
draw.ellipse([320, 560, 380, 600], fill=(255, 170, 170))
draw.ellipse([644, 560, 704, 600], fill=(255, 170, 170))
img.save(f"{OUT_DIR}/C_happy_robot.png")

print("saved A, B, C")
