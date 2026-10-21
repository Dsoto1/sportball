# Batting Style Animation Reference Specification

## Purpose

This document replaces the earlier prompt-only batting reference sheet.
It is intended to guide animation, rigging, pose-reference generation,
and implementation of six distinct right-handed batting styles:

1.  Classic
2.  Crouch
3.  Open
4.  Leg Kick
5.  Bat Wrap
6.  Slap

Left-handed versions should be mirrored in code rather than authored
separately.

The primary goal is not to copy any real player. Real MLB/Statcast
examples are used only as biomechanical anchors so the fictional game
animations remain recognizable, plausible, and mechanically consistent.

------------------------------------------------------------------------

# 1. Core Animation Sequence

Each style uses five authored key poses:

1.  **STANCE** --- settled starting position.
2.  **LOAD** --- rear-side gather, coil, and hand preparation.
3.  **FOOT PLANT** --- lead foot has completed its stride and is
    planted; hands remain back and rotation has not yet fully released.
4.  **CONTACT** --- representative ball-contact position.
5.  **FINISH** --- deceleration/follow-through after contact.

The actual stride occurs between LOAD and FOOT PLANT.

These are not five unrelated poses. They are keyframes sampled from one
continuous kinetic chain.

------------------------------------------------------------------------

# 2. Locked World-Space Rules

These rules apply to every style and every reference image.

## Home Plate and Batter's Box

-   Home plate is static world geometry.
-   Batter's-box lines are static world geometry.
-   Neither may move, rotate, resize, or recenter between poses.
-   The batter remains in the same batter's box for the entire swing.
-   No foot may occupy or cross through home-plate geometry.
-   The lead foot moves primarily along the pitcher axis during the
    stride, not laterally across home plate.
-   The rear foot remains substantially anchored through LOAD, then
    pivots during rotation.
-   A style may alter stride length and stance width, but not the
    underlying world coordinate system.

## Suggested Local Coordinate Convention

Use the batter's root at STANCE as the local origin.

-   **+Forward:** toward pitcher
-   **-Forward:** toward catcher
-   **+Plate:** toward home plate
-   **-Plate:** away from home plate
-   **+Up:** vertical

Exact engine axes may differ; preserve the semantic directions.

## Root Motion

Root motion should be conservative.

The batter may gather rearward slightly during LOAD and advance modestly
toward the pitcher during the stride, but should never appear to walk
across the plate or drift substantially out of the box.

------------------------------------------------------------------------

# 3. Character and Rig Constraints

## Anatomy

-   Use one consistent athletic adult male rig.
-   Maintain realistic shoulder, elbow, wrist, hip, knee, and ankle
    articulation.
-   Do not compensate for bat placement by breaking wrist or elbow
    anatomy.
-   Preserve believable balance and center of mass.
-   The head should remain relatively stable through the hitting zone.
-   Avoid unnecessary vertical bobbing unless the batting style
    specifically calls for it.

## Hands

Unless a style explicitly calls for a release after contact:

-   Both hands remain on the same bat handle.
-   Hands remain physically connected to the handle.
-   Hands must not merge, duplicate, disappear, or exchange positions.
-   The grip relationship should remain continuous from pose to pose.

## Bat

-   One rigid bat of constant length.
-   No bending or changing scale.
-   No floating.
-   No passing through the torso, helmet, or arms.
-   Bat movement between keyframes must describe a plausible continuous
    arc.
-   Barrel orientation at CONTACT is determined by pitch/contact intent,
    not by visual convenience.

------------------------------------------------------------------------

# 4. Camera Reference Standard

Each style should ultimately have three reference presentations.

## A. Primary Batter View

Full-body view suitable for reading the stance, hands, bat, knees,
stride, and finish.

Use one fixed camera for all five poses.

## B. Catcher / Rear View

Camera positioned directly behind the catcher looking toward the
pitcher.

Requirements:

