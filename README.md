# Sportball

Stylized retro-futurist arcade baseball. **Godot 4.7.2 stable + GDScript.**
The design brief lives in [`docs/`](docs/00_AGENT_START_HERE.md); start there.

Current state: **Phase 1 — Baseball Vertical Slice**, with a first art pass
(rigged players with the game's own baseball animations, eleven ballparks
with their own walls, air and turf, a reactive crowd and live scoreboard,
field surfaces, fonts, button icons and sound;
every third-party asset is in `docs/13_ASSET_MANIFEST.md`). A 6-inning
exhibition between any two of eleven clubs, each at home in its own park
(the **Rustwater Gearheads** and **Neon Heights Glitterati**, yes, Who's on
first, plus nine more), under arcade rules. See [`docs/PHASE1_REPORT.md`](docs/PHASE1_REPORT.md)
and the earlier [`docs/PHASE0_REPORT.md`](docs/PHASE0_REPORT.md).

## Run

Open the folder in Godot 4.7.2 and press Play, or:

```sh
godot --path .                      # random seed (printed to the console)
godot --path . -- --seed=1234       # reproduce a logged match
```

On the matchup card, ↑ / ↓ chooses a row and ← / → changes it: the away
club, the home club, and the venue (the home club's park unless you change
it). Then pick your side: J / click / A for the Gearheads (you
bat first), K / right-click / X for the Glitterati (you field first). Tab /
Back switches sides mid-game.

**Arcade rules:** 6 innings, a designated hitter for everyone, the game
ends if a team leads by 10 or more after 4 innings, extra innings start
with a runner on second, and you have 15 s to start each pitch (or it is a
ball). Ratings matter: hard throwers are faster, sluggers hit it farther,
fast runners beat out grounders, good gloves bobble less.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Contact swing | J or left click | A |
| Power swing (harder, smaller window) | K or right click | X |
| Bunt (hold ← / → to push it toward third / first) | B | B |
| Before the pitch: steal (every runner with an open base) / call it off | E / Q | RB / LB |
| ...hold 1 / 2 + steal: send just that runner | 1-2 + E | B / Y + RB |
| Pitching: slide step on/off (quicker delivery, less control) | Shift | RT |
| Pitching, before the pitch: pickoff throw (point → 1st, ↑ 2nd, ← 3rd; none = the likeliest runner) | F (+ WASD) | LT (+ stick) |
| While swinging: steer left/right field, lift (up) or chop (down) | WASD or arrows | Left stick |
| Aim pitch target | WASD or arrows | Left stick / D-pad |
| Pick pitch | Q / E | LB / RB |
| Start meter, then release | Space, J or left click | A |
| Run with the fielder (yellow ring) | WASD or arrows | Left stick |
| Dive | Shift or L | RT |
| Switch to fielder nearest the ball | F | LT |
| Throw: hold toward the base (→ 1st, ↑ 2nd, ← 3rd, ↓ home) and press throw | WASD + Space, J or left click | Left stick + RB |
| ...no direction: throw to the best play | Space, J or left click | RB |
| ...or throw straight to 1st / 2nd / 3rd / home | 1 / 2 / 3 / 4 | B / Y / X / A |
| With the ball: run at a runner / to a bag | WASD or arrows | Left stick |
| Batting, ball in play: runners advance / retreat | E / Q | RB / LB |
| ...only the runner on (or heading to) a base: hold that base | 1 / 2 / 3 / 4 | B / Y / X / A |
| Skip to next pitch after a play | J | A |
| Switch team | Tab | Back |
| Debug overlay | ` (backtick) or F1 | R-stick click |
| New match | R or F5 | Start |
| Rookie assist on/off | T | L-stick click |
| Pitching change (fielding) / pinch hitter (batting), between pitches | P | Y |
| ...in the menu: choose / confirm / cancel | W S, J / P | Stick, A / Y |

**On a MacBook:** click the trackpad to swing (contact); a two-finger click
is a power swing. Use ` and R instead of F1 and F5, which need fn. Click
the game window once if keys don't respond (it needs focus).

