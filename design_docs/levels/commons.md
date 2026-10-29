# Level: Commons (`commons`), layout v1 (S3 review)

**Tier:** +57 m, radius 75.9 m. Its roof is the bridge's 22 m disc only; the floor beyond that is open to the sky. **Stage of the pipeline:** S3 (playtest awaiting Mark). The brief was approved with R2-LEVELS (D-103); execution through D-130. Detailed art has not begun.
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
The §B5 defaults remain unchanged. The historical v0 mock failed `pole-ray` and `head` under the terrace. Production v1 now passes the Commons evaluator and bridge regression: seven surfaces/four heights reachable, zero final head/pole blocks in sampled views; landing near-field shares 3.1% Bow / 9.5% Astern. The service stage remains enclosed/non-journey and additionally passes a strict full-resolution geometry-alpha test: zero uncovered pixels in all six Bow/Astern rest/cruise/real-stop frames.

## Current review package

Private gallery and native download: https://voights-mac-studio.tail97eda0.ts.net:8452/ (both devices on Tailscale). Native game source is `f3e0b11c`, bundled AILANG v0.54.18. Cold ship/title startup passed with fresh settings and no external runtime; signature, ZIP integrity and full HTTPS download hash verified. The build is a review artifact, not a landed release.

`renders/levels/commons/s3/` contains 42 representative player views; `s3-clamp/` adds six actual under-terrace views, clamp share 1.0. The service has six independently checked final frames in `s3-service-final/`. Capture manifests, metrics and image hashes accompany them. Geometry and coloured find markers are placeholders for layout review. Use the checklist below before approving S3; approval is not inferred from automated checks or silence.

D-133 authorized a bounded court/arcade art pilot before all manual S3 items were
certified. D-134 refines that pilot across the wider physical deck: civic fronts,
planted alcoves, market shades and low garden arcs, compared against furniture alone.
See `art/commons-backdrop-pilot/README.md`. Existing WALK and cameras are unchanged;
remote scenery does not add traversable area. Review this appearance before
propagation; S3/S5 remain open. Final performance, independent evaluation and
exact-head `rig/full`/fast CI remain landing gates.

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
| 2026-10-20 | D-103 | The brief was approved with the R2-LEVELS plan ("ok yes good") |
| 2026-10-20 | D-104 | Curves: the terrace, gantry and balcony read as flowing, grown structures at S4 and S5; the greybox draws the gantry and balcony as arcs |
| 2026-10-29 | D-133 | Develop one bounded lived-in court/arcade pilot; no blanket S3/S5 acceptance inferred. |
| 2026-10-29 | D-134 | Enrich the wider backdrop toward the ship edge, using the concept's architectural/landscape depth and existing physical design. Review before propagation. |
| 2026-10-29 | D-135 | Go further with the comic aesthetic and long tendril architecture; make the still-bare deck a living, breathing civic level. The next review adds connected planted middle ground, patterned paths and ambient activity; S3/S5 remain open. |
| 2026-10-29 | D-139 | NPCs share the captain's painted comic style, with simpler animation. Replace the procedural 3D resident proxies. Named crew mingle in the crowd and retain their established portrait identities. Character replacement and crew presence remain pending implementation and review. |

## Change log
| Version | Date | What changed |
|---|---|---|
| v0 (mock) | 2026-10-20 | Greybox mock on `design/levels` (`tools/levels_intricate_mock.gd`): 7 surfaces, 4 heights, all reachable |
| v1 (S2 enclosure correction) | 2026-10-29 | The service gallery gains an opaque shell beyond both fixed camera eyes (ship X 17–35, Y −15–21; floor 52.75, ceiling underside 56.5 m), plus its practical. WALK, routes, stage flags and camera poses are unchanged. The shell never fades. Runtime frustum/clearance tests and the full-resolution geometry-alpha capture guard prevent an enclosed view exposing sky. |
| v1a (S3 compositing correction) | 2026-10-29 | Both painted captain rendering paths use ordinary alpha blending, retaining opaque ship coverage behind soft sprite edges and motion effects. Alpha depth prepasses had left 81 Bow / 20 Astern uncovered service pixels at rest despite a closed shell. The existing full-resolution no-sky capture gate remains strict. |

## D-136 native civic playtest

Mark approved playing the reviewed treatment. The normal New game/ship entry now installs the pinned civic layers and live ambient activity, while respecting reduced motion. Playable archive source is `755cd4b1`, bundled AILANG `v0.54.18`; [download/review](https://voights-mac-studio.tail97eda0.ts.net:8452/#playtest). Native fresh-settings startup, packed assets, walking, activity pause/resume and lift round trip pass; signature/ZIP/full HTTPS checksum verified. The staged pack closes all eleven civic files with byte hashes (1308 checks, zero skips/failures). See `art/commons-grown-pilot/playtest-review.md`. The S3 checklist above remains for attended play observations; no completion is inferred from automated checks.
