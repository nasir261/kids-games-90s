"""Generates a 1024x1024 happy, kid-friendly game-controller mascot app icon."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Background: cheerful sky-blue to sunny-yellow diagonal-ish gradient.
top = (79, 172, 254)
bottom = (255, 209, 92)
for y in range(SIZE):
    t = y / SIZE
    r = round(top[0] + (bottom[0] - top[0]) * t)
    g = round(top[1] + (bottom[1] - top[1]) * t)
    b = round(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

def star(cx, cy, r_outer, r_inner, color, rot=0):
    pts = []
    for i in range(10):
        ang = math.radians(i * 36 - 90 + rot)
        r = r_outer if i % 2 == 0 else r_inner
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(pts, fill=color)

# Sparkle stars scattered behind the mascot.
star(150, 190, 46, 20, (255, 255, 255), rot=8)
star(870, 210, 34, 15, (255, 255, 255), rot=-12)
star(880, 760, 40, 18, (255, 255, 255), rot=20)
star(140, 800, 30, 13, (255, 255, 255), rot=-5)

# --- Game controller body (rounded capsule) ---
body_color = (255, 90, 120)
body_shadow = (214, 62, 92)
cx, cy = 512, 540
body_w, body_h = 620, 340

def rounded_capsule(cx, cy, w, h, color):
    r = h / 2
    draw.rectangle([cx - w / 2 + r, cy - h / 2, cx + w / 2 - r, cy + h / 2], fill=color)
    draw.pieslice([cx - w / 2, cy - r, cx - w / 2 + 2 * r, cy + r], 90, 270, fill=color)
    draw.pieslice([cx + w / 2 - 2 * r, cy - r, cx + w / 2, cy + r], -90, 90, fill=color)

# Subtle drop shadow for depth.
rounded_capsule(cx, cy + 22, body_w, body_h, body_shadow)
rounded_capsule(cx, cy, body_w, body_h, body_color)

# Grips (two lower bumps at each end of the controller).
grip_r = 130
draw.ellipse([cx - body_w / 2 - 10, cy + 60, cx - body_w / 2 - 10 + grip_r * 2, cy + 60 + grip_r * 2], fill=body_color)
draw.ellipse([cx + body_w / 2 + 10 - grip_r * 2, cy + 60, cx + body_w / 2 + 10, cy + 60 + grip_r * 2], fill=body_color)

# --- D-pad (left) ---
dpad_cx, dpad_cy, dpad_arm, dpad_thick = 340, 540, 90, 46
draw.rounded_rectangle(
    [dpad_cx - dpad_thick / 2, dpad_cy - dpad_arm, dpad_cx + dpad_thick / 2, dpad_cy + dpad_arm],
    radius=12, fill=(60, 30, 40),
)
draw.rounded_rectangle(
    [dpad_cx - dpad_arm, dpad_cy - dpad_thick / 2, dpad_cx + dpad_arm, dpad_cy + dpad_thick / 2],
    radius=12, fill=(60, 30, 40),
)

# --- Face buttons (right) ---
btn_r = 40
btn_color = (255, 240, 150)
offsets = [(90, -70), (150, -10), (30, -10), (90, 50)]
for dx, dy in offsets:
    bx, by = 700 + dx, 500 + dy
    draw.ellipse([bx - btn_r, by - btn_r, bx + btn_r, by + btn_r], fill=btn_color)

# --- Happy cartoon face on the controller body ---
eye_r = 34
eye_y = 470
draw.ellipse([440 - eye_r, eye_y - eye_r, 440 + eye_r, eye_y + eye_r], fill=(40, 20, 30))
draw.ellipse([584 - eye_r, eye_y - eye_r, 584 + eye_r, eye_y + eye_r], fill=(40, 20, 30))
# Eye highlights.
hl_r = 11
draw.ellipse([440 - hl_r + 10, eye_y - hl_r - 10, 440 + hl_r + 10, eye_y + hl_r - 10], fill=(255, 255, 255))
draw.ellipse([584 - hl_r + 10, eye_y - hl_r - 10, 584 + hl_r + 10, eye_y + hl_r - 10], fill=(255, 255, 255))

# Big open smile.
smile_box = [440, 500, 584, 610]
draw.pieslice(smile_box, 15, 165, fill=(40, 20, 30))
draw.pieslice([460, 500, 564, 585], 20, 160, fill=(255, 255, 255))

img.save("/Users/nasir/Documents/kids-games-90s/KidsHappyClassicGames/KidsHappyClassicGames/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
print("saved")
