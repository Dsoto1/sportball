# MVP ROADMAP

## Baseline

Prototype in Godot 4.7.2 stable + GDScript. Use primitive/CC0 placeholders aggressively. Art acquisition must not block proof of baseball.

## Phase 0 - Foundation + Feel

Minimal Godot structure, semantic inputs, authoritative MatchState, tests/debug overlay and graybox field. Prototype pitch -> contact -> authoritative ball flight -> fielder intercept -> throw -> runner/base resolution -> reset.

Success: contact/defense are repeatedly fun and baseball logic runs without the stadium scene.

## Phase 1 - Baseball Vertical Slice

One graybox/modular stadium, two teams, inning/outs/count/bases, scoring, substitutions, basic AI and 6-inning exhibition. Use free/CC0 placeholders.

Success: complete matches without debug intervention; important outcomes are reproducible from logged state/seeds.

## Phase 2 - Identity

Canonical humanoid rig, import/retarget pipeline, polished core baseball animation set, team identity, broadcast HUD, impact animation, crowd audio and commentary hooks. Normalize free assets through the art pipeline.

Success: footage looks like this project, not an asset pack.

## Phase 3 - Show

Crowd state, Charisma, one Show modifier family, trick throws/catches, one collision interaction and clear risk/reward feedback.

Success: players intentionally choose safe versus spectacular actions.

## Phase 4 - Personality

Traits, archetypes, rivalries, signature celebrations and AI personality weights.

Success: similarly rated players feel meaningfully different.

## Phase 5 - Franchise Skeleton

Roster, calendar, training/rest, fame, sponsor objective, basic economy, season schedule and persistent history.

Success: a short season creates memorable emergent stories.

## Phase 6 - Content & Polish

More modular stadium identities, teams/players, events, career progression, accessibility, performance tiers, save migration, onboarding and final license audit.

## Cut Rules

Cut breadth before feel; stadium count before fielding responsiveness; event quantity before save reliability; cosmetics before readable animation. Use placeholders rather than delaying mechanics. Never hide weak baseball behind spectacle.

## Asset Milestones

Phase 0: primitives/disposable placeholders. Phase 1: readability assets only. Phase 2: prove canonical art/rig/material pipeline. Phase 3+: expand production assets after pipeline stability.
