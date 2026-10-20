# AGENT WORKING RULES

## Locked Foundation

Godot 4.7.2 stable; GDScript; Blender -> GLB/glTF -> Godot; authoritative simulation separate from 3D presentation; free/CC0-first assets with provenance tracking.

Do not migrate engine/language/version without explicit approval.

## Work Style

Read 00_AGENT_START_HERE.md and numbered docs. Work in small testable vertical increments. Preserve behavior unless asked to change it. Prefer simple known solutions. Keep balance values data-driven.

## Prototype Discipline

Do not build franchise breadth before baseball is fun. Use placeholders freely. A polished stadium is not progress if pitch/contact/fielding/baserunning are weak.

## Code

Typed GDScript where practical; readable names; composition over deep inheritance; semantic input actions; testable services for core calculations. Avoid giant managers, hidden globals, uncontrolled signal webs and magic numbers.

## Third-Party Assets

Find candidates via 14_ASSET_SOURCES.md, follow 12_ASSET_PIPELINE.md, and update 13_ASSET_MANIFEST.md before production use. Unknown license = do not use.

## Art Drift

Asset availability never redefines the art direction. Normalize proportions, materials, palette, animation language and performance.

## Decisions

Record consequential deviations in DECISIONS.md with date, decision, reason and affected systems.

## Done

A feature needs readable behavior, appropriate failure handling, no obvious regressions, and tests/debug instrumentation for important logic where practical.
