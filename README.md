# Sportball

Stylized retro-futurist arcade baseball. **Godot 4.7.2 stable + GDScript.**
The design brief lives in [`docs/`](docs/00_AGENT_START_HERE.md); start there.

Current state: **Phase 1 — Baseball Vertical Slice.** A 6-inning
exhibition between the **Rustwater Gearheads** and the **Neon Heights
Glitterati** (yes, Who's on first) under arcade rules, on a graybox field
with primitive placeholders. See [`docs/PHASE1_REPORT.md`](docs/PHASE1_REPORT.md)
and the earlier [`docs/PHASE0_REPORT.md`](docs/PHASE0_REPORT.md).

## Run

Open the folder in Godot 4.7.2 and press Play, or:

```sh
godot --path .                      # random seed (printed to the console)
godot --path . -- --seed=1234       # reproduce a logged match
```

On the matchup card, pick your club: J / click / A for the Gearheads (you
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
presentation/  graybox field, match view, placeholder actors
ui/            HUD and debug overlay
tests/         unit and scenario tests
tools/         test runner, input map generator, sim/feel reports, playtest bot
docs/          design brief, decisions, asset manifest, Phase 0 report
```
