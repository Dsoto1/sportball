# Handoff

State of the project and how to keep working on it, for the next agent
(or a later session of the same one). Last updated 2026-11-01.

Read this first, then `docs/00_AGENT_START_HERE.md` for the vision and the
full doc order. `docs/DECISIONS.md` is the running log of every decision,
newest at the bottom: read its last few sections before touching a system.

## What this is

A retro-futurist arcade baseball game in **Godot 4.7.2 (GDScript)**:
18 original clubs, 18 parks each built from a reference sheet, a
deterministic rules/physics core (`baseball/`) with presentation on top
(`presentation/`, `ui/`, `app/`). 216 headless tests.

## Owner's standing rules (do not break these)

- **Branches:** work on `claude/new-session-c2j0fm` and mirror every push to
  `main`:
  `git push -q origin claude/new-session-c2j0fm && git push -q origin HEAD:main`
  (retry with backoff if GitHub returns a server error).
- **Commits** end with the session's attribution lines (the harness gives
  them); never put model names or IDs in commits, PRs or code.
- **No pull requests** unless the owner asks.
- **Paid generation (Meshy / Artlist):** check the balance, quote the exact
  price, and get an explicit yes before every generation. Log every spend in
  `docs/ARTLIST_CREDITS.md` and every asset in `docs/13_ASSET_MANIFEST.md`.
  Never ask the owner to paste API keys. No AI-generated reference images.
  Meshy balance on 2026-11-01: **5,048 credits** (30 per text-to-3D
  model, 5 per remesh, 5 per rig).
- **Branding:** take layout and feel from the inspiration games, never their
  names, logos or art.
- **Before calling anything done:** render it and look at the render, and run
  the full test suite. Send the owner the renders.
- The owner reviews visually and is precise: when they point at something,
  render that exact view from several angles before and after.

## Setting up a fresh container

1. Godot 4.7.2 is not installed. Download `Godot_v4.7.2-stable_linux.x86_64`
   (godotengine releases on GitHub) into your scratchpad and set
   `G=<path to it>`.
2. Tests (headless): `GODOT=$G bash tools/run_tests.sh`. Takes a few minutes;
   run it in the background to a log file. It fails on any script error too.
   Don't run it alongside several renders: the container runs out of memory
   (exit 137).
3. After adding a file with a new `class_name`, run
   `$G --headless --path . --import` once before anything else.
4. Renders need a display: `xvfb-run -a $G --path . --resolution WxH -s res://tools/<tool>.gd -- <args>`.
   They use the Compatibility (OpenGL) renderer here; SSAO and other
   Forward+ effects don't show, so the owner's machine looks a bit
   different. Run at most 2-4 renders at once.
5. `tools/swing_path_plot.py` needs matplotlib (`pip install matplotlib`).
6. Park data is generated: edit `tools/generate_parks.gd`, then
   `$G --headless --path . -s res://tools/generate_parks.gd` to rewrite
   `data/stadiums/*.tres` (it prints validation errors; there must be none).

## Render and check tools (`tools/`)

| Tool | What it does |
|---|---|
| `stadium_tour.gd -- <out_dir> <park_id> [cam:x,y,z,tx,ty,tz] [fov:N] [orbit] [mound] [cheer:0..1] [nocrowd]` | Park shots. `cam:` for one exact view, `orbit` for 8 drone shots, `mound` for a first-person turn from the rubber. |
| `batter_closeup.gd -- <out_dir> [style:<name>] [righty\|lefty] [hands]` | Batter stills from the pitcher, chest side, back side and high behind (catcher and umpire hidden). `swing <style> [slowmo\|pitcher\|flip]` for a swing sequence. The default match batter bats **left**. |
| `swing_path.gd -- out.json <style> [righty\|lefty] [savant:tilt,attack,dir,mph]` + `swing_path_plot.py out.png a.json [b.json ...]` | Records the bat's sweet spot through a real swing and measures it the way Baseball Savant does (tilt, attack angle, attack direction, contact depth), with 3 views. |
| `pitch_view_shot.gd`, `pitch_motion_shot.gd`, `grip_test.gd`, `flight_shots.gd`, `board_shots.gd`, `model_sheet.gd` | Pitching camera + HUD, pitcher feet on the mound, grip close-ups, ball flights, scoreboards, a sheet of GLB models. |
| `pitch_view_shot.gd -- out.png [batting\|card\|final\|callout]` | The match HUD: pitching (default), batting, the matchup card, the final card, a callout. |
| `body_check.gd -- out.png [robot] [side]`, `glb_turn.gd -- res://model.glb out.png` | A worn body in six poses beside a person; any GLB from four sides. |
| `stadium_tour.gd -- <dir> <park> wall` + `wall_strip.py <dir> <park> out.png sheet.jpg` | The outfield wall unrolled pole to pole under the sheet's wall strip. |
| `menu_shots.gd -- <out_dir>` | Every menu screen, the matchup card and the pause menu (windowed). |
| `generate_parks.gd`, `generate_teams.gd` | Write the park and club data. |
| `repack_glb.py`, `cull_back.py`, `regrade_glb.py` | Shrink and clean generated models (pipeline in DECISIONS: weld, cull_back, simplify, repack). |

