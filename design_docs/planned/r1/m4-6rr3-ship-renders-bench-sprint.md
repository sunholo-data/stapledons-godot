# Sprint addendum: R1-M4-JOURNEY — M4.6rR3 ship renders and bench

**Status:** Planned (mission iteration 36, planner); execution pending. **Sprint id:** `R1-M4-JOURNEY`. **Milestone:** `M4.6rR3`, feature `M4.6rR3_SHIP_RENDERS_BENCH`.
**Design doc:** [m4-6rr3-ship-renders-bench.md](m4-6rr3-ship-renders-bench.md), full path `design_docs/planned/r1/m4-6rr3-ship-renders-bench.md`. **Parent sprint:** [m4-first-journey-sprint.md](m4-first-journey-sprint.md), Revision round 3 / R3-4, R3-7, R3-8. **Format model:** [iteration 35 addendum](m4-6gr3-ship-goldens-sprint.md). The sprint-planner skill named in CLAUDE.md is absent from the supplied catalog and tracked skills; the supplied format model governs this addendum.
**Estimate:** two working days including rig/evaluator hand-off; about 310 counted implementation LOC plus evidence. **Risk:** moderate evidence/runtime risk. **Authority:** approved round-3 work (D-66), dependencies M4.6gR3 / PR #257 already landed. This is `[LOOP+RENDER]`: prepare verified evidence, then park unmerged for Mark's S1 sign-off. Historical parent fields remain unchanged.

## Reality check at HEAD `7b4bee06b1f13ba65544d919391a7cbc161b73d1`

- Pin comparisons to `7b4bee0`, never `origin/main`. The design's spike base `13bcc40` is historical evidence, not this sprint's comparison base.
- Makefile:9 defines `SCRATCH := .godot/tmp`. Therefore the default capture and bridge logs really are `.godot/tmp/capture-m4.log` and `.godot/tmp/bench-bridge.log`. Pass `SCRATCH=.godot/tmp` explicitly below; a custom SCRATCH would require changing the checks too. The bench JSON is also fixed there by the driver.
- `capture-m4` still invokes the interior mode and tests only the sheet. Both proposed drivers are absent. `bench` still contains the Metal/Vulkan starfield loop; preserve those recipe bytes in the default branch. `BENCH_TIER` defaults to large; add a separate `BRIDGE_TIER` defaulting to medium while honoring explicit TIER.
- Make normalizes slash-containing AILANG paths with `abspath`; `GODOT_SIM` sets `AILANG_BIN` using `command -v`. The seven includes are `mk/ai.mk`, `mk/site.mk`, `mk/m5.mk`, `mk/m45.mk`, `mk/ism.mk`, `mk/navigation-usability.mk`, `mk/planet-presentation.mk`. They use relative data/tool paths and several `$(CURDIR)` paths. `make -f /tmp/base.Makefile` is safe only with `-C "$ROOT"`; running from the temporary directory without that is broken.
- The current CI was simplified on 2026-10-16: its run steps name exactly three make targets, `deps`, `lore-import`, `test`. Do not inherit iteration 35's 22-target inventory. Runtime is v0.54.11, Godot 4.7.2.
- Route seams exist: `ShipConsoles.walk_to/use`, commit's `hold_commit(GalaxyMap.HOLD_S)`, `journey_tick`, `dismiss_arrival`, camera follow and observer sync. The playthrough harness ages presentation via `_process`; home needs a tick before commit. No production seam edit is needed.
- Design-measured capture: 1202 outbound + 1226 home ticks, approximately 43 ms/tick, 149.7 s in-script, 189–245 s wall time. Real-frame blank metrics: lit 0.450–0.887, levels 128–200. Live bridge: 821 measured frames, boost/cruise 446/375, p50 41.45 / p99 85.32 ms; stopped ticks p99 15.25–15.43 ms. These are supplied measurements, not planner observations. Making live p99 <16.7 ms is parked performance work.
- Planner environment has no GPU window, network or gcloud. Every command/validation run here is **UNINFORMATIVE UNDER SANDBOX**, never a gate pass or failure. No make target or GPU drill is run by the planner. Existing recipes such as `deps` contain git writes; invoking make here would violate planner restrictions even apart from unavailable resources.

## Tasks (day-by-day, test-first)

1. **Day 1, RED — 45 min.** Write capture recipe guards and bridge dispatch/structural/verdict guards before the drivers. Keep default bench recipe verbatim. On an executor GPU host, record missing-driver RED: make rc=2; no valid final summary. Write the AC9 baseline/dry-run checks before changing dispatch. Write the wrapper below before mutations; its no-op and bad-root controls must distinguish harness errors from kills. Retain red logs in the executor report.
2. **Day 1, capture GREEN — 2 hours.** Implement `tools/m4_ship_capture.gd` with the exact pinned constants, states, image-read and filename lines in the design. Clean previous PNGs and all three manifests before scene setup. Use one real seed-424242 session, medium tier, background on, >=60000 stars, 1600x900; walk to the helm within 600 presentation frames. Check each console call/tick, maximum 4000 ticks per leg, age cards with `_process(1.0 / GalaxyMap.TICK_HZ)`, and test every state independently. Capture both views at each of seven states; six presentation frames plus post-draw after camera sync. Record snapshot values from the sim, not recomputed physics. Enforce beta/glow/phase/arrival-target bounds from the design table. Run AC1–AC4 on the GPU host (two captures, about eight minutes).
3. **Day 1, bench GREEN — 90 min.** Implement `tools/m4_ship_bench.gd`: root content scale at 2560x1440, vsync off/read back, default medium, default Metal, captain DECK eye, real committed route. Docked: 120 warm-up + 300 measured frames. Transit: departure tick + 30 presentation frames, auto heartbeat enabled, 120 warm-up, 30 wall seconds measured. Require >=300 samples, positive boosting and cruising counts, root/sky/geometry sizes, requested tier and committed start. Use nearest-rank percentiles; handle zero samples before indexing. Print the target from `P99_TARGET_MS`, record host load and JSON evidence, print GPU time unavailable on Metal. Exit driver 1 for invalid, 2 for valid MISS, 0 for valid ok; make returns 2 for either failed recipe. Run AC7; record AC8's expected performance miss without relaxing the target.
4. **Day 2, negative controls — reserve 35 min.** On the GPU host, run fresh-copy DC0 before DC1–DC5 and DB1–DB3; all nine named mutation/no-op checks in AC10–AC13 are required from the executor. Preserve the summary and named evidence before trap cleanup. Every mutation changes one pinned line exactly once; status 3 is never a killed mutant. Run DB3 as the green bench control. Run the no-op with caller errexit on and off. Scope/integrity checks run even on error.
5. **Day 2, gates and visual evidence — reserve 2 hours plus suite latency.** Run the Gate list outside the planner sandbox, AC9/AC14/AC15, inspect all 15 PNGs, and write AC5's exact look record. A different evaluator agent/model repeats DC0, DC4, DC5, DB2, DB3 and no-op, and reviews all executor evidence; allow another 15–20 minutes plus suite/GPU latency. No delegation is launched by this planner. Diagnose failures within scope; a missing asset, timeout or parse error is not a successful drill.
6. **Day 2, S1 hand-off — 30 min plus controller/network latency.** Outside every sandbox, attended or controller-run: AC6 publish/HTTP equality, then issue #1 post with all URLs, sheet and bench MISS evidence; provide the charter's review build through the controller's existing process. Add changelog and update only this feature's notes. Record S1 pending and park the PR unmerged. `passes` stays null while required outside-sandbox evidence or S1 remains pending; do not claim parent M4.6 complete or AC12 green.

