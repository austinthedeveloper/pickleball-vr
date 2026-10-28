# ADR-021: Passthrough: the court in your room

**Status:** Accepted (2026-10-28)

## Context

The lead asked: "If possible, can we support passthrough? So only
anything on the playable court stays." The Quest 3's colour passthrough
can show the real room behind the game.

## Decision

- **A setting.** MAIN has a PASSTHROUGH row (OFF/ON), saved in Settings.
  It applies to every view, the lobby's included.
- **The world.** With passthrough on, `World` draws only:
  - the court's surface and kitchens;
  - the lines;
  - the net and its posts.

  It skips the ground, the surround, the sky and the venue's scenery
  (fences, trees, stands, the gym, the stars). The background is a clear
  colour with zero alpha. The light is a plain room light rather than
  the venue's. The crowd is hidden. The scoreboard stays, since it holds
  the score.
- **The headset.** `MatchView.set_passthrough` makes the viewport's
  background transparent and sets OpenXR's environment blend mode to
  ALPHA_BLEND when the runtime offers it. Meta's passthrough is enabled
  in the export as optional (`meta_xr_features/passthrough=1`). On a
  runtime without alpha blend, or in flat mode, it stays opaque, and
  only the scenery is gone.
- **FOCUS** has nothing left to dim except the court-side scoreboard.

## Consequences

- The court is drawn at the tracked floor's height, where your room's
  floor is. The court is full size (6.1 × 13.4 m) and will run through
  walls in most rooms. That's expected: you play the part that fits.
- This can only be verified in the headset. Flat mode and screenshots
  show black where the room would be.
