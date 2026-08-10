"""Generates a 1024x1024 cute baby bear app icon."""
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Soft pastel peach-to-pink gradient background.
top = (255, 214, 170)
bottom = (255, 178, 190)
for y in range(SIZE):
    t = y / SIZE
    r = round(top[0] + (bottom[0] - top[0]) * t)
    g = round(top[1] + (bottom[1] - top[1]) * t)
    b = round(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

fur = (168, 116, 78)
fur_dark = (140, 92, 58)
inner_ear = (255, 200, 175)
snout = (255, 236, 214)

# Ears (behind head).
draw.ellipse([230, 150, 420, 340], fill=fur)
draw.ellipse([604, 150, 794, 340], fill=fur)
draw.ellipse([270, 190, 380, 300], fill=inner_ear)
draw.ellipse([644, 190, 754, 300], fill=inner_ear)

# Head.
draw.ellipse([222, 270, 802, 850], fill=fur)

# Snout patch.
draw.ellipse([380, 560, 644, 790], fill=snout)

# Eyes.
eye_r = 38
draw.ellipse([400 - eye_r, 480 - eye_r, 400 + eye_r, 480 + eye_r], fill=(50, 30, 20))
draw.ellipse([624 - eye_r, 480 - eye_r, 624 + eye_r, 480 + eye_r], fill=(50, 30, 20))
hl_r = 12
draw.ellipse([400 - hl_r + 12, 480 - hl_r - 12, 400 + hl_r + 12, 480 + hl_r - 12], fill=(255, 255, 255))
draw.ellipse([624 - hl_r + 12, 480 - hl_r - 12, 624 + hl_r + 12, 480 + hl_r - 12], fill=(255, 255, 255))

# Rosy cheeks.
cheek = (255, 150, 150)
draw.ellipse([300, 610, 400, 680], fill=cheek)
draw.ellipse([624, 610, 724, 680], fill=cheek)

# Nose.
draw.ellipse([472, 610, 552, 670], fill=fur_dark)

# Mouth (small smile lines).
draw.arc([462, 650, 512, 700], start=20, end=160, fill=fur_dark, width=10)
draw.arc([512, 650, 562, 700], start=20, end=160, fill=fur_dark, width=10)
draw.line([(512, 670), (512, 690)], fill=fur_dark, width=8)

img.save("/Users/nasir/Documents/kids-games-90s/scripts/icon_previews/D_baby_bear.png")
print("saved")
