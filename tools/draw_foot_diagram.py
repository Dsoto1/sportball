"""Top-down foot placement diagram for the six batting styles, drawn from
the game's own poses (tools/foot_diagram_data.gd). Right-handed batter,
pitcher at the top, catcher at the bottom, home plate to his right.
  godot --headless --path . -s res://tools/foot_diagram_data.gd | grep '^{' > feet.json
  python3 tools/draw_foot_diagram.py feet.json out.png"""
import json
import math
import sys
from PIL import Image, ImageDraw, ImageFont

PX = 260  # pixels per meter
W, H = 620, 700
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
POSES = [("stance", "STANCE", (120, 120, 130)), ("load", "LOAD", (40, 110, 220)),
         ("stride", "FOOT PLANT", (235, 130, 20)), ("contact", "CONTACT", (215, 40, 40)),
         ("finish", "FINISH", (40, 160, 70))]
NAMES = {"classic": "1. CLASSIC", "crouch": "2. CROUCH", "open": "3. OPEN",
         "leg_kick": "4. LEG KICK", "wrap": "5. BAT WRAP", "slap": "6. SLAP"}
# Body space (m) of a right-handed batter at his spot: forward = toward the
# plate, right = toward the catcher. The plate's middle is 0.85 m forward
# and 0.15 m toward the pitcher (BATTER_SPOT in match_view.gd).
PLATE_F, PLATE_R = 0.91, -0.49
FOOT_LEN, FOOT_W = 0.27, 0.10
ORIGIN = (250, 380)  # where the batter's spot is drawn


def to_px(right, fwd):
    # Screen: forward (toward the plate) to the right, pitcher up.
    return ORIGIN[0] + fwd * PX, ORIGIN[1] + right * PX


def foot(draw, right, fwd, yaw_deg, color, lifted, label=None):
    # Toes point along +forward, turned yaw degrees toward the pitcher.
    yaw = math.radians(yaw_deg)
    d = (-math.sin(yaw), math.cos(yaw))  # (right, fwd)
    n = (d[1], -d[0])
    pts = []
    for s, t in [(-0.5, -0.4), (0.5, -0.4), (0.55, 0.3), (0, 0.5), (-0.55, 0.3)]:
        r = right + d[0] * FOOT_LEN * t + n[0] * FOOT_W * s
        f = fwd + d[1] * FOOT_LEN * t + n[1] * FOOT_W * s
        pts.append(to_px(r, f))
    if lifted:
        draw.line(pts + [pts[0]], fill=color, width=2)
    else:
        draw.polygon(pts, fill=color + (150,), outline=color)


def panel(style, poses, font, bold):
    img = Image.new("RGBA", (W, H), (246, 246, 242, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text((16, 12), NAMES[style], fill=(30, 30, 40), font=bold)
    # Batter's box: 4 x 6 ft, its inner line 6 in off the plate's edge.
    inner = PLATE_F - 0.216 - 0.152
    box = [to_px(PLATE_R - 0.915, inner - 1.22), to_px(PLATE_R + 0.915, inner)]
    draw.rectangle(box, outline=(160, 160, 160), width=3)
    # Home plate: 17 in across, the point toward the catcher.
    plate = [(PLATE_R - 0.216, PLATE_F - 0.216), (PLATE_R - 0.216, PLATE_F + 0.216),
             (PLATE_R, PLATE_F + 0.216), (PLATE_R + 0.216, PLATE_F), (PLATE_R, PLATE_F - 0.216)]
    draw.polygon([to_px(r, f) for r, f in plate], fill=(255, 255, 255), outline=(90, 90, 90))
    draw.text(to_px(PLATE_R - 0.05, PLATE_F - 0.12), "PLATE", fill=(90, 90, 90), font=font)
    # Pitcher direction.
    ax, ay = to_px(-1.1, 0.0)
    draw.line([(ax, ay + 40), (ax, ay)], fill=(60, 60, 60), width=3)
    draw.polygon([(ax - 8, ay + 6), (ax + 8, ay + 6), (ax, ay - 8)], fill=(60, 60, 60))
    draw.text((ax + 12, ay - 4), "to the pitcher", fill=(60, 60, 60), font=font)
    draw.text(to_px(0.95, 0.55), "catcher", fill=(60, 60, 60), font=font)
    # Lead-foot travel: stance -> load -> plant.
    path = [to_px(poses[k]["foot_l"][0], poses[k]["foot_l"][2]) for k in ("stance", "load", "stride")]
    draw.line(path, fill=(60, 60, 60, 160), width=2)
    for key, name, color in POSES:
        p = poses[key]
        for side in ("l", "r"):
            r, up, f = p["foot_" + side]
            # A lifted foot (heel up, or a leg kick) is drawn as an outline.
            foot(draw, r, f, p["toe_" + side], color, up > 0.135)
    # Legend.
    y = H - 30 - 20 * len(POSES)
    for key, name, color in POSES:
        draw.rectangle([16, y + 3, 30, y + 15], fill=color)
        draw.text((38, y), name, fill=(30, 30, 40), font=font)
        y += 20
    draw.text((16, y + 2), "outline = foot off the ground or up on the toe", fill=(90, 90, 90), font=font)
    return img


def main():
    data = json.load(open(sys.argv[1]))
    font = ImageFont.truetype(FONT, 15)
    bold = ImageFont.truetype(BOLD, 24)
    order = ["classic", "crouch", "open", "leg_kick", "wrap", "slap"]
    sheet = Image.new("RGBA", (W * 3, H * 2), (255, 255, 255, 255))
    for i, style in enumerate(order):
        sheet.paste(panel(style, data[style], font, bold), ((i % 3) * W, (i // 3) * H))
    sheet.convert("RGB").save(sys.argv[2])


main()
