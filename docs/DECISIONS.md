# DECISIONS

## 2026-10-20 - Engine and Language

Decision: Godot 4.7.2 stable + GDScript for the initial PC build.

Reason: Strong fit for stylized 3D plus heavy UI, fast iteration, open-source tooling and manageable indie/agent-assisted development.

## 2026-10-20 - Authoritative Game State

Decision: The 3D scene is not authoritative game state.

Reason: Supports testability, AI, replays, simulation, save/load, franchise statistics, debugging and possible future networking.

## 2026-10-20 - Asset Strategy

Decision: Free/CC0-first. Free assets are raw material and must be normalized to the game's art direction.

Reason: Reduce cost/production burden without an asset-flip identity.

## 2026-10-20 - Asset Provenance

Decision: Every third-party production asset requires a source/license entry in 13_ASSET_MANIFEST.md.

Reason: "Free" does not guarantee commercial/redistribution rights; release provenance must be auditable.
