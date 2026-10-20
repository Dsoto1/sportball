# ASSET PIPELINE

## Principle

Free/CC0-first. Build custom only where custom creates identity. External assets are construction material, not the art direction.

## License Priority

1. **CC0/public-domain-equivalent:** preferred.
2. **Permissive commercial:** allowed after manifest review.
3. **Attribution-required:** selective; obligations recorded before import.
4. **Unknown, noncommercial, editorial-only, restricted, ripped, or provenance-unclear:** do not use.

"Free to download" is not a license.

## Candidate Sources

Search sources in the order given by `14_ASSET_SOURCES.md` (Tier 1: Quaternius, Kenney, KayKit, Poly Haven, ambientCG, Mixamo; Tier 2: itch.io, OpenGameArt, Poly Pizza; Tier 3: Sketchfab). That guide also lists what to reuse versus make our own. It is not blanket approval; verify each exact asset/pack.

## Mandatory Intake

Before production use:

1. Add the asset to `13_ASSET_MANIFEST.md`.
2. Record exact source and creator.
3. Record license and attribution requirements.
4. Preserve license evidence where practical.
5. Record original filename/version/download date.
6. Note redistribution restrictions.
7. Record intended use and modification status.

Unknown provenance means do not use.

## Blender -> Godot

Normalize to meters; use consistent axes; apply transforms when appropriate; remove unused objects; set sensible pivots; use predictable names; export production models primarily as .glb; keep editable .blend sources separate from runtime exports where practical.

## Characters

Use a canonical humanoid skeleton where practical. Free bases may be reshaped, but final characters follow the project: athletic/exaggerated, roughly 5--6 heads tall, strong archetype silhouettes, oversized readable hands/gloves/equipment, expressive heads/faces.

## Animation Tiers

- **Generic:** locomotion/idles/emotes; free/retargeted encouraged.
- **Baseball fundamentals:** shared polished batting/pitching/throwing/catching/fielding/sliding library.
- **Archetype:** power hitter, speedster, showboat, enforcer variants.
- **Signature:** unique stars/rivals/celebrations.

Test retargeting for foot sliding, prop alignment, shoulders, glove/bat attachments and extreme body types.

## Stadiums

Build modularly: field, walls, dugouts, seating, concourses, rails, stairs, tunnels, lights, screens, signage mounts, attractions, stages/show elements and crowd zones. Do not import a free stadium wholesale and call it a finished venue.

## Visual Normalization

Normalize scale, texel density, roughness/metallic response, saturation/value, stylized shading/outline treatment, material naming, shadows and LOD. Avoid accidental mixing of photoreal PBR and flat-cartoon assets.

## Textures

Prefer reusable palettes, trim sheets, masks and material variants. Avoid unnecessary 4K/8K textures.

## Crowds

Close = low-poly animated; middle = simplified/shared animation; far = impostors/billboards. Drive crowd reaction collectively from Show/game events; no gameplay AI per spectator.

## Audio

Free audio follows the same manifest/license rules. Layer/process generic sources into distinctive project sounds. No copyrighted commercial music without separate rights.

## Asset-Flip Test

Before production approval ask: does silhouette, material response, scale, animation language, palette and performance fit this game? If not, modify or replace.

## Agent Rule

Agents may recommend candidate assets but may not silently introduce third-party production content. Every external production asset must be traceable in the manifest.
