# Sprint addendum: R1-M4-JOURNEY — M4.6pR3 live-transit frame cost

**Status:** Planned, iteration 37 planner; no implementation performed. **Feature:** `M4.6pR3_LIVE_TRANSIT_FRAME_COST`. **One milestone:** M1, test-first. **Approved design:** [m4-6pr3-live-transit-frame-cost.md](m4-6pr3-live-transit-frame-cost.md), full path `design_docs/planned/r1/m4-6pr3-live-transit-frame-cost.md`. Format follows [the iteration 36 plan](m4-6rr3-ship-renders-bench-sprint.md). The sprint-planner skill named by CLAUDE.md is absent from the supplied catalog and the repository skill search; the user's explicit deliverables and supplied format govern this plan.

Planner base is `6093fc95879523625772e60467b4447188f34df9` (6093fc9), branch `mission/stapledon-iter37-m46pr3`. The immutable implementation comparison base is **175e006**, not origin/main. `git diff --name-only 175e006 6093fc9` contains only the approved design doc; executable sources are identical. Runtime inspected: AILANG v0.54.11, commit 35a49b8. Godot is pinned to 4.7.2. No make/Godot/socket/GPU gate was run by the planner. The initial tree has 31 pre-existing untracked `.gd.uid` files; preserve them.

The accepted quorum limitation is explicit: the rest of `GalaxyMap._draw_overlay` still executes while hidden, approximately 2 ms per tick. This guard only removes the ISM cost. **Do not touch `ui/galaxy_map.gd`: attended PR #264 holds it.** Open-map performance and residual hitches are outside this feature. No physics formula, sim input, package or shipped visual changes are authorized.

## M1 — hidden-window guard and evidence (test-first)

Estimate: one working day plus suite/rig latency; about 45 implementation/test/changelog lines, with room for reliable test setup. Keep one milestone even if evidence takes longer.

1. **RED (45–60 min):** extend `tests/test_ism_layer.gd` first. Use an embedded hidden Window, CanvasLayer, Control overlay and the same draw callback as the map. Enable the layer and load the model. After a queued draw and two process frames, assert the hidden overlay remains visible-in-tree and draws zero media. Verify the visibility_changed redraw connection exists before show (combine this with the hidden assertion so the total remains 19). Show the window without an explicit queue_redraw; after two frames assert 15 media. Keep the visible-root/SubViewport case drawing 15. Three new checks, 16 → 19. Record a named hidden-window failure against the unmodified layer; the legacy 16-pass test by itself is not RED evidence.
2. **GREEN (30–45 min):** add the design's get_window/host.visible guard immediately after the current visible/model guard in `IsmLayer.draw`, after last_drawn has been cleared. Connect visibility_changed to overlay.queue_redraw only if not already connected, then return zero while hidden. Keep the null-host case safe. No geometry, projection, physics or sim changes. Re-run AC4. Repeat hidden/show/hide cycles in test setup without adding duplicate signal connections. Do not rely on is_visible_in_tree alone.
3. **Evidence (reserve 90 min plus capture/suite latency):** run AC1–AC8 and the full gate list on an unrestricted rig, then DR1–DR5 sequentially on a clean fix snapshot. Keep RED and restored GREEN logs. Add one changelog fragment with measured hardware/load/p99, avoiding an unverified universal performance promise. Open AC5's two map images and AC6's 15 capture PNGs; record actual observations in this feature's JSON notes or external evidence, without adding a report file to scope.
4. **Review hand-off:** a different evaluator must review the named failure evidence, full gate logs and renders. This planner spawns no agents. Leave parent M4.6 completion, S1 and P-land to their existing processes; this feature does not grant render sign-off or landing authority. Set this feature's passes true only after every required gate and drill is informative and green; otherwise keep false with the exact outstanding evidence.

## Executor command setup

Run this setup in **bash**, from any cwd, before implementation. Keep this same session for the AC commands. All commands below use ROOT and explicit paths; no `$L` is inherited from a previous AC. Evidence and generated renders stay in temporary project copies under S. Keep S until the evidence is recorded; the trap cleans it even on error. No commands in this plan require a git write. These are executor instructions, not a claim that the planner ran them.

