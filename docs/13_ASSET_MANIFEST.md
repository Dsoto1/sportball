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
| ACG-003 | Stadium surface kit: Bricks 085, Bricks 084, Concrete 034, Metal Plates 013, Planks 037A, Rock 051, Snow 004, Marble 012, Ground 054 | ambientCG | https://ambientcg.com/view?id=<id> (each `<id>_1K-JPG.zip`) | CC0 | No | none | park facades, stands, frames, piers, walls, mountains, ground (`StadiumSurfaces`) | Yes: Color converted to a normalized grayscale detail map (tinted by each park's palette at runtime) + NormalGL, both downscaled to 512 px | 2026-10-21 | in_use | `assets/third_party/ambientcg/<id>/`, LICENSE.txt each; 1.3 MB total |
| KEN-004 | Nature Kit 2.1 (subset: 18 models - palms, pines, cacti, oak, detailed, cone and fat trees, tall rocks, cliff, bush) | Kenney | https://kenney.nl/assets/nature-kit (kenney_nature-kit.zip) | CC0 | No (credit optional) | none | trees and rocks beyond the stands (`ModelKit`) | No (scaled and leaf-tinted at runtime) | 2026-10-21 | in_use | `assets/third_party/kenney/nature-kit/`, License.txt kept; 264 KB |
| KEN-005 | City Kit Commercial 2.1 (subset: 18 buildings + colormap texture) | Kenney | https://kenney.nl/assets/city-kit-commercial (kenney_city-kit-commercial_2.1.zip) | CC0 | No (credit optional) | none | the city around each park (`ModelKit`, skyline module) | No (scaled at runtime) | 2026-10-21 | in_use | `assets/third_party/kenney/city-kit-commercial/`, License.txt kept; 1.7 MB |
| AI-001 | Fielder's glove (3D, textured GLB, ~14k verts) | Generated with Artlist AI (Hyper3D Rodin v2.5 Fast), text-to-3D from our own prompt | Artlist AI Suite generation 01a15e9f-4035-75e7-acde-3cd9280afc44 | Artlist AI Suite terms (owner's subscription) - commercial-game use to be confirmed before release | Check Artlist terms | Check Artlist terms before release | glove on every fielder's glove hand | No (scaled and placed in `ActorView`) | 2026-10-21 | replaced | replaced by AI-002 (kept in git history) |
| AI-002 | Fielder's glove v2 (3D, textured GLB, ~16k verts) | Generated with Artlist AI (Hyper3D Rodin v2.5 Fast), image-to-3D | Artlist AI Suite generation 01a15ea6-77d3-765a-980d-19caef786ca2, from a reference photo the owner supplied (source and license unknown) | Artlist AI Suite terms (owner's subscription) - commercial-game use to be confirmed before release | Check Artlist terms | PROTOTYPE ONLY until the reference photo's source is cleared, or regenerate from a cleared reference | glove on every fielder's glove hand | No (scaled and placed in `ActorView`) | 2026-10-21 | in_use | `assets/generated/artlist/glove/glove.glb` |
| QUA-001 | Universal Base Characters [Standard]: male body (`Superhero_Male_FullBody`, eyes, eyebrows), Hair_Buzzed, Hair_Beard | Quaternius | https://quaternius.com/packs/universalbasecharacters.html → https://quaternius.itch.io/universal-base-characters (Universal Base Characters[Standard].zip, 129 MB) | CC0 (License_Standard.txt in pack, kept as License.txt) | No | none | every player's body, face, hair and beard; worn on the animation library's skeleton (same 65 bones) | Yes: body, normal and roughness textures downscaled 2048→1024 px and hair textures to 512 px; the light skin texture (`T_Superhero_Male_Ligh.png`, renamed `..._Light.png`) referenced in place of the dark one in the .gltf; at runtime the body is painted with the uniform shader (skin texture tinted per player) | 2026-10-21 (fetched from itch.io; the zip stays out of the repo) | in_use | `assets/third_party/quaternius/universal-base-characters/`, 4 MB |
| QUA-002 | Universal Animation Library [Standard] (Mannequin mesh + 43 animations, `UAL1_Standard.glb`, no root motion) | Quaternius | https://quaternius.com/packs/universalanimationlibrary.html → https://quaternius.itch.io/universal-animation-library (Universal Animation Library[Standard].zip) | CC0 (License.txt in pack) | No | none | skeleton and generic motion (its Mannequin mesh is now hidden under the base character): idle, crouch, jog, sprint, roll, fall, jab/cross (tag, throw), pistol-grip pose (batting grip), dance | Yes at runtime: team-color material overrides, 1.35×/1.12× arcade build, glove and bat attached to hand bones; file unmodified | 2026-10-21 (uploaded by owner) | in_use | `assets/third_party/quaternius/universal-animation-library/`, License.txt kept; 7.6 MB |

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
