# Stapledon's Voyage: Godot rebuild

**Godot 4 renders the game. An AILANG simulation runs as a child process and
talks newline-delimited JSON (NDJSON) over stdin/stdout.** See ADR 0001 in the
design repo.

| Repo | Role |
|---|---|
| `../stapledons-design` (sunholo-data/stapledons-design) | **What** the game is: vision, feature designs, the normative physics spec (`physics/relativity-spec.md`), the roadmap (`roadmap/r1-foundations.md`) |
| this repo | **How** it's built: implementation design docs, sprints, code, tests |
| sunholo-data/ailang-packages `packages/relativity` | The `sunholo/relativity` AILANG package, the single source of physics maths |
| `../../stapledons_voyage` | The retired Go/Ebiten version. Reference only; never port code from it without checking the physics spec's audit |

## Commands

```sh
make test      # headless: physics reference, sim vs closed form, VM/interpreter parity, strict-VM core (CI runs this)
make golden    # GPU shader vs CPU reference, sub-pixel (needs a GPU window; works from the Studio shell)
make capture   # sim-driven voyage → renders/*.png (inspect them; that is the visual check)
make run       # interactive
```

AILANG is pinned to **v0.54.14** (CI, the bundled runtime and the lockfile move together; bump all three at once). Use the same version on `PATH`, or `AILANG=runtime/bin/ailang`. Use `--package-dir sim` for `run`, `--package sim` for
`check`. zsh does not word-split `$flags`, so use `${=flags}`.

**Large assets (D-18).** The sky textures (about 164 MB) aren't in git. `make sky-assets`
fetches them by sha256 from the public bucket `gs://stapledons-voyage-assets/sky/`
(pins in `data/sky/SHA256SUMS`) in seconds, or regenerates them if the bucket lacks
them. `make sky-publish` (maintainers, gcloud) uploads new pins. Dev builds:
`make publish-dev` uploads to the private `gs://stapledons-voyage-dev-builds`, and
Mark installs with `tools/install_review_build.sh --dev`. Releases use GitHub. All
infrastructure is recorded in `infra/gcp/setup.sh` (Terraform-portable).

**Tags (Mark, 2026-10-15).** A dev tag (`v*-dev.*`, e.g. `v0.4.0-dev.30-crew-replies`)
builds the macOS zip straight away; tag it only after a green local `make test`
(use the pinned runtime: `PATH=$PWD/runtime/bin:$PATH make test`). Any other `v*` tag
is a release: `release.yml` runs the full CI suite first and builds only if it passes.

## Development cycle: design doc → sprint plan → execute → evaluate

1. **Design doc.** Write it in `design_docs/planned/<release>/<id>.md`, using the
   format in `design_docs/README.md`.
   - It opens with the **pillar-alignment table**. Use the `game-vision-designer`
     skill to score it.
   - It links to the design-repo feature docs and physics-spec sections it
     implements.
   - Every acceptance criterion must be checkable by a command.
2. **Sprint plan.** Use the `sprint-planner` skill. Output goes to
   `design_docs/planned/<release>/<id>-sprint.md` plus
   `.ailang/state/sprints/sprint_<id>.json`. **Stop for approval** before
   executing.
3. **Execute.** Use the `sprint-executor` skill: test-first, progress in the
   sprint JSON.
4. **Evaluate.** Use the `sprint-evaluator` skill, run by a *different* agent
   or model from the executor (generator ≠ judge). It scores 100 points, 70 to
   pass. Output goes to `.ailang/state/evaluations/`.
5. **Landing.** Move the design doc to `design_docs/implemented/<release>/`,
   update the design repo's roadmap status, and add a changelog entry.

The R1 roadmap is also drafted as a `mission-control` charter
(`design_docs/stapledon-mission.md`). Mark armed the loop on 2026-09-27 and
ratified the charter on 2026-09-28 (ledger D-1). Inspect the current launchd
and issue status before reporting what it is doing; scheduling does not mean
an iteration is running.