```bash
set -euo pipefail
ROOT=/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter37
ROOT=$(git -C "$ROOT" rev-parse --show-toplevel)
BASE=175e006
PLANNER_BASE=6093fc95879523625772e60467b4447188f34df9
S=$(mktemp -d /tmp/m46pr3-session.XXXXXX)
trap 'rm -rf -- "$S"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
export ROOT BASE PLANNER_BASE S
export PATH="$ROOT/runtime/bin:$PATH"
cd "$ROOT"
test -x "$ROOT/runtime/bin/ailang"
git diff --quiet "$BASE" "$PLANNER_BASE" -- . \
  ':!design_docs/planned/r1/m4-6pr3-live-transit-frame-cost.md'
# Initial inventory MUST precede implementation; includes the two planner outputs.
git ls-files --others --exclude-standard | LC_ALL=C sort > "$S/untracked.before"
while IFS= read -r initial_file; do
  shasum -a 256 "$ROOT/$initial_file"
done < "$S/untracked.before" > "$S/untracked.before.sha256"
git diff --binary > "$S/planner-worktree.diff"
copy_project() {
  local dst=${1:?destination}
  mkdir -p "$dst"
  rsync -a --exclude .git --exclude renders --exclude .godot/tmp \
    "$ROOT/" "$dst/"
}
# At this point production sources are still at 6093fc9 == 175e006.
git diff --quiet "$PLANNER_BASE" -- ui/ism_layer.gd tests/test_ism_layer.gd
copy_project "$S/base"
# Overlay immutable tracked bytes; runtime/assets/caches remain copied local resources.
git -C "$ROOT" archive "$BASE" | tar -x -C "$S/base"
# Newer planning documents in this copy have no runtime role.
eq_count() {
  local f=${1:?file} p=${2:?ERE} want=${3:?count} n=0 grc=0
  test -s "$f"
  set +e
  n=$(grep -Ec -- "$p" "$f"); grc=$?
  set -e
  test "$grc" -le 1
  test "$n" -eq "$want"
}
no_errors() {
  eq_count "${1:?log}" 'SCRIPT ERROR:|Parse Error:|^ERROR:' 0
}
m_at() {
  local dir=${1:?project}; shift
  env -u MAKEFLAGS -u MFLAGS -u SCENE -u TIER -u AI_LIVE \
    PATH="$dir/runtime/bin:$PATH" make --no-print-directory -C "$dir" \
    "$@" AILANG="$dir/runtime/bin/ailang" SCRATCH=.godot/tmp
}
# Outside the planner sandbox: class caches must belong to the copied project.
godot --headless --path "$S/base" --import > "$S/base-import.log" 2>&1
no_errors "$S/base-import.log"
# Explicit AC6 BEFORE run, before changing production sources, at immutable base bytes.
m_at "$S/base" capture-m4 > "$S/base-capture.out" 2>&1
eq_count "$S/base/.godot/tmp/capture-m4.log" '^capture-m4: OK$' 1
no_errors "$S/base/.godot/tmp/capture-m4.log"
test "$(wc -l < "$S/base/renders/m4/worlds.sha256")" -eq 14
cp "$S/base/renders/m4/worlds.sha256" "$S/before.sha"
shasum -a 256 "$S/before.sha" > "$S/before.sha256"
cat "$S/before.sha256"
```

After implementing M1, create the acceptance copy, again in the same session:

```bash
copy_project "$S/fix"
F="$S/fix"
B="$F/.godot/tmp/bench-bridge.log"
export F B
godot --headless --path "$F" --import > "$S/fix-import.log" 2>&1
no_errors "$S/fix-import.log"
```

`make deps` and `make test` contain existing git-checkout recipes (Makefile:27 and included deps-ai). Do not invoke those under this run's prohibition on git writes. They remain mandatory controller/CI checks outside the planner run. `-o deps` would skip a required check and must not be reported as the full suite.

## Acceptance commands AC1–AC8

The approved criteria and thresholds are retained below with corrected commands. Setup is a prerequisite. AC1 produces the fresh bench evidence consumed by AC2 and AC3. The default target remains 16.7 ms; do not edit drivers, thresholds, duration, tier or tick rate to pass.

**AC1 — AC12 green on a quiet rig; record load and GPU state first.** Pass: block rc=0, raw make rc=0, exactly one valid OK and one exact 16.7: ok verdict. All three immediately preceding GPU samples must be present and <15%, and 1-minute load must be <5. The design's risk rule also requires docked-control p99 <=16.7 ms; exceeding it invalidates that run. A failed quiet precondition is an invalid measurement, not evidence about M1.

```bash
(
  set -euo pipefail
  for sample in 1 2 3; do
    ioreg -r -d 1 -c IOAccelerator > "$S/gpu-$sample.raw"
    test -s "$S/gpu-$sample.raw"
    grep -Eo '"Device Utilization %"[[:space:]]*=[[:space:]]*[0-9]+' \
      "$S/gpu-$sample.raw" > "$S/gpu-$sample.txt"
    test -s "$S/gpu-$sample.txt"
    awk -F= '{v=$2+0; if(v>=15) bad=1; n++} END{exit !(n>0 && !bad)}' \
      "$S/gpu-$sample.txt"
    cat "$S/gpu-$sample.txt"
    sleep 2
  done
  LC_ALL=C uptime > "$S/load.txt"
  cat "$S/load.txt"
  LC_ALL=C awk '{s=$0; if(sub(/^.*load averages?:[[:space:]]*/,"",s)!=1) exit 1;
    split(s,a,/[[:space:]]+/); if(a[1] !~ /^[0-9]+[.][0-9]+,?$/) exit 1;
    exit !((a[1]+0)<5)}' "$S/load.txt"
  rm -f -- "$B" "$F/.godot/tmp/bench-bridge.json"
  rc=0
  set +e
  m_at "$F" bench SCENE=bridge > "$S/ac1-make.log" 2>&1; rc=$?
  set -e
  printf 'AC1 make rc=%s\n' "$rc"
  test "$rc" -eq 0
  test -s "$B"
  no_errors "$B"
  eq_count "$B" '^bench-bridge: OK$' 1
  eq_count "$B" '^bench-bridge: FAIL([[:space:]]|$)' 0
  eq_count "$B" '^bench-bridge: frame ms .*\(target p99 < 16\.7: ok\)$' 1
  test -s "$F/.godot/tmp/bench-bridge.json"
  jq -e '.docked_control.p99_ms | type=="number" and .<=16.7' \
    "$F/.godot/tmp/bench-bridge.json"
)
```