## Files and LOC

| Executor file | Change | Estimated LOC |
|---|---|---:|
| `tools/m4_ship_capture.gd` | scene/route, checks, shots, manifests, sheet | 175–190 |
| `tools/m4_ship_capture.gd.uid` | generated identity | 1 |
| `tools/m4_ship_bench.gd` | live bench, structural checks, JSON | 95–110 |
| `tools/m4_ship_bench.gd.uid` | generated identity | 1 |
| `Makefile` | capture replacement, bench dispatch, publish, phony/help | 30–40 |
| `changelogs/unreleased/2026-10-16-m4-6rr3-ship-renders-bench.md` | verification behavior | 10 |
| `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | 15 look rows, AC/gate/drill statuses, public links, bench | 65–90 evidence |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | only this appended feature's progress | 10–20 evidence |

Budget about 310 counted LOC; reserve up to 350 for fail-closed checks, not production edits. The earlier ~200 estimate is superseded by the design's measured ~300. Planner writes only this addendum and the single appended feature; the design and parent sprint are read-only.

## Implementation requirements that the drills depend on

Capture must reload each saved PNG and assert both lit fraction >=0.10 and distinct luminance levels >=32 on the 64x36 sample grid. Append every successful shot path in shot order, before deduplication checks; do not deduplicate this array. Sheet is separate, never a fifteenth entry in that array. Log frame basenames so the anchored AC patterns match. The manifest schema is pinned here to top-level `frames`, `seed`, `tier`, `size`; each frame has `file`, `state`, `view`, `ship`, `journey`, `clock`, `eye_m`, `world_sha256` plus the other design metadata. `file` is a basename. Size is `[1600,900]`. World hashes are `SimBridge.encode(world)` hashes, one per frame, not PNG hashes.

**Gemini DC4 requirement, pinned:** use exactly this loop shape over the **14 recorded paths**, without any intermediate `unique`, dictionary keys or directory listing:

```gdscript
var n := shots.size()
for i in range(n):
	for j in range(i + 1, n):
		if FileAccess.get_sha256(shots[i]) == FileAccess.get_sha256(shots[j]):
			_fail("duplicate %s = %s" % [shots[i].get_file(), shots[j].get_file()])