Batting is about timing: watch the pitcher wind up, then swing as the
white ring on the plate closes (it turns green when the ball arrives).
Rookie assist (on by default) slows pitches a little and widens the timing
window while you bat. The bat finds the ball's height on its own. Lay off
pitches far off the plate, since they cost contact quality or can't be
reached. The small yellow marker on the zone shows what your stick is
adding, and the arrow on the field shows where it sends an on-time swing
(blue and long = in the air, brown and short = on the ground). Swinging
early pulls the ball left of the arrow, late pushes it right.

**Small ball.** Bunt with B: the timing window is wide, but the ball comes
off soft and on the ground, so runners move up (a sacrifice) or a fast
batter beats it out. Steer it with ← / → and bunt strikes, not high pitches
(they pop up). A foul bunt with two strikes is a strikeout. To steal, press
E / RB before the pitch. Press it before the pitcher's windup for a good
jump; late costs ground. Your runner breaks on the pitch, and the catcher
has to throw him out, with speed and arm deciding the race. If the ball is
put in play he already has a running start (hit-and-run). When you are on
defense, a runner going calls out RUNNER GOING!: throw to his base.

**Pickoffs.** Before the windup the pitcher can throw over (F / LT, aim
with WASD). A runner with a normal lead dives back safely. One leaning to
steal (watch for a runner with a bigger lead) is picked off about two times
in three. Every throw over shrinks that runner's lead for the rest of the
at-bat, which costs him jump on a steal. You get two per batter. The AI
pitcher throws over on you too, and may read your steal if you call it
early, so time it.

**Slide step.** Toggle it with Shift / RT while pitching (the pitch menu
shows it). The quick delivery takes ground away from a base stealer, but
the pitch is wilder and a little slower. The AI pitcher slide-steps against
fast runners and when he reads a lean. You can spot it because his windup
is visibly quicker, so be ready to swing a beat earlier.

Read the pitch by its trail. Each pitch has its own color and length,
longest to shortest:

