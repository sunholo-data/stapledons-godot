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
<Which surfaces and routes curve (arc pieces in the greybox), and the S4 shapes: flowing curves, grown-looking technology, no boxy silhouettes.>

## Plants (D-106)
- **Kinds:** <the plant kinds, about one painted card image each, approved at S0>.
- **Cards:** placed in `layers.foliage[]` as `{card, at, scale, layer: fore|stage|far, sway}`, painted at S4, pinned in the foliage library (`make foliage-check`).
- **Structure:** smooth stylised 3D only for trunks, planters and grown-tech fixtures.
- **Shadows:** proxy shadow casters for big plants.

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
- [ ] Plants read as painted cards in the level's style; they sway gently and cast shadows where they're big (D-106)
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
