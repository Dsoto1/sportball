"""Stitches stadium_tour.gd's thirteen "wall" frames into one strip, pole to
pole (left to right), and optionally sets it under the park's sheet strip.
  python3 tools/wall_strip.py <shots_dir> <park_id> out.png [sheet.jpg]"""
import sys
from PIL import Image

def main() -> None:
    d, park, out = sys.argv[1], sys.argv[2], sys.argv[3]
    frames = [Image.open(f"{d}/{park}_{i}.png").convert("RGB") for i in range(13)]
    w, h = frames[0].size
    strip = Image.new("RGB", (w * 13, h))
    for i, f in enumerate(frames):
        strip.paste(f, (i * w, 0))
    strip = strip.resize((1800, int(h * 1800 / (w * 13))))
    if len(sys.argv) > 4:
        ref = Image.open(sys.argv[4]).convert("RGB")
        ref = ref.resize((1125, 750)).crop((55, 683, 712, 716)).resize((1800, 90))
        both = Image.new("RGB", (1800, 90 + strip.height + 6), (16, 16, 20))
        both.paste(ref, (0, 0))
        both.paste(strip, (0, 96))
        strip = both
    strip.save(out)

main()
