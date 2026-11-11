# Sprint plan: R1-7AL-SESSION-MINORS — one source for the session minors (row 7al)

**Design doc:** [m4-7al-session-minors.md](m4-7al-session-minors.md) (revision 2; quorum round 1 BLOCKED 3/3 on
narrow points → r1; round 2 BLOCKED 2/3, kimi-k3 pass → r2 by the controller under the narrow-refinement
carve-out: glm's `missbridge`/`misssite` controls + V23, gpt's captured grep-status + `brokentest` + the r2
`notests` file; option (b) never disputed; no round 3, straight to planning). **Sprint JSON:**
`.ailang/state/sprints/sprint_R1-7AL-SESSION-MINORS.json`.
**Approval basis:** pillar table net 0, none below 0, no open questions (neutral suite hygiene; unattended loop
proceeds).
**Branch:** `mission/stapledon-iter87-7al` (HEAD `1c9018c4`, the r2 design commit; merge-base with `origin/main`
is `8334b124` = `origin/main` = the base every V-number was measured at; `git diff --name-only 8334b124..HEAD`
= the design doc alone, so every V-number applies verbatim; `git status --porcelain` empty).
**Scope:** about 240 LOC (design header): `bridge/sim_bridge.gd` +5 (a 4-line doc comment and
`const SESSION_MINOR := 18` after `:77`); one token each at `main.gd:304`, `demos/ship_geometry_demo.gd:1025`,
`ui/loading_jump.gd:254`; four test comparisons (`tests/test_bh_hud.gd:109,176`, `tests/test_comms_station.gd:133`,
`tests/test_ship_ui.gd:416`); `Makefile` +40 after `:133` (Appendix A); `tools/session_minor_guard_controls.sh`
new (Appendix B; 204-line extraction planner-measured, see D2); plus the changelog fragment. No physics, no
sim, no assets.
**No GPU, no `make golden`, no capture, no full local `make test`** (merge rule, CLAUDE.md; 7af–7ak precedent);
the targeted gates are the two new headless make targets plus the four Godot rows of MS2 on a warm compile, and
the GitHub fast tier on the draft PR (AC19). The nightly `rig/full` runs the suite on main post-merge.

**Role split:** the planner ran no Godot and no make (this file is planned read-only; all plan-time checks were
git/grep/awk reads) and runs no git write. The controller commits and lands. The executor edits the tree and runs
everything below **except** MS3's push and PR steps, which are marked **(controller)** per the mission. The
executor's only git-adjacent commands are the read-only AC15–AC18/AC20 checks; none writes git state.

## Environment (executor)

```sh
cd <executor clone>
export PATH=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin:$PATH  # AC preamble: "or the main
                                   # checkout's runtime/bin" (this clone has no runtime/); AILANG v0.56.1, Godot 4.7.2
B=8334b124                          # origin/main = the design's base; every V-number applies
S=$PWD/.godot/tmp/7al; mkdir -p "$S"   # scratch; .godot/ is .gitignore:1
export TMPDIR="$S"                  # only while the sandbox blocks /tmp (planner-measured, D1);
                                    # Appendix B/C honour ${TMPDIR:-/tmp}
```

Preamble once per session (every command headless, from the clone root; `perl -e 'alarm N; exec @ARGV'` bounds
every long run, 7ah/7ak pattern):

```sh
ailang --version    # expect "AILANG v0.56.1" (commit 05c860a); anything else -> stop
godot --version     # expect 4.7.2.stable…
```

If the executor clone has its own `runtime/bin` staged (`make runtime`, `Makefile:725`), `$PWD/runtime/bin` per
the AC preamble is equivalent; the version assert is the gate either way.

**Host note (Studio, per the mission):** the host is heavily loaded. Godot test runs (MS2) take **5–10 min** each
under load, and the first sim run in a fresh clone can hit `startup_timeout` on a **cold** sim compile — one warm
run fixes it and it is **not a regression** (the design's Verification log: the first two Godot runs failed
exactly this way at load 60–155; the warm runs below are the measurements). `loading-jump-test` and
`ship-ui-test` carry 600 s `SCRIPT_GATE` budgets (`Makefile:1240`, `Makefile:1371`); a run that exhausts its
budget under load is paused and re-run on a quieter host — never bump the bound silently.

## Plan-time checks (planner, 2026-11-11, HEAD `1c9018c4`)

Cheap re-verification of the doc's claims against the tree (all read-only, bounded):

- **Base/HEAD.** HEAD = r2 design commit `1c9018c4`; merge-base with `origin/main` = `8334b124` = `origin/main`;
  only the design doc differs. `git status --porcelain` empty.
- **Cited lines — all match the tree (planner-verified at HEAD = base for the code files).**
  `bridge/sim_bridge.gd:77` = `const EARTH_LOG_MINOR := 18`; `main.gd:304` = the `_run_map` ask naming
  `SimBridge.EARTH_LOG_MINOR` with its trailing history comment; `demos/ship_geometry_demo.gd:1025` =
  `journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.EARTH_LOG_MINOR # …`; `ui/loading_jump.gd:254` =
  `holder["value"] = SimBridge.warm(SimBridge.EARTH_LOG_MINOR) # …`. Test sites: `tests/test_bh_hud.gd:109,176`
  and `tests/test_comms_station.gd:133` compare `journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR`;
  `tests/test_ship_ui.gd:416` compares `hello_reply.proto.minor == SimBridge.EARTH_LOG_MINOR`;
  `demos/ship_consoles.gd:1186` = the `>=` feature floor quoted in the doc (V18), the file's only
  `SimBridge.*_MINOR`.
