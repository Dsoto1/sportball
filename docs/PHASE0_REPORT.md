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
- **Interactive graybox match**: batting (cursor + timing, contact/power),
  pitching (aim, pitch select, meter), throw choice on defense, a
  broadcast-style HUD, and an F1 debug overlay. The overlay shows the seed,
  match state, pitch target/location, contact quality, exit velocity,
  launch angle, landing and intercept markers, the trajectory line, fielder
  candidates, runner plans and recent domain events.
- **Reproducibility**: the gameplay seed is printed and can be passed back
  in with `--seed=`. Every intent and outcome is logged as a `[play]` line.
- **Tests**: 56 headless tests (rules, pitch/contact math, trajectory against
  the analytic projectile formula, intercepts, force/tag/third-out rules, AI
  throw choice, and 70+ full AI-vs-AI matches for completion,
  reproducibility and outcome rates). `tools/playtest_bot.gd` drives the
  real scene with simulated input through a full 6-inning match.

## Numbers (100 AI-vs-AI matches, `tools/sim_report.gd -- 100 1`)

| Metric | Value | Rough target |
|---|---|---|
| Runs / team / 6 innings | 3.08 | 2.5–3.5 |
| Hits / PA | .257 | .23–.27 |
| K% / BB% | 15.7% / 9.1% | 18–23% / 7–9% |
| HR / PA | 2.0% | 2.5–3.5% (arcade: higher is fine) |
| Pitches / game (both teams) | 215 | — |
| Diving catches | 7% of balls in play | "rare enough to stay exciting" |
| Double plays / triples / inside-the-park HR | **0 / 0 / 0** | should exist |

Hit rate by launch angle (`tools/launch_angle_report.gd`): grounders
(−10–10°) 25–32%, liners (10–20°) 79%, 20–30° 42%, high flies (40°+) 0%.
That is the right shape.

## Weak feel — read before expanding scope

These are ranked by how much they undercut the pillars. I could not
playtest with a human. Everything here comes from the sims, the playtest
bot, screenshots and reading the timings.

1. **Steered fielding is new and untuned.** *(Update: the player now
   steers the fielder; see DECISIONS.)* AI fielders run perfect routes, so a
   human is held to an AI standard. A crude bot steering at the landing
   spot made far fewer catches than the AI (8 fly catches in 29 plays) and
   gave up 17 runs. Expect to tune fielder speed, reach, the landing hint
   and the first-step feel with real players. There are no jumping catches
   at the wall yet, and auto-switching only happens on request.
2. **Only one throw per play.** That means no double plays, relays,
   cutoffs or rundowns. Runners also commit at contact and never react to
   where the ball actually goes. Defense therefore has no second act.
3. **No triples or inside-the-park home runs.** Runners only take a base
   when they beat a *perfect* throw by 0.35 s. Wall balls get cut off fast,
   and there is no throw inaccuracy or bobble to punish defenders.
4. **Dives may be too common** at ~3 per game. They are free apart from
   0.7 s of recovery, with no failure chance. "DIVING CATCH!" will stop
   feeling special. Failed dives should be possible (and content).
5. **Swing timing is frame-quantized.** At 60 fps one frame is ~24% of the
   power window. Use input event timestamps before tuning windows by feel.
6. **The batting read may be too hard for humans.** Pitches take 0.43–0.54 s.
   The cursor moves at 1.5 m/s, so a pitch on the far corner can be
   unreachable after release. There is also no hitter-side telegraph
   (pitch-type tell or location hint). This needs human testing; the AI
   batter cheats by reading location with noise.
7. **No contact feedback.** There is no bat, no swing animation, no hit
   pause and no camera punch. The batter teleports to home plate on
   contact. Contact can be correct while still feeling flat.
8. **The batting camera works but is cramped.** The crouched catcher still
   intrudes at the bottom of the frame, and the strike zone is small on
   screen. The ball-in-play camera is a single fixed high angle.

## Decisions needed (they affect architecture or feel)

1. ~~**Fielding control model.**~~ Decided: the human steers the fielder,
   and it is implemented (`baseball/fielding/live_fielding.gd`). A
   catch-timing press could still be layered on top.
2. **Batting input model.** Choose one:
   - The current approach: aim a cursor at the pitch plus swing timing. It
     is deep, but the read may be too hard (weak point 6).
   - Timing-first: the bat finds the ball's height automatically, and
     stick direction at contact sets pull or push and lift.

   This changes ContactResolver inputs and the whole skill curve.
3. **Original rules package.** The prototype uses 6 innings, standard counts,
   standard walk-off and extra innings. Decide which pace and spectacle rules
   the league adds (shot clock, tie-break format, etc.) before Phase 1
   locks MatchState.
4. ~~**Visual reference.**~~ Added as `docs/visual_reference_concept.jpg`.

## Suggested next increments (still Phase 0/1, no new systems)

1. Tune steered fielding with people; add throw accuracy/bobble.
2. Multi-throw plays: double plays, relays and live runner decisions
   (`runner_advance` / `runner_retreat`).
3. Timestamped swing input, a hit pause and a bat swing placeholder.
4. Retune dive frequency, extra-base aggression and infield depth with the
   sim and launch-angle reports.