Pitching camera view for comparisons: `cam:-0.9,2.35,-25.8,0.35,1,0 fov:23`.
Wide mound view: `cam:0.6,2.6,-21,0,6,0 fov:62`. Reference sheets are in
`docs/stadium_refs/` (panel 3 is the pitcher's view, panel 4 the home dugout).

## Where things live

- `baseball/`: rules and physics, deterministic, tested. Ball flight
  `ball/ball_trajectory.gd` (now bounces off the mound and the bags);
  field geometry `field_layout.gd` (`ground_height`, `ground_normal`,
  `base_contact`, rulebook dimensions).
- `presentation/stadium/`: `stadium.gd` builds the bowl procedurally
  (profile, decks, dugouts, behind-home design, back facade, crowd);
  `graybox_field.gd` the field and lighting; `modules/` per-park pieces;
  `model_kit.gd` the model roles.
- `presentation/match/`: `match_view.gd` (cameras, ball, bat, swing),
  `actor_view.gd` (players, gear, cloth uniform), `bat_grip.gd` and
  `foot_plant.gd` (IK).
- `presentation/animation/`: `baseball_moves.gd` and `batting_styles.gd`
  (baked poses per style), `swing_path.gd` (the Savant-shaped arc into
  contact), `pose_baker.gd`.
- `ui/hud/match_hud.gd`: broadcast HUD. `app/match_director.gd`: the match loop.

## Recent work (newest first; details in DECISIONS.md)

- **Alley distances** on every wall (five real numbers: poles, alleys, center), art moved out
  of the alleys, and nothing (landmarks, gates) standing in front of any wall.

- **Outfield walls checked against every sheet's wall strip** (`stadium_tour.gd ... wall` +
  `tools/wall_strip.py`): bigger art, signs that fit, new motifs (waterfall, swan,
  scorpion, shark, garden), denser layouts, and nothing standing on the warning track.

- **The owner's robot player** (Meshy-rigged) is the Sentinels' #25: it
  rides the player skeleton through `BodyDouble`, so every animation and
  IK works. The owner's other T-pose characters are on hold (owner: no more for now).
  Mini field top right redrawn.

- **HUD, matchup card and final card restyled** to the owner's UI
  reference (`docs/ui_reference.jpg`): `MatchHud.skin()` panels,
  drawn `ScoreBug`, `MatchupCard`, `FinalCard`.

- **Per-park skies** from the owner's Binbun3D skies pack
  (`StadiumDef.sky_preset`, `GrayboxField.sky_material()`), blended by
  the park's time of day; the haze and ambient follow the sky.

- **Owner's VFX packs** (Binbun3D, from their Drive `models/fx`): contact
  bursts by tier, home-run fireworks, slide/dive dust (`MatchFx`). Unused
  packs (battle, status, etc.) remain in the Drive.

- **Main menu, settings, pause, full screen** per the owner's UI/UX
  reference (navy/gold, Bebas Neue + Montserrat): `ui/menu/`,
  `app/game_settings.gd`, `app/menu_backdrop.gd`. The game boots to the
  menu only when `main.tscn` is the current scene; tools still get a
  match. Career and Creator Studio are "coming soon" tiles. Renders: `tools/menu_shots.gd`.

- **Swing mapped to Savant bat tracking.** `SwingPath` drives the sweet spot
  into contact on an arc in the hitter's tilted plane at his attack angle,
  direction and bat speed; contact at the pitch, per-hitter depth fit to the
  leaderboard. Verified with the swing-path tool against real hitters.
- **Flush field + solid mound and bags.** Field layers within 1.6 cm of the
  ground, ordered by a shader depth pull; ball bounces off the mound, rolls
  on it, ricochets off the bags (`hit_base`).
- **Batting stance per style:** hands ride with the shoulders, lead arm in
  front of the chest, knees over the feet.
- **Cloth uniforms** (a skinned shell over the body) and **sculpted gear**
  (cap, helmet, full catcher's gear), dugout props, waterfalls at Sakura Gate
  and Fountain Gardens (11 Meshy models).
- **Per-park behind-home designs, lighting pass, outer facade, smooth
  backstop, Sakura Gate rework** (Fuji, hills, blossoms, kitsune behind the
  stands).

## Open work

1. **Atmosphere:** skies are in; fog and post-processing per park still
   need a screenshot from the owner's machine (Forward+ renders differently).
2. **Outfield walls:** done against all 18 sheets (rusted Foundry plates, Icebox icicles and
   Warehouse Row murals included).
3. Swing follow-through after contact wasn't remeasured against Savant;
   inside/outside pitch effects on contact depth aren't modelled from data.
4. Sakura's waterfall is partly hidden by the towers from low angles.
5. Dugout props read small from wide shots.
6. Couldn't confirm in this environment that the flattened field layers
   never shimmer at long range; ask the owner if they see any.

## Gotchas learned the hard way

- A spatial shader that writes `POSITION` anywhere (even inside an `if`)
  loses Godot's own projection for every material using it: always write it.
- Godot's front faces wind **clockwise**; a mesh wound the other way is lit
  from inside (this made every mountain dark until `Scenery.lathe` was fixed).
- Vertex colors are used as linear: convert with `srgb_to_linear()`.
- Tests build stadiums outside the scene tree: use local `transform`, never
  `global_transform`, in build code.
- Pose hand targets are absolute body space; the pelvis `drop` lowers the
  shoulders under them (BattingStyles compensates).
- `get_bone_global_pose` during `_process` reads the animation's pose, not
  the IK-modified one.
- A first screenshot taken the same frame a camera moves shows the old view.
- Baseball Savant: the pages and `?csv=true` exports download with `curl`
  through the proxy; the fetch agent's DNS fails, and `mlbstatic.com`
  scripts (its visualizations) are blocked.
- `pkill -f <pattern>` can match and kill your own shell command.