## Recording Mark's decisions

The loop asks questions as OPEN rows in the charter's decision ledger
(`design_docs/stapledon-mission.md`, `## Decision ledger`) and lists them on
issue #1. Mark answers through either of two channels, **equal in rank**:

- **Remotely:** comment on issue #1 from his GitHub account.
- **In an attended session:** when Mark states a ruling, record it straight
  into the ledger. Don't send him back to the issue:

  ```sh
  A=~/dev/sunholo-data/ailang/scripts
  $A/mission_answer.sh --id D-n --answer "one line, no leading ANSWERED" \
      --file design_docs/stapledon-mission.md --commit
  $A/mission_decisions.sh --check --file design_docs/stapledon-mission.md && git push
  ```

  If the loop is mid-iteration (`~/.ailang/state/mission-stapledon.pid` is
  alive), do this from a separate worktree on `origin/main` and push. The loop
  rebases onto it.

Only the **unattended** loop is barred from resolving rows itself. This is
`mission-control` gate 0, "ATTENDED LEDGER EDITS".

## Definition of done (gates, in this order)

1. **`make test` is green locally and in CI.**
2. **Physics.** Every visual that shows SR or GR has the following, *before*
   it merges:
   - check values from `stapledons-design/physics/relativity-spec.md` asserted
     in `tests/test_physics.gd`;
   - a GPU-vs-CPU golden case in `make golden`;
   - reference renders you have actually opened and looked at.
3. **Physics maths lives in `sunholo/relativity`.** New formulas go into the
   package first: tests, `CHANGELOG`, `[release] kind`, `ailang pkg quality`
   with no gates, then publish. The simulation then pins the new version. GDScript
   and shaders mirror the package; they are never the only copy.
4. **The simulation core stays pure.** `sim/core.ail` must pass
   `--strict-bytecode` (`make strict`). I/O belongs in `sim/ship.ail` only.
   The VM and the interpreter must stay bit-identical (`make parity`).
5. **Precision.**
   - Godot `Vector3` is float32, so physics that needs precision uses float64
     scalars.
   - Take γ and 1−β from the simulation or package; never compute `1.0 - beta`
     near c.
   - Every lookup table must be finite across its whole range, with a test.
6. **Determinism.** The simulation has no hidden state. Given the same seed and
   inputs, it must produce byte-identical output.

## Python

**The game is AILANG + Godot.** Simulation, physics, data pipelines and offline
tools are AILANG; image, file and GPU I/O is Godot (a headless `--script` is
fine); shell is for downloads and glue. Python is allowed only as:

- an **oracle**: an independent reference in a second language, which catches
  bugs the VM and the interpreter would share;
- a **harness**: glue that drives AILANG or Godot in a test and checks evidence;
- a **spike**: throwaway exploration, never a pipeline step; port it or delete it.

Every tracked `*.py` is listed with its role in `tools/python-allowlist.txt`,
and `make python-guard` (part of `make test`) fails on anything unlisted. A new
pipeline step in Python is a defect: write it in AILANG, and when AILANG can't
do it, that's an upstream gap to report, not a reason to fall back. Role `port`
marks the remaining Python pipeline steps awaiting their AILANG port.

## Searching the filesystem (agents and evaluators)

Never walk home or root: no unbounded find, grep -r, rg, fd or du over /, ~,
$HOME, /Users/..., /Volumes or ~/dev, and no -maxdepth above 3 on them. On
2026-10-02 such a walk hung the rig. Search inside the repo or your worktree
(git ls-files piped to grep, or find on a repo subdir with -maxdepth 4). Known
paths: AILANG packages in runtime/cache/registry/OWNER/PKG/VER/ (or
~/.ailang/cache/registry/...), star data under data/, the design repo at
../stapledons-design, Blender work at ~/dev/blender. A PreToolUse hook
(.claude/hooks/no-broad-find.sh) enforces this for every agent in a session.

