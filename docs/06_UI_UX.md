# UI / UX

## Principle

The interface is sports broadcast + arcade cabinet, not a sci-fi dashboard. Baseball state must be understood at a glance.

## Gameplay HUD Priority

1. Score / inning / outs
2. Base occupancy
3. Count
4. Controlled player / pitcher-batter matchup
5. Context action / timing feedback
6. Crowd/Show state
7. Temporary rivalry or trait callouts

Do not let Show systems obscure baseball information.

## Input

Design controller-first with keyboard parity. Use consistent verbs across batting, fielding, and running. Context prompts should be short and appear only when actionable.

## Camera

Pitch/bat camera emphasizes timing and pitch readability. Ball-in-play camera prioritizes routes, bases, and throws. Cinematic cuts are brief and reserved for impact moments; user control returns quickly.

## Feedback

Use layered feedback: animation first, sound second, UI confirmation third. Avoid filling the screen with numbers. Impact callouts such as CRUSHED, DENIED, SHOWTIME, BAD BLOOD should be rare enough to remain exciting.

## Franchise UI

Card/roster-forward layouts with strong portraits and team identity. Important state should be visible without opening nested menus. Events should present a clear situation, consequences, and decision.

## Accessibility

Remappable controls, subtitle support, scalable HUD, color-independent base/target indicators, reduced camera shake, reduced flashes, timing-assist options, difficulty assists, and text alternatives for icon-only states.

## UX Performance Budget

Transitions should feel immediate. Avoid menu animations that delay input. The game should remain pleasant on modest hardware; presentation can scale independently of simulation.
