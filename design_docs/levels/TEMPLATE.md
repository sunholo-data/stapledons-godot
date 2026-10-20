# Level: <Name> (`<id>`), layout v<N>

**Tier:** <floor z> m, radius <r> m, roof: <the slab above / open>. **Stage of the pipeline:** S<k> (see [backlog](backlog.md)).
**Concept refs:** <art/ship-tier-concepts-v1/<id>.png, design-repo briefs, Moebius plates>. **Ledger:** <D-rows for this level>.

## Purpose (3 lines at most)
<What the player and the crew do here, and why you'd come down.>

## Mood and light
- **Palette and feel:** <...>
- **Spire segment:** <height, range to the ceiling, character>. **Practicals:** <lamps, cultivation lights, ...>
- **Sky:** <open / band from the rim, top <°> at the journey stages (§B4)>

## Shape language (D-104)
<Which surfaces and routes curve (arc pieces in the greybox), and the S4 shapes: flowing curves, grown-looking technology, no boxy silhouettes. Plants go only through `layers.foliage[]`.>

## Stages

| Stage | Bounds (ship m) | Surfaces (heights) | View(s) | Journey? | Ambience |
|---|---|---|---|---|---|
| <id> | <x0..x1, y0..y1> | <+57, +61, ...> | Bow, Astern, <clamp / enclosed> | yes/no | <id> |

## Routes

| From → to | Kind (stairs, ramp, ladder, hatch, exit, lift) | Where | Animation clip |
|---|---|---|---|

## Finds, use points and set pieces

| Kind | Id | Stage, where | Cue / reveal / when |
|---|---|---|---|

## Thresholds (`art/levels/<id>/thresholds.json`)
<Only where they differ from the defaults in levels.md §B5, each with a reason.>

## Acceptance (the shared commands)
- `make level-eval LEVEL=<id>` prints `level-eval: <id> ok`
- `make level-assets-check LEVEL=<id>` (S4 onward)
- `make level-capture LEVEL=<id> TAG=<s3|s5>`: every frame opened, sheet and per-file URLs posted
- `make levels-regress` green (S6)

## Style checklist (S5)
- [ ] No boxy silhouettes; structures read as grown, with flowing curves (D-104)
- [ ] The palette and ink match R2-BRIDGE-STYLE

## Playtest checklist (S3; 5–8 lines, answered one line each)
- [ ] <the arrival shows ...>
- [ ] <find ... without being told>
- [ ] <the route up to ... is obvious>
- [ ] <the captain never vanishes under ...>

## Rulings
| Date | Ledger | Ruling |
|---|---|---|

## Change log
| Version | Date | What changed, and why any baseline was re-pinned |
|---|---|---|