## Project brain (semantic memory)

`.claude/settings.json` wires the AILANG brain, the same embedding search the game's AI layer will
use. On each prompt, `.claude/hooks/brain-prompt.sh` injects up to 3 project-brain matches
scoring at least 0.55. That floor was measured here; ailang's own hook uses 0.70 over both brains,
and that lets a user-brain frame that matches everything through. On each commit, `.claude/hooks/brain-commit.sh` banks the
commit, with the first 2 KB of any design doc or changelog it touches, into the **main checkout's**
`.ailang/state/brain.db`. It does this even when the commit is made in the attended clone. Search
it yourself with `ailang cache search "<question>"`. Backfill with
`.claude/hooks/brain-commit.sh --backfill <range>`. `AILANG_BRAIN_HOOKS=0` disables both hooks.
The brain is local and untracked.

## AILANG

- **Report every AILANG bug or DX problem** with `ailang messages` to inbox
  `user`, `--from stapledons_godot`, with a minimal repro and the version.
  Export `AILANG_STORAGE_MESSAGING=gcp` and
  `AILANG_MESSAGES_PROJECT=ailang-multivac` first; without them the message only
  reaches a local store nobody reads.
- **Workarounds, re-checked on v0.54.14 (re-check again at each bump; still-needed ones reported as ailang#1783):**
  - Open (ailang#1827 fixed in v0.54.10, performance): with crew_core 0.5.0 the busy no-hold crew skip
    measures about 11 s on the Studio (was ~40 s), not the 2 s D-82 hoped for; Mark (2026-10-16)
    accepted that, and `crew-perf`'s `crewSkipUnheld` ceiling is 30 s.
  - Kept on purpose: `ailang check --package` beside `ailang test --package`. Since v0.54.13 the
    test runner type-checks every module and exits 1 on a compile error, but only `check` enforces
    STRICT_FALLBACK_001 (an unannotated empty `Ok`).
  - Process, not a bug: run `ailang lock` after `ailang install`; on a clean machine `ailang lock`
    also fills the package cache (`make deps`).
  - Language rule since v0.52.0: an explicitly imported name may not also be defined at module
    level (MOD015). Alias the import (`import M (x as mX)`) or rename. An aliased constructor
    import is rejected in a pattern (TC_MATCH_001); `sim/tripphase.ail` maps phases to an index.
  - Fixed and removed from the tree on v0.54.13/v0.54.14 (byte-identical outputs unless noted):
    every strict-VM list-literal split (ailang#1736, #1865: the ISM efficacy LUT, cloud planes and
    members are single literals; `applyOverride` is one chain; the crew-names table runs strict,
    `make strict` namesVm; the scripted crossing still uses role ids until the crew console sprint
    (D-80) switches it to names and re-records `crossing_hold`); the #1576 doubling in `ai/voice.ail` and the
    tail-recursive lens-table builders; the #1737 named test checks; the v0.52.0 workarounds (#1460,
    #1461, #1465, #1467, #1473, #1478, #1486, #1503, #1505, #1516, #1517, #1419 notes). The arm64
    and x86_64 replay goldens are identical but still kept per architecture.
  - Fixed upstream, nothing in-tree: `std/env.getEnvOr` of an unset variable on the bytecode VM
    (broken in v0.54.13, fixed in v0.54.14, #1864); std/map on the strict VM and `readLineOpt`
    (v0.54.11); the ~20 GB cold compile of crew_core (v0.54.8, #1812). `spawnProcessResult`
    (#1784), sharedindex scan order (#1795) and `std/package.assetPath` (#1772) are unused here;
    every `--entry` names an exported function (#1797); no `CACHE_WRITE_FAILED` (#1601).
- The game is meant to stress-test the AILANG bytecode VM. When the VM and the
  interpreter disagree, that's an upstream bug: shrink it to a minimal repro
  and report it.