-   Fixed camera.
-   Fixed home plate.
-   Fixed batter's box.
-   Pitcher direction remains centered.
-   Right-handed batter occupies the appropriate batter's box and does
    not migrate across home plate.
-   This view is especially important for hand depth, plate distance,
    stride direction, hip rotation, and attack direction.

## C. Top-Down Foot Placement Diagram

A simplified technical diagram is preferred over AI-generated imagery.

Show:

-   home plate;
-   batter's box;
-   STANCE foot locations;
-   LOAD foot locations;
-   FOOT PLANT locations;
-   CONTACT locations;
-   FINISH locations;
-   lead-foot travel arrow;
-   rear-foot pivot;
-   pitcher direction.

The top-down diagram is the authority when an artistic reference
conflicts with foot placement.

------------------------------------------------------------------------

# 5. Swing Metrics Vocabulary

MLB Statcast introduced useful terminology for describing bat movement.
These terms should be used as descriptors, not as rigid requirements for
every game animation.

## Swing Path / Tilt

Vertical tilt of the bat's path approaching contact.

-   Lower value = flatter swing.
-   Higher value = steeper swing.

MLB reported a 2025 Major League average around **32 degrees**, with
seasonal examples ranging from the low 20s to the mid/high 40s.

## Attack Angle

Vertical direction of the barrel at the instant of contact.

-   Low attack angle = flatter contact trajectory.
-   High attack angle = more upward barrel movement at contact.

This is distinct from overall swing-path tilt.

## Attack Direction

Horizontal direction of the barrel at contact.

-   Neutral is approximately straight through the middle.
-   Pull-oriented attack direction moves more toward the pull field.
-   Opposite-field attack direction moves more toward the opposite
    field.

This is especially useful for distinguishing the SLAP style from
power-oriented styles.

------------------------------------------------------------------------

# 6. Style Specifications

## 6.1 CLASSIC

**Identity:** Balanced, textbook, neutral baseline.

### STANCE

-   Feet slightly wider than shoulders.
-   Moderate knee flex.
-   Slight forward hinge from hips.
-   Weight approximately even.
-   Hands together near rear shoulder/chin height.
-   Bat angled upward and rearward.
-   Head oriented toward pitcher.

### LOAD

-   Small shift into rear hip.
-   Slight pelvic and torso coil.
-   Hands move rearward only modestly.
-   Lead heel may unweight or lift slightly.
-   Head remains controlled.

### FOOT PLANT

-   Short controlled stride toward pitcher.
-   Lead foot plants inside original batter's box.
-   Hands remain back.
-   Hips have not fully fired.
-   Stable base established.

### CONTACT

-   Hips open strongly.
-   Rear heel rises as rear foot pivots.
-   Torso follows hips.
-   Arms extend naturally without locking.
-   Head remains near original visual level.
-   Neutral-to-moderate upward attack.

### FINISH

-   Chest rotated toward pitcher.
-   Two-hand high finish.
-   Rear foot on toe/pivot.
-   Balanced enough to hold pose without falling across plate.

### Mechanical Character

Use this as the neutral comparison style for all others.

Suggested game target: - moderate swing-path tilt; - moderate attack
angle; - approximately neutral attack direction; - moderate stride; -
moderate root movement.

------------------------------------------------------------------------

## 6.2 CROUCH

**Identity:** Deep, wide, low power base.

### STANCE

-   Significantly wider than Classic.
-   Deep knee bend.
-   Lower pelvis and center of mass.
-   Chest leaned farther forward.
-   Hands lower near rear armpit/shoulder.
-   Bat somewhat flatter than Classic.

### LOAD

-   Gather deeper into rear hip rather than standing upward.
-   Small shoulder coil.
-   Hands move rearward.
-   Maintain low head height.

### FOOT PLANT

-   Low, controlled stride toward pitcher.
-   Wider final base than Classic.
-   Avoid rising substantially during stride.
-   Front side braces while maintaining flexion.