| Pitch | Trail | What it does |
|---|---|---|
| Fastball | long blue | fastest and straightest |
| Sinker | teal | runs in and down: ground balls |
| Cutter | lilac | late, short break away from a righty |
| Splitter | yellow | looks like a fastball, then falls off the table |
| Slider | orange | hard sideways break |
| Curveball | red, short | slow and drops a lot |
| Changeup | green stub | slow, fades and drops |
| **Junkball** (Gearheads' Otis Hollerith) | a single white dot | slow knuckler that dances on the way in |
| **Showstopper** (Glitterati's Tomorrow) | long gold | hangs in mid-air, then rushes the plate |

Each pitcher throws 2–4 of these, and the pitch menu shows only his. A
left-hander's pitches break the other way. Breaking balls are nastier
against same-handed hitters, and changeups and splitters against
opposite-handed ones.

After every swing the callout tells you how it went and why, for example
"SOLID contact · a hair late (9 ms) · on the edge of the zone". Hitting the
sweet spot (perfect timing on a pitch over the middle) flashes at the
plate and calls out **BARRELED!**, or **CRUSHED!** with a power swing. For
home runs: power swing, hold up for lift, perfect timing, middle pitch.

On defense, Rookie assist also makes your fielder a little quicker with
more reach, and if you let go of the stick he runs to the ball himself.
If a grounder gets past your fielder, control jumps to the teammate
closest to it. You steer the fielder who can reach the ball first; a white
ring marks where a fly ball will land. To throw, point WASD (or the stick)
at the base the way the diamond looks on screen and press Space / J / click
(RB on a gamepad). A green ring shows which base you are aiming at, and a
throw with no direction goes to the best play. Throw any time, even before
the catch. Press another one to have the receiver throw on (for
example 2 then 1 to turn a 6-4-3 double play). Long throws from the
outfield go through a cutoff man. He relays to your base unless you press
a different one while the ball is on its way to him. If you hold the ball for
more than 0.6 s, the AI takes over. Once you have the ball, the stick
moves the fielder holding it: run a runner down in a rundown, or step on
a bag yourself.

Fielders are not perfect: grounders get bobbled, throws sail, and about
a third of dives that reach the ball still don't hold it. Runners take an
extra base when that happens, and a ball off the wall takes a moment to
play. Rookie assist halves your fielders' errors.

When you are batting, runners decide for themselves until you give them
an order. Advance or retreat on its own orders everyone. Hold a base
button first to order just the runner on, heading to, or just off that
base; a yellow ring shows who that is. Runners you have ordered do what
you said, and the rest stay AI-run.

Bindings live in `project.godot` as semantic actions. To change them, edit
the table in `tools/generate_input_map.gd` and run
`godot --headless --path . -s res://tools/generate_input_map.gd`.

## Clubs

| Club | Home park | Style |
|---|---|---|
| Rustwater Gearheads | Foundry Field | small ball: steals, bunts, gloves |
| Neon Heights Glitterati | The Halo Dome | power and showboating (Who's on first) |
| Brickhaven Bankers | Ledger Street Park | patient, doubles off the Leviathan |
| Tidewater Gulls | Pier 9 Ballyard | left-handed pull power at the bay |
| Copper Mesa Comets | The Kiln | speed, gappers into triples |
| Frostgate Yetis | The Icebox | contact, sinkers, gloves |
| Atomic Falls Neutrons | Reactor Park | all-or-nothing power, flamethrowers |
| Midtown Lamplighters | The Horseshoe | pull hitters, crafty arms |
| Ironbridge Conductors | Warehouse Row | left-handed line drives |
| Cascade City Swans | Fountain Gardens | pitching and defense |
| Vaultborough Safecrackers | The Vault | turf speed, slaps, steals |

Rosters for the nine new clubs come from `tools/generate_teams.gd` (a lineup
template shifted by each club's style, steady per-player variation,
original names). `tools/league_report.gd` plays a round robin; over 240
games each the clubs land between .425 and .562.

## Ballparks

Each park's walls, wall heights, air and surface are rules: fly balls,
caroms off the walls and grounders play differently. Fielders play deeper
in deeper parks. 60 AI-vs-AI games each (`tools/park_report.gd`), with every
hitter's own swing (bat speed, attack angle, pull) in play:

| Park | Signature | R/G | HR/G | 2B/G | 3B/G |
|---|---|---|---|---|---|
| The Halo Dome | Glitterati home: symmetric, neon halo overhead | 5.42 | 1.30 | 2.40 | 0.38 |
| Foundry Field | Gearheads home: the Boilerplate, a 34 ft iron wall in short right | 4.57 | 1.00 | 2.15 | 0.60 |
| Ledger Street Park | the Leviathan, a 37 ft green wall in short left; deep triangle | 4.82 | 0.72 | 1.78 | 1.17 |
| Pier 9 Ballyard | short porch in right with the bay beyond it | 6.28 | 1.38 | 1.95 | 0.58 |
| The Kiln | thin desert air, canyon-deep outfield, red mesas | 5.58 | 0.90 | 1.47 | 1.78 |
| The Icebox | cold heavy air, ice falls and peaks beyond the wall | 4.60 | 0.77 | 2.00 | 0.43 |
| Reactor Park | night game; odd angles, a 427 ft center-field notch | 5.40 | 1.08 | 1.87 | 1.28 |
| The Horseshoe | night game; 279 / 266 ft lines, a 482 ft center field | 5.47 | 0.45 | 0.98 | 1.40 |
| Warehouse Row | 25 ft brick wall in right, the Roundhouse warehouse beyond it | 5.47 | 1.10 | 2.05 | 0.85 |
| Fountain Gardens | big and fair; garden terraces, fountains and blossoms beyond the wall | 4.85 | 0.85 | 1.18 | 1.32 |
| The Vault | fast turf under searchlights, a giant vault door in left | 5.60 | 0.98 | 2.33 | 0.45 |

### Building a park

The look is built from layers, so a park (or a future stadium designer) only edits data:

- **Field shape:** `FieldShape`, the rules (walls, heights, air, surface).
- **Palette:** the `StadiumDef` colors. `recolored(primary, secondary)` gives a copy in a club's colors.
- **Bowl and crowd:** rows, attendance and fan shares.
- **Setting:** night, turf.
- **Pieces:** `StadiumDef.pieces`, a list of placed `StadiumPiece`s (kind, spray angle, size, mirrored, settings).

The core is always built:

- the bowl, in 1 to 3 decks, with the home club's wordmarks along each deck front;
- the crowd and the batter's eye;
- dugouts (home on first, VISITORS on third);
- the backstop;
- the wall's distances and the home club's emblems. Each piece is a module from `StadiumModules.CATALOG`:

| Module | What it is | Settings |
|---|---|---|
| `centerpiece` | board in straightaway center: club name under its emblem (or a station clock), the batter's card | height, frame (board, gate, arch), clock, crown |
| `scoreboard` | line-score board over the stands | height |
| `slogan_board` | lit sign with the emblem, the park's name and the club's slogan | height, text |
| `wall_scoreboard` | hand-operated board in a wall 6 m or taller | none |
| `light_towers` | six floodlight towers and a pair flanking the centerpiece | height, flank |
| `skyline` | city ring, windows lit at night | height, count |
| `halo` | glowing ring on pylons, hung with sponsor boards | height, radius |
| `bay` | water beyond one side, low stands, boats | boats |
| `warehouse` | long brick building along a line, its name on top | length, height, text |
| `fountains` | pools with cascades and jets beyond the wall | span, basins |
| `arcade` | upper facade on the back of the stands: arches, windows, steel or timber frame, colonnade, glass curtain wall or battlements, with columns, cornice, club banners and optional towers | style, span, height, bay, banners, towers, tower_height, cap (spire, dome, pagoda, flat) |
| `canopy` | roof over the top rows, steel or timber, lit front edge | style, span, depth, height |
| `wall_art` | motifs along the outfield wall: waves, snowflakes, zigzag bolts, blossoms, gears, stars, crossed bars, emblem | motif, every, glow |
| `dome` | sealed roof; the park plays indoors | rise |
| `vault_door` | giant round bank-vault door in a tall wall behind the stands | radius |
| `searchlights` | beams sweeping into the night sky | span, count, length |
| `waterfalls` | waterfall behind the outfield stands, into a pool (or a frozen ice fall) | height, width, frozen |
| `trees` | grove across a span: palms, pines, cacti, round, cypress, blossom | span, count, kind |
| `conservatory` | glass greenhouse dome on a stone drum | radius |
| `smokestacks` | smokestacks with smoke, or cooling towers with steam (tintable) | span, count, height, style, tint |
| `cranes` | lattice gantry cranes | span, count, height |
| `lighthouse` | striped lighthouse on a rock | height |
| `sailboats` | sailboats and a tall ship on the water | span, count |
| `flying_craft` | saucer cars or blimps over the skyline | count, style |
| `flags` | flagpoles along the top of the stands in club colors | span, count |
| `statue` | bronze bull or figure on a pedestal atop the stands | figure |
| `mountains` | snowcapped peaks or red-rock mesas (with a natural arch) | style, span, count, height, distance, arch |
| `rocket` | rocket sculpture on a launch gantry | height |
| `gondola` | ski gondola line with cabins | span |
| `icicles` | snow lips and icicles along deck fronts and the top of the stands | span |
| `pipes` | industrial pipe runs along the top of the stands, the top one lit | span, runs |
| `viaduct` | elevated railway on brick arches with a lit train | span, height, distance, train |
| `lamps` | gas-lamp posts along the top of the stands | span, count |
| `bunting` | half-fan bunting along the deck fronts | span, every, club_colors |
| `water` | a straight river or a moat around the stands (wide for harbor water), optionally glowing | style, distance, width, gap, span, glow |
| `bridge` | arched bridge running out from the park; centers itself on a river there | distance, length |

- **Placing pieces:** `park.add_piece(&"warehouse", -45.0, {"text": "LOFTS"})`.
- **Checking a design:** `park.validate()` lists problems: unknown modules, settings out of range, two of a one-per-park piece, a dome with light towers, a wall scoreboard on a low wall, no scoreboard.
- **Adding a module:** one script under `presentation/stadium/modules/` and one catalog entry.
- **Surfaces:** each park picks a surface for its facade, structure, stands and ground from `StadiumSurfaces`: brick, stone, concrete, steel, wood, rock, snow, marble or sand. These are CC0 ambientCG textures tinted by the park's palette and mapped in world space. Modules ask for `&"structure"` or `&"facade"`, or a surface by name.
- **Models:** `ModelKit` hands out CC0 Kenney models by role (palm, pine, cactus, round, cypress, blossom, rock, tower, building, block), scaled to a height.

## Test

```sh
GODOT=/path/to/godot ./tools/run_tests.sh            # all tests
GODOT=/path/to/godot ./tools/run_tests.sh runner     # files matching "runner"
```

Tests run headless with no stadium loaded. The runner is a small in-repo
script (`tests/run_tests.gd`); `run_tests.sh` also fails on any engine
script error, since a GDScript runtime error does not abort a test.

## Tuning and tools

All feel numbers are in `data/defs/baseball_tuning.gd` (defaults) and
`data/tuning/baseball_tuning.tres` (overrides). Pitch families are
resources in `data/pitches/`.

```sh
godot --headless --path . -s res://tools/sim_report.gd -- 100 1           # AI-vs-AI rates over 100 matches
godot --headless --path . -s res://tools/launch_angle_report.gd           # hit rate by launch angle
godot --headless --path . -s res://tools/pitch_report.gd -- 300 1         # usage and results per pitch type
godot --headless --path . -s res://tools/park_report.gd -- 80             # how each ballpark plays
godot --path . --resolution 1280x720 -s res://tools/stadium_tour.gd -- /tmp/shots [park_id]   # screenshots of a park
godot --path . --resolution 360x420 -s res://tools/pose_gallery.gd -- /tmp/poses [lefty]      # every baked baseball move
godot --path . --resolution 420x420 --fixed-fps 60 -s res://tools/batter_closeup.gd -- /tmp/b [swing <style> [flip]]   # the batter up close, a style's swing
godot --headless --path . -s res://tools/foot_diagram_data.gd | grep '^{' > feet.json && python3 tools/draw_foot_diagram.py feet.json feet.png   # top-down foot placement per style
godot --headless --path . -s res://tools/elbow_check.gd -- [lefty] [verbose <style>]   # how close elbows come to the body, per style
godot --headless --path . -s res://tools/swing_report.gd   # every hitter's swing: style, bat speed, attack angle, direction, tilt
godot --headless --path . -s res://tools/league_report.gd -- 12 0 1   # round robin standings (slice it: -- 12 <k> 4, then -- merge files)
godot --headless --path . --fixed-fps 60 -s res://tools/playtest_bot.gd -- 900   # drive the real scene with fake input (append `"" home` to field first)
```

`playtest_bot.gd` can also save screenshots when run with a display:
`godot --path . --fixed-fps 60 -s res://tools/playtest_bot.gd -- 120 /tmp/shots`.

## Layout

```
app/           bootstrap (main.tscn) and MatchDirector: input -> intents -> resolvers -> view
baseball/      authoritative rules and math; no scene dependencies
  match_state.gd           inning/half, outs, count, score, bases, lineup, domain events
  pitch/ batting/ ball/    PitchResolver, ContactResolver, BallTrajectory
  fielding/ running/       FieldingResolver, LiveFielding, ThrowModel, RunnerResolver (read), LivePlay, PlayOutcome
  ai/                      AI pitcher and batter (produce the same intents as a human); play AI lives in LivePlay
  sim/auto_match.gd        full AI-vs-AI match with no scene
data/          tuning and pitch definitions (Resources)
presentation/  field, stadiums, match view, players and their baked baseball moves (animation/)
ui/            HUD and debug overlay
tests/         unit and scenario tests
tools/         test runner, input map generator, sim/feel reports, playtest bot
docs/          design brief, decisions, asset manifest, Phase 0 report
```
