# Phase 0 Report — Foundation + Feel

Date: 2026-10-20. Scope per `09_MVP_ROADMAP.md`: minimal Godot structure,
semantic inputs, authoritative MatchState, tests/debug overlay, graybox
field, and pitch → contact → ball flight → fielder intercept → throw →
runner/base resolution → reset.

## What exists

- **Authoritative baseball core (`baseball/`)**, with no scene dependency.
  MatchState owns count, outs, innings, score, bases, lineup order,
  walk-offs and extra innings, and it emits typed `DomainEvent`s.
  PitchResolver, ContactResolver, BallTrajectory, FieldingResolver,
  ThrowModel and RunnerResolver are explicit-input/explicit-output services.
- **Deterministic ball flight**: a 120 Hz fixed-step integrator with
  gravity, quadratic drag, bounces, rolling friction and fence rebounds or
  home runs. The visible ball samples it.
- **Data-driven balance**: every feel value is in `BaseballTuning`. The three
  pitch families are `PitchFamilyDef` resources.
- **AI** for pitcher, batter and throw choice. It produces the same intent
  objects a human produces.
- **Interactive graybox match**: timing-first batting (contact/power, stick shapes direction and loft),
  pitching (aim, pitch select, meter), throw choice on defense, a
  broadcast-style HUD, and an F1 debug overlay. The overlay shows the seed,
  match state, pitch target/location, contact quality, exit velocity,
  launch angle, landing and intercept markers, the trajectory line, fielder
  candidates, runner plans and recent domain events.
- **Reproducibility**: the gameplay seed is printed and can be passed back
  in with `--seed=`. Every intent and outcome is logged as a `[play]` line.
- **Tests**: 103 headless tests (rules, pitch/contact math, trajectory against
  the analytic projectile formula, intercepts, force/tag/third-out rules, AI
  throw choice, and 70+ full AI-vs-AI matches for completion,
  reproducibility and outcome rates). `tools/playtest_bot.gd` drives the
  real scene with simulated input through a full 6-inning match.

## Numbers (100 AI-vs-AI matches, `tools/sim_report.gd -- 100 1`, errors on)

| Metric | Value | Rough target |
|---|---|---|
| Runs / team / 6 innings | 2.55 | 2.5–3.5 |
| Hits / PA | .261 | .23–.27 |
| K% / BB% | 16.5% / 7.7% | 18–23% / 7–9% |
| HR / PA | 2.3% | 2.5–3.5% (arcade: higher is fine) |
| Pitches / game (both teams) | 203 | — |
| Dives | 6.9% of balls in play, 30% of in-reach dives fail | "rare enough to stay exciting" |
| Errors / team / 6 inn | 0.52 (bobbles + wild throws) | ~0.4–0.6 |
| Double plays / team / 6 inn | 0.51 | ~0.6 |
| Triples / doubles (% of balls in play) | 0.7% / 8.8% | ~0.5% / ~6.5% |

Hit rate by launch angle (`tools/launch_angle_report.gd`): grounders
(−10–10°) 25–32%, liners (10–20°) 79%, 20–30° 42%, high flies (40°+) 0%.
That is the right shape.

## Phase 0 status

Phase 0 is feature-complete. Every weak spot from the first report has been
worked; what is left needs people playing it, not more systems.

| Weak spot (first report) | Now |
|---|---|
| Steered fielding held to AI-perfect routes | Rookie assist: +12% speed, +0.35 m reach, auto-route with the stick at rest. Control auto-switches to a teammate when a grounder gets past your fielder (F/LT still switches by hand). |
| Live running AI-tuned only | Live decisions, rundowns, cutoffs, per-runner orders, procedural rundown poses. |
| No triples, no throw inaccuracy or bobbles | Bobbles, wild throws and wall caroms (0.8 s pickup). Runners take extra bases on a misplay, even mid-stride. Triples 0.7% of balls in play. |
| Dives free and too common | 30% of dives that reach the ball still fail and the ball gets past ("IT GETS BY HIM!"). That is a hit, not an error. |
| Swing timing jitter | Microsecond input stamps and half-frame correction. ±½ frame remains (an engine limit). |
| No pitch read | Pitch tells: trail colour and length per pitch type. |
| No contact feedback | Visible bat and swing, windup, timing ring, aim preview, sweet-spot flash, synthesized crack, callouts with the reason, camera punch, and a hit pause (50 ms solid, 110 ms barrel). |
| Cramped batting camera, fixed field camera | Telephoto batting camera with a lower catcher. The field camera follows the ball, pulls back on deep plays, tilts up for fly balls and zooms in on rundowns. |

## What only playtesting can settle

1. **Assist strength.** Batting (×0.85 pitch speed, ×1.3 window) and
   fielding values were tuned against bots. Decide whether rookies should
   win against the AI.
2. **Error rate feel.** 0.5 per team per game is about real-baseball
   rates. Arcade players may find errors frustrating when they happen to
   them; `assist_error_scale` already halves them for a human fielder.
3. **Procedural poses** read at close range but are subtle from the field
   camera. Real animation is Phase 2.
4. **Remaining ±½-frame swing jitter** matters most for power swings at
   60 fps. Report it if it feels random.

## Decisions needed before Phase 1

1. **Original rules package.** The prototype uses 6 innings, standard counts,
   standard walk-off and extra innings. Decide which pace and spectacle rules
   the league adds (shot clock, tie-break format, etc.) before Phase 1
   locks MatchState.
2. **Team names and identity** for the two Phase 1 teams.
3. **Approval to propose CC0 readability assets** (logged in the asset
   manifest before import).
