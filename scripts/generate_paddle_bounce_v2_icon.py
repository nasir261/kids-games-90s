"""Generates a new, distinct 1024x1024 icon for the standalone Paddle Bounce app
(previously reused the older racket+ball icon from the arcade app's Pong game)."""
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

top = (90, 40, 160)
bottom = (170, 80, 220)
for y in range(SIZE):
    t = y / SIZE
    r = round(top[0] + (bottom[0] - top[0]) * t)
    g = round(top[1] + (bottom[1] - top[1]) * t)
    b = round(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

# Court dashed centre line — confined to the gap between the two paddles only.
dash_h, gap_h = 40, 30
y = 280
while y < 760:
    draw.rectangle([497, y, 527, min(y + dash_h, 760)], fill=(255, 255, 255))
    y += dash_h + gap_h

# AI paddle (top, red).
draw.rounded_rectangle([332, 150, 692, 214], radius=28, fill=(230, 60, 70))
# Player paddle (bottom, bright yellow).
draw.rounded_rectangle([332, 810, 692, 874], radius=28, fill=(255, 235, 26))

# Ball with a clean comet-tail motion streak.
bx, by, br = 590, 500, 78
for i in range(3):
    off = (i + 1) * 40
    tail_r = br - (i + 1) * 18
    draw.ellipse([bx - off - tail_r, by - tail_r, bx - off + tail_r, by + tail_r],
                 fill=(255, 255, 255))
draw.ellipse([bx - br, by - br, bx + br, by + br], fill=(255, 255, 255))


img.save("/Users/nasir/Documents/kids-games-90s/scripts/standalone_icons/paddle_bounce_v2.png")
print("saved")
