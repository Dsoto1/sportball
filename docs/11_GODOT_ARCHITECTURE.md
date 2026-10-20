# GODOT ARCHITECTURE

## Purpose

Defines the initial Godot structure and boundaries. It is a starting architecture, not permission to over-engineer.

## Baseline

Use Godot 4.7.2 stable + GDScript. Commit project.godot. Do not move to preview/beta builds without a recorded project decision.

## Suggested Project Tree

```
res://
  app/           # bootstrap, session-level services
  baseball/      # match, pitch, contact, ball, fielding, runners, AI
  show/          # crowd, tricks, rivalries
  franchise/     # roster, calendar, economy, progression
  data/          # definitions/resources
  presentation/  # characters, stadiums, cameras, animation, VFX, audio
  ui/            # match, franchise, common, themes
  assets/        # runtime assets
  tests/         # unit and scenario tests
```

Do not create empty architecture for systems that do not exist yet.

## Prime Directive

The 3D scene is not the game state. MatchState is authoritative for inning/half, outs, count, score, bases, orders, active players, substitutions and rules. Scenes present that state.

## Pure/Testable Services

Prefer explicit-input/explicit-output GDScript services such as PitchResolver, ContactResolver, BallTrajectory, RunnerResolver, TagCollisionResolver, ShowResolver, and StatRecorder.

## Scenes

Favor composition:

- `MatchView.tscn`: presentation orchestration.
- `StadiumView.tscn`: field/environment.
- `PlayerActor.tscn`: visible character, animation, local effects/control adapter.
- `BallView.tscn`: visualizes authoritative trajectory.
- UI observes state/events and sends semantic player intents.

## Autoloads

Keep them few. Reasonable candidates: AppState, ContentDB, SaveService, and only if justified, a cross-domain EventBus. Never use autoloads as global dumping grounds.

## Input

Map physical controls to semantic actions: swing_contact, swing_power, pitch_primary, throw_base_2, show_modifier, runner_advance, runner_retreat.

## Events

Use local signals for presentation communication and explicit domain event/data objects for baseball facts. Avoid an uncontrolled global signal web.

## Character Rig

Standardize around one humanoid skeleton where practical. Variation comes from body/mesh proportions, head/hair/accessories, uniforms/materials and animation overrides.

## Ball Flight

Calculate authoritative trajectory from gameplay values. The visible ball follows it. Collision queries can resolve walls/catches/special stadium interactions, but uncontrolled rigid-body chaos must not silently decide competitive outcomes.

## AI

Separate tactical evaluation, personality weighting, and motor/presentation execution. AI should produce semantic intents comparable to human input where practical.

## UI

Use reusable Control scenes and a project Theme. Match and franchise UI share typography, iconography, focus/navigation and accessibility conventions.

## Debugging

Provide overlays for match state, trajectory, landing/intercept markers, fielder target/path, inputs, Show gain/loss reason, RNG seed and performance.

## Coding Conventions

- Typed GDScript for public APIs/data structures.
- Small scripts with clear responsibility.
- Composition over deep inheritance.
- Balance values live in data, not magic numbers.
- Stable IDs: `snake_case`; scene/node names: `PascalCase`; files: snake_case.

- Profile before optimizing.
- Record consequential rewrites in `DECISIONS.md`.

## Healthy Foundation Test

Baseball logic can run/test without loading a stadium; stadiums/meshes can change without altering rules; franchise mode consumes a match summary rather than reading scene nodes.
