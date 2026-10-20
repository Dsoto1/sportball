# Sportball

Stylized retro-futurist arcade baseball. **Godot 4.7.2 stable + GDScript.**
The design brief lives in [`docs/`](docs/00_AGENT_START_HERE.md); start there.

Current state: **Phase 0 — Foundation + Feel.** Graybox field, primitive
placeholders, and the full loop: pitch → contact → authoritative ball
flight → fielder intercept → throw → runner/base resolution → reset.
See [`docs/PHASE0_REPORT.md`](docs/PHASE0_REPORT.md) for the feel review
and known weak spots.

## Run

Open the folder in Godot 4.7.2 and press Play, or:

```sh
godot --path .                      # random seed (printed to the console)
godot --path . -- --seed=1234       # reproduce a logged match
```

You control the **AWAY** team: you bat in the top half, and pitch and
choose throws in the bottom half. Tab / Back switches teams.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Aim bat cursor / pitch target | WASD or arrows | Left stick / D-pad |
| Contact swing | J or left click | A |
| Power swing (harder, smaller window) | K or right click | X |
| Pick pitch | Q / E | LB / RB |
| Start meter, then release | Space, J or left click | A |
| Run with the fielder (yellow ring) | WASD or arrows | Left stick |
| Dive | Shift or L | RT |
| Switch to fielder nearest the ball | F | LT |
| Throw to 1st / 2nd / 3rd / home | 1 / 2 / 3 / 4 | B / Y / X / A |
| Skip to next pitch after a play | J | A |
| Switch team | Tab | Back |
| Debug overlay | F1 | R-stick click |
| New match | F5 | Start |

On defense you steer the fielder who can reach the ball first; a white
ring marks where a fly ball will land. Press a throw button any time
(even before the catch). If you hold the ball for more than 0.6 s, the AI
throw is used.

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
  fielding/ running/       FieldingResolver, ThrowModel, RunnerResolver, PlayOutcome
  ai/                      AI pitcher, batter and throw choice (produce the same intents as a human)
  sim/auto_match.gd        full AI-vs-AI match with no scene
data/          tuning and pitch definitions (Resources)
presentation/  graybox field, match view, placeholder actors
ui/            HUD and debug overlay
tests/         unit and scenario tests
tools/         test runner, input map generator, sim/feel reports, playtest bot
docs/          design brief, decisions, asset manifest, Phase 0 report
```