**AC2 — frame-count validity floor; cost removed rather than hidden.** Pass: rc=0, exactly one live-transit summary, at least 2500 samples in that same 30-second run. Do not treat a missing/empty/duplicate log as zero frames or as a pass.

```bash
(
  set -euo pipefail
  test -s "$B"
  eq_count "$B" '^bench-bridge: OK$' 1
  eq_count "$B" '^bench-bridge: live transit [0-9]+ frames in 30\.[0-9]+ s \(boosting [0-9]+, cruising [0-9]+\), end beta ' 1
  n=$(sed -nE 's/^bench-bridge: live transit ([0-9]+) frames in .*/\1/p' "$B")
  [[ "$n" =~ ^[0-9]+$ ]]
  test "$n" -ge 2500
)
```

**AC3 — both phases measured and structurally valid.** Pass: rc=0, valid OK marker, zero named FAIL/errors, one live-transit summary with nonzero boosting and cruising counts. Shares AC1's fresh log; a valid performance MISS can satisfy AC3 but cannot satisfy AC1.

```bash
(
  set -euo pipefail
  test -s "$B"
  eq_count "$B" '^bench-bridge: OK$' 1
  no_errors "$B"
  eq_count "$B" '^bench-bridge: FAIL([[:space:]]|$)' 0
  eq_count "$B" '^bench-bridge: live transit [0-9]+ frames in [0-9.]+ s \(boosting [1-9][0-9]*, cruising [1-9][0-9]*\), end beta ' 1
)
```

**AC4 — hidden-window test; all media still drawn when visible.** Pass: rc=0, exactly `ism-layer: 19 passed, 0 failures`; no script/parse error. The recipe's generic positive count alone is insufficient to prove the new cases ran.

```bash
(
  set -euo pipefail
  L="$F/.godot/tmp/map-ism-test.log"
  rm -f -- "$L"
  m_at "$F" map-ism-test > "$S/ac4-make.log" 2>&1
  test -s "$L"
  no_errors "$L"
  eq_count "$L" '^ism-layer: 19 passed, 0 failures$' 1
  cat "$L"
)
```

**AC5 — open Navigation station density view unchanged: 15 media.** Pass: Godot rc=0 and exactly `map-surface-capture: 0 failures, 15 media`. Open both generated map images and inspect density/boundary views; marker alone does not prove visual equality.

```bash
(
  set -euo pipefail
  L="$S/ac5-map.log"
  AILANG_BIN="$F/runtime/bin/ailang" godot --path "$F" \
    --script "$F/tools/ism_map_surface_capture.gd" > "$L" 2>&1
  test -s "$L"
  no_errors "$L"
  eq_count "$L" '^map-surface-capture: 0 failures, 15 media$' 1
  test -s "$F/renders/bubble_surface/map_density.png"
  test -s "$F/renders/bubble_surface/map_boundaries.png"
  cat "$L"
)
```

**AC6 — rendered result unchanged.** Pass: golden make rc=0, 373 anchored ok lines and `golden: 0 failures`; capture make rc=0, 14 world rows, before/after manifest hashes equal and cmp rc=0. Baseline was explicitly generated above at 175e006 executable bytes, before the guard. The manifest is ignored/untracked: `git show 175e006:renders/m4/worlds.sha256` cannot supply it. PNGs need visual review, not byte equality across GPU runs.

```bash
(
  set -euo pipefail
  L="$F/.godot/tmp/golden.log"
  rm -f -- "$L" "$F/.godot/tmp/capture-m4.log"
  m_at "$F" golden > "$S/ac6-golden.out" 2>&1
  test -s "$L"
  no_errors "$L"
  eq_count "$L" '^ok[[:space:]]' 373
  eq_count "$L" '^golden: 0 failures$' 1
  test -s "$S/before.sha"
  test "$(wc -l < "$S/before.sha")" -eq 14
  m_at "$F" capture-m4 > "$S/ac6-capture.out" 2>&1
  eq_count "$F/.godot/tmp/capture-m4.log" '^capture-m4: OK$' 1
  no_errors "$F/.godot/tmp/capture-m4.log"
  test "$(wc -l < "$F/renders/m4/worlds.sha256")" -eq 14
  cp "$F/renders/m4/worlds.sha256" "$S/after.sha"
  shasum -a 256 "$S/after.sha" > "$S/after.sha256"
  cat "$S/before.sha256" "$S/after.sha256"
  # Filenames in shasum output differ; compare digest fields, then the actual bytes.
  test "$(awk '{print $1}' "$S/before.sha256")" = "$(awk '{print $1}' "$S/after.sha256")"
  cmp "$S/before.sha" "$S/after.sha"
)
```

**AC7 — full make test green, including map-ism-test.** Pass: original make rc=0, nonempty full log, fresh exact 19-pass ISM summary and no script/parse errors. This mandatory check runs in controller/CI with its existing git-recipe authorization; it is pending under this planner's no-git-writes rule. Do not replace it with a pipeline ending in echo/grep, or with skipped prerequisites.