```

DC4 removes only the filename's view suffix, leaving two recorded entries per state pointing at the same final file. There are C(14,2)=91 comparisons, of which 7*C(2,2)=**7 equal pairs**, provided cross-state files remain distinct (the green control establishes that premise). There are seven physical shot PNGs plus the sheet, **8 PNGs**; recorded shot entries and world hashes remain 14. Deduplicating paths would give zero duplicate lines and violate this requirement. If incidental cross-state equality occurs, investigate it; do not weaken the exact seven assertion.

Make capture must assert 14 frame lines, 15 PNGs, 15 manifest hash rows, 15 distinct PNG hashes, 14 world hash rows, exactly one OK and zero FAIL/SCRIPT ERROR lines. Hash-check all PNGs. Print a named `capture-m4: FAILED` recipe footer on rejection. Driver DC3 must report only one `FAIL state boost_b09 not reached`; other states continue independently. Count/sheet failures may add other named failures and are not included in that state count.

Bench must print `bench-bridge: OK` only for structurally valid measurements, including valid MISS; recipe still rejects MISS. Preserve the driver's rc in `bench-bridge: FAILED (exit 2: ...` or `(exit 1: ...` evidence, so the make rc=2 alone cannot hide the distinction. DB3 must print `1000.0` (not `1000`) using one-decimal formatting of the constant. Unknown SCENE runs only the error branch, no GPU driver. Publishing verifies exactly 15 PNG hashes, uploads **18 files** (15 PNG + JSON + two hash manifests), fails immediately on any upload error and prints `capture-m4-publish: uploaded 18 files` only after all succeed. Capture/bridge/publish stay outside make test and CI.

## Corrected command setup (executor, bash, outside planner sandbox)

All AC blocks below are independent subshells except setup and wrapper installation. Keep the same bash session for ROOT/A/S/functions. Every temporary path is under S or created with an immediate EXIT/signal trap. Copy durable evidence into the report before closing the session. No block below performs a git write.

```sh
ROOT=/Users/voightkampff/dev/sunholo-data/.stapledon-loop-iter36
ROOT=$(git -C "$ROOT" rev-parse --show-toplevel) || exit 4
BASE=7b4bee0
A="$ROOT/runtime/bin/ailang"
C="$ROOT/.godot/tmp/capture-m4.log"
B="$ROOT/.godot/tmp/bench-bridge.log"
S=$(mktemp -d /tmp/m46r-session.XXXXXX) || exit 4
trap 'rm -rf -- "$S"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cd "$ROOT" || exit 4
m() { env -u MAKEFLAGS -u MFLAGS -u SCENE -u TIER make --no-print-directory -C "$ROOT" "$@" AILANG="$A" SCRATCH=.godot/tmp; }
count() { local n r; n=$(grep -c -- "$2" "$1"); r=$?; [ "$r" -le 1 ] || return "$r"; printf '%s\n' "$n"; }
eq_count() { local n; n=$(count "$1" "$2") || return; test "$n" -eq "$3"; }
```

## Corrected mutation wrapper (executor installs under S)

Wrapper returns 0 only for the asserted make rc and named count; 1 is assertion failure, 2 invalid root/setup, 3 unapplied mutation, 4 missing evidence/script error/integrity/timeout. Catchable signals clean up; SIGKILL cannot execute traps. It accepts worktrees whose `.git` is a file. It neither copies Git metadata nor invokes git writes. Source diff/index/status and source driver/Makefile hashes must stay equal, including untracked new drivers. Run sequentially without another writer changing ROOT.

```sh
cat > "$S/m46r_drill.sh" <<'DRILL'
#!/usr/bin/env bash
set -eu
[ "$#" -ge 8 ] && [ "$#" -le 9 ] || exit 2
R=$(git -C "$1" rev-parse --show-toplevel) || exit 2
TGT=$2; F=$3; P=$4; LOG=$5; PAT=$6; WANT=$7; EXPECT_RC=$8; PRE=${9:-}
case "$TGT" in capture-m4) args=(capture-m4);; bridge) args=(bench SCENE=bridge);; *) exit 2;; esac
case "$LOG" in .godot/tmp/capture-m4.log|.godot/tmp/bench-bridge.log) ;; *) exit 2;; esac
T=$(mktemp -d /tmp/m46r-copy.XXXXXX) || exit 2
snap=0
snapshot() {
  git -C "$R" diff --binary HEAD > "$T/$1.diff" &&
  git -C "$R" diff --cached --binary > "$T/$1.index" &&
  git -C "$R" status --porcelain --untracked-files=all > "$T/$1.status" &&
  (cd "$R" && shasum -a 256 Makefile tools/m4_ship_capture.gd tools/m4_ship_bench.gd) > "$T/$1.hash"
}
cleanup() {
  result=$?
  trap - EXIT HUP INT TERM
  set +e
  if [ "$snap" -eq 1 ]; then
    snapshot after || result=4
    for part in diff index status hash; do cmp -s "$T/before.$part" "$T/after.$part" || result=4; done
  fi
  rm -rf -- "$T" || result=4
  exit "$result"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
snapshot before || exit 4
snap=1
mkdir "$T/tree"
rsync -a --exclude .git --exclude .godot/tmp --exclude renders --exclude .scratch "$R/" "$T/tree/" || exit 4
if [ -n "$F" ]; then
  case "$F" in tools/m4_ship_capture.gd|tools/m4_ship_bench.gd) ;; *) exit 2;; esac
  cp "$T/tree/$F" "$T/original"
  # Require one substitution, not merely a changed marker or an ignored Perl error.
  perl -e 'my ($e,$f)=@ARGV; open my $h,"<",$f or die $!; local $/; my $s=<$h>; my $n=0; for (split /(?<=\n)/,$s) { my $v=eval $e; die $@ if $@; $n += $v || 0; } die "mutation matches=$n (want 1)\n" unless $n==1;' "$P" "$T/tree/$F" || {
    echo "drill: mutation did not change exactly one line of $F"; exit 3;
  }
  perl -i -pe "$P" "$T/tree/$F"
  if cmp -s "$T/original" "$T/tree/$F"; then echo "drill: mutation did not change $F"; exit 3; fi
