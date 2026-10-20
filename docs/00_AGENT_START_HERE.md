# AGENT START HERE

## Mission

Build a stylized arcade baseball game where legitimate baseball skill, physical arcade interactions, sports-entertainment spectacle, player personality and long-term franchise storytelling reinforce one another.

Inspirations are creative shorthand only. Do not clone protected teams, characters, branding, art, rules text or assets.

## Read Order

1.  `01_GAME_VISION.md`
2.  `02_CORE_GAMEPLAY.md`
3.  `03_ART_DIRECTION.md`
4.  `04_SHOW_AND_PERSONALITY_SYSTEMS.md`
5.  `05_FRANCHISE_AND_PROGRESSION.md`
6.  `06_UI_UX.md`
7.  `07_TECHNICAL_SPEC.md`
8.  `08_CONTENT_AND_DATA.md`
9.  `09_MVP_ROADMAP.md`
10. `10_AGENT_WORKING_RULES.md`
11. `11_GODOT_ARCHITECTURE.md`
12. `12_ASSET_PIPELINE.md`
13. `13_ASSET_MANIFEST.md`
14. `DECISIONS.md`
15. `PHASE0_REPORT.md` (current state and weak spots)

Review `visual_reference_concept.png` (not yet in the repository) as directional mood reference, not literal final UI.

## Locked Starting Decisions

- Godot **4.7.2 stable**
- GDScript
- Blender -> GLB/glTF
- Windows PC first
- gamepad-first with keyboard/mouse support
- authoritative game state/simulation separate from 3D scene
- free/CC0-first assets with strict license/source tracking
- stylized retro-futurist sports anime + 1990s arcade exaggeration; not chibi, photorealistic, generic cyberpunk, Fortnite-like or generic mobile 3D

## First Assignment

Start Phase 0 only: minimal project foundation, semantic inputs, authoritative match state, graybox field, and the pitch -> contact -> ball flight -> fielding/intercept -> throw -> runner/base resolution -> reset loop. Add debug visualization and tests. Report weak feel before expanding scope.

## Core Rule

Spectacle amplifies baseball; it does not replace baseball.

## Anti-Drift

Do not turn this into an MLB realism simulator, generic fighting game, cyberpunk shooter aesthetic, management game with shallow field play, or pile of unrelated free assets.

Surface missing decisions that materially affect architecture, game feel, scope, licensing or art. For small reversible details, use the simplest conventional solution.
