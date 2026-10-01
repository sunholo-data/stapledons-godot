# Stapledon Mission: R1, the first playable relativistic journey

<!--
  Charter drafted from ailang/design_docs/mission-charter-TEMPLATE.md on 2026-09-27.
  ARMED 2026-09-27 at Mark's request ("you have permission to get it up and
  running"), with registration in sunholo-data/ailang#1340. Iteration 0 =
  ratification of the bar, the queue and the guardrails, reported on issue #1.
  Live missions after arming: fleet, world, stapledon.
-->

**Type:** Long-running mission, a peer of the AILANG-repo missions. When armed,
it's advanced by a scheduled outer loop on the always-on rig.

**North star:** a player can plan a journey to α Centauri, commit to it, live
through it under a physically accurate relativistic sky, and arrive to find
home years older. It's built on an AILANG simulation that runs on the bytecode
VM and has driven fixes upstream.

**Traces to:**
- [R1 foundations roadmap](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
- [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md)
- AILANG `design_docs/planned/v1_1_0/m-game-engine-effects.md` (Stapledon as
  the v1.1 flagship)

Language gaps route back to `sunholo-data/ailang` through `ailang messages`.
They are never worked around silently.

**Skill:** the same unforked `mission-control` skill through the user-level
symlink. This repo carries only game-specific skills (`game-vision-designer`,
`starmap-manager`).

**Scheduling:** launchd `dev.ailang.mission-stapledon`, every 6 h
(`missions/stapledon.toml` in `sunholo-data/ailang`, boot offset 2100 s). The
off switch is `~/.ailang/state/mission-stapledon.disabled`.

**Log:** [stapledon-mission-log.md](stapledon-mission-log.md)

**Human-facing reporting:** GitHub issue
[#1](https://github.com/sunholo-data/stapledons-godot/issues/1), rotating
weekly. Every iteration posts its report there.

## Repo Profile (M-MISSION-PORTABILITY M2)

- **Repo slug:** `sunholo-data/stapledons-godot` (driver: `MISSION_REPO`)
- **Mission doc:** `design_docs/stapledon-mission.md` (driver: `MISSION_DOC`)
- **Mission name / state namespace:** `stapledon`, giving
  `~/.ailang/state/mission-stapledon-*`
- **Bookkeeping issue:** `#1`, rotating weekly. The live number is in
  `~/.ailang/state/mission-stapledon-gh-issue`.
- **CI workflows Gate 3b / Gate 1 poll:** `CI` (job: "headless tests (physics,
  sim, parity, strict VM)")
- **Verify profile:** `godot-game`, added to the shared skill's table in
  `sunholo-data/ailang#1340`:
  - **Rebuild before check:** none. The Godot and AILANG binaries are pinned
    releases, and `ailang lock` resolves `sunholo/relativity`.
  - **Full test suite:** `make test` (Godot headless physics tests, simulation
    vs closed form, VM/interpreter parity, strict-VM pure core).
    **GPU gates:** `make golden` and `make capture` need a GPU window, so they
    run on the Studio rig and not in CI. The evaluator must see their output
    (logs and renders) attached to the sprint.
  - **Binary staleness:** check `ailang --version` and `godot --version`
    against the pins in `.github/workflows/ci.yml` before quoting output.

---

## STATUS (rotation rule)

The newest 3 STATUS stamps live here; older ones move to
`stapledon-mission-status-archive.md`.

## STATUS 2026-10-01: iteration 7, M1.2b-T1 LANDED (pure catalogue transform)

- **T1 ✅**: PR #14, merge `f4dd9bc`, complete merge CI green. Package-only
  normal/WD transform, missing/clamped flags and independent counters;
  stable nearest-complete medium selection, quick/large input order.
  Independent Sonnet 5.5 **88/100 PASS**, zero blockers; generator GPT 6.1 Sol.
- **Next**: bounded float32 writer/sidecars, then full-tier integration and
  5-run VM parity. Carry evaluator N1 (dwarf clamp predicate discriminator),
  N2 (double trailing-newline refusal), 50,000 boundary and tier validation.
  M1.6b waits on human render review; AI foundation is routable when M1 pauses.
- **Clause map**: 1 UNMET → M1 writer/integration routable now; 2 UNMET → M2
  design/implementation; 3 UNMET → M3 package/integrator; 4 UNMET → AI
  foundation/M4; 5 ongoing → strict core/parity green, pure-list reverse
  VM gap reported. M1 5/12 plus T1 subtask; full M1.2b remains open.
  This landing moved clause 1. Harness share 0/8; last 3 landings move clause 1.
- **Routing**: planner/executor Agent-tool GPT 6.1 Sol; evaluator Agent pin
  `sonnet` rejected (Unknown model), exact Sonnet 5.5 subscription CLI fallback
  completed the independent review. Designer not needed (existing design).

## STATUS 2026-10-01: iteration 6, M1.2b-WD3 LANDED (game pins relativity 0.3.0)

- **WD-3 ✅**: PR #12, merge `68575d9`, merge-commit CI green. The game pins
  `sunholo/relativity@0.3.0`; `checkWDPackage` makes the pin load-bearing;
  the new `make wd-vm` (part of `make test`) asserts the package's WD NaN
  contract on the strict VM. That closes iteration 5's NB-2: an Exact
  NaN-guard mutant gives 3000.0000000000136 on the VM (caught) and 3000.0
  on the interpreter (masked by ailang#1419). The controller reproduced
  this first-party. Independent MiniMax-M3 **98/100 PASS**, zero blockers;
  generator Sonnet 5.5. The M1 doc carries the consumer contract, O-1 and
  the WD UI-label line.
- **Harness**: `mission-base:hardcoded-origin-dev` RESOLVED upstream
  (ailang `cb7c51c8e`); verified this fire from the driver pin (rc 0,
  records `origin/main`).
- **Next**: the bounded catalogue transform, corrected float32 writer and
  integration (full M1.2b, AC2), then M1.2c. M1.6b stays ready.
- **Clause map**: 1–4 UNMET, 5 ongoing (strict VM and parity green at this
  landing). M1 5/12 milestones counting the M1.2b WD prerequisite as done;
  full M1.2b still open. Clause 1 moved. Harness share 0/7; last three
  landings all move clause 1.

## STATUS 2026-09-30: iteration 5, M1.2b-WD1/WD2 LANDED (relativity 0.3.0 published)

- **WD package ✅**: `sunholo/relativity@0.3.0` published (blackbody WD Teff
  and V from Gaia BP−RP, VEGAMAG zero point Z=0.5906467146); package PR
  sunholo-data/ailang-packages#83 open for Mark to merge (as 0.2.0 was).
  Independent MiniMax-M3 **98/100 PASS**, zero blockers; generator Sonnet 5.5.
  New design doc `m1.2b-wd-photometry.md` (quorum: 2 rounds blocked at N−1 on
  unmeasured premises, all measured; narrow-refinement carve-out).
- **Upstream**: ailang#1419 (interpreter NaN > x true, VM false) and ailang#1420
  (nested cons pattern not compiled for strict VM) filed, both reproduced on
  v0.47.2 and v0.49.
- **Next**: M1.2b-WD3 (game pins 0.3.0, `checkWDPackage`, a VM-run NaN
  assertion), then the bounded catalogue transform. M1.6b stays ready.
- **Clause map**: 1–4 UNMET, 5 ongoing; M1 4/12 milestones (+WD-1/WD-2 of
  the M1.2b prerequisite). Clause 1 moved via the package-first WD physics.
  Harness share 0/6; last three landings all move clause 1.

## Decision ledger

<!-- decision-ledger:start -->
| ID | Status | Decision / recorded answer | Evidence |
|---|---|---|---|
| D-1 | RESOLVED | Ratify the drafted bar (clauses 1–5), queue and guardrails. Recommendation: ratify as drafted. Default if unanswered: the loop keeps working the queue on the drafted bar.  **ANSWERED — RATIFIED as drafted: bar clauses 1-5, the queue and the guardrails (Mark, attended 2026-09-28: "record decisions as ratified").** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Charter iteration-0 definition; loop armed by Mark 2026-09-27; iteration 0 ran M1.1 under the standing publish grant.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-2 | RESOLVED | Accept the M1.1 AC1 amendments: Riello G−V cross-check 0.11 mag over BP−RP 0.4–3.0 plus 0.05 over 0.4–1.3; table coverage B9V–M8.5V. Recommendation: accept. Default: accepted (0.2.0 is published).  **ANSWERED — ACCEPTED as published in 0.2.0: Riello G-V cross-check 0.11 mag over BP-RP 0.4-3.0 plus 0.05 over 0.4-1.3; table coverage B9V-M8.5V (Mark, attended 2026-09-28: "record decisions as ratified").** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Measured on Mamajek v2022.04.16: 0.1015 mag at BP−RP 3.0; M9V/M9.5V BP−RP reverses. Evaluator verdict: honest amendment.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-3 | RESOLVED | Tier data in git for M1.2. Recommendation: commit quick and medium tiers, not large. Default: that, when M1.2 starts.  **ANSWERED — YES: commit the quick and medium tiers to git; build large locally and for bench, never committed (Mark, attended 2026-09-28: "record decisions as ratified").** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Handover comment on #1, 2026-09-27.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-4 | RESOLVED | White dwarfs in M1: approximate blackbody fit, flagged approximate (design open question 3). Recommendation: yes. Default: yes, when M1.2 starts.  **ANSWERED — YES: approximate blackbody fit for white dwarfs in M1, flagged approximate in data and UI (Mark, attended 2026-09-28: "record decisions as ratified").** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Handover comment on #1; `photometry` 0.2.0 deliberately has no WD model.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-5 | RESOLVED | Bright-star tier (M1 design open question 5): accept the proposed M1.2d, a Hipparcos (HIP2, VizieR I/311) tier for V < 7 stars not in GCNS or CNS5, with AC11 and `teffFromBV` in `sunholo/relativity` 0.3.0 (about +250 LOC)? Without it Rigel, Deneb and most naked-eye stars beyond 100 pc exist only as panorama pixels (option A) or not at all (option B). Recommendation: accept. Default if unanswered: M1.2 ships without M1.2d, and the ask is repeated at the M1.4a pause, where option B makes it required.  **ANSWERED — ACCEPTED (Mark, attended 2026-09-28: 'Yes I accept those stars'): add M1.2d, a Hipparcos (HIP2, VizieR I/311) tier for V < 7 stars not in GCNS or CNS5, with AC11 and teffFromBV in sunholo/relativity 0.3.0 (about +250 LOC), so Rigel, Deneb and the naked-eye sky beyond 100 pc are real catalogue stars.** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Quorum round 1 (oc-glm-5-3), 2026-09-28; design doc Problem 5, rows V14 and M1.2d.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-6 | RESOLVED | Ship-interior presentation for M4 (resolves the isometric / first-person / fixed-scene contradiction in the design docs: design-decisions 2025-12-18 vs features/scene-based-interior-navigation 2025-12-20).  **ANSWERED — ISOMETRIC THREE-LAYER INTERIOR (Mark, attended 2026-09-28, 'yes this is more like it - lets go with these', after spikes v1-v3). The player is INSIDE the bubble; up = forward (direction of travel). Isometric play areas built as Blender 3D models (GLB), rendered in Godot with an orthographic camera tilted back (~-14 deg) at room scale (~16 m), toon + ink shading, the player walks around. Behind them: Blender interior panoramas of the ship's own structure (spire, levels, far decks), rendered from inside with space left transparent and each camera exported. Behind those: the live relativistic sky through EXACTLY that camera (catalogue stars + full-sky galaxy, per-pixel inverse aberration and Doppler). Parallax on every layer when panning: sky and galaxy fixed (at infinity), panorama slow, play area 1:1, foreground silhouettes fast. The bridge sits at the top of the spire and its dome IS the bubble's forward pole, where the starbow gathers overhead; lower decks see the sky past the level rims, which goes dark sideways at speed. Character interactions use large portraits. Art direction: Moebius / Metal Hurlant (2025-12-08). Supersedes design-decisions 2025-12-18 (first-person 3D) and the no-avatar fixed-scene model of scene-based-interior-navigation (2025-12-20); keeps the 2025-12-08 ship canon.** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Attended session 2026-09-28; feasibility spikes v1–v3 on branch `spike/iso-bridge`.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-7 | RESOLVED | Characters and AI presentation: how crew, the Archive and generated content are made and shown (supersedes the Blender-character part of the art plan).  **ANSWERED — AI-GENERATED CHARACTERS AND A GAME THAT GROWS ITS OWN ASSETS (Mark, attended 2026-09-28). (1) Characters are AI-generated PORTRAITS, not Blender models: one portrait set per character (the dialogue design's 8 emotions: neutral, happy, sad, angry, fearful, curious, loving, grieving; with age stages over the voyage). Generated dialogue text carries EMOTION MARKERS that swap the portrait live. (2) Every line is SPOKEN via generated audio with per-character voices, and the emotion markers drive delivery too. (3) Generate on first use, then CACHE: the named crew are pre-generated at build time; new people (births), aged variants, aliens and places are generated during play. The game builds up its own asset library as it is played, an AI harness in itself. (4) In-world figures are light, portrait-derived representations: the crew are seen living their lives, and the player selects someone to talk to. The figure pipeline is open for ideas; there is no Blender character modelling. (5) The AI is in the ship: the Archive's core is fused into the spire's base (terminals and the core shrine there), while the spire's own mystery stays beyond the Archive (canon from 2025-12-06 to 12-08 kept). (6) The game is an AI showcase: semantic memory, generated dialogue, voice and imagery, the Archive as a real model-driven NPC, and more; a design doc to follow. (7) Constraints: every AI output (text, audio and image selection) is RECORDED as a simulation input, so replays stay byte-identical (bar clauses 2 and 4); AI calls run outside the sim tick in their own process (ADR 0001).** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Attended session 2026-09-28.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-8 | RESOLVED | Runtime AI operating model (ai-showcase open questions 1–3): keys and cost, providers, live voice.  **ANSWERED — DECIDED (Mark, attended 2026-09-28). (1) KEYS AND COST: the PLAYER'S OWN KEY. The game ships PRE-GENERATED CORE CONTENT (the accepted founding cast, their portraits, avatars and voices, the Archive, and templated fallback lines), and live generation is OPT-IN with the player's key. Without a key the game is fully playable on the pre-generated core. (2) PROVIDERS: stay MODEL-NEUTRAL and swap models as needed through AILANG's provider routing; GEMINI is the default (text, image and TTS). (3) VOICE: NO LIVE real-time voice for now (no streaming conversation with the Archive; gemini_live deferred). Speech is PRE-RECORDED or generated per line and cached, and TEXT-ONLY mode is always available.** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Attended session 2026-09-28; features/ai-showcase.md §7.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-9 | RESOLVED | Queue the AI service foundation (features/ai-showcase.md §8, from D-7/D-8) as its own item ahead of the M4 design doc? Recommendation: yes. Default if unanswered: it waits for the M4 design doc.  **ANSWERED — ANSWERED — YES, QUEUE IT (Mark, attended 2026-09-28: 'yes put that in'): the AI service foundation from features/ai-showcase.md §8 becomes its own queue item (row 2), design doc first, then the sprint: (a) a separate AILANG AI-service process with an NDJSON request/result protocol, recording for byte-identical replay and a cache index, tested headless with a stubbed provider; (b) the shared emotion-marker grammar with a parser and tests; (c) the Medic voice and portrait-swap style frame, which stops for Mark. It runs after M1, or earlier in iterations where M1 is parked or waiting on Mark. Constraints from D-7 and D-8 apply.** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Attended session 2026-09-28.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
| D-10 | RESOLVED | M1.4a background source (M1 design open question 1): Option A on which panorama, NOIRLab `noirlab2430b` (E. Slawik, 10000×5000, CC BY 4.0) or ESO `eso0932a` (S. Brunier, CC BY 4.0)? Gaia EDR3 flux map ruled out (built from stars, no nebulae, CC BY-SA). Recommendation: NOIRLab. Default if unanswered: M1.4 waits.  **ANSWERED — OPTION A ON NOIRLAB (Mark, attended 2026-10-01: 'ok lets go with NOIRlab'): the background is the real NOIRLab noirlab2430b panorama (E. Slawik, CC BY 4.0, 10000x5000), with the point sources that are cross-matched to the shipped point layers (CNS5, GCNS, HIP2 V<7) masked and inpainted, and unmatched faint stars kept as pixels. ESO eso0932a and the Gaia EDR3 flux map are not used. The panorama is valid to about 50 ly from Sol (parallax); beyond that it is a stated post-R1 limit.** (Mark Edmondson, attended 2026-10-01, recorded directly in this ledger.)| Attended spike, branch `m1.4a-background-spike`, `docs/m1.4a/README.md` (matched-window crops, parallax validity note: a single panorama holds to about 50 ly from Sol).  **Attended ruling 2026-10-01** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf. Attended spike 2026-10-01, branch m1.4a-background-spike, docs/m1.4a/README.md.|
| D-11 | OPEN | Higgs bubble model and journey model (M2 OQ1/OQ2): what the bubble does to acceleration, felt gravity, the wall and the ISM, with everything but the bubble held to exact physics. | Attended session 2026-10-01; physics review of the bubble (tides, ISM load, photon drive, CMB). |
| D-12 | OPEN | M2 remaining open questions (OQ3 calendar, OQ4 manual flight and pausing, OQ5 commit ritual). | `design_docs/planned/r1/m2-journey-core.md` Open questions. |
| D-13 | OPEN | M3 open questions (OQ1 weak-field check value incl. bar clause 3, OQ2 2D lens table, OQ3 hover range, OQ4 demo hole). | `design_docs/planned/r1/m3-black-holes.md` Open questions; prototype V1-V13. |
| D-14 | OPEN | M4 open questions (orientation, slice cruise speed, stand-off, calendar, news beat, art stop S2, playtest incl. bar clause 4, time while docked). | `design_docs/planned/r1/m4-first-journey.md` Open questions. |
<!-- decision-ledger:end -->

The M1.4a background choice and the default exposure are asked when those
milestones are reached (design doc open questions 1 and 4).

## CURRENT GOAL

1. **Iteration 0 (definition):** ratify the bar and the queue with Mark. Decide
   whether to arm the loop, or keep running R1 attended with the inner-loop
   skills.
2. **Then:** work the queue, one sprint-sized item per iteration, through
   design doc → sprint plan → execute → evaluate.

## The bar: R1 is done when… (ratified by Mark 2026-09-28, D-1)

- **Clause 1 (sky):** M1's acceptance criteria AC1–AC10 are met. The
  relativistic sky is correct for any velocity or view direction, with a
  photometric exposure, at 60 fps with 331k stars.
- **Clause 2 (journey core):** M2 is met. There is a versioned protocol; the
  journey planner matches the rocket equations to 1e-9; commits are
  irreversible and enforced by the simulation; a 10k-tick replay is
  byte-identical on the VM and the interpreter.
- **Clause 3 (black holes):** M3 is met. The shadow is within 0.5 px of Synge's
  formula at 10, 5 and 3 r_s; the weak-field limit is within 1%; the Einstein
  ring is at the predicted angle. The geodesic integrator ships in
  `sunholo/relativity`.
- **Clause 4 (first journey):** M4 is met. Plan → commit → transit → arrive →
  news from home; a new player finishes it in under 10 minutes; the replay is
  byte-identical.
- **Clause 5 (AILANG):** the pure simulation core passes `--strict-bytecode` at
  every landing. Every VM/interpreter divergence and every DX papercut hit is
  reported upstream with a repro. When AILANG Phase 2E lands, the whole
  sidecar moves to `--strict-bytecode`.

## Guardrails

- **Physics gates are not negotiable.** No SR/GR visual merges without spec
  check values, a GPU golden case and a human-reviewed render (CLAUDE.md,
  definition of done).
- **Physics maths goes into `sunholo/relativity` first.** Mark granted
  standing permission (2026-09-27) to publish new versions of this package and
  to cut review-build tags and releases, including from the loop. The full
  gate still applies before every publish: tests, `pkg quality` with no gates,
  `CHANGELOG`, `[release] kind`, and a dry run. Other packages or registries
  need Mark.
- **Stop for the user** at a design doc's "Open questions", at the data-source
  choice in M1.4a, and at any pillar score of 0 or below.
- **Never edit the shared `mission-control` skill from this mission.** Propose
  changes instead.
- **Report AILANG issues to the gcp message store** (CLAUDE.md), never to a
  local-only store.

## Routing policy

Inherits the shared defaults (generator ≠ judge). Proposal for arming: the
executor on the default Anthropic model, and the evaluator from a different
provider. Physics code gets the strongest available evaluator.

## Queue (top = next; tags: [NEXT] [IN-SPRINT] [PARKED] [LANDED] [RULED OUT])

1. [IN-SPRINT] **M1** sky · clause 1 · sprint `R1-M1-SKY` (`.ailang/state/sprints/sprint_R1-M1-SKY.json`) · M1.0 ✅ · M1.1 ✅ (0.2.0, iter 0) · M1.6a ✅ (PR #3, merge `5218160`, iter 3, eval 87; parked upstream on ailang#1354/#1355, fixed in v0.47.2, resume predicate verified first-party) · M1.2a ✅ (PR #5 `77d3f04`, iter 2, eval 92) · M1.2b-preflight ✅ (PR #9 `01fe9ef`, iter 4, eval 85; full M1.2b remains open) · M1.2b-WD1/WD2 ✅ (`sunholo/relativity@0.3.0` published, pkg PR #83, iter 5, eval 98; design `m1.2b-wd-photometry.md`) · M1.2b-WD3 ✅ (PR #12 `68575d9`, iter 6, eval 98; pin 0.3.0, `checkWDPackage`, strict-VM `make wd-vm`) · M1.2b-T1 ✅ (PR #14 `f4dd9bc`, iter7, eval88; pure transform/selection only) · [NEXT] bounded float32 writer/sidecars (N1/N2 test gaps, tier validation) → full-tier integration + 5-run VM parity → M1.2c stats + tier commits → M1.2d HIP2 bright tier (D-5 accepted; `teffFromBV` now ships in relativity 0.4.0, since 0.3.0 is the WD release) → M1.3 → M1.5 (M1.4a ✅ D-10 NOIRLab, attended 2026-10-01 · M1.4b/c ✅ PR #16 `8e46c17`, attended, eval 91 Sonnet; AILANG fitter `sim/tools/sky_model.ail`, `make sky-vm`; follow-ups: emission-line model needs package maths, AILANG port of star removal `tools/m14a_destar.py`, input hash for `data/sky/sky_model_report.json`) · M1.6b camera + golden (unblocked; carries the M1.6a follow-up: pin the 1e-9 at-rest tolerance) · ~3,000 LOC · note (D-6): M1.4's per-pixel background can start from the spike's `spike/galaxy_sky.gdshader` (inverse aberration + Doppler surface brightness, already built)
2. [QUEUED] **AI service foundation** (D-9) · feeds clause 4 · design doc needed (routable: designer), written in `design_docs/planned/r1/` from `stapledons-design/features/ai-showcase.md` §5 and §8 plus `art/characters-blender-brief.md` §6 · runs after M1, or earlier in any iteration where M1 is parked or waiting on Mark (e.g. the M1.4a pause) · three milestones: (a) AI service skeleton: a separate AILANG process, an NDJSON request/result protocol relayed by Godot, every result recorded so replays stay byte-identical, a cache index keyed (kind, entity_id, emotion, age_stage, variant), tested headless with a stubbed provider (no key, no spend); (b) emotion-marker grammar for the 8 emotions, shared by text, TTS and the portrait switcher, with a parser and tests; (c) ⏸ Medic style frame: a TTS voice for the accepted Medic, one generated line whose markers swap the existing portraits in a conversation UI; stop for Mark (voice and swap timing) · constraints: D-8 (player's own key, opt-in live generation, model-neutral with Gemini default, no live voice, text-only always available); the sim never calls AI · ~1,200 LOC (estimate)
3. **M2** journey core · clause 2 · design doc drafted (attended 2026-10-01, `design_docs/planned/r1/m2-journey-core.md`; 5 open questions for Mark) · PRNG blocked on strict-VM bitwise ops (ailang#1450; LCG fallback in the doc) · ~3,100 LOC (estimate)
4. **M3** black holes · clause 3 · design doc drafted (attended 2026-10-01, `design_docs/planned/r1/m3-black-holes.md`; 4 open questions for Mark, incl. the clause-3 weak-field value: exact deflection at b = 100 r_s is 1.5% above 2r_s/b) · `sunholo/relativity` next free minor (0.5.0 or 0.6.0, shared with M2.0) for the geodesic integrator · M3.1–M3.4 need nothing from M1 · ~2,600 LOC (estimate)
5. **M4** first journey · clause 4 · design doc drafted (attended 2026-10-01, `design_docs/planned/r1/m4-first-journey.md`; 7 open questions for Mark; protocol interface aligned with M2), **unblocked by D-6** (interior design: `stapledons-design/art/ship-interior-blender-brief.md`; reference spike: branch `spike/iso-bridge`, `spike/interior3.gd`); D-7 (attended 2026-09-28: AI-generated portraits with emotion markers, generated voice, generate-on-first-use and cache, the Archive in the spire base) is an input to the M4 design doc; builds on the AI service foundation (row 2, D-9) · ~2,500 LOC (estimate)
6. [NEW] **Toolchain gate hygiene** · clause 5 · `make deps` fails whenever the PATH `ailang` differs from the pin (now v0.50.0, bumped attended 2026-10-01; `runtime/` restaged) (it rewrites the lockfile version line), so every local gate needs `AILANG=runtime/bin/ailang`: default the Makefile to the pinned runtime when present, or make `deps` ignore the version lines · ~20 LOC
7. [HARNESS] ticket:mission-base:hardcoded-origin-dev RESOLVED (ailang `cb7c51c8e`, harness-resolved reply acked iter 6; verified from the driver pin) · ticket:skill:gate0-ledger-provenance-S (open, non-blocking)
5. [LANDED] **Arming prerequisites** · `godot-game` profile, registry, env, bookkeeping issue #1 (`sunholo-data/ailang#1340`)

---
**Document created:** 2026-09-27. It is a draft. Iteration 0 ratifies it with
Mark before any sprint runs unattended.
