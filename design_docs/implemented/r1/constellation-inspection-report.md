# R1-CONSTELLATIONS: implementation and verification

**Status:** Landed in [PR #271](https://github.com/sunholo-data/stapledons-godot/pull/271) as `633a4259` on 2026-10-19; CI timing exception explicitly approved by Mark.
**Approval:** Mark, attended 2026-10-17, “yep continue”.
**Source:** `3acc0c7`, verification `ad4f9d8`, and clean current-main integration `a0ccd120` (AILANG v0.54.14).
**Design:** [constellation-inspection.md](constellation-inspection.md).
**Sprint:** [constellation-inspection-sprint.md](constellation-inspection-sprint.md).

Holding I adds faint Earth guides for Orion, Cassiopeia, Crux and the Big Dipper.
All 23 vertices resolve to existing sources and follow the rendered stars under
motion, turns, zoom and rebasing. Missing/invisible/replaced vertices omit their
incident lines. GR suppresses guides and displays an unavailable message.
The guide canvas, including figure labels, is hull-masked between sky and ship;
the inspector's names, rings and cards remain above. Opaque celestial-disc boxes
conservatively suppress intersecting connectors. No new physics or sim inputs.

## Evidence

| Check | Result |
|---|---|
| `make constellation-test` | 35 assertions pass; identities, malformed/missing/duplicate sources, held-I lifecycle/typing/probe, no world mutation, body masks, replacements, zoom/viewport, warm rebase and finite near-c samples |
| `make ship-star-identification-test` | 59 existing assertions pass |
| `make export-filter-audit` | 95 literals checked, 0 failures |
| `make golden AILANG=runtime/bin/ailang` | Full existing suite and 33 constellation cases pass; strengthened constellation-only rerun also passes |
| GPU endpoint accuracy | β 0/.5/.9/.99/.999, rolled/off-axis views, origin/far GPU/far CPU: worst 0.151 px; resize cases 0.290 px at 1280×720 and 0.167 px at 2560×1440, against ≤0.75 px |
| Isolated mutation | A 1.5 px endpoint offset in `/tmp/constellation-mutant` fails 30 base and both resize cases: 32 failures; hull mask stays valid |
| `make constellation-capture` | 32 exact-size images at both resolutions; all opened through a contact sheet, plus individual figure/GR/hull checks by executor and independent evaluator |
| `make constellation-bench` | Apple M4 Max, 1920×1080, 300 warm frames each: CPU p95 0.004 ms released / 0.144 ms held; 8 visible segments, 0 identity rescans |
| `make export-macos AILANG=runtime/bin/ailang` | App builds with bundled v0.54.11, production source at `3acc0c7` |
| `make ship-star-identification-export-smoke` | Manifest complete; native I hold, exact card, release and map handoff pass; `constellation-export-smoke: OK` |
| Full pinned-runtime `make test` | Exit 0 on 2026-10-17 at 19:05 UTC; includes the 107,455-assertion ship playthrough |

Reproducible images and JSON manifests: `renders/constellations/`. Run logs:
`/tmp/constellations-baseline-test.log`, `/tmp/constellations-targeted.log`,
`/tmp/constellations-full-golden.log`, `/tmp/constellations-final-golden.log`,
`/tmp/constellations-mutant.log`, `/tmp/constellations-final-visual.log`, and
`.godot/tmp/ship-identification-export.log`.

## Visual findings and limits

The four rest patterns are recognisable; at 0.5c they move and contract with the
stars. A frozen observer +20 ly in world X changes their vertex angles, especially
the nearer Big Dipper members. These frames are labelled renderer reviews, not a
simulated voyage history. Body/GR/high-speed examples show partial or unavailable
guides. Constellation lines are chart connectors; their colour is not photometry.

Initial native-window 1440p captures were invalid because macOS clamped window
height. Final tools use an exact-size SubViewport; both captures and GPU resize
checks align. Review SR frames update background velocity alongside the stars.
The performance result is for the Studio, not an M2 Air claim. Full IAU boundaries,
all 88 figures, other cultures, proper motion and GR image-order-aware guides stay
outside scope. Conservative body boxes can remove extra connectors near a globe.

## Review and landing

Independent evaluation: `.ailang/state/evaluations/eval_R1-CONSTELLATIONS_round_1.json`.
Current-main integration `a0ccd120` passed full local `make test constellation-golden` with AILANG v0.54.14 (exit 0; 33 GPU cases, zero failures). macOS export and packaged identification smoke also exited 0. Independent follow-up review found no new correctness concern and independently reran 35 focused assertions successfully.

[CI run 39062583511](https://github.com/sunholo-data/stapledons-godot/actions/runs/39062583511) failed twice on the unchanged `crew-perf crewSkip` wall-time gate: 2.30 s and 2.26 s against 2.0 s. The identical benchmark source and runtime on base `50242fa4` passed main CI in 1.80 s; it passed the integrated local run in 1.18 s. No limit was changed for the retry. CI stops at that benchmark, so later CI targets are not claimed as verified.

Mark explicitly granted the exception on 2026-10-19 (“ok merge it”), directly answering the request to merge despite this CI timing failure. [PR #271](https://github.com/sunholo-data/stapledons-godot/pull/271) merged as `633a4259` at 06:00:30 UTC. CI remains failed; neither the timing limit nor its result was changed.

These documents moved together to `implemented/r1/`, and the sprint is complete with that recorded exception. The roadmap update landed in [design PR #27](https://github.com/sunholo-data/stapledons-design/pull/27) (`cd3a9348`). The changelog fragment is included. No dev tag, build upload or release was created.

Integration evidence: `/tmp/constellations-merge-verification.log`, `/tmp/constellations-merge-export.log`, `/tmp/constellations-merge-export-smoke.log`; CI failure logs: `/tmp/constellation-ci-failed.log`, `/tmp/constellation-ci-retry-failed.log`.
