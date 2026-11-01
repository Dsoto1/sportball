# Swing mechanics references

The batting poses follow Dr. Larry VanSuch, *Baseball Swing Mechanics*
(2013), supplied by the owner. The book's copyright forbids reproducing
it, so its photos are not in the repo: ask the owner for the PDF. The
figures used (right-handed hitter):

| Book figure (page) | Phase / view |
|---|---|
| 1-1, 1-2 (p. 2-3) | stance: hands at shoulder height, 10-12 in in front |
| 2-14a / 2-15a (p. 11) | stance from across the plate / from behind |
| 2-14c / 2-15c (p. 11), 3-3 (p. 31) | top of the load, bat cocked toward the pitcher |
| 2-11 (p. 9) | back elbow lifted (abducted) at the load |
| 4-38 (p. 53) | back elbow tucked in the "L" |
| 4-43 (p. 56), 4-49 (p. 59) | contact: front arm straight, back elbow bent, wrists square |
| 5-1a/b, 5-6a/b (p. 62, 65) | contact and finish from the pitcher's side |

Check with `tools/stance_probe.gd` (joint positions and elbow angles per
phase) and `tools/batter_closeup.gd ... swing <style> chest|rear`.
