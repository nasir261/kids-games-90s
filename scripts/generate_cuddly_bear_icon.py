"""Generates a 1024x1024 very happy, cuddly baby bear app icon (with hug pose + heart)."""
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Warm, soft pink-to-cream gradient background.
top = (255, 200, 210)
bottom = (255, 236, 214)
for y in range(SIZE):
    t = y / SIZE
    r = round(top[0] + (bottom[0] - top[0]) * t)
    g = round(top[1] + (bottom[1] - top[1]) * t)
    b = round(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

fur = (176, 124, 84)
fur_dark = (140, 92, 58)
inner_ear = (255, 205, 180)
snout = (255, 240, 220)

def heart(cx, cy, s, color):
    r = s * 0.5
    draw.ellipse([cx - s, cy - s, cx, cy], fill=color)
    draw.ellipse([cx, cy - s, cx + s, cy], fill=color)
    draw.polygon([(cx - s, cy - s * 0.15), (cx + s, cy - s * 0.15), (cx, cy + s * 1.3)], fill=color)

# Little floating hearts for the "cuddly / lovable" vibe.
heart(180, 220, 34, (255, 120, 140))
heart(860, 250, 26, (255, 150, 165))
heart(870, 700, 30, (255, 130, 150))

# --- Body (small round belly with stubby arms wrapped in a hug) ---
body_cy = 860
draw.ellipse([352, 760, 672, 1040], fill=fur)
draw.ellipse([392, 800, 632, 1010], fill=snout)  # belly patch
# Hugging arms crossed in front.
draw.ellipse([300, 800, 470, 930], fill=fur)
draw.ellipse([554, 800, 724, 930], fill=fur)
draw.ellipse([370, 850, 500, 950], fill=fur)
draw.ellipse([524, 850, 654, 950], fill=fur)

# --- Ears (behind head) ---
draw.ellipse([230, 150, 420, 340], fill=fur)
draw.ellipse([604, 150, 794, 340], fill=fur)
draw.ellipse([270, 190, 380, 300], fill=inner_ear)
draw.ellipse([644, 190, 754, 300], fill=inner_ear)

# --- Head ---
draw.ellipse([222, 260, 802, 840], fill=fur)

# Snout patch.
draw.ellipse([378, 540, 646, 780], fill=snout)

# --- Sparkly happy eyes (upward crescent shape, eyes-closed-with-joy style is too subtle for icon;
# use big round sparkling eyes instead for clear "happy" read at small sizes). ---
eye_r = 42
for ex in (398, 626):
    draw.ellipse([ex - eye_r, 470 - eye_r, ex + eye_r, 470 + eye_r], fill=(50, 30, 20))
    draw.ellipse([ex, 470 - 30, ex + 28, 470 - 2], fill=(255, 255, 255))
    draw.ellipse([ex - 18, 470 + 8, ex - 4, 470 + 22], fill=(255, 255, 255))

# Rosy round cheeks (bigger + brighter for extra joy).
cheek = (255, 140, 145)
draw.ellipse([290, 600, 400, 680], fill=cheek)
draw.ellipse([624, 600, 734, 680], fill=cheek)

# Nose.
draw.ellipse([470, 600, 554, 664], fill=fur_dark)
draw.line([(512, 632), (512, 655)], fill=fur_dark, width=8)

# Big wide-open happy grin.
draw.pieslice([430, 630, 594, 760], 10, 170, fill=fur_dark)
draw.pieslice([452, 630, 572, 730], 15, 165, fill=(255, 140, 150))

img.save("/Users/nasir/Documents/kids-games-90s/scripts/icon_previews/E_cuddly_bear.png")
print("saved")