```bash
(
  set -euo pipefail
  rm -f -- "$ROOT/.godot/tmp/map-ism-test.log"
  rc=0
  set +e
  PATH="$ROOT/runtime/bin:$PATH" make -C "$ROOT" test \
    AILANG="$ROOT/runtime/bin/ailang" > "$S/ac7-test.log" 2>&1; rc=$?
  set -e
  printf 'AC7 make rc=%s\n' "$rc"
  test -s "$S/ac7-test.log"
  test "$rc" -eq 0
  no_errors "$S/ac7-test.log"
  eq_count "$ROOT/.godot/tmp/map-ism-test.log" '^ism-layer: 19 passed, 0 failures$' 1
)
```

**AC8 — no other implementation file changes.** Pass: exactly the two source/test files and one named changelog fragment relative to **175e006**, including local/untracked changes. Approved design/planner metadata are explicitly accounted for, not silently mistaken for implementation. The committed base-to-planner delta must still be exactly the approved design doc. All other pre-existing untracked files must survive unchanged; compare their initial hashes/status as part of hand-off. AC8 at the pristine base is RED because no implementation files exist yet.

```bash
(
  set -euo pipefail
  P=design_docs/planned/r1/m4-6pr3-live-transit-frame-cost-sprint.md
  D=design_docs/planned/r1/m4-6pr3-live-transit-frame-cost.md
  J=.ailang/state/sprints/sprint_R1-M4-JOURNEY.json
  C=changelogs/unreleased/2026-10-17-m4-6pr3-live-transit-frame-cost.md
  printf '%s\n' "$D" > "$S/expected-baseline.names"
  git -C "$ROOT" diff --name-only "$BASE" "$PLANNER_BASE" > "$S/baseline.names"
  cmp "$S/expected-baseline.names" "$S/baseline.names"
  git -C "$ROOT" diff --quiet "$PLANNER_BASE" -- "$D" ui/galaxy_map.gd
  shasum -a 256 -c "$S/untracked.before.sha256"
  git -C "$ROOT" diff --name-only "$BASE" -- > "$S/changed.tracked"
  git -C "$ROOT" ls-files --others --exclude-standard | LC_ALL=C sort > "$S/untracked.after"
  # initial inventory contains pre-existing UIDs and planner files, not implementation.
  comm -13 "$S/untracked.before" "$S/untracked.after" > "$S/changed.untracked"
  cat "$S/changed.tracked" "$S/changed.untracked" | LC_ALL=C sort -u > "$S/changed.all"
  awk -v d="$D" -v p="$P" -v j="$J" '$0!=d && $0!=p && $0!=j' \
    "$S/changed.all" > "$S/implementation.names"
  printf '%s\n' ui/ism_layer.gd tests/test_ism_layer.gd "$C" | LC_ALL=C sort > "$S/expected.names"
  cmp "$S/expected.names" "$S/implementation.names"
  test -s "$ROOT/$C"
  jq -e . "$ROOT/$J" > /dev/null
  # Other feature entries and all parent fields must equal the frozen planner base.
  git -C "$ROOT" show "$PLANNER_BASE:$J" | jq -S . > "$S/parent.before.json"
  jq -S 'del(.features[] | select(.id=="M4.6pR3_LIVE_TRANSIT_FRAME_COST"))' \
    "$ROOT/$J" > "$S/parent.after.json"
  cmp "$S/parent.before.json" "$S/parent.after.json"
  jq -e '[.features[] | select(.id=="M4.6pR3_LIVE_TRANSIT_FRAME_COST")] | length==1' "$ROOT/$J"
)
```

## Mutation drills DR1–DR5

Install the following wrapper under `$S/drill.sh` (the code block is the complete file), then invoke the commands below. ROOT must be a controller-prepared clean fix snapshot for `ui/ism_layer.gd`; the wrapper never commits, resets or restores via git. Every mutation runs against a separate temporary copy. Its EXIT trap restores the mutated file from backup even on failure, asserts byte equality and **git diff --quiet on that file** using ROOT's read-only object/index metadata and the copy as work tree, then removes the copy. ROOT is never mutated. Require exclusive access during the drill. SIGKILL cannot execute traps; never use it to stop a drill.

