# TECHNICAL SPEC

## Locked Technology Stack

- **Engine:** Godot 4.7.2 stable. Do not migrate to preview/beta builds without an explicit project decision.
- **Primary language:** GDScript.
- **3D authoring:** Blender.
- **3D interchange:** glTF 2.0 / GLB.
- **Rendering:** Godot Forward+ for the desktop target, with scalable quality tiers.
- **UI:** Godot Control nodes and Themes.
- **Source control:** Git; Git LFS for large binary art/audio assets.
- **Initial target:** Windows PC desktop.
- **Input:** Gamepad-first gameplay with keyboard/mouse parity.
- **Data:** Godot Resources for strongly typed internal definitions; JSON/CSV only where external authoring, bulk data, or modding benefits.
- **Physics:** Godot physics for collision queries and presentation; custom/tunable baseball math for authoritative pitch/contact/ball-flight outcomes.
- **Save:** Versioned custom save schema with migration support.

## Architectural Prime Directive

THE 3D SCENE IS NOT THE GAME STATE.

Nodes, character rigs, balls, cameras, particles, HUD elements, and animations present the game. They are not the authoritative record of the baseball game. Match state and simulation must remain testable without rendering a stadium.

This separation is required for reliable AI, replays, debugging, franchise statistics, save/load, accelerated simulation, and any future networking work.

## Goal

Create a modular architecture where baseball simulation, presentation, Show systems, franchise systems, and content data evolve independently.

## Major Modules

- Match State / Rules
- Pitching
- Batting / Contact Resolver
- Ball Trajectory
- Fielding / Player Control
- Base Running
- Tags / Collisions
- AI Decision Layer
- Show / Crowd
- Traits / Abilities
- Presentation / Camera / Replay
- Audio / Commentary Events
- Team / Player Data
- Franchise / Calendar / Economy
- Save / History / Records
- Content Tools

## Separation Rules

The baseball rules layer does not know how a celebration is rendered.

Presentation subscribes to domain events. Franchise systems consume match summaries rather than frame-level scene state. Cosmetic randomness is separate from gameplay randomness.

## Event Model

Use explicit domain events such as PitchThrown, BallContacted, CatchCompleted, ThrowReleased, RunnerAdvanced, TagAttempted, CollisionResolved, RunScored, OutRecorded, ShowPlayAttempted, ShowPlayResolved, and RivalryTriggered.

Godot signals may transport events at presentation boundaries, but domain logic should not become an uncontrolled web of signals. Prefer explicit typed event/data objects and clear ownership.

## Baseball Authority

A hit should originate from authored/tunable values such as exit velocity, launch angle, spray direction, spin, hitter/pitcher modifiers, and environment modifiers. The presentation layer then moves the visible ball to match that authoritative result.

Do not make arbitrary rigid-body impulses the primary baseball rules engine.

## Determinism and Debugging

Strict multiplayer lockstep is not an MVP requirement. Record gameplay RNG seeds and important inputs/outcomes so a problem can be reproduced.

Add a debug overlay capable of showing pitch target, contact quality, exit velocity, launch angle, projected landing point, fielder intercept target, and current match state.

## Data

Players, teams, traits, abilities, pitches, equipment, stadium modifiers, sponsor objectives, events, progression curves, and animation mappings live in versioned definitions rather than scattered constants.

## Save Data

Persist stable IDs, not display names. Save franchise state, player history, relationships/rivalries, unlocks, records, schedule, settings, and version information. Every schema change that affects existing saves requires a migration decision.

## Animation

Use a reusable humanoid skeleton wherever practical. Retarget generic locomotion/emote animations. Baseball fundamentals form a shared custom library; archetypes may override them; signature stars may have unique animations. AnimationTree/state machines must not contain baseball rules.

## Performance

Prioritize input latency and stable ball/player motion. Crowd density, particles, reflections, secondary animation, signage, and attractions are scalable. No expensive per-spectator gameplay AI.

## AI

Separate tactical evaluation from personality weights. Shared baseball intelligence can produce different players/teams by weighting aggression, Show appetite, steal frequency, pitch selection, collision appetite, and risk tolerance.

## Testing

Automate pure logic: counts/outs, inning transitions, runner advancement, force/tag rules, stat recording, Show scoring, rivalry accumulation, trajectory math, intercept estimates, save migrations, and data validation. Visual tests are separate from rules tests.

## Multiplayer

Do not build online multiplayer into MVP. Preserve a clean authoritative match model so networking can be evaluated later rather than requiring a rewrite.

## Asset Strategy

The project is free/CC0-first, but free assets are raw material, not the art direction. Follow 12_ASSET_PIPELINE.md and record every third-party asset in 13_ASSET_MANIFEST.md. No third-party asset enters production without a known license and source.
