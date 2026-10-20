# Level: Commons (`commons`), layout v1 (draft brief)

**Tier:** +57 m, radius 75.9 m. Its roof is the bridge's 22 m disc only; the floor beyond that is open to the sky. **Stage of the pipeline:** S0 (brief, awaiting Mark with the R2-LEVELS plan).
**Concept refs:** `art/ship-tier-concepts-v1/commons.png`; the approved Commons zoning (open civic plaza, curved arcades, planted walks; `website/docs/ship-layer-reference.mdx`); the existing painted court and arcade (`assets/ship_commons/`). **Ledger:** D-34, D-35, D-100.

## Purpose
The civic heart: where news from home arrives, the crew meet and argue, and the market runs. It should be busy, warm and layered. It's the first place you go down to from the bridge.

## Mood and light
- **Palette and feel:** the Commons' cream terraces and teal ribs, with ochre stall awnings and violet rails (the bridge's palette family), all on R2-BRIDGE-STYLE's finish.
- **Spire segment:** a key light at about +69 m, its range ending at the bridge's underside (+81 m), with faint patterns on the spire. **Practicals:** stall lamps, gantry lamps, a reading lamp at the notice board.
- **Sky:** open above the outer ring. From the court, the starbow sits over the far rim at 0.99c ([mock](https://storage.googleapis.com/stapledons-voyage-assets/refs/levels/mock/commons_bow_cruise.png)).

## Stages

| Stage | Bounds (ship m) | Surfaces | View(s) | Journey? | Ambience |
|---|---|---|---|---|---|
| `landing` | the lift landing, about x 4–14, y 0–12 | +57 | Bow, Astern | yes | `commons_landing` |
| `court` | x 14–36, y −10 to 20 | +57 (alcove stalls to port) | Bow, Astern, ceiling clamp under the terrace and gantry | yes | `commons_court` |
| `terrace` | x 30–38, y 0–16 | +61 | Bow, Astern | yes | `commons_terrace` |
| `gantry` | x 8–44, y 10–16 | +66 (catwalk and the bow balcony) | Bow, Astern | yes | `commons_gantry` |
| `service` | x 18–34, y −4 to 10 | +52.75 (the gallery under the slab) | enclosed (low, close) | no | `commons_service` |

## Routes

| From → to | Kind | Where | Clip |
|---|---|---|---|
| lift → landing | lift | ship (8, 8) | `ride_idle` |
| landing → court | exit | x 14, y 3–7 (the existing opening) | — |
| court → terrace | stairs | x 24–30, y −2 to 0 | `stairs` |
| terrace → gantry | ladder | x 37.5, y 13 | `climb_ladder` |
| gantry → lift | gantry walk | x 8.5, y 12 | — |
| court → service | hatch | x 20, y 6 | `crouch` |

## Finds, use points and set pieces

| Kind | Id | Stage, where | Cue / reveal / when |
|---|---|---|---|
| find | `notice_board` | court, port alcoves | lamp; news from home (clear from the court's first view in the mock) |
| find | `terrace_bench` | terrace | a crew anchor (someone sits there); hidden from the court in the mock, so it **needs a cue** |
| find | `telescope` | gantry, bow balcony | a glint at the rail; hidden from the court in the mock, so it **needs a cue** |
| find | `service_panel` | service | a hum, and a light under the hatch grille |
| set piece | `balcony_stop` | gantry balcony | at a stop: the body 30° off the bow, framed by the balcony rail |
| set piece | `gantry_cruise` | gantry | at 0.99c: the starbow over the arcade roof |
| set piece | `lift_descent` | the lift ride | the court and its lights rising into view under the bridge's underside |

## Thresholds
The §B5 defaults. The greybox v0 fails `pole-ray` (the civic tower stands on the pole line) and `head` under the terrace (8% even with the clamp). Fixing both is the S2 work.

## Playtest checklist (S3)
- [ ] The lift arrival shows the court, the stalls and the starbow.
- [ ] The way up to the terrace and the gantry is obvious from the court.
- [ ] Find the telescope without being told.
- [ ] The captain never vanishes under the terrace or the gantry.
- [ ] The service gallery feels enclosed and different.
- [ ] Bow ↔ Astern on every stage, with nothing turning.
- [ ] At a stop, the balcony frames the body.

## Rulings
| Date | Ledger | Ruling |
|---|---|---|
| 2026-10-20 | D-100 | "we need more intricate level design now we have fixed position sorted" |

## Change log
| Version | Date | What changed |
|---|---|---|
| v0 (mock) | 2026-10-20 | Greybox mock on `design/levels` (`tools/levels_intricate_mock.gd`): 7 surfaces, 4 heights, all reachable |