### CONTACT

-   Strong pelvic rotation from low base.
-   Rear knee drives inward.
-   Head remains comparatively low and stable.
-   Bat travels through zone without exaggerated upper-body lift.

### FINISH

-   Finish remains visibly lower than Classic.
-   Two hands retained.
-   Rotation completes without the body standing completely upright.

### Mechanical Character

Primary visual difference should come from body height, stance width,
and rotational base---not from an implausibly extreme bat path.

------------------------------------------------------------------------

## 6.3 OPEN

**Identity:** Open starting geometry that closes toward a more neutral
hitting position.

### STANCE

-   Lead foot begins farther away from plate.
-   Lead toes turned somewhat toward pitcher.
-   Chest is more visible to pitcher.
-   Hands high near rear ear.
-   Bat relatively upright.

### LOAD

-   Lead foot unweights.
-   Lead knee/foot begins moving inward toward neutral alignment.
-   Torso coils while maintaining visual access to pitcher.

### FOOT PLANT

-   Lead foot lands closer to a conventional alignment.
-   The style should visibly transition from OPEN at stance to
    substantially less open at plant.
-   Hands remain back.

### CONTACT

-   Hips rotate through.
-   Lead leg stabilizes.
-   Bat travels through a conventional hitting zone.
-   Do not preserve the exaggerated open stance all the way through
    contact.

### FINISH

-   High two-hand finish.
-   Balanced final position.

### Mechanical Character

The defining animation is the change in foot/pelvis geometry between
STANCE and FOOT PLANT.

------------------------------------------------------------------------

## 6.4 LEG KICK

**Identity:** Large timing gather and explosive forward move.

### STANCE

-   Taller and more upright than Classic.
-   Hands high.
-   Bat more upright.
-   Stable rear-side posture.

### LOAD

-   Lead knee lifts prominently.
-   Thigh may approach horizontal.
-   Center of mass gathers over rear leg.
-   Rear hip accepts the load.
-   Hands and barrel move back/up.
-   Shoulders coil strongly.

IMPORTANT: the player should balance over the rear leg, not drift toward
home plate.

### FOOT PLANT

-   Lead leg drives forward toward pitcher.
-   Longer stride than Classic.
-   Foot plants firmly inside batter's box.
-   Hands remain back at plant.
-   Body should appear stretched between planted front side and loaded
    hands.

### CONTACT

-   Explosive hip rotation.
-   Strong rear-foot pivot.
-   Front leg braces.
-   Arms accelerate into extension.
-   Head remains controlled despite larger lower-body action.

### FINISH

-   Large rotational finish.
-   Chest may rotate somewhat beyond pitcher-facing.
-   High finish.
-   Maintain balance; do not allow momentum to carry feet across home
    plate.

### Mechanical Character

Largest vertical lead-leg action and longest stride of the six styles.

The leg kick is a timing mechanism, not a jump.

------------------------------------------------------------------------

## 6.5 BAT WRAP

**Identity:** Power-oriented upper-body setup with barrel wrapped behind
head.

### STANCE

-   Hands high beside rear ear.
-   Rear elbow elevated.
-   Barrel points substantially behind helmet.
-   Bat appears more horizontally wrapped than Classic.

### LOAD

-   Hands move slightly farther back/up.
-   Barrel wraps/tips farther behind head.
-   Lower body remains controlled.

### FOOT PLANT

-   Medium stride.
-   Hands remain back.
-   Wrapped barrel position is still visually recognizable at plant.

### CONTACT

-   Barrel unwinds around from wrapped position.
-   Hands stay connected to body until release into hitting zone.
-   Avoid casting the hands far away from torso too early.
-   Arms extend through contact.

### FINISH

-   One-hand release is allowed only AFTER contact.
-   Top hand may release.
-   Bottom hand carries bat through high finish.
-   Do not show a one-handed grip in LOAD, FOOT PLANT, or CONTACT.

