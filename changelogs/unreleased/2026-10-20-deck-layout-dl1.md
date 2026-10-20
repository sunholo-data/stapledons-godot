### Changed

- **The bridge faces the bow** (R2-DECK-LAYOUT DL1, D-95; a blockout). The navigation arc stands at
  the bow rail on the centreline with the captain's chair behind it, and the Voyage and Crew
  consoles flank it; at every station the captain stands stern of the console facing the way the
  ship is going, and each console's close-up looks out at the sky ahead. A new game starts behind
  the helm (the manifest's `spawn_captain`), and the first step forward walks to the helm, not into
  the lift. Operator points are authored in Blender (`stations.<id>.use_m`). The props keep their
  grounded-v2 look; the hand-finished art follows Mark's playtest.

### Added

- `make deck-layout-eval` (the bow evaluator: every bridge walk sample through the Bow and Astern
  views, §D4 thresholds), `make deck-layout-eval-test` and `make deck-assets-check` in `make test`;
  `make ship-baseline` fetches the pinned pre-move deck for the evaluator's positive control; the
  bridge's fading props are data (`views.json` `levels.bridge.occluders`).
