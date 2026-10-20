# ASSET MANIFEST

Authoritative third-party asset ledger. No third-party production asset should ship without an entry here.

## Status

candidate / approved / in_use / replaced / rejected

## License Classes

CC0 / permissive-commercial / attribution-required / restricted-do-not-use / unknown-do-not-use

## Asset Ledger

| ID | Asset / Pack | Creator | Exact Source | License | Attribution? | Redistribution Notes | Intended Use | Modified? | Download Date | Status | Notes |
|----|--------------|---------|--------------|---------|--------------|----------------------|--------------|-----------|---------------|--------|-------|
| EXAMPLE-001 | Example | Example | exact source URL | CC0 | No | verify package terms | prototype prop | Yes | YYYY-MM-DD | candidate | Example only — delete when real assets are logged |

Phase 0 uses **no third-party assets**. All geometry is Godot primitive meshes generated in code; no textures, audio or fonts beyond the engine default are shipped.

## Candidate Source Register

Discovery order, rationale and reuse-versus-custom rules live in `14_ASSET_SOURCES.md`. This table is the quick license reference.

| Tier | Source | Typical Use | Requirement |
|------|--------|-------------|-------------|
| 1 | Quaternius | characters, animation, environments, props | record the license of the exact pack/version: CC0 (older) or Quaternius Asset License (2026+; commercial OK, no standalone redistribution) |
| 1 | Kenney | UI, controller prompts, icons, props, audio | CC0 per asset page; record exact pack |
| 1 | KayKit / Kay Lousberg | stylized props, environments, characters, animation | many packs CC0; verify each exact pack |
| 1 | Poly Haven | HDRIs, textures, source models | CC0; record exact asset; stylize before production |
| 1 | ambientCG | PBR surfaces | verify current license on the exact asset page |
| 1 | Adobe Mixamo | generic humanoid animation, auto-rig tests | royalty-free (not CC0); never final signature baseball animation |
| 2 | itch.io | niche props, UI, audio | creator-specific; explicit commercial license required |
| 2 | OpenGameArt | SFX, music, UI, textures | mixed; prefer CC0; attribution/share-alike/GPL need deliberate review |
| 2 | Poly Pizza | single low-poly props | mixed; verify per asset |
| 3 | Sketchfab | genuine gaps only | explicit downloadable commercial rights and provenance; no franchise rips or fan recreations |
| — | Godot official demos/assets | reference/example content | verify exact redistribution/license |

## Required Evidence

For every approved asset be able to answer: source, creator, license at download, attribution, redistribution rights, where used, and modifications.

## Release Gate

Review every in_use entry; remove unresolved/unknown items; generate required credits; verify redistribution terms; ensure replaced assets are not shipped.
