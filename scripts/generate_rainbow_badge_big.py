"""Generates a bigger version of the rainbow game-collection badge icon."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)


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


gradient_bg(draw, (86, 60, 200), (255, 92, 158))

# Bigger badge: smaller margin so the circle fills more of the canvas.
draw.ellipse([56, 56, 968, 968], fill=(255, 255, 255))
draw.ellipse([100, 100, 924, 924], fill=(60, 40, 140))

# Glyphs scaled up ~20% and re-centered to match the bigger badge.
draw.ellipse([446, 210, 578, 342], fill=(0, 210, 255))                       # ball
draw.rounded_rectangle([378, 464, 646, 574], radius=20, fill=(255, 90, 90))  # brick/paddle
draw.polygon(star_pts(512, 758, 118, 50, rot=0), fill=(255, 221, 60))        # star
draw.rounded_rectangle([230, 452, 302, 588], radius=18, fill=(120, 255, 140))  # side paddle
draw.rounded_rectangle([722, 452, 794, 588], radius=18, fill=(120, 255, 140))

img.save("/Users/nasir/Documents/kids-games-90s/scripts/icon_previews/B_rainbow_badge_big.png")
print("saved")