For every drill the real gate must first be GREEN, then RED under a functional mutation with named valid evidence, then GREEN after restoration. DR4 additionally preserves the original comment-only GREEN control. DR5 additionally preserves no-op refusal (rc=3), which is a harness control, never counted as a killed functional mutant. This strengthens the design's DR4/DR5 so neither can substitute for the requested RED→GREEN proof. Bench drills inherit AC1's quiet-rig precondition; record fresh GPU/load samples immediately before each bench phase. Headless and GPU drills run outside this sandbox.

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT=${1:?ROOT}; ID=${2:?DR1..DR5}; S=${3:?session evidence directory}
ROOT=$(git -C "$ROOT" rev-parse --show-toplevel)
G=$(git -C "$ROOT" rev-parse --absolute-git-dir)
REL=ui/ism_layer.gd
case "$ID" in DR1|DR4) KIND=bench;; DR2|DR3|DR5) KIND=test;; *) exit 2;; esac
test -d "$S"
git -C "$ROOT" diff --quiet HEAD -- "$REL"
T=$(mktemp -d /tmp/m46pr3-drill.XXXXXX)
C="$T/tree"; F="$C/$REL"; ORIG="$T/original"
backed=0; rc=0; noop_rc=0; result=0; phase=initial
cleanup() {
  result=$?
  trap - EXIT HUP INT TERM
  set +e
  if [ "$backed" -eq 1 ]; then
    cp "$ORIG" "$F" || result=4
    cmp -s "$ORIG" "$F" || result=4
    git --git-dir="$G" --work-tree="$C" diff --quiet HEAD -- "$REL" || result=4
  fi
  rm -rf -- "$T" || result=4
  exit "$result"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$C"
rsync -a --exclude .git --exclude renders --exclude .godot/tmp "$ROOT/" "$C/"
cp "$F" "$ORIG"
backed=1
export PATH="$C/runtime/bin:$PATH"
godot --headless --path "$C" --import > "$S/$ID-import.log" 2>&1
test -s "$S/$ID-import.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|^ERROR:' "$S/$ID-import.log"; then exit 4; fi
count_is() {
  local file=${1:?file} pat=${2:?pattern} want=${3:?count} n=0 grc=0
  test -s "$file"
  set +e
  n=$(grep -Ec -- "$pat" "$file"); grc=$?
  set -e
  test "$grc" -le 1
  test "$n" -eq "$want"
}
mutate() {
  local expr=${1:?expression} mrc=0
  # Build a candidate first; a no-op cannot overwrite the target or count as a kill.
  if perl -e '
    my ($expr,$file)=@ARGV;
    open my $h,"<",$file or die $!; local $/; my $s=<$h>;
    my $n=eval "\$s =~ $expr"; die $@ if $@;
    exit 3 unless $n;
    die "mutation matches=$n (want 1)\n" unless $n==1;
    print $s;
  ' "$expr" "$F" > "$T/candidate"; then :; else
    mrc=$?
    return "$mrc"
  fi
  if cmp -s "$F" "$T/candidate"; then return 3; fi
  cp "$T/candidate" "$F" || return 4
}
quiet() {
  local p=${1:?phase} i=0
  for i in 1 2 3; do
    ioreg -r -d 1 -c IOAccelerator > "$S/$ID-$p-gpu-$i.raw"
    grep -Eo '"Device Utilization %"[[:space:]]*=[[:space:]]*[0-9]+' \
      "$S/$ID-$p-gpu-$i.raw" > "$S/$ID-$p-gpu-$i.txt"
    test -s "$S/$ID-$p-gpu-$i.txt"
    awk -F= '{if(($2+0)>=15) bad=1; n++} END{exit !(n>0&&!bad)}' "$S/$ID-$p-gpu-$i.txt"
    sleep 2
  done
  LC_ALL=C uptime > "$S/$ID-$p-load.txt"
  LC_ALL=C awk '{s=$0; if(sub(/^.*load averages?:[[:space:]]*/,"",s)!=1) exit 1;
    split(s,a,/[[:space:]]+/); if(a[1] !~ /^[0-9]+[.][0-9]+,?$/) exit 1;
    exit !((a[1]+0)<5)}' "$S/$ID-$p-load.txt"
}
gate() {
  local expect=${1:?green|red} p=${2:?phase} log='' out=''
  local rc=0
  local args=()
  out="$S/$ID-$p-make.log"
  if [ "$KIND" = bench ]; then
    quiet "$p"
    log="$C/.godot/tmp/bench-bridge.log"; args=(bench SCENE=bridge)
    rm -f -- "$C/.godot/tmp/bench-bridge.json"
  else
    log="$C/.godot/tmp/map-ism-test.log"; args=(map-ism-test)
  fi
  rm -f -- "$log"
  set +e
  env -u MAKEFLAGS -u MFLAGS -u SCENE -u TIER -u AI_LIVE \
    make --no-print-directory -C "$C" "${args[@]}" \
    AILANG="$C/runtime/bin/ailang" SCRATCH=.godot/tmp > "$out" 2>&1
  rc=$?
  set -e
  test -s "$log"
  cp "$log" "$S/$ID-$p-gate.log"
  count_is "$log" 'SCRIPT ERROR:|Parse Error:|^ERROR:' 0
  if [ "$expect" = green ]; then
    test "$rc" -eq 0
  else
    test "$rc" -eq 2 # make's recipe failure, not the driver's code
  fi
  if [ "$KIND" = bench ]; then
    test -s "$C/.godot/tmp/bench-bridge.json"
    jq -e '.docked_control.p99_ms | type=="number" and .<=16.7' \
      "$C/.godot/tmp/bench-bridge.json"
    count_is "$log" '^bench-bridge: OK$' 1
    count_is "$log" '^bench-bridge: FAIL([[:space:]]|$)' 0
    count_is "$log" '^bench-bridge: live transit [0-9]+ frames in [0-9.]+ s \(boosting [1-9][0-9]*, cruising [1-9][0-9]*\), end beta ' 1
    if [ "$expect" = red ]; then
      count_is "$log" '^bench-bridge: frame ms .*\(target p99 < 16\.7: MISS\)$' 1
      count_is "$out" '^bench-bridge: FAILED \(exit 2:' 1
    else
      count_is "$log" '^bench-bridge: frame ms .*\(target p99 < 16\.7: ok\)$' 1
    fi
  elif [ "$expect" = red ]; then
    count_is "$log" '^ism-layer: [0-9]+ passed, [1-9][0-9]* failures$' 1
    # M1 names its new checks with this common prefix; exclude legacy failures.
    count_is "$log" '^  FAIL  M4\.6pR3 hidden-window' 1
  else
    count_is "$log" '^ism-layer: 19 passed, 0 failures$' 1
  fi
  printf '%s %s: %s (make rc=%s)\n' "$ID" "$p" "$expect" "$rc"
}
gate green initial
if [ "$ID" = DR4 ]; then
  mutate 's/^(\t# M4\.6pR3: a map)/$1 (drill)/gm'
  gate green comment-control
  cp "$ORIG" "$F"