- **Makefile anchors.** `ci-fast:` at `:55`, `test:` at `:57` (never edited); the include list at `:30–40`;
  7ah's block ends at `:133` (`\t@MAKE='$(MAKE)' sh tools/similar_guard_controls.sh .`), so Appendix A inserts
  after one blank line there; `make -pq` counts **21** `ci-fast` prerequisites at HEAD (V19's `origin/main`
  number; 23 after the block lands). `similar-main-guard` at `:116`, `similar-guard-controls` at `:132`.
- **Godot row anchors.** `loading-jump-test: import` at `:1239`, recipe `:1240`
  (`$(SCRIPT_GATE) loading-jump-test $(SCRATCH)/loading-jump.log 600 '^loading-jump: [1-9][0-9]* passed, 0
  failures$$'`); `SCRATCH := .godot/tmp` (`:13`). `comms-station-test` lives in `mk/earth-link.mk:6` (log
  `.godot/tmp/comms-station.log`). `bh-hud-test: lens-assets` at `:415` (its recipe gates on the `bh-hud:` tail;
  not SCRIPT_GATE-wrapped). `ship-ui-test: import` at `:1370`, recipe 600 s, log `.godot/tmp/ship-ui.log`.
  `lens-assets` at `:1035`; `runtime:` at `:725`; `import:` at `:42`.