### Mechanical Character

The defining difference is hand/barrel geometry and a visibly longer
barrel journey---not excessive root movement.

------------------------------------------------------------------------

## 6.6 SLAP

**Identity:** Compact contact swing emphasizing speed to the ball and
opposite-field capability.

### STANCE

-   Narrower stance.
-   Slight crouch.
-   Hands choked several inches up handle.
-   Visible gap between knob and bottom hand.
-   Hands lower and slightly farther forward than Classic.
-   Bat moderately angled.

### LOAD

-   Minimal rearward movement.
-   Small inward turn of lead knee.
-   Slight hand gather.
-   Avoid large coil.

### FOOT PLANT

-   Very short, quick stride.
-   Minimal root displacement.
-   Hands remain compact.

### CONTACT

-   Short direct hand path.
-   Restrained torso opening compared with power styles.
-   Flatter contact geometry.
-   Capable of an opposite-field-oriented attack direction.
-   Body may already show intent to exit toward first base, but feet
    must remain mechanically plausible at the instant of contact.

### FINISH

-   Compact finish.
-   Both hands remain on bat.
-   Arms finish more forward than wrapped around body.
-   Body can begin transitioning out of the box only after the hitting
    action is complete.

### Mechanical Character

Shortest and most compact of the six.

MLB's Brice Turang is a useful biomechanical reference for the concept
of a short, compact, opposite-field-oriented swing, but this animation
should not reproduce his likeness or exact swing.

------------------------------------------------------------------------

# 7. Relative Style Matrix

  -------------------------------------------------------------------------------------------------
  Style     Stance       Stance   Stride         Load       Rotation     Bat Setup        Finish
            Height       Width                                                            
  --------- ------------ -------- -------------- ---------- ------------ ---------------- ---------
  Classic   Medium       Medium   Short/Medium   Medium     Medium       Neutral          High
                                                                                          2-hand

  Crouch    Low          Wide     Medium         Deep/Low   Strong       Lower/Flatter    Low
                                                                                          2-hand

  Open      Medium       Open     Short          Medium     Medium       High/Upright     High
                                                                                          2-hand

  Leg Kick  Tall         Medium   Long           Very Large Explosive    High/Upright     Large
                                                                                          2-hand

  Bat Wrap  Medium       Medium   Medium         Medium     Strong       Wrapped          High
                                                                                          1-hand
                                                                                          release

  Slap      Medium-Low   Narrow   Very Short     Minimal    Restrained   Compact/Choked   Compact
                                                                                          2-hand
  -------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 8. Reference Image Generation Workflow

Do NOT generate all styles in one image.

Do NOT rely on a single generated five-pose sheet as animation truth.

## Per Style

Generate or author poses sequentially:

1.  STANCE
2.  LOAD
3.  FOOT PLANT
4.  CONTACT
5.  FINISH

Approve each before proceeding.

Use the preceding approved pose as a visual continuity reference
whenever the tool supports it.

## Locked Elements

Every generated frame must preserve:

-   same character;
-   same body proportions;
-   same uniform;
-   same bat dimensions;
-   same camera;
-   same focal length/perspective;
-   same home plate;
-   same batter's box;
-   same image dimensions;
-   same ground plane;
-   same lighting.

## Pose Prompt Constraint Block

Append this concept to pose-generation prompts:

> Treat this as another animation keyframe of the exact same rigged
> character in the exact same fixed scene. Home plate and the batter's
> box are locked world-space geometry and may not move. The batter
> remains inside the same batter's box. The lead foot travels toward the
> pitcher rather than across home plate. Preserve anatomically valid
> shoulders, elbows, wrists, hips, knees and ankles. Both hands remain
> physically wrapped around the same rigid bat handle unless this
> specific keyframe explicitly occurs after an approved one-hand
> release. The bat cannot bend, resize, float, duplicate, or intersect
> the body.

