# ASSET MANIFEST

Authoritative third-party asset ledger. No third-party production asset should ship without an entry here.

## Status

candidate / approved / in_use / replaced / rejected

## License Classes

CC0 / permissive-commercial / attribution-required / restricted-do-not-use / unknown-do-not-use

## Asset Ledger

| ID | Asset / Pack | Creator | Exact Source | License | Attribution? | Redistribution Notes | Intended Use | Modified? | Download Date | Status | Notes |
|----|--------------|---------|--------------|---------|--------------|----------------------|--------------|-----------|---------------|--------|-------|
| KEN-001 | Impact Sounds 1.0 (subset: punch, wood, soft, plate, grass footsteps) | Kenney | https://kenney.nl/assets/impact-sounds (kenney_impact-sounds.zip) | CC0 | No (credit optional) | none | glove pops, bat layer, ball landing, bag touches, runner steps | No (selected files only) | 2026-10-21 | in_use | `assets/third_party/kenney/impact-sounds/`, License.txt kept |
| KEN-002 | Interface Sounds (subset: click, confirmation, error, select, switch, tick, toggle, drop, bong) | Kenney | https://kenney.nl/assets/interface-sounds (kenney_interface-sounds.zip) | CC0 | No (credit optional) | none | menus, pitch select, callouts | No (selected files only) | 2026-10-21 | in_use | `assets/third_party/kenney/interface-sounds/`, License.txt kept |
| KEN-003 | Input Prompts 1.5 (icon fonts: Keyboard & Mouse, Xbox Series) | Kenney | https://kenney.nl/assets/input-prompts (kenney_input-prompts_1.5.zip) | CC0 | No (credit optional) | none | on-screen control prompts | Renamed file (`&` removed) | 2026-10-21 | in_use | `assets/third_party/kenney/input-prompts/`, glyph maps + License.txt kept |
| ACG-001 | Grass 004 | ambientCG | https://ambientcg.com/view?id=Grass004 (Grass004_1K-JPG.zip) | CC0 | No | none | outfield/infield grass detail under project palette | Yes: Color + NormalGL downscaled to 512 px | 2026-10-21 | in_use | `assets/third_party/ambientcg/Grass004/` |
| ACG-002 | Ground 037 | ambientCG | https://ambientcg.com/view?id=Ground037 (Ground037_1K-JPG.zip) | CC0 | No | none | infield dirt detail under project palette | Yes: Color + NormalGL downscaled to 512 px | 2026-10-21 | in_use | `assets/third_party/ambientcg/Ground037/` |
| FNT-001 | Bungee Regular | David Jonathan Ross / The Bungee Project Authors | https://github.com/google/fonts/tree/main/ofl/bungee | SIL OFL 1.1 | No (license file must ship) | may bundle; may not sell the font by itself; Reserved Font Name rules on modified versions | HUD headlines and callouts | No | 2026-10-21 | in_use | `assets/third_party/fonts/bungee/`, OFL.txt kept |
| FNT-002 | Rajdhani SemiBold + Bold | Indian Type Foundry | https://github.com/google/fonts/tree/main/ofl/rajdhani | SIL OFL 1.1 | No (license file must ship) | as FNT-001 | scoreboard and body text (HUD text now FNT-003) | No | 2026-10-21 | replaced | `assets/third_party/fonts/rajdhani/`, OFL.txt kept |
| FNT-003 | M PLUS 1 (variable; used at weight 700) | The M+ FONTS Project Authors | https://github.com/google/fonts/tree/main/ofl/mplus1 | SIL OFL 1.1 | No (license file must ship) | as FNT-001 | HUD text and menus (free stand-in for the commercial FOT-Rodin used by Wii-era menus; Rodin itself is not bundled) | No (weight set via `ui/fonts/menu_font.tres`) | 2026-10-21 | in_use | `assets/third_party/fonts/mplus1/`, OFL.txt kept |
| QUA-001 | Universal Base Characters [Standard] (2 base models, 5 hairstyles) | Quaternius | https://quaternius.com/packs/universalbasecharacters.html → https://quaternius.itch.io/universal-base-characters | CC0 (stated on pack page and itch "Asset license") | No | none | player bodies (future) | — | — | approved | Owner approved 2026-10-21; not downloaded (122 MB, too big to upload). The animation library's mannequin covers this pass |
| QUA-002 | Universal Animation Library [Standard] (Mannequin mesh + 43 animations, `UAL1_Standard.glb`, no root motion) | Quaternius | https://quaternius.com/packs/universalanimationlibrary.html → https://quaternius.itch.io/universal-animation-library (Universal Animation Library[Standard].zip) | CC0 (License.txt in pack) | No | none | player bodies and generic motion: idle, crouch, jog, sprint, roll, fall, jab/cross (tag, throw), pistol-grip pose (batting grip), dance | Yes at runtime: team-color material overrides, 1.35×/1.12× arcade build, glove and bat attached to hand bones; file unmodified | 2026-10-21 (uploaded by owner) | in_use | `assets/third_party/quaternius/universal-animation-library/`, License.txt kept; 7.6 MB |

Phases 0 and 1 used no third-party assets. The first art pass (2026-10-21) adds the rows above; team names, uniforms and colors remain original. Binary assets are plain git objects (this remote rejects Git LFS pushes), so keep each pack small.

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
