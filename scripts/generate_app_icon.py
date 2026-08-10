"""Generates a 1024x1024 flat-design table tennis (Pong) app icon."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Background: vertical purple gradient, matching the app's Pong accent color.
top = (60, 20, 110)
bottom = (18, 6, 36)
for y in range(SIZE):
    t = y / SIZE
    r = round(top[0] + (bottom[0] - top[0]) * t)
    g = round(top[1] + (bottom[1] - top[1]) * t)
    b = round(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

# Center dashed net line, echoing the in-game Pong court.
dash_len, gap_len, dash_w = 46, 34, 14
x_mid = SIZE // 2
y = 60
while y < SIZE - 60:
    draw.line([(x_mid, y), (x_mid, min(y + dash_len, SIZE - 60))],
               fill=(255, 255, 255, 255), width=dash_w)
    y += dash_len + gap_len

def rotated_rect(cx, cy, w, h, angle_deg, fill, outline=None, outline_w=0):
    angle = math.radians(angle_deg)
    hw, hh = w / 2, h / 2
    corners = [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)]
    pts = []
    for x, y in corners:
        rx = x * math.cos(angle) - y * math.sin(angle)
        ry = x * math.sin(angle) + y * math.cos(angle)
        pts.append((cx + rx, cy + ry))
    draw.polygon(pts, fill=fill, outline=outline, width=outline_w)

# --- Table tennis racket (paddle), angled bottom-left to top-right ---
handle_cx, handle_cy = 430, 700
rotated_rect(handle_cx, handle_cy, 70, 230, -35, fill=(120, 72, 40))
rotated_rect(handle_cx, handle_cy, 70, 60, -35, fill=(90, 52, 28))

paddle_cx, paddle_cy = 560, 500
paddle_r = 195
# Paddle rim (dark red) then rubber face (cyan, matching in-game player paddle color).
draw.ellipse(
    [paddle_cx - paddle_r, paddle_cy - paddle_r, paddle_cx + paddle_r, paddle_cy + paddle_r],
    fill=(178, 34, 34),
)
inner_r = paddle_r - 24
draw.ellipse(
    [paddle_cx - inner_r, paddle_cy - inner_r, paddle_cx + inner_r, paddle_cy + inner_r],
    fill=(0, 200, 210),
)
# Subtle highlight for depth.
hl_r = 70
draw.ellipse(
    [paddle_cx - 70 - hl_r // 2, paddle_cy - 90 - hl_r // 2,
     paddle_cx - 70 + hl_r // 2, paddle_cy - 90 + hl_r // 2],
    fill=(120, 230, 235),
)

# --- Ball, upper right with motion streaks ---
ball_cx, ball_cy, ball_r = 790, 300, 68
for i, alpha_w in enumerate([26, 18, 10]):
    offset = (i + 1) * 55
    draw.line(
        [(ball_cx - offset - 90, ball_cy - offset + 30), (ball_cx - offset, ball_cy + 10)],
        fill=(255, 255, 255), width=alpha_w,
    )
draw.ellipse(
    [ball_cx - ball_r, ball_cy - ball_r, ball_cx + ball_r, ball_cy + ball_r],
    fill=(255, 250, 235),
)
draw.ellipse(
    [ball_cx - 22, ball_cy - 30, ball_cx + 6, ball_cy - 2],
    fill=(255, 255, 255),
)

img.save("/Users/nasir/Documents/kids-games-90s/KidsHappyClassicGames/KidsHappyClassicGames/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
print("saved")
