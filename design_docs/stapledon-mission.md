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

## STATUS 2026-09-27 (late): ARMED, iteration 0 next

- Registration: `sunholo-data/ailang#1340` (registry, env, boot offset,
  `godot-game` profile). Dry run OK. Bookkeeping issue #1.
- Sprint R1-M1-SKY is in progress. **M1.0 review builds ✅**: `v0.1.0-m0`
  runs on Mark's laptop. Next is M1.1 (`sunholo/relativity@0.2.0`
  photometry).
- AILANG `origin/dev` is now v0.47.0, with unboxed `Array[float]` and VM-native
  binary/JSON ingest. Re-plan M1.2's pipeline on it (the rig binary is still
  v0.45.0; pin the upgrade deliberately).

## STATUS 2026-09-27: PRE-ITERATION-0, charter drafted, awaiting ratification

- M0 spike landed: `stapledons-godot` `e6315cf`, `sunholo/relativity@0.1.0`
  published.
- M1 design doc written: `design_docs/planned/r1/m1-relativistic-sky.md`. The
  next step is a sprint plan, attended.
- Not armed. No bookkeeping issue. The `godot-game` verify profile has not been
  added to the shared skill.

## CURRENT GOAL

1. **Iteration 0 (definition):** ratify the bar and the queue with Mark. Decide
   whether to arm the loop, or keep running R1 attended with the inner-loop
   skills.
2. **Then:** work the queue, one sprint-sized item per iteration, through
   design doc → sprint plan → execute → evaluate.

## The bar: R1 is done when… (RATIFY with Mark)

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

1. [IN-SPRINT] **M1** sky · clause 1 · sprint `R1-M1-SKY` (`.ailang/state/sprints/sprint_R1-M1-SKY.json`) · M1.0 ✅ · [NEXT] M1.1 → (M1.2 ∥ M1.6) → M1.3 → M1.4a ⏸ Mark picks the background → M1.4b/c → M1.5 · ~3,000 LOC
2. **M2** journey core · clause 2 · design doc needed · ~2,000 LOC (estimate)
3. **M3** black holes · clause 3 · design doc needed; `sunholo/relativity` 0.3 (Binet integrator) · ~1,800 LOC (estimate)
4. **M4** first journey · clause 4 · design doc needed; blocked on the ship-interior decision (design repo open question) · ~2,500 LOC (estimate)
5. [LANDED] **Arming prerequisites** · `godot-game` profile, registry, env, bookkeeping issue #1 (`sunholo-data/ailang#1340`)

---
**Document created:** 2026-09-27. It is a draft. Iteration 0 ratifies it with
Mark before any sprint runs unattended.