fi
# Reimport the copied project to refresh class_name registrations; no source edits.
if ! (cd "$T/tree" && perl -e 'alarm 120; exec @ARGV' godot --headless --path . --import > "$T/import.out" 2>&1); then cat "$T/import.out"; exit 4; fi
if grep -Eq 'SCRIPT ERROR:|Parse Error:' "$T/import.out"; then cat "$T/import.out"; exit 4; fi
if [ "$PRE" = stale ]; then
  mkdir -p "$T/tree/renders/m4"
  cp "$R"/renders/m4/*.png "$T/tree/renders/m4/"
  cp "$R/renders/m4/manifest.json" "$R/renders/m4/m4_manifest.sha256" "$R/renders/m4/worlds.sha256" "$T/tree/renders/m4/"
  (cd "$T/tree/renders/m4" && shasum -a 256 -c m4_manifest.sha256 >/dev/null)
  test "$(ls "$T/tree"/renders/m4/*.png | wc -l | tr -d ' ')" -eq 15
  # This proves the stale set would satisfy the old sheet-only assertion.
  test -s "$T/tree/renders/m4/contact_sheet.png"
elif [ -n "$PRE" ]; then exit 2; fi
set +e
(cd "$T/tree" && env -u MAKEFLAGS -u MFLAGS -u SCENE -u TIER perl -e 'alarm 900; exec @ARGV' make --no-print-directory "${args[@]}" AILANG="$T/tree/runtime/bin/ailang" SCRATCH=.godot/tmp > "$T/make.out" 2>&1)
rc=$?
set -e
case "$rc" in 0|2) ;; *) exit 4;; esac
log="$T/tree/$LOG"
cat "$T/make.out"
test -s "$log" || exit 4
if grep -Eq 'SCRIPT ERROR:|Parse Error:' "$log"; then cat "$log"; exit 4; fi
set +e
n=$(grep -c -- "$PAT" "$log"); grc=$?
set -e
[ "$grc" -le 1 ] || exit 4
printf 'drill make_rc=%s count=%s want=%s\n' "$rc" "$n" "$WANT"
[ "$rc" -eq "$EXPECT_RC" ] && [ "$n" -eq "$WANT" ] || exit 1
if [ "$EXPECT_RC" -eq 2 ]; then
  if [ "$TGT" = capture-m4 ]; then
    grep -q '^capture-m4: FAILED' "$T/make.out" || exit 4
  else
    grep -q '^bench-bridge: FAILED (exit 1:' "$T/make.out" || exit 4
  fi
fi
if [ "$PRE" = stale ]; then
  # Early quit occurs before driver cleanup: the old files really remained available.
  (cd "$T/tree/renders/m4" && shasum -a 256 -c m4_manifest.sha256 >/dev/null)
fi
DRILL
check_drill() (
  set +e
  bash "$S/m46r_drill.sh" "$ROOT" "$@"
  rc=$?
  test "$rc" -eq 0
)
```

For no-op AC13 invoke the wrapper directly and assert 3; do not send it through check_drill, which deliberately requires 0. A make timeout (alarm signal), absent log, import/parse error, or prerequisite error cannot supply a named recipe rejection and is not a kill. The wrapper prints evidence before removing its tree; the executor retains it in the report/session transcript.

## Acceptance criteria (AC1–AC15, exact corrected commands)

Expected codes below are for the complete block, unless explicitly labeled raw. All functional evidence must come from outside the planner sandbox. AC1 precedes AC2–AC6; AC4 replaces the capture set, so AC5 and AC6 inspect/publish that final set. Run each block with bash. Count helpers tolerate a genuine zero-match grep, but never a missing-file or invalid-pattern error.

**AC1 — S1 output contract.** Expected block rc=0, raw make=0; frame lines 14, OK 1, FAIL 0, PNGs 15, hash rows 15/distinct 15, world rows 14. Recipe also asserts these, not just this caller.

```sh
(set -eu; m capture-m4; eq_count "$C" '^capture-m4: ok frame ' 14; eq_count "$C" '^capture-m4: OK$' 1; eq_count "$C" '^capture-m4: FAIL' 0; eq_count "$C" 'SCRIPT ERROR:' 0
 test "$(ls renders/m4/*.png | wc -l | tr -d ' ')" -eq 15
 test "$(wc -l < renders/m4/m4_manifest.sha256)" -eq 15
 test "$(cut -d' ' -f1 renders/m4/m4_manifest.sha256 | sort -u | wc -l)" -eq 15
 test "$(wc -l < renders/m4/worlds.sha256)" -eq 14
 (cd renders/m4 && shasum -a 256 -c m4_manifest.sha256))
```

**AC2 — Every state/view and its real sim value.** Expected rc=0; one line per named file (14 total), two cruising beta-0.99 lines, six zero-glow rest/arrival lines. Driver asserts boost .5<=beta<.51, boost .9<=beta<.91, brake .49<beta<=.5, cruise glow>0/live sky; docked/arrivals beta=0 and glow=0, correct phase/target. These are driver failures, not descriptive log text.

```sh
(set -eu
 states=(docked boost_b05 boost_b09 cruise_099 brake_b05 arrived_acen arrived_home)
 for i in "${!states[@]}"; do
   for view in deck forward; do
     file=$(printf '%02d_%s_%s.png' "$((i+1))" "${states[$i]}" "$view")
     eq_count "$C" "^capture-m4: ok frame $file " 1
   done
 done
 eq_count "$C" '^capture-m4: ok frame ' 14
 eq_count "$C" '^capture-m4: ok frame 04_cruise_099_.* phase cruising beta 0\.99 ' 2
 eq_count "$C" '^capture-m4: ok frame 0[167]_.* glow_pole_w_m2 0\(\.0\)\?$' 6)
```

**AC3 — Structured manifest.** Expected rc=0; 14 frame objects, 14 SHA256s (seven state worlds, each shared by two views), seven state IDs, two views, and 2 Sol / 2 alpha-Cen arrival frames. Check structure, not pretty-print line counts; remaining frame metadata required by Design §1 is written and reviewed.

```sh
jq -e '.seed == 424242 and .tier == "medium" and .size == [1600,900] and
 (.frames | length == 14) and
 ([.frames[].file] | unique | length == 14) and
 ([.frames[].world_sha256] | unique | length == 7) and
 (.frames | group_by(.state) | all(.[]; length == 2 and ([.[].view] | sort == ["deck","forward"]) and ([.[].world_sha256] | unique | length == 1))) and
 ([.frames[].state] | unique | sort == (["docked","boost_b05","boost_b09","cruise_099","brake_b05","arrived_acen","arrived_home"] | sort)) and
 ([.frames[].view] | unique | sort == ["deck","forward"]) and
 ([.frames[] | select(.world_sha256 | test("^[0-9a-f]{64}$"))] | length == 14) and
 ([.frames[] | select(.state == "arrived_acen" and .journey.plan.target.id == "CNS5:3627")] | length == 2) and
 ([.frames[] | select(.state == "arrived_home" and .journey.plan.target.id == "Sol")] | length == 2) and
 ([.frames[] | select(has("ship") and has("clock") and has("eye_m"))] | length == 14)' renders/m4/manifest.json
```

**AC4 — Repeat worlds.** Expected rc=0, second make=0; 14 world-hash rows each run, byte-equal. Temporary baseline is trap-cleaned even when capture fails. Pixel identity across runs is not required.

```sh
(set -eu; T=$(mktemp -d /tmp/m46r-worlds.XXXXXX); trap 'rm -rf -- "$T"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP
 test "$(wc -l < renders/m4/worlds.sha256)" -eq 14
 cp renders/m4/worlds.sha256 "$T/worlds"
 m capture-m4
 test "$(wc -l < renders/m4/worlds.sha256)" -eq 14
 cmp "$T/worlds" renders/m4/worlds.sha256)
```

**AC5 — Opened and looked at.** Expected rc=0; exactly 15 distinct PNG rows, matching the manifest, each with a nonempty observation. Executor opens all 15 images, then writes `| renders/m4/<basename> | <what I actually saw> |` rows in the report. A row-count check cannot substitute for viewing; evaluator reviews the observations, especially starbow/glow/arrival cards and contact-sheet consistency. S1 is still Mark's decision.

```sh
(set -eu
 RPT=design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md
 test "$(grep -c '^| renders/m4/' "$RPT")" -eq 15
 awk -F'|' '/^\| renders\/m4\// {if ($3 !~ /[^[:space:]]/) exit 1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); sub(/^renders\/m4\//,"",$2); print $2}' "$RPT" | LC_ALL=C sort > "$S/look.names"
 awk '{print $2}' renders/m4/m4_manifest.sha256 | LC_ALL=C sort > "$S/hash.names"
 test "$(sort -u "$S/look.names" | wc -l)" -eq 15
 cmp "$S/look.names" "$S/hash.names")
```

**AC6 — Publish and public equality, MUST RUN OUTSIDE ANY SANDBOX, attended or controller-run.** Expected rc=0; publish raw make=0, exactly one `uploaded 18 files` summary, exactly 18 fetched/hash-equal files, including the 15 PNGs. Requires gcloud credentials/network and public HTTP. Controller receives this exact pending task if executor lacks those capabilities. No simulated sandbox upload counts.

```sh
(set -eu; set -o pipefail
 m capture-m4-publish > "$S/publish.out" 2>&1
 cat "$S/publish.out"
 eq_count "$S/publish.out" '^capture-m4-publish: uploaded 18 files$' 1
 (cd renders/m4 && shasum -a 256 -c m4_manifest.sha256)
 cp renders/m4/m4_manifest.sha256 "$S/public.sha256"
 (cd renders/m4 && shasum -a 256 manifest.json m4_manifest.sha256 worlds.sha256) >> "$S/public.sha256"
 test "$(wc -l < "$S/public.sha256")" -eq 18
 n=0
 while read -r sum name; do
   curl -fsSL -o "$S/public.file" "https://storage.googleapis.com/stapledons-voyage-assets/refs/m4_ship_s1/$name"
   got=$(shasum -a 256 "$S/public.file" | cut -d' ' -f1)
   test "$got" = "$sum"
   n=$((n+1))
 done < "$S/public.sha256"
 test "$n" -eq 18)
```

**AC7 — Valid structure and correct verdict/status mapping.** Expected rc=0; raw make=2 for the measured MISS (driver=2), or raw make=0 if legitimately fast; exactly one valid OK, zero structural FAIL/SCRIPT ERROR, exactly one verdict. Capture stdout separately so the recipe's driver exit footer and host load survive. Driver asserts frames>=300 and >=1 each boosting/cruising, sizes/tier/vsync/commit. No fixed 821/446/375 sample counts are assumed.

```sh
(set +e
 m bench SCENE=bridge > "$S/bench.out" 2>&1; rc=$?
 set -e
 cat "$S/bench.out"
 eq_count "$B" '^bench-bridge: OK$' 1
 eq_count "$B" '^bench-bridge: FAIL' 0
 eq_count "$B" 'SCRIPT ERROR:' 0
 eq_count "$B" '^bench-bridge: frame ms ' 1
 if grep -q 'target p99 < 16\.7: ok)$' "$B"; then
   test "$rc" -eq 0
   eq_count "$B" 'target p99 < 16\.7: ok)$' 1
   eq_count "$B" 'target p99 < 16\.7: MISS)$' 0
 else
   test "$rc" -eq 2
   eq_count "$B" 'target p99 < 16\.7: MISS)$' 1
   eq_count "$B" 'target p99 < 16\.7: ok)$' 0
   eq_count "$S/bench.out" '^bench-bridge: FAILED (exit 2:' 1
 fi
 test -s .godot/tmp/bench-bridge.json)
```

**AC8 — AC12 performance evidence; expected unmet until M4.6pR3, required at P-land.** Reuse AC7's same run; raw invocation is `m bench SCENE=bridge`, expected raw make=2 on current spike, driver=2. The following expected-MISS assertion block exits 0, explicitly checking the two codes through log/footer. It is a successful check of red evidence, not a passing 60-fps gate. If a quiet-rig rerun really passes, use the second block and record measured p99, never force a MISS.

```sh
(set -eu; eq_count "$B" 'target p99 < 16\.7: MISS)$' 1; eq_count "$S/bench.out" '^bench-bridge: FAILED (exit 2:' 1)
# Actual P-land performance criterion (expected rc=1 while the measured MISS remains):
(set -eu; eq_count "$B" 'target p99 < 16\.7: ok)$' 1)
```

**AC9 — Default unchanged and dispatch rejects unknown scene.** Expected rc=0; default dry-run byte-equal with fixed base; unknown raw make=2, exactly one error; bridge dry-run selects the new driver exactly once. Both makefile evaluations run with ROOT as CURDIR, identical includes, absolute runtime and no directory banners. No command is executed by `-n -o lens-assets bench` (bench has no recursive-make line). S is already trap-owned.

```sh
(set -eu
 git -C "$ROOT" show "$BASE:Makefile" > "$S/base.Makefile"
 m -f "$S/base.Makefile" -n -o lens-assets bench > "$S/bench.before"
 m -n -o lens-assets bench > "$S/bench.after"
 cmp "$S/bench.before" "$S/bench.after"
 m -n -o lens-assets bench SCENE=bridge > "$S/bench.bridge"
 eq_count "$S/bench.bridge" 'tools/m4_ship_bench\.gd' 1
 set +e
 m -o lens-assets bench SCENE=nope > "$S/bench.nope" 2>&1; rc=$?
 set -e
 test "$rc" -eq 2
 eq_count "$S/bench.nope" '^bench: unknown SCENE=nope ' 1)
```

**AC10 — Four capture mutants.** Every call expected wrapper/block rc=0 and raw make=2, with exact named counts below. DC1 blank=14; DC2 docked duplicate=1 (other transit duplicate pairs deliberately not counted); DC3 unreached boost_b09=1; DC4 duplicate pairs=7. See the arithmetic/loop requirement above.

```sh
check_drill capture-m4 tools/m4_ship_capture.gd 's/^\tvar img := root\.get_texture\(\)\.get_image\(\)$/\tvar img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)/' .godot/tmp/capture-m4.log '^capture-m4: FAIL blank' 14 2
check_drill capture-m4 tools/m4_ship_capture.gd 's/^const FORWARD := \[89\.99, 0\.0\]/const FORWARD := DECK/' .godot/tmp/capture-m4.log '^capture-m4: FAIL duplicate 01_docked_deck.png = 01_docked_forward.png$' 1 2
check_drill capture-m4 tools/m4_ship_capture.gd 's/"beta_min": 0\.9\}/"beta_min": 1.5}/' .godot/tmp/capture-m4.log '^capture-m4: FAIL state boost_b09 not reached$' 1 2
check_drill capture-m4 tools/m4_ship_capture.gd 's/%02d_%s_%s\.png" % \[OUT, n, state, view\]/%02d_%s.png" % [OUT, n, state]/' .godot/tmp/capture-m4.log '^capture-m4: FAIL duplicate' 7 2
```

**AC11 — DC5 stale set cannot satisfy a driver that exits before cleanup/shooting.** Expected wrapper rc=0, raw make=2, zero driver OK, one named recipe rejection. Seed actual AC1 PNGs and matching manifests, not text files with `.png` suffixes. PRE verifies hashes and old sheet-only positive assertion before make; post-check proves files stayed available when the recipe rejected them. The new recipe's OK/frame-count guards must cause rejection. Parse errors and missing-log errors cannot count.

```sh
check_drill capture-m4 tools/m4_ship_capture.gd 's/^(func _run\(\) -> void:)$/$1\n\tquit(0)\n\treturn/' .godot/tmp/capture-m4.log '^capture-m4: OK$' 0 2 stale
```

**AC12 — Bench mutants and green control.** Each wrapper exits 0. DB1/DB2 raw make=2, driver=1, named FAIL exactly once. DB3 raw make=0, driver=0, verdict `target p99 < 1000.0: ok)` exactly once. No recipe mutation is needed for DB3; it matches the driver's printed target. Zero-frame code must not access an empty percentile array.

```sh
check_drill bridge tools/m4_ship_bench.gd 's/^const BENCH_S := 30\.0$/const BENCH_S := 0.0/' .godot/tmp/bench-bridge.log '^bench-bridge: FAIL measured 0 frames' 1 2
check_drill bridge tools/m4_ship_bench.gd 's/^\troot\.content_scale_size = SIZE$/\troot.content_scale_size = SIZE \/ 2/' .godot/tmp/bench-bridge.log '^bench-bridge: FAIL viewport 1280x720' 1 2
check_drill bridge tools/m4_ship_bench.gd 's/^const P99_TARGET_MS := 16\.7$/const P99_TARGET_MS := 1000.0/' .godot/tmp/bench-bridge.log 'target p99 < 1000\.0: ok)$' 1 0
```

**AC13 — Unapplied mutation is an error, both caller modes.** Expected block rc=0, wrapper=3 twice, message once per invocation. Also DC0 positive-control wrapper/make=0, `capture-m4: OK` exactly one. A bad-root control expects 2. This prevents a missing mutation or an unrecognized worktree from masquerading as rejection.

```sh
check_drill capture-m4 '' '' .godot/tmp/capture-m4.log '^capture-m4: OK$' 1 0
(for option in -e +e; do
  if bash -c 'set "$1"; shift; bash "$@"' _ "$option" "$S/m46r_drill.sh" "$ROOT" capture-m4 tools/m4_ship_capture.gd 's/NO_SUCH_TEXT/x/' .godot/tmp/capture-m4.log '^capture-m4: OK$' 0 2 > "$S/noop.out" 2>&1; then rc=0; else rc=$?; fi
  test "$rc" -eq 3 || exit 1
  eq_count "$S/noop.out" '^drill: mutation did not change' 1 || exit 1
 done)
(if bash "$S/m46r_drill.sh" "$S/not-a-checkout" capture-m4 '' '' .godot/tmp/capture-m4.log x 0 0; then rc=0; else rc=$?; fi; test "$rc" -eq 2)
```

**AC14 — No production changes.** Expected rc=0, zero protected-path differences including local tracked edits; scope review below additionally catches untracked/committed additions. Pin the base to the supplied HEAD.

```sh
git -C "$ROOT" diff --quiet "$BASE" -- demos interior ui sky bridge sim physics assets data main.gd export_presets.cfg tools/interior_capture.gd tools/bench.gd .github mk
```

**AC15 — Suite, goldens, guards.** Expected rc=0 outside sandbox; golden total exactly 373, zero FAIL and exactly one zero-failure overall summary. No new physics formula or shipped scene, no new Python; lint/guard remain unchanged. Gate inventory also requires deps and the cross-repo lore check.

```sh
(set -eu; m test; m golden; m lint-precision python-guard
 eq_count "$ROOT/.godot/tmp/golden.log" '^ok' 373
 eq_count "$ROOT/.godot/tmp/golden.log" '^FAIL' 0
 eq_count "$ROOT/.godot/tmp/golden.log" '^golden: 0 failures$' 1)
```

## Drill list, expected outputs and runtime ownership

Times use the design's 189–245 s capture and ~1.5 min full bench budget, not new sandbox timings. Add 0.5–1 minute per invocation for copy/import/cleanup of ignored assets. Nine named drills are DC1–DC5, DB1–DB3 and no-op; DC0 is an extra positive control. Bad root does no copy and takes <1 s. No-op occurs before import, after copy. Sequential executor budget is roughly **30–35 minutes including DC0 and copy overhead**, with 900 s per-make timeout; slow fence teardown may extend it. It is not nine GPU runs of equal duration.

| Drill | Required output/count; raw make | Core estimate | Executor | Evaluator |
|---|---|---:|---|---|
| DC0 positive | `drill make_rc=0 count=1 want=1`, capture OK | 4 min | yes, first | yes, first |
| DC1 black | `make_rc=2 count=14 want=14`, named blank lines | 4 min | yes | review evidence |
| DC2 identical views | `make_rc=2 count=1 want=1`, docked duplicate | 4 min | yes | review evidence |
| DC3 unreachable .9 | `make_rc=2 count=1 want=1`, state boost_b09 not reached | 4 min | yes | review evidence |
| DC4 overwrite | `make_rc=2 count=7 want=7`, duplicate pairs | 4 min | yes | repeat |
| DC5 stale | `make_rc=2 count=0 want=0`, recipe FAILED; seed hashes valid | 0.5 min | yes | repeat |
| DB1 zero samples | `make_rc=2 count=1 want=1`, measured 0 frames | 0.5 min | yes | review evidence |
| DB2 half size | `make_rc=2 count=1 want=1`, viewport 1280x720 | 1.5 min | yes | repeat |
| DB3 1000 ms | `make_rc=0 count=1 want=1`, 1000.0: ok | 1.5 min | yes | repeat |
| No-op | wrapper=3; mutation did not change exactly one line; no make | 0.1 min each | both caller modes | repeat |

Each expected result above is enforced by the wrapper and callers, not just printed. Evaluator repeats cost ~15–20 minutes with copy overhead, in addition to reviewing all nine executor outcomes. A report must distinguish expected named failures from script/import/prerequisite/timeout failures. DC1 may also produce duplicate lines (all black), DC3 may produce output-count failures, DC4 must also fail the 15-PNG recipe guard; only the named counts in the table are pinned. Do not assert an invented total failure count.

## Gate list

Read directly from `.github/workflows/ci.yml` at `7b4bee0`: **all make targets in run steps are `deps`, `lore-import`, `test`, in that order**. CI also provisions Godot 4.7.2 and AILANG v0.54.11 and obtains the design repo for both halves of lore verification. Removed CI pre-steps are not separate current gates. The following is the complete executor inventory plus this design's new/changed targets and explicit policy guards:

| Gate command (ROOT session above) | Expected outcome outside sandbox |
|---|---|
| `m deps` | raw rc=0; locked packages resolve without dependency changes |
| `m lore-import CHECK=1 D=/tmp/stapledons-design` | raw rc=0; vendored lore and manifest-pinned design objects both match; controller provisions D first |
| `m test` | raw rc=0; every existing prerequisite guard succeeds, zero failures; unchanged suite provides its own counts |
| `m golden` then AC15 counts | raw rc=0; **373 ok**, zero failures; needs GPU window outside sandbox |
| `m lint-precision python-guard` | raw rc=0; precision and Python policy guards succeed, no new Python |
| `m capture-m4` then AC1–AC4 | raw rc=0; 14 frames + sheet, 15 PNG hashes, 14 deterministic world hashes; GPU window |
| `m bench SCENE=bridge` then AC7/AC8 | raw rc=2 / driver=2 expected for valid p99 MISS; structure OK exactly once; raw rc=0 only for real p99<16.7; GPU window |
| `m capture-m4-publish` then AC6 | raw rc=0; **18 uploads + 18 public byte matches**; MUST RUN OUTSIDE ANY SANDBOX, attended/controller, gcloud/network |
| AC9 default bench dry-run and unknown SCENE | default byte-identical; unknown raw rc=2, bridge dispatch one driver |

`capture-m4` is replaced, `bench SCENE=bridge` is a new dispatch, and `capture-m4-publish` is a new target. No CI change. `sky-assets` and `lens-assets` are capture prerequisites; provision/import assets on the GPU host before the controls. Do not infer that an AC7 expected MISS discharges the P-land performance gate. All commands attempted in a sandbox must be reported **UNINFORMATIVE UNDER SANDBOX**, including apparently successful headless checks. Existing full gates invoke their own git-mutating recipes (`deps`, test controls); this planner invokes none. Execution under a continued no-git-write restriction must be handed to a controller with suitable authority rather than running those recipes here.

## Scope check

Planner scope: only this new addendum and exactly one appended JSON feature with `passes: null`. Existing untracked UID files (31 at planner start) are pre-existing and untouched. Executor scope is the eight paths in Files and LOC; generated `renders/m4/` and `.godot/tmp/` are ignored evidence, not shipped changes. Mutation tools live only under trap-owned /tmp directories. No main/demo/interior/UI/sky/bridge/sim/physics/assets/data/export/CI/mk edits; no package pins, default starfield bench, original interior capture or existing feature edits.

Before implementation retain `git status --porcelain --untracked-files=all` and the exact list of pre-existing untracked UID paths in S. At completion inspect both `git diff --name-status 7b4bee0` and status, allowing only the eight executor paths and that exact saved UID list. Reject any new unrelated UID; read every Makefile hunk to confirm the default loop is unchanged. AC14 checks the protected tracked tree. Wrapper snapshots additionally protect the source during every temp-copy drill, including failure/no-op paths. No git-write cleanup is allowed; traps only delete paths they created.

## Design-command defects found and fixed

1. **`[ -d "$R/.git" ]` -> rejects this linked worktree's `.git` file ->** `R=$(git -C "$1" rev-parse --show-toplevel) || exit 2`. Setup uses an explicit absolute ROOT too; no caller-CWD inference. The supplied default SCRATCH paths were verified correct, so they are not counted as a defect.
2. **Wrapper `set -u` with unchecked rsync/cp/perl and only an EXIT trap -> setup/mutation errors can continue and signals can leak copies ->** `set -eu`, checked setup, immediate EXIT/HUP/INT/TERM cleanup and integrity snapshots in the corrected wrapper. All session scratch and AC4 baselines are also trap-owned; catchable exit paths clean up.
3. **`cmp` alone / fixture-only expression checks -> a malformed or multiply applied mutation can be accepted; original wrapper proves no source integrity ->** require exactly one substitution plus changed bytes, and compare source diff/index/status/driver hashes on every cleanup. AC13 explicitly asserts 3 for no-op and 2 for bad ROOT. The plan supplies the wrapper, not an assumed pre-existing `/tmp/m46r_drill.sh`.
4. **`grep -c ... 2>/dev/null; n=${n:-0}` -> missing evidence/error can satisfy a wanted zero, especially DC5 ->** require fresh nonempty log, reject script/parse errors, tolerate only grep statuses 0/1, require named recipe rejection and exact make rc. DC5 seeds real verified PNGs and matching manifests, proves the old positive sheet check, and rechecks stale hashes afterward.
5. **AC4 `cp ... /tmp/m46r_w1` -> fixed shared baseline, no cleanup ->** unique `mktemp -d` with immediate traps, assert 14 rows in both captures, then `cmp` in AC4.
6. **AC3 line-oriented grep for a target and world keys -> depends on JSON formatting and does not prove per-frame structure ->** AC3 `jq -e` asserts 14 frames/files/hashes, named state/view sets, required metadata and two correct arrival targets each. AC1 and AC5 additionally assert all emitted/countable artifacts rather than merely printing numbers.
7. **AC6 `make ... && n=0; while ...` -> upload failure can fall through to fetching an older public set; per-file mismatches need not stop the loop; only PNGs checked ->** AC6 `set -eu`/pipefail, explicit make success, exact 18-upload summary, curl to a checked temp file, immediate hash comparison, final count=18 including all metadata. Marked outside every sandbox, attended/controller-run.
8. **AC7 `test $rc != 0`, AC8 bare expected exit 0 and bench help “exit 1” -> conflates driver 1/2 with make's 2, and advertises an unmet performance criterion ->** AC7 captures make rc explicitly: MISS requires 2 plus footer driver=2, fast verdict requires 0. AC8 reuses the run, asserts expected MISS evidence and separately labels the actual ok criterion expected red until M4.6pR3; no performance waiver masquerades as green. Bridge help states make nonzero, driver invalid=1/MISS=2.
9. **AC9 `git show origin/main:Makefile`, AC14 `git diff origin/main` -> moving base; `make -f` from temp cwd -> relative includes/CURDIR/tool paths break ->** pin `BASE=7b4bee0`, materialize only its Makefile under S, use `m` (`make -C "$ROOT" --no-print-directory`) for both evaluations with identical absolute runtime and scratch. Assert each dry-run status, then `cmp`; unknown SCENE must return exactly 2, with one named message. AC14 compares the pinned base including local tracked changes; scope checks include untracked files.
10. **AC10–AC12 MODE fail accepts any nonzero, callers may abort before checking statuses under errexit ->** wrapper asserts exact raw make=2/0 with fresh named evidence; check_drill captures status explicitly; AC13 exercises both caller modes and asserts wrapper=3. The stale drill requires the recipe FAILED footer; no unrelated prerequisite error counts.
11. **DC4 expected seven depends on an unstated implementation loop -> deduplicating recorded paths makes zero pairs and invalidates the drill ->** pin `for i in range(n): for j in range(i + 1, n):` over all 14 recorded paths and final file hashes. Seven groups of two give seven equal pairs, eight actual PNGs. Expected count remains seven, with arithmetic documented above.
12. **“9 drills … roughly 35 minutes” without ownership or differentiated cost -> misses fast no-op/early exits, copy overhead and judge work ->** per-drill table separates core/copy costs; executor runs all nine plus positive control (~30–35 min); independent evaluator repeats the risky subset (~15–20 min). AC5's printed-row surrogate is strengthened with distinct manifest-matching observations and actual image opening; S1 remains parked.

No design edits are made to repair these commands; this addendum and appended feature are the executable interpretation. Every numeric count in the acceptance commands is tested or passed to an enforcing helper; reported variable timings/frame counts have explicit structural bounds, not assumed spike equality.

## Risks and executor evidence

- Live transit's p99 MISS is measured and expected; stopping ticks, switching crew off, reducing resolution/tier, or relaxing 16.7 would invalidate the bench. Profile/fix via separate M4.6pR3, likely touching attended production files. It blocks P-land, not preparation of S1 evidence.
- Window clamp at 2560x1288 requires content scaling; DB2 must check the actual root viewport and both subviewports, not window dimensions. Metal GPU timestamps are unavailable; wall time remains authoritative.
- Fence timeout on exit can add ~95 s; preserve rc and script errors and use bounded 900 s drills. An alarm signal is a harness error. Host load affects p99; record load/adapter/tier/vsync and use a quiet rig for final performance evidence.
- PNG equality is claimed within a run, not across machines or Godot versions. AC4 compares encoded worlds only. Shader exposure/card fades may affect DC2 transit pairs; count only the docked pair. Do not introduce a pixel regression baseline before S1.
- Default consent crew, tick bound and console walking must stay as the player gets them. A future hold can prevent arrival; fail explicitly rather than silently skipping a state. Post-home selection tick and sim-time card aging are necessary.
- Ignored assets make copies large. Use sequential copies and unconditional cleanup; retain evidence before deletion. Shared Makefile work around held PRs must not expand into crew-perf or other unrelated targets. Do not move comparison refs mid-review.

## S1 park and deliberate exclusions

After AC1–AC7, AC9–AC15 and the complete gate inventory have trustworthy outside-sandbox evidence (with AC8 explicitly recorded unmet if still slow), the controller posts 15 public PNG links, contact sheet, metadata URLs, look record, bench summary and review-build link to issue #1. **Park unmerged for Mark to open/sign S1.** A controller lacking gcloud/network retains AC6 pending and routes it to an attended outside-sandbox run; neither sandbox results nor lack of reply supplies approval.

Out of scope: production visual/scene/HUD/sim/shader changes; performance fixes; 0.999c on the alpha-Cen leg; interior pans; removal of the old interior set; reviewed regression pins; CI integration of GPU targets; package/physics changes; Mark's sign-off itself. Keep design and sprint in planned/. Parent AC11's sign-off grep, final `m4-report.md`, actual AC12 green, P-land moves/roadmap updates, and R2 playtest remain parked. The controller's eventual PR/build/publication workflow is separate from this planner's two-file, no-git-write authorization.

## Planner verification

Read CLAUDE.md first, design/model/parent inputs, feature-array shape, current CI, Makefile and included target seams, console/playthrough and capture/bench references at pinned HEAD. Static inspection resolves scratch and tool paths, CI inventory, make/driver status differences and DC4 arithmetic. No GPU, network, gcloud, make target, mutation drill or git write was attempted. JSON/shell/scope validation commands run in this sandbox are **UNINFORMATIVE UNDER SANDBOX**; they are formatting/static checks only and discharge no executor acceptance criterion or gate. Only the two requested deliverables are written; existing feature bytes are preserved by a single insertion at the features-array tail.

Static validation record — **UNINFORMATIVE UNDER SANDBOX**: `jq -e .` raw rc=0 on the appended JSON; removing the one inserted object reproduces HEAD JSON bytes and data exactly. `bash -n` raw rc=0 on all 17 shell blocks. The AC3 jq query returned raw rc=0 for a synthetic 14-frame manifest and rc=1 after removing one frame. All eight mutation patterns matched their pinned-line fixture exactly once using the wrapper's Perl guard. These are static checks, not execution of any absent driver, mutation drill, acceptance gate or upload. Final scope inspection showed only the two deliverables added/modified alongside the unchanged pre-existing UID files.