## Assembly

Only after individual poses are approved should they be composited into:

-   Primary five-pose sheet;
-   Catcher/rear five-pose sheet;
-   Top-down foot-placement diagram.

The final sheet is a presentation artifact. The approved individual
poses and technical foot diagram are the animation references.

------------------------------------------------------------------------

# 9. Animation QA Checklist

Before accepting an animation or pose sheet:

### World

-   [ ] Home plate stays fixed.
-   [ ] Batter's box stays fixed.
-   [ ] Camera stays fixed.
-   [ ] Batter remains in correct box.
-   [ ] No foot crosses home plate.

### Feet / Lower Body

-   [ ] Rear foot remains substantially anchored through load.
-   [ ] Lead-foot stride is primarily pitcher-ward.
-   [ ] Foot plant matches style.
-   [ ] Rear foot pivots naturally during rotation.
-   [ ] Finish remains balanced.

### Upper Body

-   [ ] Pelvis begins rotation before/with torso appropriately.
-   [ ] Shoulders remain anatomically plausible.
-   [ ] Elbows bend naturally.
-   [ ] Wrists are not broken to force bat orientation.
-   [ ] Head remains reasonably stable.

### Bat / Hands

-   [ ] One bat only.
-   [ ] Constant bat length.
-   [ ] Both hands contact handle where required.
-   [ ] Grip continuity makes sense between frames.
-   [ ] Bat does not intersect body.
-   [ ] Contact pose follows intended swing style.

### Continuity

-   [ ] Every pose looks like the same character.
-   [ ] LOAD can plausibly transition into FOOT PLANT.
-   [ ] FOOT PLANT can plausibly transition into CONTACT.
-   [ ] CONTACT can plausibly transition into FINISH.
-   [ ] No unexplained teleporting of feet, hands, bat, or root.

------------------------------------------------------------------------

# 10. MLB / Statcast Research Notes

These values are reference anchors, not mandatory game-animation
targets.

MLB's 2025 Statcast swing metrics distinguish:

-   **Swing Path (Tilt):** vertical shape of the bat path approaching
    contact.
-   **Attack Angle:** vertical barrel direction at contact.
-   **Attack Direction:** horizontal barrel direction at contact.

Examples reported by MLB for 2025 included:

-   Riley Greene: 46° swing path (steep extreme).
-   Yandy Díaz: 24° swing path (flat extreme in the cited article).
-   Eugenio Suárez: 20° attack angle (high extreme).
-   Vladimir Guerrero Jr.: 1° attack angle (low extreme).
-   Isaac Paredes: 15° pull-oriented attack direction.
-   Brice Turang: 11° opposite-field-oriented attack direction.

MLB also reported a Major League average swing-path tilt around 32° and
a slightly pull-oriented average attack direction around 2°.

These metrics describe different properties and should not be collapsed
into one generic "swing angle."

## Research Sources

-   MLB --- *The hitters with MLB's most extreme swings* (May 20, 2025)
-   MLB --- *4 new swing metrics tell us more than we've ever known
    about contact* (May 20, 2025)
-   Baseball Savant --- Swing Path / Attack Angle leaderboard

------------------------------------------------------------------------

# 11. Implementation Principle

The six animations should read differently even when shown only as
silhouettes.

Do not create six versions of the same swing with one exaggerated pose
changed.

Each style should have a recognizable motion signature:

-   **CLASSIC:** balance and neutrality.
-   **CROUCH:** low center of mass and wide rotational base.
-   **OPEN:** visible closing move from open stance to plant.
-   **LEG KICK:** pronounced gather and long controlled stride.
-   **BAT WRAP:** distinctive hands/barrel load and longer barrel
    journey.
-   **SLAP:** minimal gather, short stride, compact directional swing.

Gameplay animation can exaggerate these signatures modestly for
readability, but exaggeration must preserve plausible baseball mechanics
and the locked spatial rules above.