elif [ "$ID" = DR5 ]; then
  set +e
  mutate 's/NO_SUCH_TEXT/x/g'; noop_rc=$?
  set -e
  test "$noop_rc" -eq 3
  cmp -s "$ORIG" "$F"
  printf 'DR5 no-op refused rc=%s; not a functional kill\n' "$noop_rc"
fi
if [ "$ID" = DR3 ]; then
  mutate 's/^(\t+)host\.visibility_changed\.connect\(overlay\.queue_redraw\)$/${1}pass/gm'
else
  mutate 's/^\tif host != null and not host\.visible:$/\tif false:/gm'
fi
if cmp -s "$ORIG" "$F"; then exit 3; fi
gate red mutated
cp "$ORIG" "$F"
cmp -s "$ORIG" "$F"
git --git-dir="$G" --work-tree="$C" diff --quiet HEAD -- "$REL"
gate green restored
git --git-dir="$G" --work-tree="$C" diff --quiet HEAD -- "$REL"
printf '%s PASS: RED under mutation, GREEN after restore; file clean\n' "$ID"
```

Commands (all expected wrapper rc=0; any other rc is failure/inconclusive, not a kill):

```bash
bash "$S/drill.sh" "$ROOT" DR1 "$S" # disable guard; valid bench MISS then restored ok
bash "$S/drill.sh" "$ROOT" DR2 "$S" # disable guard; hidden-window test red then 19/0
bash "$S/drill.sh" "$ROOT" DR3 "$S" # remove connect; hidden-window connection/show check red then 19/0
bash "$S/drill.sh" "$ROOT" DR4 "$S" # comment-only bench green control, then DR1 red/green
bash "$S/drill.sh" "$ROOT" DR5 "$S" # no-op refused 3, then DR2 red/green
```

Name the single combined hidden/connection assertion `M4.6pR3 hidden-window ...` so both DR2 and DR3 have one precise failure marker. The other new assertions must use distinct names. If removing the connection still passes, strengthen the observable signal contract in the test, not the mutation verdict. Import/prerequisite failures, timeouts, missing logs and GPU contention never kill a mutant. The wrapper requires actual changed bytes; patterns must still match the implemented design guard/comment. DR3 cannot be satisfied merely by any nonzero make exit.

## Pristine-base baseline (6093fc9)

Every AC command above is covered here, including reasoned outcomes. No make gate was executed: deps/test contain git writes, and Godot/GPU/socket results in this sandbox are **UNINFORMATIVE UNDER SANDBOX**. Supplied design measurements V12/V13/V15 are historical evidence, not planner passes. No implementation exists at 6093fc9.

| Command | Planner status | Expected result on pristine 6093fc9, outside sandbox | Why / interpretation |
|---|---|---|---|
| AC1 `m_at "$S/base" bench SCENE=bridge` plus quiet/verdict checks | UNINFORMATIVE UNDER SANDBOX | RED, make rc=2, valid MISS on quiet rig | Same executable sources as 175e006; V13 p99 36.035/36.217 ms. Already red at base: measures the repo, not a newly introduced regression; this change must turn it green. |
| AC2 frame floor on AC1's valid base log | UNINFORMATIVE UNDER SANDBOX | RED, check rc=1 | V13 1500/1447 frames <2500. Already red at base: measures the repo, not the change; fixed spike 3227–3398. |
| AC3 valid OK/nonzero boosting+cruising checks on same log | UNINFORMATIVE UNDER SANDBOX | GREEN, check rc=0 | Current driver emits OK for structurally valid MISS and requires both phases. Counts need fresh unrestricted evidence. |
| AC4 `make map-ism-test` plus exact 19/0 | UNINFORMATIVE UNDER SANDBOX | Raw make GREEN (16/0), exact AC4 RED (rc=1) | V12 and source show 16 checks. New 19-check contract is intentionally already red at base; measures missing test coverage until M1, not an existing test regression. Adding only the test must yield a named functional RED too. |
| AC5 Godot map capture plus exact 0 failures/15 media | UNINFORMATIVE UNDER SANDBOX | GREEN, rc=0 | V12 directly measured 15; visible map path unchanged. |
| AC6 `make golden`, base `make capture-m4`, subsequent capture/hash/cmp | UNINFORMATIVE UNDER SANDBOX | Expected GREEN: 373 ok, golden 0 failures; 14 byte-equal world rows | Makefile pins 373; same seed, sim, driver and ticks. SHA itself must be measured by the explicit baseline command; do not invent a digest or reuse stale existing renders. |
| AC7 pinned `make test` plus fresh 19/0 check | UNINFORMATIVE UNDER SANDBOX | Full raw suite expected GREEN in configured CI; corrected 19/0 postcheck RED at base | Exact summary deliberately ahead of implementation. Full-suite success is reasoned, not observed. Any unrelated raw-suite RED at base measures the repo, not this change; reproduce/log it before attribution. |
| AC8 fixed-base scope, exact three implementation files | Reasoned from read-only git; not executed with future-session inputs | RED, rc=1 | Base delta has only the approved design; no source/test/changelog implementation delta. Already red at base is a scope-completeness check measuring the repo, not a change regression. Metadata subchecks should pass after these planner outputs are installed. |

No timing result from a sandbox run may be labeled pass/fail. Outside the sandbox, preserve every valid run, including misses; a thin-margin miss is not license to change the 16.7-ms or 2500-frame thresholds. Use a quiet rig with three low-GPU samples, no concurrent bench/capture, same hardware/driver/tier/resolution, and record docked control. As the design's Risks specifies, docked-control p99 >16.7 ms invalidates that measurement: record it and repeat after quiet conditions return. Do not select only the best of many valid runs. Persistent failures remain open evidence. Capture worlds must match; pixels need not be identical across runs.

## Executor gate list and CI derivation

Derived at 6093fc9 with the exact requested `grep -n 'make ' .github/workflows/ci.yml`:

```text
43:          make deps
45:          make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang
48:      # (Mark, 2026-10-16): every target in them is a prerequisite of make test, which ran them twice.
49:      - name: make test
50:        run: make test
```

Only lines **43, 45 and 50** are run-step commands. Lines 48 (comment) and 49 (step name) add no target. No old 22-target list applies. `ai-live-guard` is **NOT present in ci.yml**. It **does exist in the Makefile graph**, via `include mk/ai.mk` at Makefile:841, definition mk/ai.mk:414. Run it as a separate additional regression gate, not as a claimed direct CI run step.

All commands use the pinned runtime; each must exit zero outside sandbox. Log original statuses directly as in AC1/AC7. Use existing controller/CI infrastructure for the design repo at the lore manifest's recorded commit; no package install, git clone/write, publish or network write is part of this planner run. Under the current hard rules, a controller-only check remains pending, never waived.

| Required gate | Exact executor command / pass condition |
|---|---|
| CI line 43: deps | `PATH="$ROOT/runtime/bin:$PATH" make -C "$ROOT" deps AILANG="$ROOT/runtime/bin/ailang"` — rc=0, lock resolution unchanged; controller/CI only because recipe performs git checkout. |
| CI line 45: lore-import | `PATH="$ROOT/runtime/bin:$PATH" make -C "$ROOT" lore-import CHECK=1 D=/tmp/stapledons-design AILANG="$ROOT/runtime/bin/ailang"` — rc=0; D must already contain the pinned design commit. |
| CI line 50: test | AC7 exact command — raw rc=0, all prerequisites including precision/Python/physics, VM/interpreter parity, strict VM, determinism and new ISM checks. Controller/CI only under this run's rules. |
| Additional ai-live-guard | `PATH="$ROOT/runtime/bin:$PATH" make -C "$ROOT" ai-live-guard AILANG="$ROOT/runtime/bin/ailang"` — rc=0, all existing provider-start negative controls caught; do not edit its implementation. |
| Feature headless | AC4 `make map-ism-test` — 19/0; retain test-only RED first. |
| GPU physics regression | AC6 `make golden` — 373 anchored ok, golden 0 failures, raw rc=0. |
| Ship capture regression | Setup baseline `make capture-m4` at 175e006 bytes and AC6 fixed capture — raw rc=0, record before/after SHA256 of worlds.sha256; **equal digests and cmp=0**, 14 worlds each. Open every capture PNG. |
| Live bridge | AC1 `make bench SCENE=bridge` at 2560×1440, medium, vsync off, 30 s — p99 <16.7, raw rc=0, AC2 >=2500 and AC3 both phases. |
| Visible-map review | AC5 exact Godot command and two opened images — 0 failures, 15 media. |
| Negative controls | All five wrapper invocations above — named RED then restored GREEN, DR4 comment GREEN, DR5 no-op 3, clean-file restoration checks. |
| Scope / metadata | AC8, `jq -e . "$ROOT/.ailang/state/sprints/sprint_R1-M4-JOURNEY.json"`, and read-only diff review — exactly this feature added, parent entries unchanged. |

## Design-command fixes

| ID | Defect | Fix | Reason |
|---|---|---|---|
| AC1, AC7 | `make; echo rc=$?` leaves echo's success as block status | Capture rc directly with set +e/cmd/rc=$?/set -e, then assert rc=0 | A failing make cannot appear green. |
| AC1 | ioreg/uptime only print; GPU marker may be absent and load unparsed | Require nonempty raw/extracted samples, three samples <15%, parsed 1-minute load <5 | Missing hardware evidence or contention cannot certify quiet performance. |
| AC1–AC3 | Stale/default bench log may be reused | Delete log+JSON immediately before run, require nonempty log, exact valid OK marker | A missing/empty/stale artifact cannot pass via zero failures. |
| AC2, AC3 | `$L` unset outside another AC, unquoted; empty/multiple numeric matches | Explicit B/L initialized by documented setup, quote paths, require one anchored summary and numeric count | Works under set -u and rejects ambiguous evidence. |
| AC3 | `grep -c FAIL == 0` accepts missing evidence without a valid summary; phase match is unanchored | Nonempty log, exact OK, bounded FAIL/errors and anchored nonzero phase summary | Zero failure lines alone prove nothing. |
| AC4 | Trailing grep hides make rc; generic passed-count recipe also accepts legacy 16 | Fail on make status, require fresh exact 19/0 and no errors | Proves new cases actually executed. |
| AC5 | `godot | grep` can succeed when Godot fails | Direct redirected Godot command under errexit, then exact marker check | Preserve producer status and reject error logs. |
| AC6 | Before SHA path undefined; base's worlds manifest is not tracked | Explicit pre-change base-copy capture, 14-row check, trap-owned before.sha and its SHA256, then after hash+cmp | Establish provenance and byte equality without pretending git show can read an ignored file. |
| AC6 | Golden expected counts/summaries stated but not asserted by the caller | Require nonempty fresh golden log, 373 `^ok[[:space:]]` and exact golden 0 failures | Match the approved criterion explicitly, alongside recipe rc. |
| AC8 | Moving origin/main, triple-dot HEAD ignores local/untracked edits | Fixed 175e006, frozen 6093fc9 design delta, working-tree diff plus initial/untracked delta | Stable scope check covers actual executor edits. |
| AC8 | Exact three-file rule conflicts with approved design and requested planner metadata already present | Account for those exact three metadata paths, assert design unchanged and JSON parent equality | Avoid both false scope failures and blanket metadata exemptions. |
| All AC/DR | Relative cwd, ambient MAKEFLAGS/SCENE/TIER/AI_LIVE, inconsistent AILANG | Explicit root/project paths, sanitized make invocation, pinned copied runtime, bash setup | Same intended driver/tier/runtime regardless of caller's shell or directory. |
| AC1, AC2, DR1, DR4 | Thin 16.7-ms margin makes contended timing flaky | Quiet precondition on every measured phase, fixed settings, preserved misses and asserted docked-control p99 <=16.7; no relaxed threshold | Separate invalid environment from true performance failure. |
| DR1–DR5 | Wrapper uses only set -u, unchecked setup and mutation; zero/no-op replacements can count | set -euo pipefail, initialized state, copy-safe candidate and backup, explicit no-op rc=3 | Harness failure is not a killed mutant. |
| DR1–DR5 | Original trap restores but proves neither integrity nor restored gate; failures may interrupt cleanup | Immediate EXIT/signal traps, restore+cmp+git diff --quiet on mutated copy even on failure, restored GREEN required | Every drill proves reversibility and recovery. |
| DR1–DR5 | make rc/grep status can be lost or polluted; structural errors may masquerade as red | Direct original rc capture, fresh nonempty logs, exact named failures, no errors, make=2 and driver=2 footer for bench MISS | Distinguish a real regression from parse/asset/measurement failure. |
| DR3 | Removing connect may still show pixels because Godot can redraw on show automatically | Assert redraw connection before show within the hidden-window test, plus observable show drawing | Mutation tests the approved redraw contract deterministically. |
| DR4, DR5 | Comment-only green/no-op refusal alone cannot meet a RED→restore→GREEN requirement | Keep both original controls, then add a functional guard mutation and restored gate in each drill | Preserve control semantics while making every named drill prove a functional kill and recovery. |

## Scope, risks and definition of done

Executor implementation files: **only** `ui/ism_layer.gd`, `tests/test_ism_layer.gd`, and new `changelogs/unreleased/2026-10-17-m4-6pr3-live-transit-frame-cost.md`. Operational progress may update only this new feature's JSON entry; this plan is the evidence/command reference. Temporary mutation copies, logs, caches and renders belong under /tmp; no extra repository report, wrapper, render or UID file is authorized. This planner writes only the plan and the one additive JSON entry, leaves both uncommitted, and preserves all 31 pre-existing UIDs.

**Must not touch:** `ui/galaxy_map.gd` (PR #264); demos, bench/capture drivers, Makefile/mk files, sim/AI sources, package pins/runtime/lockfiles, physics/shaders/data, the approved design doc or parent sprint fields. Read them freely. Runtime-generated changes from mandatory controller gates must be isolated and accounted for; do not absorb unrelated diffs into this feature.

Risks: GPU contention and catch-up ticks inflate timing; thin p99 margin and unknown residual hitches remain; headless visibility and CanvasLayer/window relationships need real Godot evidence; redraw-on-show could mask a missing signal subscription; copy caches may need import; stale logs and pre-existing generated UIDs can confuse scope. Mitigations are the explicit quiet checks, base/fix copies, structural guards, signal assertion, no-op control, exact log contracts and restoration checks above. Do not widen scope to eliminate the remaining 2-ms overlay work.

Done means: test-only named RED preserved; minimal guard GREEN with exact 19/0; every AC1–AC8 and CI-derived/additional gate informative and green outside sandbox; five complete drills with restored-green and clean-file proof; before/after worlds hashes recorded and equal; all reference images actually opened with observations; only allowed implementation/progress paths changed; independent evaluator agrees. CLAUDE.md physics gates remain: no new physical visual or formula here, so no new physics case/package release is needed, but existing golden, precision, pure-core strict VM, parity and determinism gates must stay green. No new Python file or pipeline is introduced. Keep passes=false until this evidence exists; no S1, P-land, publish or merge is implied.
