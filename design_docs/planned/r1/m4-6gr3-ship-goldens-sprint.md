# Sprint addendum: R1-M4-JOURNEY — M4.6gR3 ship goldens

**Status:** Planned (mission iteration 35, planner); execution remains pending. **Sprint id:** `R1-M4-JOURNEY`. **Milestone:** `M4.6gR3`, feature `M4.6gR3_SHIP_GOLDENS`.
**Design doc:** [m4-6gr3-ship-goldens.md](m4-6gr3-ship-goldens.md). **Parent sprint:** [m4-first-journey-sprint.md](m4-first-journey-sprint.md#r3-4-m46-gated-half-re-scoped-to-the-3d-ship), Revision round 3 / R3-4.
**Estimate:** one executor iteration, half a day (4 hours), about 160–180 counted LOC: driver about 150, Makefile about 8–15, main hook 1; no fixture files. Reserve up to one day if GPU/gate latency dominates. **Risk:** low implementation risk, moderate GPU/evidence risk.
**Authority:** parent revision approved by D-66; charter explicitly permits M4.6gR3 (see `design_docs/stapledon-mission.md`, “The loop may now build … M4.6gR3”). Historical approval-pending notes in the parent JSON are preserved; this planner adds only a feature. S1 belongs to M4.6rR3 and remains separate.
**Shape models:** [iteration 33 addendum](m4-7ig-context-crosscheck-sprint.md) and iteration 34 addendum read via local `origin/mission/stapledon-iter34-7ij` (`06c25c2`), without fetching. No sprint-planner skill is available in the supplied catalog or clone; these supplied models define the format.

## Reality check at HEAD `8cf3a70`

- Baseline 363 `ok` lines is the supplied/design measured baseline; this planner did not rerun the GPU. Arithmetic is **363 + 3 + 1 + 6 = 373**, correct. S4 is 3 cap profiles + 2 absolute poles + 1 rest.
- `golden` is at Makefile:358; invocation at :360 uses `$(GODOT)`, not `$(GODOT_SIM)`. Add existing `m4-physics-probe` (:182) as a prerequisite; it compares interpreter and VM outputs in `.godot/tmp/m4-physics-probe{,-vm}.txt`. The probe's `stop sun` and `stop guided-cap-2e-9` rows provide the physical poles and cap rapidity; do not confuse the old `glow cap` row (1-beta 1e-6) with the guided cap.
- Last driver is `tools/gr_golden.gd` at main.gd:898; insert the new await immediately before the summary at :899. Use path loading, since tools are excluded from exports.
- Scene seam: setup/composite :120–151, `_draw_layer` :174, `set_sky_state` :280, `_sync_observer` :287 in `demos/ship_geometry_demo.gd`. Camera follows at `ship_demo_camera.gd:13`, sync at :24; `InteriorSky.apply` :196 does not read phase. No production scene edit is needed.
- All four design Perl expressions apply to stdout copies of the current files. D1 appends after camera line 40; D2a replaces shader line 57; D2b replaces forward_glow line 119; D3 replaces scene line 145. Parentheses and literal `$` anchors are correct in these Perl expressions. Paths and AC12 make targets exist.
- Registry reuse: existing `sunholo/relativity` mirrors/probe only. No package, sim, formula, fixture or Python addition.

## Tasks (Day 1, test-first)

1. **RED: Makefile assertions first — 30 minutes.** Add `m4-physics-probe` to `golden` prerequisites. After the interior summary guard, assert exactly 1 S2, 3 S3, 6 S4, the zero-failure ship summary, and 373 total `^ok` lines. Use `test` with `grep -c`, not mere presence for S2. Keep every existing guard. Extend help/failure text with S2/S3/S4 counts. Run AC1 on the executor's GPU window; it must fail for missing ship lines even though legacy cases pass. Save RED evidence.
2. **GREEN: driver and hook — 90 minutes.** Add `tools/m4_ship_golden.gd` (`extends RefCounted`, `run(main) -> int`) and its Godot-generated `.uid`; add the one-line path-loaded await in `main.gd` last in the golden sequence. Parse probe rows fail-closed (missing, duplicate, non-finite or nonpositive physical pole/temperature is failure), tie 0.99c pole to frozen `sky_review.json` within 1e-9 relative, and derive all beta/gamma/one-minus-beta via rapidity mirrors. Build A without stars/background, B with them; instantiate the actual ship scene with captain eye and zero pullback. Freeze auto/journey ticks/process exposure, hide only CanvasLayers >= 0, disable/empty dust, and free each demo after readback.
   - S3: boost .5 / cruise .99 / brake .5; tilt 89.99 degrees, yaw 0. Captain Camera3D projection is the independent reference; cross-check float64 `AreaBundle.project`. Reject covered/bright pre-star windows (geometry alpha 0, peak < .02); centroid final-frame star within .75 px, with nonzero finite centroid weight. Do not derive the expected pole from the perturbed sky camera.
   - S2: cruise, tilt 30 degrees, yaw .47; compare final and sky RGBA8 over 40x24 grid, geometry alpha 0. Assert n >= 500, lit >= 50, ship >= 20, max RGB error <= 1/255 + 1e-6. Attach the existing synthetic gradient if panorama absent; a dark/empty frame cannot pass.
   - S4: read the linear unit-gain sky target, require format 14. Aim at wall points from the off-centre captain; reference `wall_cos` at centre pixel +.5 and `profile(P_sim,c)` using the independently parsed sim pole, never `pole_of` output. Three cap profile angles 0/45/80 degrees within 1%, cosine within .005; two absolute poles .99c/cap within 1%, c >= .9999; rest exactly zero. Fail on invalid reference/readback. Read after three frames plus frame_post_draw. Print exactly the design's 10 named `ok`/`FAIL` case lines, then ship summary; setup failures must fail the recipe. Run AC1–AC4 GREEN.
3. **Mutation drills — 45 minutes.** Install the corrected /tmp wrapper below; run AC5–AC10 sequentially on the green tree. Read every kill log, require the named failure counts and rc, and retain evidence before cleanup. Check source integrity after every drill via the wrapper trap. Repeat AC10 once with caller `set -e` and once with `set +e` to exercise both caller modes. No mutation ever touches the clone.
4. **Gate/scope review — 45 minutes.** Run the complete GATE LIST, AC11 and the scope check below. Preserve command statuses and logs; diagnose failures without expanding scope. Long suite runs may run in the background with bounded log polling. A positive baseline must precede the negative drills; stale/missing logs do not count.
5. **Changelog and progress — 30 minutes.** Add `changelogs/unreleased/2026-10-16-m4-6gr3-ship-goldens.md` describing new ship golden coverage. Record RED/GREEN, all twelve AC outcomes, mutation evidence and gate status in only the new JSON feature's notes/started/completed/passes. Set passes true only after every gate succeeds. Preserve every pre-existing feature, including M4.6_PHYSICS_GATES (renders/bench remain pending). Keep both docs in planned/ for this milestone; no design-doc move or P-land work is planned.

## Makefile RED guard insertion

Keep these as one continued recipe chain after the interior zero-failure guard, using Make's doubled dollar signs. They intentionally fail before the new driver exists; S2 is an exact count, correcting the design's presence-only grep.

```make
  test "$$(grep -c '^ok    G-M4-S2 one tonemap (ship)' $(SCRATCH)/golden.log)" = 1 && \
  test "$$(grep -c '^ok    G-M4-S3 forward pole (ship)' $(SCRATCH)/golden.log)" = 3 && \
  test "$$(grep -c '^ok    G-M4-S4 glow' $(SCRATCH)/golden.log)" = 6 && \
  test "$$(grep -c '^ok' $(SCRATCH)/golden.log)" = 373 && \
  grep -q '^m4 ship golden: 0 failures$$' $(SCRATCH)/golden.log && \
```

## Corrected mutation wrapper (executor installs under /tmp)

The explicit ROOT argument resolves the repository from any caller directory. The temp copy includes the executor's uncommitted driver/hook but excludes Git and old scratch logs. Source diff/index/status snapshots allow planned implementation edits while proving the source stayed identical throughout each drill. All four mutation targets must additionally match HEAD by Git blob hash. Exit 3 means a mutation did not apply; exit 4 is a harness/integrity failure. Negative drills return the underlying make status (normally 2); `check_drill` captures it with errexit off and returns zero only for the expected evidence. Cleanup runs on success, failure and catchable signals (SIGKILL cannot run shell traps).

```sh
cat > /tmp/m46g_drill.sh <<'DRILL'
#!/usr/bin/env bash
set -eu
# ROOT is mandatory: works regardless of the caller's current directory.
# usage: bash /tmp/m46g_drill.sh ROOT FILE PERL MARKER FAILPAT
[ "$#" -eq 5 ] || { echo 'usage: ROOT FILE PERL MARKER FAILPAT' >&2; exit 64; }
R=$(git -C "$1" rev-parse --show-toplevel)
file=$2; expr=$3; marker=$4; failpat=$5
# These production files must be clean before and after every drill.
protected=(demos/ship_demo_camera.gd interior/glow_overlay.gdshader
           interior/forward_glow.gd demos/ship_geometry_demo.gd)
git -C "$R" diff --quiet HEAD -- "${protected[@]}" || exit 4
T=$(mktemp -d /tmp/m46g.XXXXXX)
snapshot=0
cleanup() {
  result=$?
  trap - EXIT HUP INT TERM
  set +e
  if [ "$snapshot" -eq 1 ]; then
    git -C "$R" diff --binary HEAD > "$T/diff.after"
    check=$?; [ "$check" -eq 0 ] && cmp -s "$T/diff.before" "$T/diff.after" || result=4
    git -C "$R" diff --cached --binary > "$T/index.after"
    check=$?; [ "$check" -eq 0 ] && cmp -s "$T/index.before" "$T/index.after" || result=4
    git -C "$R" status --porcelain --untracked-files=all > "$T/status.after"
    check=$?; [ "$check" -eq 0 ] && cmp -s "$T/status.before" "$T/status.after" || result=4
  fi
  git -C "$R" diff --quiet HEAD -- "${protected[@]}" || result=4
  for p in "${protected[@]}"; do
    actual=$(git -C "$R" hash-object "$R/$p"); a_rc=$?
    expected=$(git -C "$R" rev-parse "HEAD:$p"); e_rc=$?
    [ "$a_rc" -eq 0 ] && [ "$e_rc" -eq 0 ] && [ "$actual" = "$expected" ] || result=4
  done
  rm -rf -- "$T" || result=4
  [ "$result" -ne 4 ] || echo 'drill: source integrity or harness failure' >&2
  exit "$result"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
git -C "$R" diff --binary HEAD > "$T/diff.before"
git -C "$R" diff --cached --binary > "$T/index.before"
git -C "$R" status --porcelain --untracked-files=all > "$T/status.before"
snapshot=1
mkdir "$T/tree"
rsync -a --exclude .git --exclude .godot/tmp "$R/" "$T/tree/"
if [ -n "$file" ]; then
  case "$file" in
    demos/ship_demo_camera.gd|interior/glow_overlay.gdshader|interior/forward_glow.gd|demos/ship_geometry_demo.gd) ;;
    *) echo 'drill: unsupported mutation path' >&2; exit 64 ;;
  esac
  cp "$T/tree/$file" "$T/original"
  perl -i -pe "$expr" "$T/tree/$file"
  if cmp -s "$T/original" "$T/tree/$file" || ! grep -qF -- "$marker" "$T/tree/$file"; then
    echo "drill: mutation did not apply to $file"
    exit 3
  fi
fi
# Do not inherit errexit for the expected failing make; always capture its status.
set +e
(cd "$T/tree" && perl -e 'alarm 900; exec @ARGV' make golden AILANG=runtime/bin/ailang > golden.out 2>&1)
rc=$?
set -e
log=$T/tree/.godot/tmp/golden.log
if [ ! -s "$log" ] || grep -q 'SCRIPT ERROR:' "$log"; then
  cat "$T/tree/golden.out" >&2
  echo 'drill: missing evidence or script error' >&2
  exit 4
fi
# grep status 1 means a valid zero count; status 2 remains an error.
count() { grep -c -- "$1" "$log" || [ "$?" -eq 1 ]; }
n=$(count "$failpat")
ok=$(count '^ok')
printf 'drill rc=%s fails=%s ok=%s\n' "$rc" "$n" "$ok"
# Evidence is printed before cleanup; keep it in the caller's /tmp log.
grep -E '^(FAIL|m4 ship golden:|golden:)' "$log" || true
exit "$rc"
DRILL
```

Executor setup and caller-safe assertion helper (bash):

```sh
# Run these definitions in bash. This subshell leaves caller options unchanged.
# ROOT may be supplied explicitly; this default resolves even from elsewhere.
ROOT=/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter35
ROOT=$(git -C "$ROOT" rev-parse --show-toplevel)
cd "$ROOT"
L=.godot/tmp/golden.log
check_drill() (
  want_rc=$1; want_fail=$2; want_ok=$3; shift 3
  evidence=$(mktemp /tmp/m46g-evidence.XXXXXX) || exit 4
  trap 'rm -f -- "$evidence"' EXIT
  set +e
  bash /tmp/m46g_drill.sh "$ROOT" "$@" > "$evidence" 2>&1
  rc=$?
  cat "$evidence"
  # Explicit checks work with either caller errexit setting.
  [ "$rc" -eq "$want_rc" ] || exit 1
  if [ "$want_rc" -eq 3 ]; then
    grep -q '^drill: mutation did not apply to ' "$evidence" || exit 1
  else
    grep -Eq "^drill rc=$want_rc fails=$want_fail ok=$want_ok$" "$evidence" || exit 1
  fi
  exit 0
)
```

## Acceptance criteria (AC1–AC12, corrected commands)

Run after the setup above, from ROOT; `L=.godot/tmp/golden.log`. Each listed command exits 0 when its criterion is met; drill status 2/3 is captured and asserted by `check_drill`. Numeric limits are driver assertions, not just text labels.

**AC1 — All old and new GPU cases pass.** Expected: exit 0; prints 373 (363 + 3 S3 + 1 S2 + 6 S4); golden: 0 failures and m4 ship golden: 0 failures.

```sh
make golden AILANG=runtime/bin/ailang && n=$(grep -c '^ok' "$L") && printf '%s\n' "$n" && test "$n" -eq 373
```

**AC2 — Captain-eye pole within 0.75 px, each phase; reference interior retained.** Expected: exit 0; ship=3 interior=6; one boosting, cruising and braking line, each error <= 0.75 px.

```sh
(for phase in boosting cruising braking; do test "$(grep -c "^ok    G-M4-S3 forward pole (ship) $phase beta" "$L")" -eq 1 || exit 1; done; test "$(grep -c '^ok    G-M4-S3 forward pole (ship)' "$L")" -eq 3 && test "$(grep -c '^ok    G-M4-3 forward pole' "$L")" -eq 6 && printf 'ship=3 interior=6\n')
```

**AC3 — One tonemap; sky/lit/ship sample floors.** Expected: exit 0; exactly one ok line printing n >= 500, lit >= 50, ship >= 20 and worst <= 1/255 + 1e-6; driver asserts all four bounds.

```sh
test "$(grep -c '^ok    G-M4-S2 one tonemap (ship): ' "$L")" -eq 1 && grep '^ok    G-M4-S2 one tonemap (ship): ' "$L"
```

**AC4 — Six glow cases with independent sim reference.** Expected: exit 0; profile=3 absolute=2 rest=1; cap 0/45/80 degrees <= 1%, |wall cos - cos(theta)| <= .005, format 14; absolute 0.99c/cap <= 1%, c >= .9999; rest exactly 0.

```sh
test "$(grep -c '^ok    G-M4-S4 glow' "$L")" -eq 6 && test "$(grep -c '^ok    G-M4-S4 glow profile (ship) cap theta' "$L")" -eq 3 && test "$(grep -c '^ok    G-M4-S4 glow absolute (ship)' "$L")" -eq 2 && test "$(grep -c '^ok    G-M4-S4 glow rest (ship)' "$L")" -eq 1 && test "$(grep -c '^ok    G-M4-S4 glow absolute (ship) cap 1-beta 2e-9: .* sim ship\.ism\.glow_pole_w_m2 56\.330348' "$L")" -eq 1 && printf 'profile=3 absolute=2 rest=1\n'
```

**AC5 — Positive control in fresh temp copy.** Expected: exit 0; drill rc=0 fails=0 ok=373.

```sh
check_drill 0 0 373 '' '' '' '^FAIL'
```

**AC6 — D1: mutation is killed by the named ship case.** Expected: exit 0 from check_drill; underlying make/wrapper rc=2; drill rc=2 fails=3 ok=<reported>; matching ^FAIL  G-M4-S3 forward pole (ship) evidence (not a parse/prerequisite failure).

```sh
check_drill 2 3 '[0-9]+' 'demos/ship_demo_camera.gd' 's/^(\tif position.length\(\)>=100\.: sky.set_glow_pole\(0\.\))$/$1\n\tsky.camera.look(sky.camera.yaw,sky.camera.pitch+.003,sky.camera.roll)/' 'sky.camera.pitch+.003' '^FAIL  G-M4-S3 forward pole (ship)'
```

**AC7 — D2a: mutation is killed by the named ship case.** Expected: exit 0 from check_drill; underlying make/wrapper rc=2; drill rc=2 fails=5 ok=<reported>; matching ^FAIL  G-M4-S4 evidence (not a parse/prerequisite failure).

```sh
check_drill 2 5 '[0-9]+' 'interior/glow_overlay.gdshader' 's/float e = pole \* ct;/float e = pole * ct * 1.02;/' 'pole * ct * 1.02' '^FAIL  G-M4-S4'
```

**AC8 — D2b: mutation is killed by the named ship case.** Expected: exit 0 from check_drill; underlying make/wrapper rc=2; drill rc=2 fails=5 ok=<reported>; matching ^FAIL  G-M4-S4 evidence (not a parse/prerequisite failure).

```sh
check_drill 2 5 '[0-9]+' 'interior/forward_glow.gd' 's/return _field\(world, POLE_FIELD\)$/return _field(world, POLE_FIELD) * 1.02/' 'POLE_FIELD) * 1.02' '^FAIL  G-M4-S4'
```

**AC9 — D3: mutation is killed by the named ship case.** Expected: exit 0 from check_drill; underlying make/wrapper rc=2; drill rc=2 fails=1 ok=<reported>; matching ^FAIL  G-M4-S2 evidence (not a parse/prerequisite failure).

```sh
check_drill 2 1 '[0-9]+' 'demos/ship_geometry_demo.gd' 's/_draw_layer\(sky.get_texture\(\),-40\);/_draw_layer(sky.get_texture(),-40);_rects[0].modulate=Color(.98,.98,.98);/' '_rects[0].modulate=Color(.98,.98,.98)' '^FAIL  G-M4-S2'
```

**AC10 — Unapplied mutation is a harness error.** Expected: exit 0 from check_drill; wrapper exits 3 and prints drill: mutation did not apply to demos/ship_geometry_demo.gd; cleanup/integrity checks still run.

```sh
check_drill 3 0 0 demos/ship_geometry_demo.gd 's/NO_SUCH_TEXT/x/' 'NO_SUCH_MARKER' '^FAIL'
```

**AC11 — No production or reference-gate change.** Expected: exit 0; prints 0; no protected-path changes in branch commits or staged/unstaged local changes; also run the scope check below to cover untracked files.

```sh
git diff --quiet origin/main...HEAD -- demos interior ui sim physics sky bridge tools/interior_golden.gd && git diff --quiet HEAD -- demos interior ui sim physics sky bridge tools/interior_golden.gd && printf '0\n'
```

**AC12 — Full suite, precision and Python policy.** Expected: exit 0; suite summaries contain zero failures, lint-precision: ok, python-guard succeeds; scope check allows no new Python.

```sh
make test AILANG=runtime/bin/ailang && make lint-precision python-guard AILANG=runtime/bin/ailang
```

Corrections to the design mapping are explicit: AC1–AC4 now assert numeric counts rather than merely printing them; AC2 additionally requires each named phase once; AC4 checks the 3/2/1 split and escapes literal dots in the sim field. AC5–AC10 use ROOT and caller-safe capture; AC10 tests status 3 instead of relying on `echo $?`. AC11 uses the merge base and checks local changes. AC12's three targets exist; passing the runtime override to both make invocations keeps them consistent.

## GATE LIST (executor runs every listed target)

These are **all 22 distinct make targets in actual `run:` steps of `.github/workflows/ci.yml`**, in workflow order, not the target dependencies inferred from `make test`. The pin is v0.54.8 (`AILANG=runtime/bin/ailang`, absolute after Makefile normalization).

```sh
make deps AILANG=runtime/bin/ailang
make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=runtime/bin/ailang
make import starmap-assets ui free-nav-recovery-test ship-ui-test ship-demo-input-test ai-live-guard map-ism-test no-twitch-test free-nav-stop-test loading-jump-test AILANG=runtime/bin/ailang
make planet-presentation-test moon-lifecycle-test sim-bootstrap-test exposure-frames-test manual-exposure-test tour-attitude-test tour-pacing-test alpha-centauri-test AILANG=runtime/bin/ailang
make test AILANG=runtime/bin/ailang
make golden AILANG=runtime/bin/ailang
make lint-precision python-guard AILANG=runtime/bin/ailang
```

Explicit target inventory: `deps`, `lore-import`, `import`, `starmap-assets`, `ui`, `free-nav-recovery-test`, `ship-ui-test`, `ship-demo-input-test`, `ai-live-guard`, `map-ism-test`, `no-twitch-test`, `free-nav-stop-test`, `loading-jump-test`, `planet-presentation-test`, `moon-lifecycle-test`, `sim-bootstrap-test`, `exposure-frames-test`, `manual-exposure-test`, `tour-attitude-test`, `tour-pacing-test`, `alpha-centauri-test`, `test`. Additional required targets: `golden`, `lint-precision`, `python-guard`; `m4-physics-probe` runs as the new golden prerequisite.

Provision the design-repo input at `/tmp/stapledons-design` before the lore gate, as CI does; the gate must exercise both lore-check halves. CI also runs the non-make command `AILANG=ailang python3 tools/replay.py --case m4_transit_harness`; run it with `AILANG="$ROOT/runtime/bin/ailang"` after deps. GPU golden uses the available executor GPU window, without `--headless`. All listed commands must exit 0, and the drill assertions must pass. This planner runs none of these targets. Existing target recipes may themselves mutate generated/cache/lock files; do not use their dry-runs in the planner clone.

## Scope check

Planner scope is exactly this new addendum and one added JSON feature. Executor scope is exactly:

- `tools/m4_ship_golden.gd` and `tools/m4_ship_golden.gd.uid`;
- `main.gd` (one golden hook), `Makefile` (golden prerequisite/guards/help);
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (only the new feature's progress);
- `changelogs/unreleased/2026-10-16-m4-6gr3-ship-goldens.md`;
- `design_docs/planned/r1/m4-6gr3-ship-goldens-sprint.md`.

No design doc or sprint doc move is planned; `design_docs/planned/r1/m4-6gr3-ship-goldens.md` stays byte-identical. If later landing separately authorizes moves, enumerate both old and new paths then, not a broad `design_docs/` exemption. `demos/`, `interior/`, `ui/`, `sim/`, `physics/`, `sky/`, `bridge/`, `tools/interior_golden.gd`, package pins, Python and CI stay unchanged. The mutation files are changed only inside /tmp copies.

Run this once before implementation to snapshot tolerated pre-existing untracked `.gd.uid` paths, keeping the resulting path in the same bash session, and again at completion as shown. No newly created unrelated UID receives this exemption.

```sh
UID_BASE=$(mktemp /tmp/m46g-uids.XXXXXX)
git -C "$ROOT" status --porcelain --untracked-files=all > "$UID_BASE.status"
sed -n 's/^?? //p' "$UID_BASE.status" | grep '\.gd\.uid$' > "$UID_BASE" || true
cat "$UID_BASE.status"
# At completion: list every change, then reject anything outside the exact list.
(
  set -eu
  trap 'rm -f -- "$UID_BASE" "$UID_BASE.status"' EXIT
  git -C "$ROOT" status --porcelain --untracked-files=all > "$UID_BASE.status"
  cat "$UID_BASE.status"
  while IFS= read -r row; do
    p=${row:3}
    case "$p" in
      tools/m4_ship_golden.gd|tools/m4_ship_golden.gd.uid|main.gd|Makefile|.ailang/state/sprints/sprint_R1-M4-JOURNEY.json|changelogs/unreleased/2026-10-16-m4-6gr3-ship-goldens.md|design_docs/planned/r1/m4-6gr3-ship-goldens-sprint.md) ;;
      *) if [[ "$row" == '?? '* ]] && grep -qxF -- "$p" "$UID_BASE"; then
           printf 'tolerated pre-existing UID: %s\n' "$p"
         else printf 'OUT OF SCOPE: %s\n' "$row" >&2; exit 1; fi ;;
    esac
  done < "$UID_BASE.status"
)
```

Expected: exit 0, only the seven enumerated paths plus the saved pre-existing untracked UIDs (31 at planner start). This status check covers local tracked/untracked files; additionally review `git diff --name-status origin/main...HEAD` against the same list for committed scope, and use AC11 for protected code. No git write operation is part of this plan's verification.

## Defects found in the design doc

1. **Wrapper root depends on caller cwd.** Bare `git rev-parse --show-toplevel` fails outside the repo. Fix: required ROOT argument and `git -C "$ROOT"`; all calls pass it.
2. **Cleanup is not unconditional.** Original wrapper removes the copy only on normal completion and its explicit no-op branch, leaking on rsync/Perl/errors/signals. Fix: install EXIT/HUP/INT/TERM traps immediately after mktemp; always delete the copy.
3. **Mutation application guard can pass vacuously.** Finding a marker alone does not prove bytes changed. Fix: save temp original, require byte difference and marker; return 3 for the deliberate no-op.
4. **No source-tree integrity proof.** Original wrapper does not compare the working tree after drills. Fix: compare full diff/index/status snapshots and require clean protected-path diff plus each target's `hash-object` equal to `HEAD:FILE` after every drill, including positive/no-op controls.
5. **Expected nonzero / caller-errexit handling.** Original internal make has an `|| rc=$?` guard, but the wrapper itself ultimately returns cleanup's success, hiding make's rc; AC10's `bash ...; echo $?` exits before echo when the caller has `set -e`. Fix: wrapper returns captured make rc; every invocation runs in `check_drill` with explicit `set +e`, captures rc, then asserts it. AC10 asserts 3 under either caller setting. Do not merely wrap a failing command and assume a following assignment executes.
6. **Missing/stale logs and grep errors can masquerade as counts.** `grep -c ... || true` suppresses missing-file/regex errors; original does not assert that a log was produced. Its scratch exclusion is already correct. Fix: retain the exclusion, require a fresh nonempty log, reject script errors, tolerate only grep status 1 for zero counts, and assert actual rc plus named failures. Save printed evidence before cleanup.
7. **Counts are reports, not assertions.** AC1's last grep returns success for 372 positive matches; AC2–AC4 also just print counts. The proposed recipe uses S2 presence rather than exactly one line. Fix: `test` every expected count, enforce S2=1/S3=3/S4=6 and total=373 in Makefile; require each S3 phase and S4's 3/2/1 split. Escape the literal dots in AC4's sim field regex. There is no arithmetic error in 363+3+1+6.
8. **AC11 moving diff base and unchecked count.** `git diff origin/main` changes meaning when origin/main advances, and `wc -l` does not assert zero. Fix: `git diff --quiet origin/main...HEAD -- <protected paths>` plus `git diff --quiet HEAD -- <protected paths>` and the untracked-aware scope review. Three-dot uses the branch merge base, including branch commits; it does not include local edits, hence the second check.

No wrong mutation path or nonmatching Perl regex was found: all four expressions were tested against actual source via stdout-only Perl. AC12 `test`, `lint-precision`, `python-guard` all exist. The defect corrections belong to this addendum/new feature; the design doc is read-only.

## Risks and executor evidence

- Half-float quantization makes the .99c 80-degree profile unsuitable for a 1% bound. Keep profiles at the guided cap, and .99c only as absolute pole; do not relax tolerances to make a dark/subnormal frame pass.
- D1 must compare GPU output with the captain camera, never the mutated sky camera. D2b needs the parsed sim pole as reference, not the same mutated helper used by the upload. Both independent references are necessary for non-vacuous kills.
- Window size, late frame updates and HUD/geometry occlusion can spoil readback. Keep the chosen pose, clear-window guard, fixed exposure, dust suppression, three-frame/post-draw wait and count floors. Panorama fallback must still satisfy lit/ship floors.
- A timeout, missing asset/probe row or parse error is a harness failure, not a successful mutation kill. Positive AC5 must pass first; review named failure evidence. Shared D2a also breaks legacy G-M4-4; still require five S4 failures (rest stays zero).
- /tmp copies carry large ignored assets; confirm disk space and clean up traps. The wrapper is sequential; retain each drill's stdout in executor evidence if needed. Do not run simultaneous source edits during snapshots.
- Full CI gates can outlast the nominal half-day estimate; use the reserve for diagnosis, keep pins unchanged, and record any blocking gate accurately. Captures/bench/S1 and P-land are the separate M4.6rR3 work.

## Planner verification

At HEAD `8cf3a70`, read all requested files, the parent revision, both shape models (iteration 34 via local Git object), target definitions and current mutation lines. Ran four `perl -pe` stdout dry-runs, checked changed bytes/markers, and extracted all 22 CI make targets; checked all named target definitions statically. Confirmed arithmetic and independent references. Checked every shell block with bash -n; AC1 count suffix and AC2–AC4 assertions pass a synthetic 373-line case log and reject wrong total, wrong phase, duplicate S2 and missing rest. No functional acceptance/gate run was performed. Validated JSON and proved removing only the appended feature reproduces the original JSON bytes and existing data. No make target, Godot run, git write, design edit or clone mutation drill was executed.