- **Fence extraction (commands in "Byte-for-byte rule") planner-measured:** A.mk = **40** lines (matches the
  header's "Makefile +40"), carries the two edge lines at its `:13–14`; B.sh = **204** lines (see D2), first
  line `#!/bin/sh`, last line `echo "session-minor-guard-controls: $rejected rejected, $accepted accepted"`, 0
  tabs, the r2 cases R17/R18/R19 at its `:166/:172/:178` and the r2 `notests` `printf` after R16 (`:158`);
  7al_meta.sh = **43** lines, `#!/bin/sh` … `echo "meta: $caught weakenings caught"`.
- **Tools on this host:** `gmake`, `/bin/dash`, `shellcheck`, `godot` 4.7.2 all on PATH; macOS make is GNU Make
  3.81 and Homebrew gmake is 4.4.1 (V21's pair). **grep flavour differs:** this planner's PATH grep is BSD grep
  `2.6.0-FreeBSD`, the designer's was ugrep 7.8.4 (V24's partial probe). Both exit 2 on a dangling symlink beside
  a matching file, but the `brokentest` case is **UNMEASURED** in the doc (V24): MS1 measures and records it,
  with the doc's `chmod 000` fallback if not `grep rc 2`.
- **Clone state.** `.godot/` already imported (the designer's `godot --headless --path . --import`, rc 0;
  the 7 CSV-translation errors are pre-existing). `data/lens/lens_fwd.bin` and `lens_inv.bin` are the designer's
  symlinks into the main checkout, verified against `data/lens/SHA256SUMS` (untracked, `.gitignore:34`) — a
  fresh clone re-imports and runs `make lens-assets` instead (Design AC preamble; without them `bh-hud` fails 7
  checks with `gr lens: lens_fwd missing`). No `runtime/` — see Environment.
- **Workflow.** `.github/workflows/ci.yml` is `name: CI`; the job runs on `ubuntu-latest`; steps invoke
  `make deps` then `make ci-fast` on push/PR (Godot only installed under `inputs.full`, ci.yml:41–42 — V4).
  AC19's `--workflow ci.yml` selects it; V20 proved the job-log pipeline on main's run `42991331626`.

**Discrepancies (record, don't fix mid-sprint):**

- **D1. `/tmp` and TMPDIR.** This sandbox refuses writes to `/tmp` (planner-measured:
  `touch /tmp/7al_plan_probe` → `Operation not permitted`), as in 7ah/7ak. Affected paths: AC12's
  `/tmp/7al_meta.sh`, AC13's `/tmp/7al_noop.sh`, AC18's `/tmp/7al_pr`/`/tmp/7al_base`, and both scripts'
  `mktemp` roots via `${TMPDIR:-/tmp}`. Reroot 1:1 to `$S` with `export TMPDIR="$S"` (Environment): every
  `/tmp/7al_…` path becomes `$S/7al_…`, expectations byte-identical (`sh $S/7al_meta.sh "$PWD"` prints the same
  lines; AC15's `find "${TMPDIR:-/tmp}"` then scans `$S` and must still print `0`). If the executor's sandbox
  allows `/tmp`, run as written — assert the same outputs. The scripts never touch the tree regardless (AC15).
- **D2. Script size line-count.** The design header says the script is "new, 183 lines (Appendix B)". The r2
  fence extracts to **204** lines: 183 was the revision-1 prototype count and r2 added the `missbridge`,
  `misssite`, `brokentest` cases and the r2 `notests` readable-test file (~21 lines). The header and the
  ~240 LOC estimate keep their r1 numbers (same shape as 7ah's header discrepancy). The fence is authoritative
  (V17's byte-identity discipline); do not fix the header mid-sprint.

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the three fences, build the tree from the extractions, prove
with `cmp`:

```sh
D=design_docs/planned/r1/m4-7al-session-minors.md
awk '/^## Appendix A\./,/^## Appendix B\./' $D | awk '/^```make$/{f=1;next} /^```$/{if(f){exit}} f' > $S/A.mk
awk '/^## Appendix B\./,/^## Appendix C\./' $D | awk '/^```sh$/{f=1;next}  /^```$/{if(f){exit}} f' > $S/B.sh
awk '/^## Appendix C\./,0'                  $D | awk '/^```sh$/{f=1;next}  /^```$/{if(f){exit}} f' > $S/7al_meta.sh
wc -l $S/A.mk $S/B.sh $S/7al_meta.sh    # expect 40, 204, 43 (planner-measured)
```

Tabs survive awk (planner-measured: A's 24 tab-led recipe lines). The cmp proofs close in MS1 (the Makefile
region and the script) and MS2 (the meta file exactly as run). A cmp mismatch means re-extract, never retype.

## Test-first order (mandatory)

The design's sub-milestones **T1 → M1 → M4 → V → G** map to **MS1** (T1 RED first, then M1 + the Appendix-A
edges green — note: Appendix A carries the `test:`/`ci-fast:` edge lines, so M4's wiring lands with the block;
its AC9 evidence waits for MS3 per the mission's cut), **MS2** (V: the Godot rows, the meta-drills, AC14),
**MS3** (G: fragment, AC9, the controller's push/draft-PR/AC19). The RED half comes first: on the unchanged
tree the sites still name `EARTH_LOG_MINOR` and there is no `SESSION_MINOR`, so the guard **must** fail — and it
fails at its first branch, `SESSION MINOR unresolved` (design T1: red first; not run at design time, so MS1's
run is the first measurement — record actuals). Never present a control as green that never went red:

| New/changed line | Killing control (proves it can fail) | Exact red evidence |
|---|---|---|
| The whole Makefile block + the controls script | **T1 on the unchanged tree** (MS1 step 4) | `make session-minor-guard` rc 2 with `session-minor guard: SESSION_MINOR unresolved in bridge/sim_bridge.gd` (+ `make: *** [session-minor-guard] Error 1`); `make session-minor-guard-controls` stops at `session-minor-guard-controls: pristine: make rc 2, want 0`, make rc 2, no totals line |
| `bridge/sim_bridge.gd` `const SESSION_MINOR := 18` | controls `nosession`, `exprsession`, `orphan`; meta-drill M3 | each rejected with its exact line in AC2's run |
| The three site tokens | controls `map`, `ship`, `prefetch` (plus `literal`, `arith`, `ternary`, `twice`, `removed`, `renamed`, `unbounded`, `stray`); in-tree drills AC3–AC5 | AC3–AC5 each print `session-minor guard: <file> <func> does not ask SimBridge.SESSION_MINOR` (or the testname line), `make: *** [session-minor-guard] Error 1`, `rc=2`, each restored by its own `mv` in the same command |
| The four test comparisons | control `testname`; in-tree drill AC6; scan known-positive `notests` | AC6: `session-minor guard: tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`, `rc=2` |
| The r2 grep-status capture (no `or true`) | control `brokentest` — **V24: UNMEASURED in the doc, MS1 measures it** | `session-minor guard: test scan error (grep rc 2)`; if this host's grep does not exit 2 on the dangling symlink, the doc's stated fallback applies (the case's symlink becomes an unreadable file via `chmod 000`), recorded in the sprint JSON |
| The r2 missing-file branches | controls `missbridge`, `misssite` — **V24: UNMEASURED** | `session-minor guard: missing bridge/sim_bridge.gd` / `session-minor guard: missing main.gd` |
| The r2 `notests` mutation (one readable empty test, so grep exits 1 not 2) | control `notests` — **V24: UNMEASURED in its r2 form** | `session-minor guard: no test compares journey_sim's minor with a SimBridge constant` |

Green expectation after M1 (V9/V21 measured): the AC1 ok line, rc 0.

## Milestones

### MS1 — T1 red → M1+M4 green: guard, controls, the one constant, three tokens, four test comparisons

Files (the design's nine paths): `Makefile` (insert after `:133`, one blank line + the Appendix-A block),
`tools/session_minor_guard_controls.sh` (new, from `$S/B.sh`), `bridge/sim_bridge.gd` (insert after `:77`),
`main.gd` (`:304`, one token), `demos/ship_geometry_demo.gd` (`:1025`, one token), `ui/loading_jump.gd`
(`:254`, one token), `tests/test_bh_hud.gd` (`:109`, `:176`), `tests/test_comms_station.gd` (`:133`),
`tests/test_ship_ui.gd` (`:416`).
Closes: **AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC13, AC15, AC16, AC17, AC18, AC20.** All headless, no Godot.

1. **Preamble + anchor assert (cheap; stop on any mismatch):** the Environment block; then
   `sed -n '77p' bridge/sim_bridge.gd; sed -n '304p' main.gd; sed -n '1025p' demos/ship_geometry_demo.gd;
   sed -n '254p' ui/loading_jump.gd; sed -n '109p;176p' tests/test_bh_hud.gd; sed -n '133p'
   tests/test_comms_station.gd; sed -n '416p' tests/test_ship_ui.gd; sed -n '105,133p' Makefile | tail -1` → the
   planner-verified lines above (the last is 7ah's `@MAKE=` recipe at `:133`).
2. **Fence extraction** (Byte-for-byte rule) → `40`, `204`, `43`.
3. **Apply the appendices:**
   ```sh
   awk 'NR<=133 {print; next} NR==134 {print ""; while((getline l < "'"$S"'/A.mk") > 0) print l} {print}' Makefile > $S/Makefile.new
   cmp -s <(sed -n '1,133p' Makefile) <(sed -n '1,133p' $S/Makefile.new) && echo head-unchanged   # 7ah's block bytes untouched
   mv $S/Makefile.new Makefile
   cp $S/B.sh tools/session_minor_guard_controls.sh    # invoked via `sh` (Appendix A's recipe); no +x needed
   ```
   The `ci-fast:`/`test:` lines (`:55`,`:57`), the include list (`:30–40`) and `Makefile:105–133` are never
   edited; `mk/script-gates.mk:27` is the edge pattern's precedent, untouched.
4. **RED evidence — T1 on the unchanged tree (record actuals; the first run of this guard ever):**
   `make session-minor-guard; echo rc=$?` → `session-minor guard: SESSION_MINOR unresolved in
   bridge/sim_bridge.gd`, `make: *** [session-minor-guard] Error 1`, `rc=2` (the sites still name
   `EARTH_LOG_MINOR`, and there is no `SESSION_MINOR` at all). `make session-minor-guard-controls; echo rc=$?` →
   stops at `session-minor-guard-controls: pristine: make rc 2, want 0`, make rc 2; no `rejected`, no accepted,
   no totals line. Record both outputs in the sprint JSON.
5. **M1 product + test edits** (design "M1", one line + three tokens + four comparisons):
   - `bridge/sim_bridge.gd`: after `:77` insert a 4-line doc comment (names the three sites — `main.gd`
     `_run_map`, `demos/ship_geometry_demo.gd` `_create_navigation`, `ui/loading_jump.gd` `_work_sim` — and says
     a bump moves this line) then **byte-exact** `const SESSION_MINOR := 18` — the guard's resolver and AC7's
     sed both anchor on `^const SESSION_MINOR := <digits>$`.
   - Sites (one token each; trailing history comments kept byte-identical):
     `sed -i.bak -e '1025s/SimBridge\.EARTH_LOG_MINOR/SimBridge.SESSION_MINOR/' demos/ship_geometry_demo.gd && rm demos/ship_geometry_demo.gd.bak`
     and the same swap at `main.gd:304` and `ui/loading_jump.gd:254`; verify each edited line is unchanged
     except the one token (`git diff` shows 1+/1− per file).
   - Tests: `tests/test_bh_hud.gd:109,176` and `tests/test_ship_ui.gd:416` — the same one-token swap in the
     comparison, check messages unchanged. `tests/test_comms_station.gd:133`: the comparison becomes
     `demo.journey_sim.want_minor == SimBridge.SESSION_MINOR and SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR`
     (the floor keeps the feature's own 2.18 need) and the message becomes `the session asks SESSION_MINOR (2.18
     or later) and the world carries earth and its log`; the `world.get("earth") … world.get("earth_log") …`
     tail is unchanged (V15's `ok the session asks SESSION_MINOR (2.18 or later) …` at 42/0).
6. **cmp proofs + GREEN:**
   ```sh
   cmp $S/B.sh tools/session_minor_guard_controls.sh && echo B-ok
   b=$(grep -n '^# Row 7al: one source' Makefile | cut -d: -f1); test -n "$b" || exit 1
   sed -n "${b},$((b+39))p" Makefile > $S/A.tree.mk; cmp $S/A.mk $S/A.tree.mk && echo A-ok
   ```
   then **AC1** — `make session-minor-guard; echo rc=$?` →
   `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd
   _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it`, `rc=0` (V9/V21;
   under 0.1 s).
7. **AC2 (the controls; ~2–4 s, V21)** — `make session-minor-guard-controls; echo rc=$?` → the **22 case lines
   of the M3 table in order** (`pristine map ship prefetch literal arith ternary twice removed renamed unbounded
   stray nosession exprsession orphan testname notests missbridge misssite brokentest bump comment`), each
   `session-minor-guard-controls: <case> rejected (session-minor guard: <exact line>)` or `… <case> accepted`,
   then `session-minor-guard-controls: 19 rejected, 3 accepted`, `rc=0`.
   **V24 — record verbatim in the sprint JSON** the four items the doc leaves unmeasured: the `missbridge`,
   `misssite`, `brokentest` case lines and the r2 `notests` case line. `brokentest` must read `rejected
   (session-minor guard: test scan error (grep rc 2))`: if this host's grep does not exit 2 on the dangling
   `tests/broken.gd` symlink (the readable tests still emit their comparisons), apply the doc's stated fallback
   — the case replaces the symlink with an unreadable file (`chmod 000`) — record which form ran and its exact
   line. Any other deviation (case count, order, reason text, totals ≠ 19/3) → stop (Pause points).
8. **AC3–AC7 in-tree RED drills, verbatim from the design's AC table** (each mutation is proven, then restored
   by its own `mv` in the same command line; V9 re-asserted green after each `mv`):
   - **AC3:** `sed -i.bak '/^func _run_map(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_LOG_MINOR/' main.gd && make -s session-minor-guard; echo rc=$?; mv main.gd.bak main.gd` → `session-minor guard: main.gd _run_map does not ask SimBridge.SESSION_MINOR`, `make: *** [session-minor-guard] Error 1`, `rc=2`.
   - **AC4:** `sed -i.bak '/^func _create_navigation(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_MINOR/' demos/ship_geometry_demo.gd && make -s session-minor-guard; echo rc=$?; mv demos/ship_geometry_demo.gd.bak demos/ship_geometry_demo.gd` → `session-minor guard: demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR`, `rc=2`.
   - **AC5:** `sed -i.bak '/^func _work_sim(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_LOG_MINOR/' ui/loading_jump.gd && make -s session-minor-guard; echo rc=$?; mv ui/loading_jump.gd.bak ui/loading_jump.gd` → `session-minor guard: ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`, `rc=2`.
   - **AC6:** `sed -i.bak 's/journey_sim\.want_minor == SimBridge\.SESSION_MINOR/journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR/' tests/test_comms_station.gd && make -s session-minor-guard; echo rc=$?; mv tests/test_comms_station.gd.bak tests/test_comms_station.gd` → `session-minor guard: tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`, `rc=2`.
   - **AC7 (a bump is one line):** `sed -i.bak 's/^const SESSION_MINOR := 18$/const SESSION_MINOR := 17/' bridge/sim_bridge.gd && make -s session-minor-guard; echo rc=$?; mv bridge/sim_bridge.gd.bak bridge/sim_bridge.gd` → `session-minor guard: ok, SESSION_MINOR (17) = WORLDS_MINOR; …; 4 test comparisons name it`, `rc=0`.
9. **AC8 (7ah stays green):** `make similar-main-guard similar-guard-controls; echo rc=$?` →
   `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)`, …,
   `similar-guard-controls: 13 rejected, 3 accepted`, `rc=0` (V14; 7ah's guard reads the property, so it passes
   unchanged on the new constant — it is never edited).
10. **AC13 (no-op mutation exits 3):** `/tmp` → `$S` per D1 (the design's literal path is
    `/tmp/7al_noop.sh`): `sed '/^mutate map /s/\\1EARTH_LOG_MINOR/\\1SESSION_MINOR/' tools/session_minor_guard_controls.sh > /tmp/7al_noop.sh; MAKE=make sh /tmp/7al_noop.sh . >/dev/null; echo rc=$?` →
    `session-minor-guard-controls: map: mutation left main.gd unchanged` on stderr, `rc=3`.
11. **AC15/AC16/AC17/AC18/AC20**, commands verbatim from the design (AC15 and AC18's `/tmp` paths → `$S` per D1):

**AC15** — expected `unchanged`, then `0`:

```sh
h=$(shasum bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_*.gd Makefile | shasum); make -s session-minor-guard-controls >/dev/null; test "$h" = "$(shasum bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_*.gd Makefile | shasum)" && echo unchanged; find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'session-minor-guard.*' | wc -l
```

**AC16** — `make uid-guard python-guard script-gate-lint audio-silent-guard; echo rc=$?; git diff --check origin/main; echo rc=$?` →
`uid-guard: ok`, `python-guard: ok`, `script-gate-lint: ok`, `audio-silent-guard: ok`, `rc=0`, `rc=0` (the new
script is shell: no `.uid`, no Python allowlist row).

**AC17** — `git diff --name-only origin/main` → at MS1 exactly the nine touched paths plus
`design_docs/`/`.ailang/state/` files (the changelog fragment joins at MS3, where this re-runs; AC17's full
expected set is the nine paths plus the fragment and docs/state).

**AC18** — `conflicts=0` twice (merge base `B` with attended PR #412; the only #412 file this row touches is
`demos/ship_geometry_demo.gd`, and no #412 hunk is within 3 lines of `:1025` or touches a `want_minor`/`_MINOR`
line, V16):

```sh
B=$(git merge-base origin/main origin/feat/captain-command); for f in demos/ship_geometry_demo.gd Makefile; do git show origin/feat/captain-command:$f > /tmp/7al_pr; git show $B:$f > /tmp/7al_base; git merge-file -p /tmp/7al_pr /tmp/7al_base $f > /dev/null; echo conflicts=$?; done
```

**AC20** — the production comparison enumeration still matches V18/V23 (first: the five `want_minor`
assignments — `demos/black_hole_visit.gd:52`, `demos/ship_geometry_demo.gd:1025` with `SESSION_MINOR`,
`main.gd:258`, `:304` with `SESSION_MINOR`, `:414`; second: exactly `demos/ship_consoles.gd:1186` (or its moved
line) and the two `bridge/` validity reads). Any **new** production comparison of a session minor must be added
to the scan or recorded as a blind spot before landing:

```sh
git grep -nE '(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' -- demos/ main.gd ui/ interior/ sky/ bridge/
git grep -nE 'get\("minor"' -- demos/ main.gd ui/ interior/ sky/ bridge/
```

12. **Cleanliness:** `git status --porcelain` shows only the nine touched files (plus the controller's
    plan/JSON) and no `.bak` files; the AC3–AC7 `mv`s restored the tree (V9).

### MS2 — V: runtime evidence on a warm compile (AC10, AC11), meta-drills (AC12), robustness matrix (AC14)

Files: none persisted (`/tmp/7al_meta.sh` is sprint evidence, never committed — design Deliverables/AC12).
Depends on MS1. All bounded; Godot runs individually bounded by their `SCRIPT_GATE` budgets (600 s).

1. **Fresh-clone prerequisites (this clone already has both):** a first `godot --headless --path . --import`
   (rc 0, ~43 s; the 7 CSV-translation errors are pre-existing) and the lens tables (`make lens-assets`,
   `Makefile:1035`, seconds from the bucket — or the symlinks this clone already carries, verify with
   `sh tools/lens_assets.sh verify`). Without the tables `bh-hud` fails 7 checks with `gr lens: lens_fwd
   missing` (Verification log).
2. **Warm the compile first (host note):** if the first Godot run dies at `startup_timeout` on a cold sim
   compile under load, that is the measured cold-compile failure, not a regression — re-run once warm.
3. **AC10** — `make loading-jump-test; echo rc=$?` → the log (`.godot/tmp/loading-jump.log`, bounded 600 s at
   `Makefile:1240`) ends `loading-jump: 77 passed, 0 failures` including the three `… prefetched simulation`
   checks, `rc=0` (5–10 min under Studio load).
4. **AC11** — `make comms-station-test bh-hud-test ship-ui-test; echo rc=$?` → `comms-station: 42 passed, 0
   failures` (`.godot/tmp/comms-station.log`; the line now reads `ok the session asks SESSION_MINOR (2.18 or
   later) and the world carries earth and its log`, V15), `bh-hud: 64 passed, 0 failures`,
   `ship-ui: 288 passed, 0 failures` (the exact counts may grow with main), `rc=0`.
5. **AC12 (meta-drills; Appendix C is sprint evidence, saved to `/tmp` — D1: `$S`):**
   `/tmp/7al_meta.sh` is the `$S/7al_meta.sh` extraction (43 lines; if the sandbox allows `/tmp`,
   `cp $S/7al_meta.sh /tmp/7al_meta.sh && cmp /tmp/7al_meta.sh $S/7al_meta.sh && echo C-ok`), then
   `sh /tmp/7al_meta.sh "$PWD"; echo rc=$?` → `meta base: rc 0 :: session-minor-guard-controls: 19 rejected,
   3 accepted`; M1 → `map: make rc 0, want 2`; M2 → `twice: …`; M3 → `orphan: …`; M4 → `testname: …`; M5 →
   `notests: …`; M6 → `arith: …`; M7 (range end back to `^func `) → `stray: make rc 0, want 2`; M8 (bounded
   check deleted) → `unbounded: make rc 0, want 2`; M9 (function-present check deleted) → `renamed: missing
   reason: …`; `meta: 9 weakenings caught`, `rc=0`.
6. **AC14** — commands verbatim from the design (the `-n` pass recursively executes the `$(MAKE)` controls
   line, 7ah pattern; read-only, under 4 s per run, V21):

```sh
for m in make gmake; do for f in '' -n -j4 -k; do $m $f session-minor-guard-controls 2>&1 | tail -n 1; done; done
gmake SHELL=/bin/dash session-minor-guard >/dev/null; echo rc=$?
MAKE=gmake dash tools/session_minor_guard_controls.sh . | tail -n 1
shellcheck tools/session_minor_guard_controls.sh && shellcheck -s dash tools/session_minor_guard_controls.sh
```

   Expected: every controls run ends `session-minor-guard-controls: 19 rejected, 3 accepted` (8 of 8); the dash
   guard `rc=0`; the dash controls end `19 rejected, 3 accepted`; both shellchecks silent (the only finding on
   the r1 prototype was SC2016 on `stray`'s awk `$0`, already silenced in the appendix, V21).

### MS3 — G: changelog fragment + AC9 local half (executor); push, DRAFT PR, AC19 (controller)

Files: `changelogs/unreleased/2026-11-11-session-minors.md`. Depends on MS2. Closes: **AC9** (local half +
its GitHub landing evidence) and **AC19** (the one criterion that cannot run on this host — measured on
GitHub's runner; it **gates the PR leaving draft**).

Executor:

1. **Fragment** (per `changelogs/unreleased/README.md`; the 7ah/7ak shape — `### Added`, since nothing was
   red): name row **7al** and sprint `R1-7AL-SESSION-MINORS`; the three sessions and the four test comparisons
   now name one constant `SimBridge.SESSION_MINOR` (18) in `bridge/sim_bridge.gd`, so a protocol bump the game
   adopts edits one line; `make session-minor-guard` and `make session-minor-guard-controls` (19 rejected, 3
   accepted, ~2 s) run in `make test` and `ci-fast`, so a partial bump fails at the PR instead of the next
   nightly; visible behaviour identical (every session still asks 2.18 and the prefetch is still adopted on all
   three routes, V15); no product, sim, asset or physics change.
2. **AC9 (local half)** — commands verbatim from the design:

```sh
make -n ci-fast 2>/dev/null | grep -cE 'session_minor_guard_controls\.sh|SESSION_MINOR := '
grep -nE '^(test|ci-fast): session-minor-guard session-minor-guard-controls$' Makefile
make -pq 2>/dev/null | grep -E '^ci-fast:' | tr ' ' '\n' | grep -c .
make -pq 2>/dev/null | grep -E '^ci-fast:' | tr ' ' '\n' | grep -nx -e session-minor-guard -e session-minor-guard-controls
```

   Expected: `2`; the two lines `test: session-minor-guard session-minor-guard-controls` and `ci-fast:
   session-minor-guard session-minor-guard-controls`; `23` (21 on `origin/main`); the two new targets 19th and
   20th (V19).
3. **Re-assert hygiene after the fragment:** AC16's line again, and AC17 now showing exactly the nine paths +
   `changelogs/unreleased/2026-11-11-session-minors.md` + `design_docs/`/`.ailang/state/` files; AC15's
   `unchanged` / `0` if anything re-ran. `git status --porcelain` shows only the sprint's own files.
4. **Evidence note (per the mission):** record the sprint's evidence into
   `.ailang/state/sprints/sprint_R1-7AL-SESSION-MINORS.json` before handoff — each milestone's `measured` field
   (the RED actuals of MS1 step 4; AC1's ok line; AC2's 22 case lines **with the four V24 lines verbatim** and
   the `brokentest` symlink-vs-`chmod 000` note; AC3–AC8, AC13, AC15–AC18, AC20 actuals; AC10/AC11 tails; AC12's
   meta log; AC14's matrix; wall times), `passes: true` per milestone, the fragment path, and wall-clock totals
   under `velocity`. MS3's executor half passes only with that evidence recorded; the controller's steps append
   the AC19 run id, head sha and two log lines.

**(controller — the controller, not the executor, pushes and opens the PR, per the mission):**

5. Push the branch and open a **draft** PR with `gh pr create --draft` (`gh`, CLAUDE.md). The PR fires the
   ci.yml fast tier on the PR head.
6. **AC19 (GNU userland, kimi-k3)** — read the fast-tier job log through the API (never `gh run view --log`;
   V20 proved this exact pipeline on main's run `42991331626`, where it found 7ah's two lines) — commands
   verbatim from the design:

```sh
SHA=$(git rev-parse HEAD); R=sunholo-data/stapledons-godot
RUN=$(gh run list -R $R --workflow ci.yml --commit "$SHA" --event pull_request --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view "$RUN" -R $R --json conclusion,headSha --jq '.conclusion+" "+.headSha'
JOB=$(gh run view "$RUN" -R $R --json jobs --jq '.jobs[0].databaseId')
E=$(printf '\033'); gh api --allow-escape-sequences repos/$R/actions/jobs/$JOB/logs | LC_ALL=C sed "s/$E\[[0-9;]*m//g" | grep -cE 'session-minor guard: ok, SESSION_MINOR \(18\) = EARTH_LOG_MINOR; .* 4 test comparisons name it$|session-minor-guard-controls: 19 rejected, 3 accepted$'
```

   Expected: `success <head sha>`; then `2`, the two matching lines being `session-minor guard: ok,
   SESSION_MINOR (18) = EARTH_LOG_MINOR; …; 4 test comparisons name it` and `session-minor-guard-controls: 19
   rejected, 3 accepted` (each after the runner's timestamp). **The PR does not leave draft until this holds.**
   A red or missing run blocks landing — fix the dependency or invocation and re-run the GitHub fast-tier
   check; do not remove either edge or suppress its failure (the design's Risks, verbatim rule).
7. **AC9's GitHub evidence at landing:** after the cross-family evaluation passes and the PR head is the final
   commit, the GitHub fast-tier run on the **final** commit (`gh run list --commit <final sha>`) is `success`,
   and its job log shows the two AC19 lines. Record the run id, its head sha and the two log lines in the
   sprint JSON (AC9 Expected; design Deliverables).

## Pause points (stop and report; do not improvise)

- Preamble: `ailang --version` ≠ v0.56.1 or `godot --version` ≠ 4.7.2 → stop; never let `AILANG ?= ailang`
  (`Makefile:2`, `Makefile:6`) fall through to an unpinned PATH `ailang`.
- MS1: a fence extraction ≠ 40/204/43 lines, a cmp proof fails, or the anchor assert mismatches → re-extract /
  stop; never retype design text. The RED run printing anything but `SESSION_MINOR unresolved in
  bridge/sim_bridge.gd` with make rc 2 → tree drift; stop. AC1/AC3–AC8 any deviation in one token → stop.
  AC2: case count ≠ 22, order wrong, a reason line differs, totals ≠ `19 rejected, 3 accepted`, or make rc ≠ 0
  → stop (the only pre-authorized adjustment is V24's `brokentest` fallback, recorded). AC13 not rc 3 → stop.
  Any `.bak` left or a `mv` not restoring → stop; the tree must be exact (V9).
- MS2: a Godot row's count or the loading-jump log's `… prefetched simulation` checks deviate → fixture or
  product drift; stop and re-measure like the design's V2, never weaken a `SCRIPT_GATE` regex. A meta-drill not
  caught, `meta: 9 weakenings caught` absent, or the no-op AC13 not rc 3 → stop. Cold-compile
  `startup_timeout` → one warm re-run (host note); a run exhausting its 600 s budget under load → pause, re-run
  on a quieter host, never bump the bound silently.
- MS3: AC9's count ≠ `2`, the two rule lines absent, prerequisite count ≠ 23 → stop. AC19: a red/missing run,
  `conclusion` ≠ `success`, the head sha ≠ the PR head, or the final grep ≠ `2` → **landing blocked**: fix and
  re-run; never remove either `ci-fast` edge or suppress its failure (design Risks, verbatim). The PR stays
  draft until AC19 holds.
- Any temptation to touch the do-not-touch list below → stop; the fix needs none of it. No merge before the
  cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **A site function renamed/split or made last-in-file:** fail-loud (`has no func …(`, `mentions <token> 0
  times`, `range unbounded`; controls `renamed`, `removed`, `unbounded`, `stray`) — never silent; the fix is one
  word in the recipe's site list and the script's ranges.
- **A fourth prefetch session appears** (a new title route): the guard does not know it; the nightly
  loading-jump pid checks catch it only if the route is in `test_routes`. The site list is one line to extend.
- **A bump author adds `FOO_MINOR := 19` and forgets `SESSION_MINOR`:** every session stays at 18 together, the
  prefetch still works, and the new feature's own tests fail — the intended trade (Non-goals, b″).
- **A test reads the session minor in another form** (`journey_sim.get("want_minor")` or constant-on-left, F4):
  the scan does not see it; V18/V23 and the AC20 re-enumeration measure none exists today, and `notests` keeps
  the scan known-positive.
- **Production comparisons are a documented blind spot**: the scan reads `tests/*.gd` only;
  `demos/ship_consoles.gd:1186`'s `>=` floor stays true at any bump; the nightly `comms-station-test` floor
  (`SESSION_MINOR >= EARTH_LOG_MINOR` at `:133`) is the backstop; AC20 re-enumerates at MS1.
- **The lexical limit remains at merge time** (7ah's): a write the text does not show passes the guard; the
  nightly runtime checks (`test_ship_ui.gd:416`, the pid checks) catch it — the accepted split (lexical in
  `ci-fast`, runtime nightly).
- **GNU userland is only measured remotely**: this host has no GNU sed/grep/gawk and no docker (kimi-k3's
  blocker); r1 removed the divergent constructs (M3 "Portability") and AC19 measures the runner before the PR
  leaves draft. A runner/environment failure blocks landing — fix, never weaken (design, verbatim).
- **(Planner-added) Host load:** the Studio is heavily loaded — MS2's four Godot runs are 5–10 min each and the
  first can cold-compile into `startup_timeout` (one warm run fixes it); keep the 600 s bounds, pause on a
  saturated host.
- **(Planner-added) grep flavour:** BSD grep here vs the designer's ugrep (V24). Both exit 2 on a dangling
  symlink, but `brokentest` is unmeasured in the doc — MS1 records the actuals; fallback `chmod 000` if not
  `grep rc 2`.
- **(Planner-added) `/tmp` blocked in the sandbox (D1):** all `/tmp/7al_…` paths and both scripts' temp roots
  reroot to `$S` via `TMPDIR`; expectations byte-identical; AC15's leftover check still prints `0`.
- **(Planner-added) A fifth comparison landing on main before this row:** AC19's grep pins `4 test comparisons
  name it` and AC2's pristine accept allows `[1-9][0-9]*`; if main's count moves, AC19's pattern is the thing
  to revisit at landing (its `4` is today's V5 enumeration) — record at AC20.

## Files allowed and do-not-touch (design, verbatim scope)

- **Allowed (the design's nine paths + landing files):** `bridge/sim_bridge.gd`, `main.gd`,
  `demos/ship_geometry_demo.gd` (the one-token `:1025` line only — the one touch inside attended PR #412's
  surface, measured conflict-free at AC18/V16), `ui/loading_jump.gd`, `tests/test_bh_hud.gd`,
  `tests/test_comms_station.gd`, `tests/test_ship_ui.gd`, `Makefile` (insert after `:133` only),
  `tools/session_minor_guard_controls.sh` (new); plus `changelogs/unreleased/2026-11-11-session-minors.md` and
  this sprint's plan/JSON/scratch.
- **Do not touch:** the trailing history comments on the three site lines; 7ah's `similar-main-guard`, its
  controls and `Makefile:105–133`; the `ci-fast:`/`test:` lines (`Makefile:55,57`); the include list
  (`Makefile:30–40`, where #412 adds a line); `demos/ship_consoles.gd`; every other `want_minor` writer
  (`main.gd:258,280,414`, the black-hole visit, tools/tests opening their own sessions); attended PR #412's
  files beyond the one `:1025` token; `sim/`; `tests/fixtures/protocol_*`. No `.gd` changes outside the listed
  tests → no new `.uid`; no Python → no allowlist row.

## Local PR gates (targeted, headless, bounded)

The GitHub fast tier (`make ci-fast`) **gains the two new targets** with this row (that is the point of the
row, design Problem §3/AC9/AC19). Locally:

1. MS1 on record: the T1 RED actuals; the `A-ok`/`B-ok` cmp proofs; AC1's ok line `rc=0`; AC2's 22 case lines,
   `19 rejected, 3 accepted`, the four V24 lines recorded; AC3–AC7 each `rc=2` with their exact reason and the
   tree restored; AC8 (7ah unchanged and green); AC13 `rc=3`; AC15 `unchanged`/`0`; AC16 four guards `ok`; AC17
   the allowed file set; AC18 `conflicts=0` twice; AC20 the enumerated sets.
2. MS2 evidence: AC10 `loading-jump: 77 passed, 0 failures` rc 0; AC11 `42/64/288` (may grow with main) rc 0;
   AC12 `meta: 9 weakenings caught` rc 0 with the `19 rejected, 3 accepted` base; AC14's 8/8 tails, dash rc 0,
   both shellchecks silent.
3. MS3: the fragment in place; AC9 local half (`2`; the two rule lines; `23`); porcelain sprint-files only.
4. The GitHub gate is AC19 on the **draft** PR's head: `success` + the two log lines (gnu userland proof) —
   the controller's read. No GPU gate, no `make golden`, no capture, no full local `make test` (merge rule);
   the nightly `rig/full` runs the suite on main post-merge, and AC10/AC11's four tests are the nightly
   backstops this row leans on.

## Controller checks (the controller re-runs after the executor, before landing)

The T1 RED log vs AC1's GREEN ok line · the `A-ok`/`B-ok` cmp proofs against fresh fence extractions (40/204/43)
· AC2's 22 case lines in order and the V24 four verbatim, plus the `brokentest` instrument note · AC3–AC7's
rc=2 reason lines and restored tree (no `.bak`, porcelain clean) · AC8 (`asks SESSION_MINOR (18)`, 13/3) ·
AC13 rc 3 · AC15 `unchanged`/`0` · AC16 · AC17 (nine paths + fragment + docs/state) · AC18 `conflicts=0` twice ·
AC20's two enumerations against V18 · AC10's log tail and the three prefetch oks · AC11's three counters ·
AC12's meta log (base 19/3, nine M-lines, `9 weakenings caught`) · AC14's matrix · AC9 local half · **AC19 on
the draft-PR head** (`success <head sha>`, grep count `2`) and AC9's final-commit evidence with run id, head
sha and the two log lines recorded in the sprint JSON · the sprint JSON's `measured` fields filled.

## Landing (controller, after the cross-family evaluation passes and AC19 holds) and post-merge check

Fragment already in tree from MS3; `git mv` doc + plan to `design_docs/implemented/r1/`; README index row;
charter row 7al status; sprint JSON → recorded counts, wall times and the AC19/AC9 evidence, `status:
completed`, evaluation block, path moves. The PR leaves draft only after AC19 holds (design AC19). Post-merge
(observation, not a gate): the next nightly `rig/full` (`make test`) runs the two new targets and stays green,
and the next `ci-fast` on main shows the two lines; a `session-minor guard:` failure on an unmutated tree is a
product finding for its own row, never an allowlist entry. If attended #412 lands first, AC18 and AC20 re-run
on the new base before treating the row's ACs as holding.

## Velocity / estimate

~240 LOC (design header; the fence-extraction authority is 40 Makefile + 204 script + ~12 product/test).
Machine time is dominated by MS2's four Godot runs (5–10 min each under Studio load, plus one possible
cold-compile warm-up) and the draft-PR fast tier (~10 min, V19); the guard and controls themselves are seconds
(V21: guard <0.1 s, controls 1.7 s at r1). **This repo's recent rows of this size each took one iteration**
(7ah ~180 LOC one executor session; 7aj ~55; 7ai ~16; 7ak ~4): the same is planned here — one iteration, no
day-count estimated.
