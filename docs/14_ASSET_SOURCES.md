# ASSET SOURCES

## Purpose
This is the project's approved asset-discovery guide. It tells developers and agents **where to look first**, what each source is good for, and what licensing checks are required.

This file does not approve a specific asset. Every third-party production asset must still be recorded in `13_ASSET_MANIFEST.md` before use.

## Search Order

### Tier 1 — Primary Sources
Search these first because they combine useful content, clear licensing, and good compatibility with our Godot/Blender workflow.

#### 1. Quaternius
**Best for:** stylized characters, humanoid animation, city/environment kits, props, nature, sci-fi pieces, modular scenery.

**Especially relevant:**
- Universal Base Characters
- Universal Animation Library / Library 2
- Downtown City MegaKit
- Sci-Fi Essentials Kit
- Stylized Nature MegaKit
- general modular props/environment packs

**License rule:** Quaternius licensing changed in 2026. Current assets may use the Quaternius Asset License (QAL), while older pack pages/downloads may identify CC0. Record the license attached to the **exact downloaded pack/version**. QAL permits commercial use and modification without required credit, but prohibits redistributing/reselling the assets themselves as standalone assets.

**Use in this project:** character/rig prototypes, generic animation, stadium surroundings, city backdrops, show props, futuristic mechanical dressing.

#### 2. Kenney
**Best for:** UI, controller prompts, icons, generic props, prototype pieces, simple environment kits, audio.

**License expectation:** Kenney states that game assets on its asset pages are CC0 and may be used commercially without required attribution. Still record the exact pack/source in the manifest.

**Use in this project:** things the player should not care were custom-made—UI glyphs, barriers, generic furniture, background props, simple signs, utility objects and prototype art.

#### 3. KayKit / Kay Lousberg
**Best for:** stylized low-poly environments, characters, props and humanoid animations.

**Especially relevant:**
- Character Animations
- Adventurers as a rig/character-pipeline test
- Prototype Bits
- Platformer Pack for rails, barriers, signs, supports and general arcade-sports dressing
- City/environment packs when stylistically appropriate

**License expectation:** many free KayKit packs are explicitly CC0, commercial-use, no attribution required, and include FBX/glTF. Verify each exact pack.

**Use in this project:** secondary character/animation reference, generic stylized props, stadium/concourse dressing and prototype environments.

#### 4. Poly Haven
**Best for:** HDRIs, textures/materials and selected realistic 3D source assets.

**License expectation:** Poly Haven states all of its assets are CC0 and usable commercially without required attribution.

**Use in this project:** source material for concrete, painted metal, rubber, asphalt, fabric, dirt, wood and lighting/HDRI references. Most realistic assets should receive a stylization pass before production use.

#### 5. ambientCG
**Best for:** PBR surface materials and environmental textures.

**Use in this project:** source surfaces for stadium architecture, concourses, tunnels, dugouts and utility areas. Stylize/optimize before shipping.

**Rule:** verify the current license on the exact asset/source page and log it in the manifest.

#### 6. Adobe Mixamo
**Best for:** humanoid animation prototyping, generic movement, celebration, gesture and reaction animation; optional auto-rig experiments.

**License expectation:** Adobe states Mixamo characters and animations can be used royalty-free in personal, commercial and nonprofit projects, including video games. Mixamo is not CC0.

**Use in this project:** running, idles, cheering, taunting, dancing, falling, reactions and other generic motion. Retarget and modify rather than allowing Mixamo to define our animation style.

**Do not rely on it for:** final signature batting, pitching, fielding, catching, throwing, sliding or trick-play animation.

---

### Tier 2 — Gap-Filling Sources

#### itch.io Game Assets
**Best for:** highly specific props, UI, audio and niche packs.

**License:** creator-specific. "Free" does not mean CC0 or commercial-use. Require an explicit license before production use.

**Search strategy:** prefer packs explicitly marked CC0 or clearly allowing commercial use. Do not infer rights from a zero-dollar price.

#### OpenGameArt
**Best for:** SFX, music, UI, textures and unusual miscellaneous content.

**License:** mixed. OpenGameArt supports multiple licenses with different obligations. Prefer CC0 for this project. Attribution/share-alike/GPL-style assets require deliberate review before use.

#### Poly Pizza
**Best for:** finding an individual low-poly prop when primary libraries have a gap.

**License:** verify per asset. Treat as mixed-license until the exact asset proves otherwise.

---

### Tier 3 — Last Resort

#### Sketchfab
Use only when the primary and gap-filling sources fail.

**Why:** enormous selection but inconsistent style and asset-by-asset licensing/provenance. Require explicit downloadable rights, commercial compatibility, creator/source record and manifest approval before import.

Do not use ripped franchise content, fan recreations of protected teams/players/stadiums, or uploads with questionable provenance even when downloadable.

---

## What We Should Reuse

Actively seek free assets for:
- generic chairs, benches and tables
- trash cans and utility props
- railings, stairs and barriers
- generic lights and speakers
- lockers and cabinets
- concession/background props
- generic city/background buildings
- crowd base meshes
- generic locomotion and emotes
- UI/controller icons
- basic surface materials
- non-signature ambient SFX

## What Should Become Ours

Prioritize custom creation or substantial modification for:
- player body archetypes and faces
- uniforms and team branding
- baseball gloves and catcher gear
- bats and signature equipment
- futuristic baseball technology
- mascots
- signature stadium landmarks
- championship trophies
- Show/trick-play equipment
- superstar accessories
- batting, pitching and core fielding animation
- signature celebrations
- primary gameplay UI visual identity

## Baseball-Specific Search Checklist

Before custom-building a non-signature asset, search approved sources for:
- bat/baseball/ball-like prototype props
- gloves or hand-prop bases
- sports barriers and rails
- stadium/arena seating
- scoreboards/video screens
- floodlights/light towers
- PA speakers
- cameras/media equipment
- dugout/bench furniture
- lockers
- concessions
- flags/banners
- crowd characters
- city skyline/background modules
- industrial/mechanical sci-fi props
- celebration/emote animations
- running/jumping/falling/reaction animations

A found baseball-specific asset is **not automatically desirable**. If its style is wrong, a generic clean base that we can modify may be better.

## Agent Discovery Workflow

1. Define the asset need and whether the player will notice it.
2. Check this document.
3. Search Tier 1 in the most relevant order.
4. If no good candidate exists, search Tier 2.
5. Use Tier 3 only for genuine gaps.
6. Verify the exact license and provenance.
7. Add the candidate to `13_ASSET_MANIFEST.md`.
8. Download/import only after it passes the license check.
9. Normalize it according to `12_ASSET_PIPELINE.md`.
10. Replace it later if it weakens the art direction.

## Selection Score

When comparing free candidates, evaluate:
- license confidence
- style fit
- topology/rig quality
- Godot/Blender format compatibility
- ease of modification
- performance cost
- texture/material consistency
- animation-retargeting compatibility
- uniqueness/provenance risk

Choose the asset that reduces **total production work**, not merely the one that is fastest to download.

## Source-of-Truth Rule

Websites, licenses and asset catalogs can change. `14_ASSET_SOURCES.md` is discovery guidance, while `13_ASSET_MANIFEST.md` records what we actually obtained and under what terms. For every downloaded production asset, preserve the exact source and license evidence applicable at download time.
