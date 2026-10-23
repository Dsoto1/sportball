"""Measure and draw swings recorded by tools/swing_path.gd, the way Baseball
Savant's bat tracking does (sweet spot, about 6 in from the barrel's end):

- swing path tilt: the angle of the plane the sweet spot travels in over the
  last 40 ms before contact, from horizontal;
- attack angle: the sweet spot's direction at contact, up from horizontal;
- attack direction: its direction at contact across the field (negative =
  toward the pull side, as Savant signs it);
- contact point: inches in front of the plate's front edge, and in front of
  the batter (toward the pitcher).

Draws each swing three ways (from behind the catcher, from the side, from
above), the last 40 ms before contact in bold, contact marked, beside the
target numbers (the hitter's own profile, or Savant's league range).

  python3 tools/swing_path_plot.py out.png swing1.json [swing2.json ...]"""
import json
import math
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

M_TO_IN = 39.3701
WINDOW = 0.040
# Savant's league (2025 bat tracking leaderboard, 207 qualified hitters).
LEAGUE = {"tilt": (32.5, 22.7, 44.5), "attack_angle": (10.2, 1.1, 20.4),
          "attack_direction": (-2.0, -16.1, 10.4), "contact_vs_plate": (3.1, -8.3, 22.5),
          "contact_vs_batter": (31.0, 20.1, 38.9)}


def measure(d: dict) -> dict:
    t = np.array([s["t"] for s in d["samples"]])
    p = np.array([s["sweet"] for s in d["samples"]])
    side = -1.0 if d["bats_left"] else 1.0
    tc = d["contact_t"]
    # Position and velocity at contact (central difference on the samples).
    i = int(np.argmin(np.abs(t - tc)))
    i = max(1, min(i, len(t) - 2))
    contact = p[i]
    v = (p[i + 1] - p[i - 1]) / (t[i + 1] - t[i - 1])
    horiz = math.hypot(v[0], v[2])
    attack_angle = math.degrees(math.atan2(v[1], horiz))
    # Toward the pitcher is -z; the pull side is -x for a righty (third
    # base), +x for a lefty. Negative = pull, as Savant.
    attack_direction = math.degrees(math.atan2(v[0] * side, -v[2]))
    # Tilt: best-fit plane through the window's points.
    w = (t >= tc - WINDOW) & (t <= tc + 1e-6)
    pts = p[w]
    tilt = float("nan")
    if len(pts) >= 3:
        c = pts - pts.mean(axis=0)
        normal = np.linalg.svd(c)[2][2]
        tilt = math.degrees(math.acos(min(1.0, abs(normal[1]))))
    batter = np.array(d["batter"])
    return {
        "tilt": tilt,
        "attack_angle": attack_angle,
        "attack_direction": attack_direction,
        "contact_vs_plate": (d["plate_front_z"] - contact[2]) * M_TO_IN,
        "contact_vs_batter": (batter[2] - contact[2]) * M_TO_IN,
        "sweet_speed_mph": float(np.linalg.norm(v)) * 2.23694,
        "contact": contact, "t": t, "p": p, "window": w, "i": i,
    }


def target(d: dict) -> dict:
    prof = d.get("profile") or {}
    out = {}
    if "tilt" in prof:
        out["tilt"] = prof["tilt"]
    if "attack_lift" in prof:
        out["attack_angle"] = prof["attack_lift"]
    if "attack_yaw" in prof:
        # attack_yaw: + toward the opposite field.
        out["attack_direction"] = prof["attack_yaw"]
    return out


def main() -> None:
    out_png = sys.argv[1]
    runs = [json.load(open(f)) for f in sys.argv[2:]]
    fig, axes = plt.subplots(len(runs), 4, figsize=(18, 4.2 * len(runs)), squeeze=False)
    for row, d in zip(axes, runs):
        m = measure(d)
        tg = target(d)
        p, w, i = m["p"], m["window"], m["i"]
        side = -1.0 if d["bats_left"] else 1.0
        views = [("From behind the catcher", 0, 1, "x (m, + first base)", "height (m)", False),
                 ("From the side (pitcher to the left)", 2, 1, "z (m, - toward pitcher)", "height (m)", True),
                 ("From above", 0, 2, "x (m)", "z (m, - toward pitcher)", False)]
        for ax, (title, a, b, xl, yl, flip) in zip(row[:3], views):
            ax.plot(p[:, a], p[:, b], color="0.75", lw=1.2)
            ax.plot(p[w][:, a], p[w][:, b], color="tab:orange", lw=3, label="last 40 ms")
            ax.plot(p[i, a], p[i, b], "o", color="tab:red", ms=8, label="contact")
            ax.plot([-0.2159, 0.2159], [0.0, 0.0] if b == 1 else [-0.2159, -0.2159], color="k", lw=4) if a == 0 else None
            if a == 2:
                ax.axvline(-0.2159, color="k", lw=1, ls="--")
            if b == 2:
                ax.axhline(-0.2159, color="k", lw=1, ls="--")
            ax.set_title(title)
            ax.set_xlabel(xl)
            ax.set_ylabel(yl)
            ax.set_aspect("equal", adjustable="datalim")
            if flip:
                ax.invert_xaxis()
            ax.grid(alpha=0.3)
        row[0].legend(loc="upper left", fontsize=8)
        txt = ["%s, %s" % (d["style"], "bats left" if d["bats_left"] else "bats right"), ""]
        for key, label, unit in [("tilt", "Swing path tilt", "deg"), ("attack_angle", "Attack angle", "deg"),
                                 ("attack_direction", "Attack direction", "deg"),
                                 ("contact_vs_plate", "Contact vs plate front", "in"),
                                 ("contact_vs_batter", "Contact vs batter", "in")]:
            mean, lo, hi = LEAGUE[key]
            own = tg.get(key)
            mark = "" if lo <= m[key] <= hi else "  OUT OF RANGE"
            txt.append("%-24s %6.1f %s" % (label, m[key], unit))
            txt.append("   target %s   league %.1f (%.1f..%.1f)%s" % (
                "%.1f" % own if own is not None else "-", mean, lo, hi, mark))
        txt.append("")
        txt.append("Sweet spot speed at contact %.1f mph" % m["sweet_speed_mph"])
        if "hands" in d["samples"][0]:
            hands = np.array([s["hands"] for s in d["samples"]])
            knob = np.array([s["knob"] for s in d["samples"]])
            gap = np.linalg.norm(hands - knob, axis=1)
            pre = m["t"] <= d["contact_t"]
            txt.append("Animation hands to knob before contact (grip IK closes it): max %.2f m" % gap[pre].max())
            for ax, (a, b) in zip(row[:3], [(0, 1), (2, 1), (0, 2)]):
                ax.plot(hands[:, a], hands[:, b], color="tab:blue", lw=1, alpha=0.6, label="animation hands (before grip IK)")
        row[3].axis("off")
        row[3].text(0.0, 1.0, "\n".join(txt), va="top", family="monospace", fontsize=9)
        print("%-9s %s tilt %5.1f  attack %5.1f  dir %6.1f  vs plate %6.1f in  vs batter %5.1f in  speed %5.1f mph  | target %s" % (
            d["style"], "L" if d["bats_left"] else "R", m["tilt"], m["attack_angle"], m["attack_direction"],
            m["contact_vs_plate"], m["contact_vs_batter"], m["sweet_speed_mph"],
            {k: round(v, 1) for k, v in tg.items()}))
    fig.tight_layout()
    fig.savefig(out_png, dpi=70)


if __name__ == "__main__":
    main()
