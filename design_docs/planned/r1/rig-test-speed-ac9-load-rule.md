# L4 AC9 amendment: count only the load from outside the run, and let a keep-going red run count when its red targets match (D-173 A)

**Status:** Planned (mission iteration 111 design pass, 2026-11-23). **Revision 3** (iteration 113 designer, evidence only): reads V21, the overnight host sampler (§I; V21, V27 to V32). OQ2's recommendation records the outcome, and OQ3 and R1 gain one sentence each. No change to the rule, the thresholds or the ACs. D-173 stays OPEN. **Revision 2** (controller, Gate 2 narrow-refinement carve-out after quorum round 2 BLOCKED 3 of 3 present on proof completeness and unrecorded `rig_check.sh` premises): proof Step 2.5, V26, AC13's `tree_group` check; no rule change. **Revision 1** answers design-quorum round 1, which was BLOCKED 3 of 3 present (see the Quorum log). None of the three rejects disputes option A's direction. The main change: §E now credits the run only with a **verified lower bound** on its unseen CPU in each window, not an even spread, and it cannot double-count. **Design and quorum only. No code until Mark's OK** (D-173's default: "the loop writes A's design doc and quorum only, no code, and stops for your OK; the baseline stays parked").
**Release:** r1. **Milestone:** none. This is an amendment to charter row L4 (merge tooling): AC9, §1b `report` and §1f of the parent design.
**Priority:** P1, inherited. L4's M1b baseline cannot be taken without it ([finding](rig-test-speed-1f-load-rule-finding.md)).
**Implements:** ledger [D-173](../../stapledon-mission.md) option **A**: "the loop redesigns the rule to count only load from processes outside the run (keeping the thresholds and the median-of-three), and lets a keep-going run count when its failing targets are named and identical on both sides".
**Amends:** [rig-test-speed.md](rig-test-speed.md) (AC9, §1b `report`, §1f) and [rig-test-speed-sprint.md](rig-test-speed-sprint.md) (M1b resume predicate, AC9 notes).
**Answers:** [rig-test-speed-1f-load-rule-finding.md](rig-test-speed-1f-load-rule-finding.md) (iteration 110). Nightly red: issue [#392](https://github.com/sunholo-data/stapledons-godot/issues/392) (`nightly-rig`), now red on rows 7as (`ui-theme-check`) and 7at (`basis-gate`).
**Depends on:** D-173 answered **A** (still OPEN in the ledger; this doc is its default's design-only step). Parent M1a, already on main: `tools/suite_profile.sh`, `tools/timed_recipe_shell.sh` and `tools/test_suite_profile.sh`; `tools/rig_check.sh` already runs `suite_profile.sh run --make gmake … -- $trace -k test` under `bounded` (line 113, read verbatim in V26). GNU Make 4.4.1 at `/opt/homebrew/bin/gmake`. macOS `ps`, `iostat` and `sysctl`.
**Estimated LOC:** about 300 in two PRs, split under the parent's 270-line rule.
- **A1a, the instrument (≈ 125):** `tools/suite_profile.sh` +45 (the CPU sampler and header fields); `tools/test_suite_profile.sh` +75 (`ps` and `iostat` stubs, the 8th column in `record()`, sampler and cleanup cases); `tools/timed_recipe_shell.sh` +1 −1; `CHANGELOG.md` +4.
- **A1b, the classifier (≈ 175):** `tools/suite_profile.sh` `report` +95 (the lower bound and the keep-going rule); `tools/test_suite_profile.sh` +80 (the classifier and keep-going cases).

Neither PR touches a `Makefile`, `mk/*.mk`, `tools/rig_check.sh`, `tools/test_rig_check.sh` or `tools/rig_nightly.sh` line, a held file, or Python (V22). The parent doc and sprint need about 30 more lines of text (A2).
**Evidence of this pass (revision 2, the controller's round-2 carve-out added V26's two files):** `/tmp/i111-design-evidence/` (155 files; the other 154 are listed with their hashes in its `SHA256SUMS`, sha256 `e4b0b0c66829c3ba5e7901ccbf343175b504447bd68919ec85149ea35c226b27`), packed as `/tmp/i111-design-evidence.tgz` (2,711,913 B, sha256 `65db991047566344c6ff3eb5878d1674a79e1c4eeb03ea431494efdcc6e8b773`) and published as `gs://stapledons-voyage-assets/benchmarks/ac9-design-iter111/ac9-design-iter111-evidence.tgz`. Revision 1's sums were `bba36bd1…aec12e9f7` (tgz `42d4e147…9587e6`). Revision 0's bundle hashes (`48cae8fd…`, `f9964a28…`) are superseded: revision 1 adds only files, and every revision-0 file is unchanged. The controller publishes the bundle next to iteration 110's (`gs://stapledons-voyage-assets/benchmarks/`). Each reading below cites its file. The Verification log (V-rows) gives the commands. V20 and V24 re-derive the analyses byte for byte from the raw samples. Revision 1 made **no new rig run**: its readings are re-analyses of revision 0's raw samples and runs on synthetic data, plus one `report` call on a copy of a nightly profile. That kept the host quiet for V21. **Revision 3 (iteration 113)** made no rig run either. It read V21 and two nightly profiles in place (§I). Its evidence is `/tmp/i113-v21-evidence/` (`SHA256SUMS` sha256 `c2d305f1…94c84c24b`), published as `gs://stapledons-voyage-assets/benchmarks/v21-overnight-iter113/i113-v21-evidence-clean.tgz` (365,238 B, sha256 `740c9a10…b969b3cc`), without the two nightly `database.txt` files (§I warning).

**Provenance key.**
- `[i111]` means measured in this design pass on the Studio, from the clone `stapledons-godot-iter111` at `e20175b5`, 2026-11-23 17:49 to 18:17 CET. Measurement took about 17 minutes in total. It used no GPU and ran no `make test` or `make golden`. `uptime` was read before and after every run (`uptimes.txt`).
- `[nightly]` means the three profiled nightly `rig/full` runs on main (`49314f81`, `059bad3c`, `17623c04`), read in place from `$TMPDIR/rig-check/<sha>.profile/`. Copies and hashes are in `nightly/` and `nightly-inputs.sha256`.
- `[i110]` means inherited from the finding and was not re-measured here.
- `UNMEASURED` means no run in this pass supports the value. Every such value names its fallback.

## Game vision alignment

The pillars were scored in the parent design's feature-validation style against `stapledons-design/vision/core-pillars.md`. The pillar names are taken from the parent's table (V34 there), because the design repo is not checked out on this host (`../stapledons-design` is absent). The `game-vision-designer` skill was not re-run; the scores follow the parent's own reasoning for the same tooling.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | The only clock is the test harness's. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals. Physics gates 2 and 3 are untouched. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics change. Every physics check still runs every night. |
| **Net** | | **0** | **Go, aligned with no conflict.** This is suite tooling, so every pillar is neutral. **All seven pillars score 0. None scores below 0**, and all are stated here as the rule asks. D-88 holds that test and audit hygiene does not stop at a net of 0. **The doc stops for Mark anyway** under D-173's default. |

## Problem

### 1. The rule counts the run's own work as noise

AC9 marks a run "comparable" from the host's 1-minute load average, sampled every 30 s into `load.tsv`. The strict rule needs every sample ≤ 5. The fallback needs a median ≤ 5 and no sample > 8. That load counts every runnable thread on the host, the suite's own included.

- `[i110]` All three profiled nightlies read `loaded` under both rules: medians 3.51–3.97, maxima 10.35–13.27.
- `[i111]` `gmake worlds-leak` was run alone through the real instrument on the quiet rig (1-minute load 2.50 at the start; 379.2 s; rc 0). The parent's `report` read **median 7.010, max 7.380: `loaded` under both rules** (`wl-old-rule-report.txt`, V3).
- `[i111]` In the same run, a whole-host `ps` sampler took a reading every 5 s. The run's own process tree used **4.6–4.9 cores** in each steady 30-s window. Its observed CPU summed to 1,752.9 s, against the exact 1,768.8 s that the recipe wrapper's `times` recorded (99.1 %). The rest of the host stayed at **1.8–3.8 cores** (`wl.analyse2.tsv`, V4). Removing the run's own share therefore turns this run from `loaded` into a quiet one (§A).

### 2. A red main refuses every run

`report` refuses any header with `rc≠0`. `[i111]` This pass ran the current `report --load-rule fallback` (tools at `e20175b5`) on a scratch copy of the unmodified `17623c04` nightly, whose header says `rc=2`. It printed `suite-profile: failed run n17623c04.tsv` and exited 1 (`rc2-refusal.txt`, V23). Main's `make test` has been red since 2026-11-13 and 2026-11-17 (`[i110]`).

`[i111]` The nightly already runs `-k`: `rig_check.sh` line 113 passes `-- $trace -k test` to `suite_profile.sh run` (V26, verbatim; the make-3.81 profile fallback on line 122 passes the same). Each profile names its own red targets, and the names agree exactly with the rig log (`nightly-failing-sets.txt`, V5):

| main | header `rc` | MAKELEVEL-1 recipe lines with rc ≠ 0 | rows with rc ≠ 0 at MAKELEVEL 2 | `gmake: *** [...]` lines in the rig log |
|---|---|---|---|---|
| `49314f81` | 2 | `basis-gate`, `ui-theme-check` | `script-gate-drill` (under `sim-bridge`) | `basis-gate`, `ui-theme-check` |
| `059bad3c` | 2 | the same | the same | the same |
| `17623c04` | 2 | the same | the same | the same |

The MAKELEVEL-2 row is a drill that fails on purpose inside a passing recipe. It is not a red target, so only MAKELEVEL-1 rows can name the failing set. No recipe line in `Makefile` or `mk/*.mk` starts with `-`, and there is no `.IGNORE` (V6). A non-zero MAKELEVEL-1 line therefore is a make error. The two red targets take 0.4 s and 0.2 s (`17623c04`), and the only target they hold back under `-k` is `test` itself (`Target 'test' not remade because of errors`, V5).

### 3. The 1-minute load is a sampled run queue, not CPU

- **It agrees with CPU in steady state.** `[i111]` In the 8 steady windows of the worlds-leak run, `load1` minus the 60-s-damped host CPU (from the kernel's tick counters, via `iostat`) was −0.14 to +0.32 cores, with a mean of +0.10 (V4, `wl` columns `load1` and `ewma_host` of `analyse.sh`).
- **It jumps on short bursts.** `[i111]` At 18:09:41 CET a 5-s interval showed `us 16 sy 20`, which is 5.8 of 16 cores busy. In that single 5-s update, `load1` went from **5.45 to 11.50** (`runs/r-esc-pg/host.tsv`, last row; `uptimes.txt`). Jumping by 6 in one update at XNU's 5-s decay of e^(−5/60) takes about 80 runnable threads at the sampling instant. That is a burst of threads, not 80 cores of work. Its source is not attributed: the process came from outside this pass's runs.
- **It carries the previous minute.** `[i111]` Every fixture in this pass began with `load1` at 5.8–11.5, the tail of the run before it, while host CPU was back at 2.2–3.0 cores (`uptimes.txt` against the first `host` value in each `*.analyse2.tsv`). A run that starts right after a busy target inherits that target's load for about a minute.

### 4. What the amendment must keep

- The thresholds: strict max ≤ 5; fallback median ≤ 5 and max ≤ 8.
- The baseline as the median of ≥ 3 comparable serial gmake runs.
- An explicit, common rule across both sides, with no implicit fallback.
- At most two repeats per slot, and the exhaustion rule (fewer than 3 comparable `-j6` runs means no landing, and the case goes to Mark).
- CPU-seconds as the second measure.
- The refusals of non-4.4.1 runs, closure mismatches and bad jobs counts.

The quorum's round-2 concern was that rig noise must not pose as a `-j` effect. That concern is what the amendment has to keep honouring (parent, Quorum log).

## Goals and non-goals

**Goals.**
- A run is comparable when the **CPU used by processes outside the run** stays under the same thresholds, measured on the same 1-minute time scale as the load average.
- The estimate errs toward "loaded" **in every window**, not only in total. The run is credited only with CPU it provably used in that window (§E). Anything else, including run CPU whose timing is unknown, counts as outside load. The credit can never exceed the run's actual CPU (§E, the proof).
- A red run counts only if it ran with `-k`, names its failing targets in its own record, and every run in the report names the identical set.
- Hermetic fixture cases and mutation drills cover each new rule. A short real-rig drill set shows that the rule reads a self-loading target as quiet and injected outside load as loaded.
- **Two baseline paths, co-primary until the overnight data decides (OQ2).**
  1. The nightlies cost no extra rig hours. From the night after A1a lands, every nightly `rig/full` writes the new samples.
  2. Controller runs in a quiet window the controller picks by hand cost rig hours but avoid the night windows where §I suspects outside CPU.

  V21, the overnight host sampler, was read in iteration 113 (§I). Outside CPU stayed at or below 4.13 cores in both night windows, so the switch to controller runs did not trigger. Under §I's rule as written the two paths stay co-primary, by a margin of 0.03 cores on one row, and the nightlies are the expected source.

**Non-goals.**
- The thresholds, the median-of-three, the repeat rule and the 0.5/0.35 ratios do not change.
- No test is removed. 7as and 7at are not fixed here (they stay attended).
- No change to `Makefile`, `mk/*.mk`, `rig_check.sh`, `rig_nightly.sh` or CI.
- No Linux support for the new sampler. The rig is macOS, and on a host without `iostat` the report refuses instead of guessing.

## Design

### A. What "load from outside the run" means

The sampler takes a snapshot about every 5 s. **Interval** *k* runs from one snapshot to the next. A **window** *w* is 6 consecutive intervals, about 30 s, aligned to the snapshots rather than to the clock. For each window:

> **x(w) = H(w) − R(w)**, in cores.

- **H(w)** is the host's busy CPU in cores: `(us + sy) / 100 × ncpu`, weighted by the time each interval covers. In A1a the 5-s `iostat` interval is the sampler's own sleep, so each H value covers the same interval as the `ps` differences (§F). The numbers are the kernel's CPU tick counters, so they include every process, short-lived ones too.
- **R(w)** is a **verified lower bound** on the run's own CPU in cores. It is what the sampler saw (§D) plus the part of the unseen CPU that provably fell inside *w* (§E), divided by the window's length.

The series the classifier reads is the **external load E**, a damped average on the 1-minute load's time scale:

> E(0) = x(0); E(w) = E(w−1)·e^(−30/60) + x(w)·(1 − e^(−30/60)).

E starts at the run's own first window. Unlike `load1`, it does not carry the previous target's tail (Problem 3).

**What the thresholds compare against.** The rule keeps the same constants. The strict rule needs max E ≤ 5. The fallback needs median E ≤ 5 and max E ≤ 8. Before, 5 meant "the whole host's 1-minute run queue". Now it means "five cores' worth of work that is not this run, damped like a 1-minute load".

On the quiet rig in this pass, between 17:49 and 18:17 CET, that outside level was about 2.1–2.6 cores. In the idle control, host CPU per window was 2.08–3.23 and E was 2.37–3.23 (`idle.analyse.tsv`, V2). Under revision 1's rule, the worlds-leak run read an E median of 2.40 and a max of 2.73 (`wl.analyse3.tsv`, V24). V21 sampled the night of 23–24 November (§I, iteration 113). With no test running, host CPU had a median of 2.08 cores and E a maximum of 6.64. Inside the two nightly runs E (estimated) reached at most 4.13.

### B. The candidates, measured

| # | Candidate | Reading in this pass | Verdict |
|---|---|---|---|
| (i) | `load1` minus the run tree's summed `pcpu` | Not run. It subtracts two different units: `load1` is a damped count of runnable threads (Problem 3), while macOS `pcpu` is a decaying CPU average with its own undocumented constant. It also misses every child that exits between samples. | Rejected on units. |
| (ii) | Host CPU minus the run tree's CPU, where the tree's CPU is only the `ps` cumulative-`time` differences between 5-s snapshots | Adversarial fixture `own` (6 burners of 20 s plus **480 burners of 0.25 s**, all inside the run; exact own CPU 232.9 s). The sampler saw only **91.2 s** of it. E read **5.06, 5.14** (raw 5.06, 5.27), so a run with no outside load would breach the strict rule (`r-own2.analyse2.tsv`, `fx-own.analyse.tsv`, V7). | Rejected. Short-lived children make it read "loaded" falsely. |
| (ii′) | As (ii), but with `ps -S` to fold reaped children into their parent | On macOS 26.6.2, `ps -S -o time=` of a shell whose child had just burned 1.0 s read `0:00.00`, while the shell's `times` read `0m1.001s` (`macos-ps-semantics.txt`, V8). | Not available on this host. |
| (iii) | **Revision 0's hybrid, even spread.** Host CPU minus (the tree's observed CPU plus, for each recipe line, the exact CPU from the wrapper's `times` that `ps` did not see, spread evenly over the line). | Fixture: E read 2.91, 2.82 (V7). **Unsafe per window** (codex, round 1). It can subtract CPU from a window where the run used none. On codex's two-window case it reads **E = 4.96, 4.96, comparable under both rules**, where the true outside load is 8.96 and then 0.96 (`synthetic/cx-spanning.analyse3.tsv`, V25). It also double-counts when attribution fails: with no wrapper pid it read worlds-leak at **E = −2.79 to −1.59** (V24, column `E_even`). | Rejected in revision 1. |
| **(iii′)** | **Revision 1, a lower bound.** Host CPU minus (the tree's observed CPU plus, per line, only the unseen CPU that the other intervals of the line's span could not have held, §E). | Fixture `own`: E **4.06, 4.17**, comparable under both rules; 55.0 s of the 141.6 s unseen was credited. Codex's case: E **8.96, 8.96**, loaded under both rules. worlds-leak: median 2.40, max 2.73. Godot target: max 2.06 (V24, V25). | **Chosen.** |
| (iv) | Direct sum: the CPU differences of every process *not* in the tree | Idle control: visible 0.64–2.04 cores against host 2.08–3.23. About 0.5 cores of host CPU belong to processes too short for `ps` to see (V2). It undercounts outside work, which is the unsafe direction. | Rejected. Not used even as a diagnostic. |

### C. Units, and why CPU instead of load

The rule works in CPU cores on both sides of the subtraction. H comes from tick counters, and R comes from cumulative user+sys seconds (`ps -o time`, 10 ms resolution, and the wrapper's `times`). The damping then puts x on `load1`'s time scale.

The evidence that the two scales match on this host is in Problem 3: in steady state `load1` minus damped H averaged +0.10 cores over 8 windows (V4). `load1` stays in `load.tsv` and is still printed, but it no longer decides anything.

**What the rule gives up.** Bursts of runnable threads that use little CPU (Problem 3) no longer count. A run slowed only by run-queue contention, without CPU use from outside, would read comparable. Risk R4 covers this.

**Saturation.** H cannot exceed `ncpu`. When the host is saturated, outside work gets less CPU than it asked for, so E under-reads it. The report prints `saturated_windows`, the number of windows with H ≥ 0.95 × ncpu (15.2 cores here), but does not gate on it. A `-j8` run may saturate the host on its own, and that is a real `-j` effect, not noise. This pass measured no saturated window; the highest H was 13.04 in `r-both`.

### D. Which processes belong to the run

The **root** is the `suite_profile.sh run` shell (`$$`). It is the parent of make and of both samplers. At each 5-s snapshot, `ps -A -o pid=,ppid=,pgid=,lstart=,time=` is read. A process **belongs to the run** if any of these holds. Membership decides only what counts as **observed** run CPU. It never adds to the unseen credit (§E).
1. it is the root, or its parent belongs to the run (repeated until nothing changes);
2. **sticky:** it belonged at an earlier snapshot, and its identity, **pid + `lstart`**, is unchanged. A child reparented to launchd (ppid 1) stays in the run;
3. **group:** its `pgid` is the root's pid. This applies only when the root leads its own process group. On the nightly path it does (V26): `rig_check.sh` line 113 runs `bounded "$TEST_S" sh tools/suite_profile.sh run …`, and `bounded`'s child calls `setpgrp(0, 0)` and then `exec`s, so the `suite_profile.sh` shell is the group leader (pgid = its pid). A probe of the same `perl` pattern read `pid=54004 pgid=54004`, against a control without `setpgrp` that read `pid=54103 pgid=54094` (`bounded-pgid-probe.txt`). Otherwise `tree_group=-` is recorded, only rules 1 and 2 apply, and group-only orphans fall to E, the safe direction. AC13 asserts `tree_group == tree_root` on the first nightly rather than assuming it.

Measured cases:
- **`nohup` escape, same group:** `escape-pg` backgrounds a 40-s burner with `nohup`, and its recipe line exits after 1 s. The group rule kept it. The tree's observed CPU was **35.9 s**, and E read 1.93, 2.21 (`r-esc-pg.analyse2.tsv`, V9). Under revision 1 it read 1.78, 1.88 (`r-esc-pg.analyse3.tsv`).
- **Full escape:** `escape-sid` double-forks with `setsid`, leaving the tree, the group and the session. The burner (pid 99763, ppid 1, pgid 99762) used 36.0 s and was **not** counted as the run's. It went to E, which is the safe direction (`runs/r-esc-sid/procs.raw.gz`, `r-esc-sid.analyse2.tsv`, V10). Nothing in the suite is known to escape this way. If something does, its run reads more loaded, never less.
- **AILANG workers:** worlds-leak's four `ailang` workers stayed inside the tree in every window (10 members per window; 99.1 % of the exact CPU observed, V4). None was reparented.
- **Godot and its sim child:** `title-screen-test` (headless, `-o import`, 24.2 s, rc 0) used 22.6 s of exact CPU. `ps` saw 14.4 s, and the remaining **8.2 s** came from children too short to sample. E read ≤ 2.09 with 10-s windows (`r-godot.analyse2-w10.tsv`, V11). Under revision 1, which credits none of the 8.1 s unseen because the line spans every window, it read ≤ 2.06 (`r-godot.analyse3-w2.tsv`, V24). The run was too short for the 30-s windows.
- **pid reuse is real:** pids wrapped within minutes in this pass. The escaped burner was pid 99763 at 18:09, and the wrapper of the 18:12 run was pid 4262 (`runs/r-godot/prof/profile.tsv`, column 8). Identity is therefore pid + `lstart`, never pid alone.
- **`pcpu` is not read.** Only the cumulative `time` field is used, so the decaying average does not enter the rule.

### E. Children that start and exit between snapshots

The recipe wrapper already records each recipe line's exact children's CPU (`times`, line 2) in `profile.tsv` column 3. That figure covers every process the line reaped, however short. The amendment adds the wrapper's own pid as **column 8**, so that processes seen by `ps` can be matched to their line.

**Notation.** For interval *k*, with length Δt_k:
- O_k is the CPU the sampler saw for run members (§D): the sum of `ps` `time` differences, counting a process from zero when it is born after the previous snapshot.
- H_k is the host's busy cores.

For each MAKELEVEL-1 line *L*:
- **obs(L)** is the observed CPU of members whose `ppid` chain, read **in the same snapshot**, reaches *L*'s wrapper pid while that row's span holds the sighting.
- **U(L)** is the observed CPU of members attributed to **no** line, in every interval that touches *L*'s span. These include make, the samplers, the wrapper shells themselves, group-only members and chains that broke.
- **rem(L) = max(0, cpu(L) − obs(L) − U(L))** is the line's CPU that was never observed.

**The lower bound (revision 1, replacing the even spread).**
- **Spare room in an interval** is what the host could have run beyond the observed run CPU: spare_k = max(0, (H_k + s)·Δt_k − O_k). The slack s = 0.02 × ncpu (0.32 cores here) covers `iostat`'s whole-percent rounding of `us` and `sy`. A larger spare only lowers the bound, so the slack errs safe.
- **The most of *L*'s unseen CPU that interval *k* could hold** is cap_L(k) = min(spare_k, ncpu × |span(L) ∩ k|).
- **The credit to window *w*:** lb_L(w) = min(cap_L(w), max(0, rem(L) − Σ_{k ∈ span(L), k ∉ w} cap_L(k))). That is, *L*'s unseen CPU minus the most the rest of its span could have held.
- **The window total** is LB(w) = min(Σ_L lb_L(w), Σ_{k∈w} spare_k), and **R(w) = (Σ_{k∈w} O_k + LB(w)) / Δt_w**.

Any unseen CPU whose window the data cannot pin down stays in E. Three consequences:
- A line that sits inside one window is credited in full.
- A long line whose unseen CPU could have been anywhere is credited nothing, so it falls back to the `ps`-only reading of candidate (ii). That direction is safe.
- Codex's counterexample reads loaded. Its line spans both windows, each window could hold all 240 core-s, so lb = 0 in both and E = 8.96 in both (`synthetic/cx-spanning.analyse3.tsv`). When the same 240 core-s line sits inside window 2, it is credited in full: E is 8.96, then 5.81 damped, which is raw 0.96, the truth (`synthetic/cx-inside.analyse3.tsv`, V25).

**Why R(w) never exceeds the run's actual CPU in w** (gemini, round 1). Say a process is **reaped through *L*** when its CPU ends in the wrapper's `times`: its parent waits for it, and so on up to the wrapper.
1. **Every reaped-through-*L* process that was seen falls in obs(L) or in U(L), never in another line's obs.** All its ancestors up to the wrapper are alive while it is alive. A parent that exits first leaves it reparented, so it would not be reaped through *L*. At any snapshot that shows it, its ancestors are therefore members of that same snapshot, and the chain read in that snapshot ends at *L*'s wrapper. If the chain breaks anyway, for example because a non-atomic `ps` listing omits a parent, the process is attributed to no line and its CPU lands in U(L). It lands there because it ran inside *L*'s span. A different line's wrapper cannot be its ancestor, since identity is pid + `lstart`.
2. **So rem(L) ≤ unseen(L).** cpu(L) is the CPU of the processes reaped through *L*, minus nothing. obs(L) + U(L) is at least their observed part, so rem(L) ≤ their unobserved part. U(L) may also hold CPU that is not *L*'s, such as make or a daemon. That only lowers rem(L), the safe direction.
2.5. **The global interval inequality** (gemini, round 2, its fix (2) applied verbatim in substance). In every interval *k*, H_k·Δt_k ≥ O_k + Σ_L unseen_L(k), whichever line produced O_k: the host's busy CPU covers all observed run CPU and all unobserved run CPU in *k* (plus any outside CPU), and the two run parts are disjoint. Hence, for every line *L*, unseen_L(k) ≤ H_k·Δt_k − O_k ≤ spare_k (the slack s only widens spare_k), and unseen_L(k) ≤ ncpu·|span(L) ∩ k|, so unseen_L(k) ≤ cap_L(k). This holds at a boundary interval too, where O_k includes CPU of another line L′ that ran in the part of *k* outside span(L): that CPU is observed, so it is in O_k and not in unseen_L(k). Across concurrent lines (M2's `-j6`) the shared constraint Σ_L unseen_L(k) ≤ spare_k is not needed for step 4, because each lb_L(w) is bounded by its own unseen_L(w); the window cap LB(w) ≤ Σ_{k∈w} spare_k is an extra guard, not a premise. One assumption remains: `iostat` and `ps` cover the same interval *k*. A1a takes both on one 5-s clock (`iostat -c 2 -w 5` as the sampler's sleep); that alignment is UNMEASURED. A misaligned H_k shifts spare_k by the CPU that crossed the interval edge, in either direction: over-stating it is safe, under-stating it is not (judge N5). Two smaller unsafe-direction errors remain and are bounded in A1a's requirements below: `iostat`'s whole-percent rounding of H (at most about 0.16 cores per window on 16 cores) and whole-second timestamps.
3. **So lb_L(w) ≤ unseen_L(w).** unseen_L(k) ≤ cap_L(k) in every interval (step 2.5). The host ran it, beyond what was observed, inside *L*'s span. So unseen_L(w) = unseen(L) − Σ_{k∉w} unseen_L(k) ≥ rem(L) − Σ_{k∉w} cap_L(k).
4. **Lower bounds add.** Σ_L lb_L(w) ≤ Σ_L unseen_L(w), and observed CPU is counted once, in O. Hence R(w)·Δt_w ≤ observed run CPU in w + unseen run CPU in w = the run's actual CPU in w.

Gemini's scenario, where an intermediate child exits before its first snapshot and its grandchild is reparented to launchd and admitted only by the group rule, adds to O and to U(L). The grandchild is not reaped through *L*, so it is not in cpu(L), and it lowers rem(L) instead of being counted twice. The hermetic case `ext-no-double-count` uses the harder variant. Its process **is** reaped through *L*, but its parent is missing from every snapshot. Revision 0 read E = 0.35 against a true 2.01; revision 1 reads 2.01 (`synthetic/no-double-count.analyse3.tsv`, V25).

**Measured effect on real targets (re-analysis of revision 0's raw samples, no new rig run; V24):**

| Run | Line CPU (exact) | Unseen, rev 1 rem | Credited by the bound | E, `ps` only | E, rev 0 even spread | **E, rev 1 bound** | Verdict, rev 1 (strict / fallback) |
|---|---:|---:|---:|---|---|---|---|
| Adversarial `own` (AC4) | 232.9 s | 141.6 s | 55.0 s | 4.79, 5.14 | 2.59, 2.54 | **4.06, 4.17** | comparable / comparable |
| worlds-leak (AC9) | 1,768.8 s | 15.8 s | 0.0 s | med 2.40, max 2.73 | (−2.79 to −1.59, attribution absent) | **med 2.40, max 2.73** | comparable / comparable |
| `title-screen-test` (AC10, 10-s windows) | 22.6 s | 8.1 s | 0.0 s | max 2.06 | max 1.73 | **max 2.06** | comparable / comparable |
| `ext`, 6 burners outside (AC5) | 0 | 0 | 0 | 7.63, 7.75 | same | **7.63, 7.75** | loaded / loaded |
| `both` (AC6) | 240.1 s | 145.3 s | 25.1 s | 10.02, 10.55 | 7.79, 7.89 | **9.21, 9.98** | loaded / loaded |

The adversarial fixture still passes, with a margin of 0.83 under the strict max. Its unseen CPU is dense enough that the spare room in the rest of each line's span cannot hold all of it, so 55 s of it is pinned to particular windows. It sits much closer to the line than under revision 0 (4.17 against 2.82). A recipe that is mostly unseen CPU on a host with more background would read loaded, which is the safe direction. The real targets measured (worlds-leak, the Godot title test) barely need the credit, because `ps` sees 99.1 % and 64 % of their CPU. The full suite's unseen share by target is UNMEASURED until a nightly writes `cpu.tsv` (A1a). Risk R9 covers the `-j6` after side, where six lanes of unseen CPU could push E up.

**Alignment.** The prototype matched each `ps` interval to the nearest streaming `iostat` line, at most 2.6 s apart. A1a removes that offset: the sampler runs `ps`, then `iostat -n 0 -c 2 -w 5`, whose second line is the CPU over the next 5 s, and that call is also the sampler's sleep. Each H value then covers the same interval as O, apart from the few milliseconds the `ps` call takes. This alignment is UNMEASURED. If A1a's cadence check shows gaps over 0.5 s, the report widens the slack by the gap's share.

Two limits remain:
- **Daemons** that the chain never reaps are in no row. They count while `ps` sees them, as members by rules 2 and 3 of §D, and their observed CPU also lowers rem(L) through U(L). Anything missed goes to E, the safe direction.
- **Nested sub-make rows** are not used for the remainder. A nested line's CPU is already inside its MAKELEVEL-1 parent's `times`, the same rule `summary` uses. A nested row's narrower span could tighten the bound later; that is not done here.

### F. What `run` writes

- **`profile.tsv`** gains column 8, the wrapper's pid. `summary`, `targets`, `compare` and `agree` read columns 1–7 and are unchanged. `report` accepts only 8-column rows (§G).
- **`cpu.tsv`** is new, written beside `load.tsv` by a second sampler subshell. It is started and killed exactly like the load sampler: the same traps, with its pid recorded as `cpu_sampler_pid`. It has three kinds of row, tab-separated:
  - `H <epoch_start> <epoch_end> <us+sy>`: the second line of the `iostat -n 0 -c 2 -w 5` call that follows each snapshot and serves as the sampler's sleep (§E, Alignment).
  - `N <epoch> <pid> <ppid> <pgid> <lstart>`: the first sighting of a member, with `lstart` spaces turned into `_`.
  - `C <epoch> <pid> <ppid> <lstart> <cpu_s>`: each member at each snapshot. It carries that snapshot's `ppid`, so the attribution chain is read within one snapshot (§E).

  Membership (§D) is worked out in the sampler's `awk` from the previous snapshot's member file, so the file holds only the run's own processes. **Size:** worlds-leak had 10 members per snapshot, so a 6,200-s nightly holds about 1,240 × 10 `C` rows, roughly 0.5 MB. That is an extrapolation; the real size is UNMEASURED, and if it passes 2 MB the committed copy is gzipped. **Cost:** one `ps -A` snapshot cost 12 ms of CPU (10 snapshots: 0.12 s user+sys; 829 processes; V12), or 0.24 % of one core at 5-s cadence. The full sampler, `ps` plus `awk` plus `iostat`, is UNMEASURED; the fallback is a 10-s cadence.
- **`header.txt`** gains:
  - `cpu_sampler_interval=5`
  - `cpu_sampler_pid=…`
  - `tree_root=<pid>`
  - `tree_group=<pid|->`
  - `make_args=<the arguments after -->`, with newlines removed

  `cores` already records `ncpu`.

### G. The classifier in `report`

`report [--load-rule strict|fallback] [--stage M2|M3]`. The options, the slot and attempt rules and the medians are as before. For each run:
1. **It refuses (rc 1):**
   - a missing `cpu.tsv`, with the message `no external-load samples`;
   - any `profile.tsv` row that is not 8 columns (`no wrapper pid`);
   - a run where fewer than 90 % of its intervals have an `H` row (`sparse cpu samples`). An interval without one gets no spare room and no credit, so the gap is not read as an idle host.

   The existing refusals stay: make version, closure, jobs, attempt, slot, and a missing `load.tsv`.
2. **It computes** x(w) and E(w) as in §A to §E.
3. **It decides:** strict means `comparable` iff max E ≤ 5. Fallback means `comparable` iff median E ≤ 5 and max E ≤ 8. The rule name is printed in the first line, as now.
4. **It prints** one line per run, in this order:

   ```
   <file> make=… jobs=… span=… cpu=… ext_median=… ext_max=… own_cpu=… observed=… unseen=… credited=… saturated_windows=… load_median=… load_max=… failing=<set|-> <comparable|loaded> attempt=…
   ```

   `load_*` are kept only as context.

Everything after these steps is unchanged: the baseline median, the `-j6` median, the ratio and the exhaustion rule.

### H. The keep-going rule

The **failing set** F(run) is the sorted set of column 6 over `profile.tsv` rows with column 5 = 1 and column 4 ≠ 0. It comes from the run's own record, written by the wrapper. `report` never reads the rig log for this. On the three nightlies the set agrees with the log (Problem 2).

| Header `rc` | F | `make_args` has `-k` (a short-flag cluster containing `k`) or `--keep-going` | Result |
|---|---|---|---|
| 0 | ∅ | any | the run may count (green) |
| 0 | ≠ ∅ | any | **refuse** `rc 0 with failing rows` (a `-` recipe line or a wrapper fault) |
| 2 | ≠ ∅ | yes | the run may count (**red, keep-going**) |
| 2 | ≠ ∅ | no | **refuse** `red run without keep-going` |
| 2 | ∅ | any | **refuse** `failed run with no named target` (for example a make-level "No rule to make target") |
| anything else (124 watchdog, 130, 143, 1, …) | any | any | **refuse** `failed run` |

Two more conditions apply across the report:
- **One failing set per report.** Every run on the before side and the after side must have the identical F. Otherwise the report refuses with `failing targets differ: <file> {…} vs {…}`, in the same way it refuses a closure mismatch. If 7as or 7at is fixed partway through, the runs taken before the fix do not combine with those taken after it, and the baseline is re-collected (OQ4).
- **The same work.** A red run counts only if `compare` against the report's first before-run reads `missing=0 fewer=0`. Under `-k`, a red target holds back its dependents, so this proves both sides skipped the same work.

The first output line then prints `failing=<F>`. A committed report thereby says which red targets its ratio excludes. That ratio compares the same closure minus the same red work. It is not a claim about a green suite's speed.

### I. The three nightly profiles, and the first new baseline

**They cannot be re-classified on load grounds.** They have no `cpu.tsv` and 7-column rows (all 766 rows in `17623c04` have 7 columns, V13), so the new `report` refuses them with `no external-load samples`. Their failing sets would pass §H: each is `{basis-gate, ui-theme-check}`, with closure `47d40348…` on all three.

**A retrospective estimate (not a classification).** I took `load1` minus damped own CPU, where own CPU is each line's exact CPU spread evenly over the line. This mixes units, and §C says why the rule does not do it. With that caveat (`nightly-retro.txt`, V14):

| main | `load1` samples > 5 / > 8 | estimate median | estimate max | estimate samples > 5 / > 8 |
|---|---|---:|---:|---|
| `49314f81` | 53 / 8 | 2.50 | 9.13 | 14 / 2 |
| `059bad3c` | 60 / 13 | 2.52 | 12.34 | 24 / 4 |
| `17623c04` | 41 / 6 | 1.98 | 10.71 | 10 / 2 |

Removing the run's own CPU removes most of the samples over 8 (8 to 2, 13 to 4, 6 to 2), and every median would pass. **A few spikes per night remain.** They fall in targets that use about 1 core of their own, at 22:3x to 23:4x and at 05:3x to 06:2x CET: `sound-test`, `strict`, `free-nav-stop-test`, `title-screen-test`, `playable-voyage-test` and the `ship-demo-*` block (`nightly-retro-over5.txt`). **The V11 inference (oc-glm-5-3, round 1).**
- Alone on the quiet rig, `title-screen-test` held `load1` at 2.97–3.13, so it moved it by less than 0.2. It used 0.93 cores of its own (22.6 s in 24.2 s) and set off no thread burst (V11).
- In `17623c04` the same target sits in the window where `load1` read 11.74 at 23:46:07 CET, with damped own CPU 1.03 (`nightly-retro-over5.txt`).
- So that spike is not plausibly `title-screen-test`'s own threads. It is more plausibly outside CPU, which E counts and which would keep max E above 8, or outside thread bursts, which E ignores.
- The same holds less firmly for the other spike-bearing targets, none of which was run alone in this pass.

**The working assumption, written in iteration 111, was that the night windows may carry outside CPU, so the first instrumented nights might read `loaded` under both rules.** V21, read below in iteration 113, tested that assumption on one night and did not find it: the late-night `load1` spikes were bursts of threads, not CPU from outside the run. The OQ1 approval package still asks Mark to decide OQ3 now, because one night is one sample.

**V21, the overnight control: READ (iteration 113).**

**What it means for Mark's choice (OQ2, OQ3).** On the night of 23–24 November, CPU from outside the test run stayed low in both night windows. "Outside CPU" means CPU used by everything on the machine that is not the test run, in cores, smoothed over a minute like the load average. It peaked at **4.13** cores in the late-evening window and **2.87** in the early-morning window, against the rule's limits of 5 (strict) and 8 (fallback). So the rule that would make quiet-window controller runs primary **did not trigger**. One night is evidence that the nightlies can supply the baseline at no extra rig time. Applied to the letter, though, §I's rule gives **co-primary**, not "nightlies primary": in one of the 15 `load1` jumps the unsmoothed outside CPU of that single 30-s row read **5.03** cores against the limit of 5 (smoothed, it was 3.24; the thread-burst test uses the unsmoothed value). That row is most likely an artefact of the estimate (below). The old rule, run on the same two runs, reads `loaded` on both: 9 and 12 samples over 8. That is the self-loading and the thread bursts this amendment removes.

- **What was sampled.** The controller's host sampler (pid 31503, `/tmp/i111-overnight-tools/host_sampler.sh`, sha256 `af550012…5322b57`, unchanged) wrote one `iostat -n 0 -c 2 -w 30` row every 30 s from 18:28:04 to 07:27:24 CET (2026-11-23T17:28:04Z to 2026-11-24T06:27:24Z). That is 1,552 rows plus the header. The rows are 30 s apart (1,321 rows) or 31 s apart (230), so there are no gaps. The 13-h `alarm` stopped it; pid 31503 is gone. Times are CET = UTC+1, converted with `TZ=Europe/Berlin date -r`. As a check, `d8b7baf9`'s `end_ms` converts to 00:13:51 CET, which matches the mtime of its rig log (00:13:51) and the rig-nightly log's `FAILED` line (00:13:56).
- **Two nightly `rig/full` runs fell inside it, not one.** The record expected one. The launchd fires that started them are in `~/Library/Logs/stapledon-rig-nightly.log`:
  - **`d8b7baf9`** ran 22:30:26 to 00:13:51 CET. Its golden half ran 00:31:44 to 00:34:41.
  - **`328b01f8`** ran 04:15:32 to 06:07:12 CET. Its golden half ran 06:16:46 to 06:19:43.

  Both runs are red: header `rc=2`. Both have the closure `47d40348…`, the same as the three older nightlies. Both name the failing set `{basis-gate, ui-theme-check}`, from their own `profile.tsv` (MAKELEVEL 1, rc ≠ 0) and from the rig log's `gmake: *** [` lines. §H's keep-going rule would therefore admit both, with one failing set. Each run covers one window. `d8b7baf9` covers the whole of the 22:30–00:15 window except its last 2 min. `328b01f8` covers 05:00–06:07 of the 05:00–06:30 window. The 06:07–06:30 part had no test run and is reported separately below.
- **The method, as §I states it, with the estimate's known weakness.** H = (`us` + `sy`)/100 × 16 is the host's busy CPU in cores. **own** is each MAKELEVEL-1 line's exact CPU (`profile.tsv` column 3, from the wrapper's `times`; see `tools/timed_recipe_shell.sh`), spread evenly over the line's span. x = H − own, and E is x damped by e^(−0.5) per row. A **thread burst** is a row where `load1` rose by ≥ 3 since the previous row while x < 5.
  - The even spread is the unsafe estimate that §B rejects for classification. Where a line's CPU really came in bursts, it can make E read too low.
  - The table therefore also gives **E_H**, host CPU damped with no credit for the run at all. Since the run's own CPU is never negative, E_H is an upper bound on the true outside CPU, and on what §E's lower-bound rule would read.
- **The reading, per window and run** (`summary.txt`, `extra.txt`, V27 to V29):

| Rows (30 s each) | Rows | H median / max | own mean / max | **E median / max** | rows E > 5 / > 8 | E_H max (rows > 5 / > 8) | `load1` jumps ≥ 3: thread bursts / CPU-backed | old rule: V21 `load1` rows > 5 / > 8 |
|---|---:|---|---|---|---|---|---|---|
| `d8b7baf9`, 22:30–00:13 (all in the 22:30–00:15 window) | 206 | 2.88 / 8.48 | 1.53 / 4.67 | **1.79 / 4.13** | 0 / 0 | 7.17 (14 / 0) | 7 / 1 | 56 / 9 |
| `328b01f8`, 05:00–06:07 (in the 05:00–06:30 window) | 133 | 2.56 / 5.92 | 1.11 / 2.99 | **1.52 / 2.87** | 0 / 0 | 4.61 (0 / 0) | 3 / 0 | 15 / 2 |
| `328b01f8`, 04:15–05:00 (before the window) | 89 | 4.16 / 7.84 | 2.19 / 4.71 | **2.04 / 3.08** | 0 / 0 | 6.80 (15 / 0) | 4 / 0 | 53 / 8 |
| `328b01f8`, the whole run | 222 | 2.88 / 7.84 | 1.54 / 4.71 | **1.67 / 3.08** | 0 / 0 | 6.80 (15 / 0) | 7 / 0 | 68 / 10 |
| 06:07–06:30 (in the window, no test run; includes the golden half) | 46 | 2.24 / 4.32 | 0.01 / 0.36 | **2.26 / 3.28** | 0 / 0 | 3.28 (0 / 0) | 3 / 0 | 9 / 3 |
| Golden halves (00:31–00:35, 06:16–06:20) | 6 + 6 | 2.56 / 3.36; 3.12 / 4.00 | 0 | **2.42 / 2.52; 3.04 / 3.17** | 0 / 0 | the same | 0 / 0 | 0 / 0 |

  - **Controls.** The spread credits 9,443.2 of `d8b7baf9`'s 9,494.8 s of MAKELEVEL-1 CPU to its 206 rows, and 10,273.9 of `328b01f8`'s 10,336.0 s to its 222 rows. The rest falls in the 1-s gaps between `iostat` intervals and the runs' edge rows, so own reads slightly low, which is the safe direction.
  - **Where E_H passes 5.** Every row of E_H above 5, except one, falls during or within a minute after the run's heaviest targets. One is `worlds-leak`: 4.67 and 4.71 cores of its own, of which `ps` saw 99.1 % in V4, so §E's bound would credit it as observed CPU. The other is `sim`, at 2.26 cores of its own.
  - **The exception** is 23:55:38. That row read H 8.48 with `sy` 39 %, during `display-audit-comms` (1.10 cores of its own). It is the highest outside reading of the night: x 7.38, E 4.13, E_H 5.16.
- **The flip rule, applied** (the criteria as written in iteration 111):
  - **Controller-run quiet-window baselines become primary if damped outside CPU exceeds 8 in at least one row in each of the two windows (22:30–00:15 and 05:00–06:30 CET), or exceeds 5 in more than 10 % of the nightly run's rows.** Not met. E > 8 in 0 rows of either window (E_H > 8 in 0 rows too). E > 5 in 0 of 206 rows (`d8b7baf9`) and 0 of 222 rows (`328b01f8`).
  - **The nightlies stay primary if outside CPU stays ≤ 5 throughout and the `load1` spikes all classify as thread bursts.** Met by `328b01f8`: E max 3.08, and 7 of 7 jumps were bursts. Missed by `d8b7baf9` on one row: E max 4.13, but 1 of its 8 jumps had raw (undamped) x = **5.03** (damped E on that row 3.24; the burst test reads raw x, interpretation 3 below). That row is 23:14:56: `load1` +3.58, H 7.68, own 2.65, during `replay`, which used 299 s of CPU in 95 s. An even spread understates a bursty line's peak, so the row is more plausibly `replay`'s own burst than outside CPU (inferred).
  - **Anything in between stays co-primary.** That is the outcome for the night.
- **The old rule on the same runs.** The `load.tsv` samples over 5 / over 8 were **58 / 9** for `d8b7baf9` (207 samples; median 3.87, max 14.66) and **71 / 12** for `328b01f8` (224 samples; median 3.72, max 13.15). Both read `loaded` under both rules, like the V14 three. V14's mixed-unit estimate (`load1` minus damped own CPU, `retro.sh` unchanged) still leaves 3 and 4 samples over 8 (max 13.58, 12.30) (`oldrule-retro.txt`). The CPU measure shows why. The biggest `load1` spike of the night, 19.29 at 00:07:42 during `playthrough-negative`, came with H 3.36 cores: about 15 threads woke at once and used little CPU.
- **Idle control** (no test or golden half running and not within 2 min after one; 1,096 rows: 18:28–22:30, 00:15–04:15 and 06:21–07:27 CET). H median **2.08**, max **8.16**. E (= E_H, since own is 0) median **2.14**, max **6.64**. E > 5 in **7 rows (0.6 %)**, E > 8 in **0**. H > 5 in 12 rows. `load1` was over 5 in 134 rows and over 8 in 51, with no test running; 45 of its 47 jumps of ≥ 3 were thread bursts. The idle host spikes `load1` as often as the test runs do.
- **What the outside CPU was** (timing only; `attrib.txt`).
  - **Measured.** The idle peaks were at 03:30–03:32 (E up to 6.64, `sy` up to 25 %) and 06:39–06:41 (E up to 5.76). The AILANG nightly eval (launchd `dev.ailang.nightly-eval`) ran 03:00:00 to 05:39:05 CET, so it overlapped the first 84 min of `328b01f8`. That window part, 04:15–05:39, read E ≤ 3.08. The mission `iteration-fixture` logged from 06:40:07 to 06:51:12. A `mission-fleet` fire logged 23:53:00 to 23:53:56, 2 min before the 23:55:38 row. The other mission fires logged a few seconds each (control every 90 min; world at 00:15 and 04:15; triage at 04:34 and 04:54; stapledon at 01:29 and 02:10).
  - **Inferred, not measured.** The 03:30 peak was the eval, the 06:40 peak was the fixture, and the 23:55:38 row was the fleet fire or `display-audit-comms`'s own system time. No process was sampled, so none is attributed.
  - **The golden halves were quiet,** at E ≤ 3.17 (measured).
- **Interpretations of §I made in this reading.**
  - Each V21 row covers [`epoch_end` − 30 s, `epoch_end`]. A row belongs to a run if its midpoint lies in the run's span.
  - E runs continuously through the night, with own = 0 outside the runs. It is not reset at each run's start.
  - The thread-burst test uses the row's raw x, not E. A "`load1` spike" is a rise of ≥ 3 since the previous row.
  - Each window is judged on the run that covers it: `d8b7baf9` for the late-evening window, `328b01f8` for the early-morning one. The 10 % clause is judged per run, over all of its rows.
  - The golden halves and the 2 min after any half are kept out of the idle control.
  - Zero-length lines are credited to the row in which they start.
- **What this reading cannot say.** It is **one night** and a diagnosis, not a classification. Only the instrumented nightlies after A1a can classify. Thread bursts and short-lived processes inside a 30-s `iostat` row are averaged in, not resolved.

Evidence: `/tmp/i113-v21-evidence/` (hashed in its `SHA256SUMS`, sha256 `c2d305f16d304b48bcc31891271d5e52b0d3a0e804ebb4f84f9407594c84c24b`), published as `gs://stapledons-voyage-assets/benchmarks/v21-overnight-iter113/i113-v21-evidence-clean.tgz` (365,238 B, sha256 `740c9a1020bb83f914af701d163a66f016ff63bc7dd35580d174a949b969b3cc`). The two nightly profiles' `database.txt` files are deliberately left out (see the warning below), so `SHA256SUMS` no longer lists them; `closure.txt`, which `suite_profile.sh` derives from them, is kept.

**⚠ A profile directory is not safe to publish or commit as it stands (found in iteration 113).** `tools/suite_profile.sh` (line 52) writes `make -p` output to `<profile>/database.txt`, and `make -p` prints every environment variable. The nightly `rig/full` runs under the launchd job's full environment, so each nightly's `database.txt` holds the rig's credentials (15 non-empty secret-named variables in `328b01f8`'s). Iteration 113's first evidence pack included both files and was public for about 90 s before the controller deleted it; the incident went to Mark privately. Until `suite_profile.sh` stops writing environment-origin variables (a queue row), **copy only `profile.tsv`, `load.tsv`, `header.txt`, `closure.txt` and (after A1a) `cpu.tsv`** from any profile directory, into `rig-test-speed-data/` or into any evidence pack, and check the pack against the rig's secret values before publishing it.

**The first new baseline needs no rig change.** Once A1a is on main, `rig_check.sh` runs the new `suite_profile.sh run` from the clone's `tools/` (line 113), with `-k test`. Every nightly `rig/full` then writes `cpu.tsv` and 8-column rows into `$TMPDIR/rig-check/<sha>.profile/`, which outlives the clone (V15). Three nightlies with one closure hash and one failing set, each comparable, form the baseline. The controller copies their `profile.tsv`, `load.tsv`, `header.txt`, `closure.txt` and `cpu.tsv` (never `database.txt`, per the warning above) into `rig-test-speed-data/` within a day, because `$TMPDIR` is not permanent. The `--trace` run that AC3 needs is still one controller run (`RIG_TRACE=1 tools/rig_check.sh main`), and it counts if it is comparable.

### J. Replacement text for the parent

- **AC9, the "comparable" sentence**, becomes: "A run is **comparable** only if its external load E (this amendment §A to §G: host CPU from `iostat` minus a verified lower bound on the run's own CPU, damped with τ = 60 s) is ≤ 5.0 in every 30-s window (strict), or, if the Studio's normal background makes that unachievable, has median ≤ 5.0 and max ≤ 8 (fallback). `report` refuses a run with no `cpu.tsv`, with non-8-column rows, or with sparse CPU samples. A red run counts only under the keep-going rule (amendment §H), and every run in one report has the identical failing set." The rest of AC9 stands as written.
- **§1f, last paragraph** ("A run that fails the AC9 load rule is repeated under the same rule") gains: "From the night after the AC9 amendment lands, the nightly `rig/full` profiles on main are candidate baseline runs (amendment §I)."
- **The sprint's M1b resume predicate** becomes: "D-173 answered A, A1a and A1b landed, then ≥ 3 comparable serial gmake runs (nightly, or controller runs in a quiet window, per V21 and OQ2) with one closure and one failing set".

## Acceptance criteria

All commands run from the implementation root. In the table cells below, `\|` is Markdown's escape for a literal `|`; type `|` when running a command (judge N2). The drill block below is saved as `.godot/tmp/ac9-drills.sh`, an ignored path (parent V36). "This pass" readings come from the revision-1 prototype `/tmp/i111-design-evidence/scripts/analyse3.sh`, which uses the formulas of §A to §E, applied to the raw samples of revision 0's runs. Its windows are 6 snapshot intervals; revision 0's were 30 clock seconds, so the digits differ slightly from the `*.analyse2.tsv` files. The implementation must reproduce the verdicts, not the exact digits.

| # | Criterion | Command | Expected | Reading in this pass |
|---|---|---|---|---|
| AC1 | The instrument's control stays green on both makes | `sh tools/test_suite_profile.sh > .godot/tmp/sp.log 2>&1; echo rc=$?; tail -1 .godot/tmp/sp.log` | `rc=0`, `suite-profile control: 76 cases, 0 failures` (38 cases × 2 makes) | Base: `rc=0`, `suite-profile control: 40 cases, 0 failures`, 17 s (`control-baseline.log`, V1). After A1a/A1b: UNMEASURED. Fallback: no landing. |
| AC2 | Each new case is present and passes | `grep -c -E '^suite-profile control (ext-own-only\|ext-external\|ext-short-lived\|ext-two-window\|ext-no-double-count\|ext-pgid\|ext-escape\|ext-pid-reuse\|ext-sparse\|kg-same\|kg-differ\|kg-unnamed\|kg-rc0-rows\|kg-no-k\|kg-watchdog\|legacy-no-cpu\|level2-ignored\|cpu-sampler-cleanup): ok$' .godot/tmp/sp.log` | `18` | The case logic is UNMEASURED (new code). Its expected verdicts for `ext-short-lived`, `ext-two-window` and `ext-no-double-count` come from the prototype on identical synthetic data (AC17, AC18). The cases are hermetic: `ps` and `iostat` are PATH stubs, like the existing `sysctl` stub. Fallback: no landing. |
| AC3 | Every new guard kills its mutant | `for m in X V D G S K U E L W; do sh -c ". .godot/tmp/ac9-drills.sh; drill \"$PWD\" $m"; echo "$m rc=$?"; done` | `X: killed` … `W: killed`, each `rc=0` | UNMEASURED. The RED run on `origin/main` copies is recorded first. Fallback: no landing. |
| AC4 | **Own load alone reads quiet.** The adversarial fixture `own` has 480 children of 0.25 s inside the run. | `sh .godot/tmp/ac9-drills.sh rig own` (runs `suite_profile.sh run --make gmake -- -C .godot/tmp/ac9-fx own`, then `report --load-rule strict` and `--load-rule fallback` on it) | the run's line reads `comparable` under both rules, `ext_max ≤ 5`, `unseen > 100`, `credited > 0`; rc 1 (`preliminary`, one run) | Revision 1: E **4.06, 4.17** (median 4.12, max 4.17), comparable under both rules; unseen 141.6 s, credited 55.0 s (`r-own2.analyse3.tsv`, V24). `ps` only: 4.79, 5.14 (strict loaded). `load1` 7.29 → 6.90. Start load 6.65, the previous run's tail. **Margin 0.83 under the strict max.** If the implementation reads `loaded`, that is the safe direction: AC4 is then recorded as a known false-loaded, and A1b still lands on AC9 and AC10. |
| AC5 | **Outside load reads loaded.** Six burners outside the run during `idle` | `sh .godot/tmp/ac9-drills.sh rig ext` | `… loaded` under `--load-rule strict` **and** `--load-rule fallback` (median E > 5) | Revision 1: E **7.63, 7.75** (`r-ext.analyse3.tsv`, V24). Revision 0: 7.62, 7.76, 7.73 (V16). |
| AC6 | **Own and outside together read loaded** | `sh .godot/tmp/ac9-drills.sh rig both` | `… loaded`, both rules | Revision 1: E **9.21, 9.98** (`r-both.analyse3.tsv`). Revision 0 read 7.75, 8.01 against a true outside load of about 8, so it under-read; `ps` only read 10.02, 10.55. |
| AC7 | A `nohup` child in the run's group counts as own | `sh .godot/tmp/ac9-drills.sh rig escape-pg` | `own_cpu ≥ 30` (the 40-s burner), `comparable` | Tree observed **35.9 s**; E 1.78, 1.88 (`r-esc-pg.analyse3.tsv`, V9) |
| AC8 | A `setsid` double-fork escape counts as outside (the safe direction) | `sh .godot/tmp/ac9-drills.sh rig escape-sid` | `own_cpu < 1` | Tree observed **0.0 s**; the escaped burner used 36.0 s outside; E 2.88, 2.69 (V10) |
| AC9 | **The self-loading suite target reads quiet on a quiet rig** | `uptime; sh .godot/tmp/ac9-drills.sh rig worlds-leak` (≈ 6.5 min) | when the 1-minute load is < 5 at the start: `… comparable` under strict | Revision 1: E median **2.40**, max **2.73**; unseen 15.8 s, credited 0 (`wl.analyse3.tsv`, V24). The parent's rule on the same run read median 7.010, max 7.380, **`loaded`** (`wl-old-rule-report.txt`, V3). Start load 2.50. Fallback if the rig is not quiet: at most two repeats, then the case goes to Mark. |
| AC10 | A headless Godot target reads quiet | `sh .godot/tmp/ac9-drills.sh rig title` (`-o import title-screen-test`) | `comparable` | Revision 1: E ≤ **2.06** with 10-s windows; unseen 8.1 s, credited 0 (`r-godot.analyse3-w2.tsv`, V24). The 30-s-window reading is UNMEASURED, because the run is shorter than one window; the report treats a single window as its own median and max. |
| AC11 | The nightly failing sets are named and identical | `for d in "$TMPDIR"/rig-check/{49314f81,059bad3c,17623c04}*.profile; do awk -F'\t' '$5==1 && $4!=0 {print $6}' "$d/profile.tsv" \| sort -u \| tr '\n' ' '; echo; done` | three identical lines `basis-gate ui-theme-check` | **Measured:** three identical lines (V5) |
| AC12 | The legacy nightly profiles are refused, not guessed | scratch copies as in the finding's re-check, then `sh tools/suite_profile.sh report --load-rule fallback n*.tsv; echo rc=$?` | `no external-load samples`, `rc=1` | Premise measured: no `cpu.tsv`, 7-column rows (V13). Today's tool refuses them on `rc` instead: `failed run`, rc 1 (V23). The new refusal is UNMEASURED (new code). |
| AC13 | The first nightly after A1a writes the new record | `d=$(ls -dt "$TMPDIR"/rig-check/*.profile \| head -1); test -s "$d/cpu.tsv" && awk -F'\t' 'NF!=8' "$d/profile.tsv" \| wc -l` | `0`, and `grep -c '^make_args=.*-k' "$d/header.txt"` = `1`, and `test "$(grep '^tree_group=' "$d/header.txt")" = "tree_group=$(grep '^tree_root=' "$d/header.txt" \| cut -d= -f2)"` succeeds (kimi, round 2: the group rule applies on the baseline path) | UNMEASURED. The premises are read: line 113 passes `-k test` and `bounded` makes the root a group leader (V26). Fallback: M1b stays parked and the controller files the gap; if only the `tree_group` check fails, `tree_group=-` is accepted as the production norm, recorded in the A4 baseline report, and rule 3 of §D is inert there (group-only orphans fall to E). |
| AC14 | Sampler cost | `/usr/bin/time -p sh -c 'for i in 1 2 3 4 5 6 7 8 9 10; do ps -A -o pid=,ppid=,pgid=,lstart=,time= >/dev/null; done'` | user + sys ≤ 0.5 s (≤ 1 % of a core at 5-s cadence) | **0.12 s** (V12). The full sampler is UNMEASURED; the fallback is a 10-s cadence. |
| AC15 | Scope: no Python, no held file, no make wiring, no rig-control edit | `git diff --name-only origin/main...HEAD \| grep -c '\.py$'; git diff --name-only origin/main...HEAD \| grep -c -x -E 'Makefile\|mk/.*\|tools/rig_check\.sh\|tools/test_rig_check\.sh\|tools/test_rig_keep_going\.sh\|tools/rig_nightly\.sh\|tools/python-allowlist\.txt'` | `0`, `0` | This design branch adds only this doc: `0`, `0`. `tools/test_rig_check.sh` stays untouched because it checks only the control's exit status (V22). |
| AC16 | The fast tier stays green | GitHub `make ci-fast` on each PR | success | UNMEASURED. The touched files are not in `ci-fast`'s closure (`rig-check-control` is reached only from `test`, V17). |
| AC17 | **Codex's two-window counterexample reads loaded** | the case `ext-two-window` (AC2), and in this pass `sh scripts/mksyn.sh D cx-spanning; sh scripts/analyse3.sh D 100 D/profile.tsv` | `loaded` under strict **and** fallback | **Measured on synthetic data:** revision 1 E **8.96, 8.96**, loaded under both rules. Revision 0 (even spread) read **4.96, 4.96**, comparable under both, which was the defect. Truth: 8.96, then 0.96 raw (`synthetic/cx-spanning.analyse3.tsv`, V25). Control `cx-inside`, the same CPU inside window 2: credited in full, E 8.96 then 5.81 (`synthetic/cx-inside.analyse3.tsv`). |
| AC18 | **No double counting** | the case `ext-no-double-count` (AC2); in this pass `mksyn.sh D no-double-count` | E = 2.01 (the true outside load); `credited = 0` | **Measured on synthetic data:** revision 1 **2.01, 2.01**; revision 0 **0.35**, an under-read of 1.67 cores (`synthetic/no-double-count.analyse3.tsv`, V25) |

### Hermetic cases (AC2)

Each case writes synthetic `profile.tsv`, `header.txt`, `load.tsv` and `cpu.tsv` inside `T`. Each is listed with the mutant that must fail it.

| Case | Asserts | Killing mutant |
|---|---|---|
| `ext-own-only` | `load1` 9 in every sample; H = R + 2 → `comparable` (strict) | E: eligibility read from `load.tsv` |
| `ext-external` | H = R + 7 → `loaded` under strict and fallback | (control for E) |
| `ext-short-lived` | a line inside one window whose CPU `ps` never sees, 8 cores over 2.08 outside → credited in full, E 2.08 → `comparable` under strict. With the credit removed, E reads 5.23, `loaded` under strict (`synthetic/short-inside.analyse3.tsv`). | X: drop the credit (`ps` only) |
| `ext-two-window` | codex's counterexample (AC17) → `loaded` under both rules | V: even spread instead of the bound |
| `ext-no-double-count` | a member reaped through *L* whose parent is missing from every snapshot (AC18) → E 2.01 | D: drop U(L) from rem(L) |
| `ext-pgid` | a ppid-1 process in the root's group, `tree_group=<root>`, counts as own | G: drop the group rule |
| `ext-escape` | a ppid-1 process in another group counts as outside | S: count every ppid-1 process as own |
| `ext-pid-reuse` | the same pid with a new `lstart` is not sticky | W: identity by pid alone |
| `ext-sparse` | `H` rows in fewer than 90 % of intervals → refuse | (guard) |
| `kg-same` | rc 2, `-k`, F = {a} on both sides → counts, prints `failing=a` | K: ignore failing-set inequality (paired with `kg-differ`) |
| `kg-differ` | F = {a} before, {a, b} after → `failing targets differ` | K |
| `kg-unnamed` | rc 2, F = ∅ → refuse | U: accept a red run without names |
| `kg-rc0-rows` | rc 0 with a failing MAKELEVEL-1 row → refuse | (guard) |
| `kg-no-k` | rc 2 without `-k` → refuse | (guard) |
| `kg-watchdog` | rc 124 → refuse | (guard) |
| `legacy-no-cpu` | 7-column rows, no `cpu.tsv` → `no external-load samples` | (guard) |
| `level2-ignored` | an rc ≠ 0 row at MAKELEVEL 2 inside a green run leaves F = ∅ | L: count every level in F |
| `cpu-sampler-cleanup` | after a normal exit, TERM and INT, the CPU sampler and its `iostat` child are gone (the existing `sampler-cleanup` pattern) | (guard) |

The existing 20 cases stay. `record()` gains an 8th column and a quiet `cpu.tsv` companion, so `report-load` and `report-medians` keep their meaning. `report-load` now varies `cpu.tsv`, not `load.tsv`, in its strict and fallback checks. `atomic-rows` checks `NF==8`. A1a lands the sampler cases (`cpu-sampler-cleanup`, the column, the header); A1b lands the rest.

### Drill block (saved verbatim as `.godot/tmp/ac9-drills.sh`)

```sh
# drill ROOT MUTANT: mutate a scratch copy of tools/, prove the mutation applied, expect the named case to FAIL.
#   X credit dropped (ps only)  -> ext-short-lived     V even spread, no bound  -> ext-two-window
#   D U(L) dropped from rem(L)  -> ext-no-double-count G group rule dropped     -> ext-pgid
#   S every ppid-1 counted own  -> ext-escape          K failing sets not compared -> kg-differ
#   U red run with F empty ok   -> kg-unnamed          E eligibility from load.tsv -> ext-own-only
#   L all MAKELEVELs in F       -> level2-ignored      W identity = pid only    -> ext-pid-reuse
# The sed anchors are fixed by the executor against the landed code and recorded in the sprint JSON;
# each mutation is proven by `cmp` (exit 3 if unchanged), and the control is run for that one case.
drill() (
  set -u; ROOT=${1:?}; m=${2:?}; cd "$ROOT" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/ac9-drill.XXXXXX") || exit 2; trap 'rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp -R tools "$T/tools" || exit 2
  case "$m" in X) want=ext-short-lived ;; V) want=ext-two-window ;; D) want=ext-no-double-count ;;
    G) want=ext-pgid ;; S) want=ext-escape ;; K) want=kg-differ ;; U) want=kg-unnamed ;;
    E) want=ext-own-only ;; L) want=level2-ignored ;; W) want=ext-pid-reuse ;; *) exit 2 ;; esac
  sh "$ROOT/.godot/tmp/ac9-mutate-$m.sh" "$T/tools/suite_profile.sh" || exit 2   # written by the executor, one sed each, beside this block (judge N1)
  cmp -s tools/suite_profile.sh "$T/tools/suite_profile.sh" && exit 3
  rc=0; sh "$T/tools/test_suite_profile.sh" "$want" > "$T/log" 2>&1 || rc=$?
  test "$rc" = 1 || exit 1; grep -q "^suite-profile control $want: FAIL" "$T/log" || exit 1; echo "$m: killed"
)
# rig CASE: one bounded real-rig drill, headless and GPU-free. Records uptime; a run is counted only from load < 5 at start.
#   own|escape-pg|escape-sid|idle: fixture targets from .godot/tmp/ac9-fx/Makefile (scripts/fixture.mk of the i111 evidence);
#   ext: `idle` with six 68-s perl burners started outside the run; both: `own` with six 58-s burners outside;
#   worlds-leak: PATH=$PWD/runtime/bin:$PATH, target worlds-leak; title: -o import title-screen-test.
```

The `rig` half is given here as a specification in comments. The executor writes the `rig` function and a dispatcher (`case "${1:-}" in rig) shift; rig "$@" ;; esac`) so that `sh .godot/tmp/ac9-drills.sh rig <case>` runs one case, and records the finished block in the sprint JSON. The `rig` half is about 15 minutes of rig time in total (AC4 to AC10). It runs from the A1b PR's clone. It uses no GPU, so it obeys CLAUDE.md's merge rule. Each run is bounded by `perl -e 'alarm 600; exec @ARGV'`.

## Milestones and estimates

| Milestone | Files (LOC) | Total | Order |
|---|---|---:|---|
| **A1a:** the instrument: CPU sampler (with `iostat` as its sleep), wrapper pid column, header fields | `tools/suite_profile.sh` +45; `tools/test_suite_profile.sh` +75 (`ps`/`iostat` stubs, `record()` 8th column, `cpu-sampler-cleanup`, `atomic-rows`); `tools/timed_recipe_shell.sh` +1 −1; `CHANGELOG.md` +4 | ≈ 125 | After Mark's OK on D-173 A. Its own quorum and judge (generator ≠ judge). Landing it first lets every nightly start writing `cpu.tsv` while A1b is built. |
| **A1b:** the classifier: lower bound, U(L), refusals, keep-going rule | `tools/suite_profile.sh` `report` +95; `tools/test_suite_profile.sh` +80 (17 cases); `CHANGELOG.md` +2 | ≈ 177 | After A1a. Its own quorum and judge. |
| **A2:** parent amendment | `rig-test-speed.md` AC9, §1f, §1b (about 20 lines); `rig-test-speed-sprint.md` M1b predicate (about 10); `.ailang/state/sprints/sprint_R1-RIG-TEST-SPEED.json` notes | docs | In the A1b PR. |
| **A3:** real-rig drills | none (AC4 to AC10, about 15 min, headless) | 0 | Executor, before the A1b PR goes up for review |
| **A4:** baseline (parent M1b, 1f) | `rig-test-speed-data/before-gmake-{1,2,3}.*`, including `.cpu.tsv` | data | Controller, by the path V21 and OQ2 select (nightlies, quiet-window controller runs, or both), plus the `RIG_TRACE=1` run (AC3) and the 3.81 fallback run as the parent specifies |

No AILANG change is involved: this is shell, awk and the report's existing inline Perl. No physics, no `sim/`, no package.

## Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | The night windows carry outside CPU, so nightly baselines read `loaded` (§I: the V11 inference, and the estimate of 2–4 samples > 8 per night) | Thresholds stay (D-173). V21 (read in iteration 113, one night): outside CPU at most 4.13 cores in the nightly runs, 0 rows over 5, and the `load1` spikes were thread bursts (§I). The risk is smaller than first feared, but not ruled out after one night. Quiet-window controller runs are co-primary from the start (Goals, OQ2). Mark decides OQ3 in the OQ1 package, not after seven loaded nights. |
| R2 | The lower bound credits little, so a target with much unseen CPU reads `loaded` falsely | False-loaded is the safe direction. Measured: the adversarial fixture still passes (4.17), and the real targets measured barely need the credit (worlds-leak 99.1 % seen, the Godot title test 64 %). The full suite's unseen share is UNMEASURED until A1a's first nightly. A1b's report prints `unseen` and `credited` per run, so the controller sees which targets drive E before any baseline is taken. |
| R3 | `iostat` and `ps` intervals are not aligned | A1a uses `iostat -c 2 -w 5` as the sleep, so both cover the same interval (§E, Alignment; UNMEASURED). An interval without `H` gets no spare room and no credit. More than 10 % missing refuses the run. |
| R4 | Thread bursts that use little CPU no longer count (Problem 3) | Stated as a trade-off. Spans are still medians of ≥ 3, and CPU-seconds stay the second measure. If Mark wants bursts counted, `load1` can be added back as a separate clause (OQ1). |
| R5 | A process escapes the tree with `setsid` | It counts as outside, so the run reads more loaded, never less (AC8). |
| R6 | Format change: 8-column rows | `summary`, `targets`, `compare` and `agree` read columns 1–7 (unchanged). Only `report` requires 8, and it refuses with a named message. `tools/test_rig_check.sh` checks only `profile.tsv`'s existence, `^totals` in the log and the control's exit status (V22). |
| R7 | The baseline profiles in `$TMPDIR` are deleted before they are copied | The controller copies them into `rig-test-speed-data/` within a day (A4), never `database.txt`, which holds the rig's environment and credentials (§I warning). |
| R8 | 7as or 7at gets fixed between runs, so F changes | The report refuses the mixed set by name. The baseline is re-collected on the new F (OQ4). |
| R9 | The `-j6` after side: six lanes of unseen CPU, with the bound crediting little, could push E over 5 when the outside is quiet, so the speed-up cannot be certified | UNMEASURED (M2 does not exist yet). The safe direction is to read loaded. Before M2's runs, the controller reads `unseen` and `credited` on the serial baselines. If unseen CPU per lane is large, the remedy is a shorter `ps` cadence (2 s: about 0.6 % of a core at 12 ms a snapshot, V12), not a weaker bound. That is decided at M2 with Mark. |

## Open questions for Mark

| # | Question | Loop's recommendation | Default if unanswered |
|---|---|---|---|
| OQ1 | **The approval package.** In plain words: the numbers 5 and 8 would then limit the CPU used by everything that is not the test run (in cores, smoothed over a minute), not the whole machine's run queue, and the 1-minute load average would be printed but would no longer decide anything (judge N7). Approve the rule as specified, together with your answer to OQ3? The rule: external load = host CPU (`iostat` ticks) minus a **verified lower bound** on the run's own CPU (`ps` plus the wrapper's exact `times`, credited only where the data pins it), damped like a 1-minute load, with thresholds 5 and 8 unchanged and `load1` printed but not gated. | Yes. It is CPU on both sides of the subtraction (§C). It errs toward `loaded` in every window and cannot double-count (§E). | Stop. D-173's default holds until this doc is approved. |
| OQ2 | Where should the baseline come from: the nightly `rig/full` runs on main, controller runs in a quiet window the controller picks, or both? | **Both, as co-primary: V21's outcome (iteration 113, §I).** Expect the nightlies to supply the baseline, at no extra rig time. Keep quiet-window controller runs as the fallback if instrumented nights read `loaded`. On the night of 23–24 November, outside CPU in the two nightly runs peaked at 4.13 cores (22:30–00:15) and 2.87 (05:00–06:30). It went over 5 in 0 of 206 and 0 of 222 rows, so the switch to controller runs (over 8 in both windows, or over 5 in more than 10 % of rows) did not trigger. The nightlies missed "primary" on one row out of 15 `load1` jumps, where the unsmoothed outside CPU of that 30-s row read 5.03 cores against a limit of 5 (3.24 smoothed), most likely the estimate's artefact. Controller runs cost about 103 min of rig time each, and three are needed. The `--trace` run (AC3) and the 3.81 fallback run stay controller runs either way. Mark decides. | Co-primary (V21's outcome); Mark decides. |
| OQ3 | **Decided now, as part of OQ1:** if instrumented night runs read `loaded` on max E, should the baselines (a) come only from quiet-window controller runs, or (b) should the max clause tolerate one short spike? (b) changes a threshold, which D-173 A excludes, so it would be a separate ruling. | (a). It keeps the thresholds, and costs about 5 h of rig time for three runs, plus repeats. V21 suggests the case may not arise. On one night the estimated max E was 4.13 and 3.08 for the two nightly runs. Even crediting the run with no CPU at all, the max was 7.17 and 6.80, with 0 rows over 8, so neither would have failed the fallback's max ≤ 8 (§I). | (a). |
| OQ4 | When 7as or 7at is fixed partway through, re-collect the whole baseline on the new failing set? | Yes. One failing set per report (§H). | Yes. |
| OQ5 | M2's parallel runner must also run `-k` and write the same record, so its after-runs can match a red before side. Make that an M2 requirement? | Yes. | Yes. |

## Deliverables

- This doc. Its quorum and judge are run by the controller.
- After Mark's OK: the A1a PR (the instrument), then the A1b PR (the classifier, drills and parent amendment), then the A4 baseline report.
- V21 was read in iteration 113 (§I): co-primary under the rule as written, with the nightlies the expected source. Evidence: `gs://stapledons-voyage-assets/benchmarks/v21-overnight-iter113/`.

## Premises of the finding, checked

- **Confirmed:** the three profiles have `rc=2`, 207 load samples, and > 5 / > 8 counts of 53/8, 60/13 and 41/6 (V14 reproduces the finding's table). worlds-leak alone reads `loaded` under the parent's rule (V3: median 7.010, max 7.380, a third reading after 6.26/10.86 and 5.44/8.05). Today's `report` refuses an `rc=2` header with `failed run` (V23).
- **Answered (the finding marked it UNMEASURED):** "Whether those [other > 8 samples] are the suite's own or the rig's". By the estimate in §I, the run's own CPU at most of those samples was about 1 core. Own CPU explains 6 of 8, 9 of 13 and 4 of 6 of the samples over 8, but not the rest. One of the remaining spikes falls on a target that does not move `load1` alone (V11). **This qualifies D-173's case for A.** Option A removes the self-load that blocks every run, but it may not by itself make the nightly windows pass max ≤ 8. Hence OQ2's co-primary paths and V21. This is an estimate in mixed units, not a measurement under the new rule. V21 (iteration 113) later measured host CPU on one night, in cores. The remaining `load1` spikes of two new nightlies came with low host CPU (E at most 4.13; the largest spike, `load1` 19.29, at H 3.36). So on that night they were thread bursts, not outside CPU (§I).
- **Different reading, not a contradiction:** the iteration-110 judge found worlds-leak at about 84 % of host CPU. This pass read its tree at 4.6–4.9 of 6.1–7.8 busy cores (about 66–70 %), with the rest of the host at 1.8–3.8 cores. Background levels differ between quiet moments.
- **Moot under A:** finding point 3 ("six busy lanes add about 6 to the load"). Under this rule a run's own lanes are not outside load. R9 notes the new, smaller after-side risk, which is unseen lane CPU.
- **The brief's candidate (i) does not work as stated:** subtracting `pcpu` from `load1` mixes units, and `ps -S` cannot recover children on macOS (V8). The wrapper's `times` is needed because 61 % of the adversarial fixture's CPU was invisible to 5-s `ps` snapshots (V7). Revision 1 uses it only as a bounded credit.

## Independent evaluation

- **Judge round 1** (Sonnet 5.5 via the Agent tool, `.ailang/state/evaluations/eval_R1-RIG-TEST-SPEED_ac9-design_round_1_sonnet.json`): **85/100 PASS**, 0 blocking. It re-derived the bundle hashes, every analyse3 output and the quoted AC readings byte for byte, re-read V26, found no counterexample to R(w) ≤ actual run CPU, and judged the round-2 carve-out legitimate. Its non-blocking findings, applied as clarifications before commit (no rule change):
  - N1: the drill reads each mutant script from `$ROOT/.godot/tmp/ac9-mutate-<m>.sh`, not from the fresh `mktemp` dir; the `rig` half stays a specification the executor writes.
  - N2: `\|` in table cells is Markdown escaping.
  - N3, N4 (unsafe direction, small): A1a must (a) take H from `iostat`'s whole-percent figures with the rounding bound stated in the report line, at most 2 × 0.5 % × ncpu, about 0.16 cores per window here, and (b) time intervals with a sub-second clock (`perl -MTime::HiRes`), not `date +%s`, or else count intervals by `iostat`'s own 5-s cadence; both are A1a design-review items.
  - N5: Step 2.5's alignment caveat corrected: misalignment shifts spare_k either way, and only under-statement is unsafe.
  - N6: a member first admitted after it has already run (for example by the group rule on its first sighting) has no CPU baseline; A1a counts its first sighting from its `lstart`, attributing CPU before the run's first snapshot to no window, or else excludes that first delta and says so.
  - N7: the thresholds 5 and 8 now bound damped outside CPU in cores, not the run queue, and `load1` no longer gates: this is OQ1's substance and is now said there in those words.

## Quorum log

- **Round 1** (2026-11-23, `rig-test-speed-ac9-load-rule-2026-11-23T17-23-46Z.json`): **BLOCKED**, 3 of 3 present seats rejected. oc-kimi-k3 was absent (an invalid, empty response), and the reserve codex:gpt-6.2-sol took its seat. None disputes option A's direction, and each gave a concrete fix. Revision 1 applies all three.

| Seat | Objection, in one line | Lands on | What changed |
|---|---|---|---|
| codex:gpt-6.2-sol | Spreading unseen CPU evenly can subtract run CPU from a window where the run used none. In the two-window case it reads E 5, 5 while the true first window is 9. | §E remainder | §E now credits a verified lower bound per window (spare room, cap_L, lb_L). The counterexample reads loaded under both rules (AC17, case `ext-two-window`, mutant V). AC4 and AC9 were re-run from the raw samples: 4.17 and 2.73, both still comparable (V24). |
| gemini-4-argon | It is not proven that R(w) cannot exceed the run's actual CPU: a broken `ppid` chain plus a group-only member could double-count. | §E/§D attribution | The chain is read within one snapshot. U(L), the unattributed observed CPU in *L*'s span, is subtracted from rem(L). §E gives a 4-step proof that R(w) ≤ actual run CPU. Case `ext-no-double-count` (AC18, mutant D): revision 0 read 0.35, revision 1 reads 2.01, the truth. |
| oc-glm-5-3 | The nightly-baseline plan rests on an unmeasured night window that the doc's own V11 argues against. `test_rig_check.sh:114`'s assertion is unrecorded. The rc≠0 premise has no V-row. | §I/OQ plan | §I draws the V11 inference. OQ3's decision moves into the OQ1 package. Quiet-window controller runs are co-primary (Goals, OQ2). V21 (the overnight sampler, then IN FLIGHT, launched by the controller; read in iteration 113, §I) has a stated flip criterion. V22 records line 114 and `tools/test_rig_check.sh` joins AC15's untouched list. V23 runs today's `report` on an rc=2 header. |

- **Round 2** (2026-11-23, `rig-test-speed-ac9-load-rule-2026-11-23T17-40-34Z.json`): **BLOCKED**, 3 of 3 present (gemini-4-argon, oc-glm-5-3, oc-kimi-k3; no absentee). No objection disputes option A or revision 1's rule; each names a proof step or an unrecorded premise and gives its own fix. Under Gate 2's narrow-refinement carve-out the **controller** made one bounded second revision applying those fixes, with no further quorum round, and routed the doc to the independent judge and then to Mark (D-173 stops before code anyway).

| Seat | Objection, in one line | Lands on | What changed (the reviewer's own fix) |
|---|---|---|---|
| gemini-4-argon | Step 3 of the §E proof (`unseen_L(k) ≤ cap_L(k)`) is not justified at a boundary interval where O_k holds another line's observed CPU, nor across concurrent `-j6` lines. | §E proof | Its fix (2): Step 2.5 states the global interval inequality H_k·Δt_k ≥ O_k + Σ_L unseen_L(k), so each unseen_L(k) ≤ spare_k whichever line produced O_k; the formula is unchanged; the iostat/ps alignment it rests on is named UNMEASURED. |
| oc-glm-5-3 | Line 113's `-k` and `bounded`'s `setpgrp`/`exec` are asserted with no V-row, while `rig_check.sh` is frozen by AC15. | Depends on, Problem 2, §D rule 3 | V26 reads both verbatim (no rig time) and is cited from Depends on, Problem 2 and §D rule 3. Both premises hold, so the contingencies it asked for (OQ2 path 1 void; AC7 under a setpgrp harness) are not triggered. |
| oc-kimi-k3 | §D rule 3 rests on an unread `bounded`; AC13 never checks `tree_group == tree_root` on the nightly. | §D rule 3, AC13 | V26 plus a pgid probe with a control; AC13 gains its `tree_group` equality check, with `tree_group=-` accepted and recorded in A4 as the fallback. |

Surfaces per round (Gate 2 rule (a)): round 1 landed on §E remainder, §E/§D attribution and the §I/OQ plan; round 2 on the §E proof and on recorded premises of `rig_check.sh`. They converge on verification of what revision 1 already chose, not on a new surface.

## Verification log

All files of V1 to V26 are under `/tmp/i111-design-evidence/`, with hashes in `SHA256SUMS` (sha256 `e4b0b0c6…5c226b27`, revision 2). The files of V27 to V32 (iteration 113) are under `/tmp/i113-v21-evidence/`, with hashes in its own `SHA256SUMS` (`c2d305f1…94c84c24b` after the two `database.txt` files were removed; see §I). Revision 0's prototype scripts are `scripts/sampler.sh` (`da68b14b…`), `scripts/analyse.sh` (`936d0dfc…`), `scripts/analyse2.sh` (`205abbf0…`), `scripts/retro.sh` (`6f67f966…`), `scripts/runwith.sh` and `scripts/fixture.mk` (`a3157773…`). The scratch wrapper with the pid column is `scripts/timed_recipe_shell.scratch-pid-column.sh`, a one-line diff from `tools/timed_recipe_shell.sh` at `e20175b5`. **Where the prototype differs from §D to §F:** it kept a whole-host `ps` snapshot (`procs.raw`, gzipped) instead of members-only rows; it keyed sticky identity on command name plus non-decreasing `time` instead of `lstart`, so it would miss a pid reused by a process with the same command name. A1a implements the design (`lstart`), and its `ext-pid-reuse` case covers the difference. Revision 1's are `scripts/analyse3.sh` and `scripts/mksyn.sh` (V24, V25).

| V | What | Command | Result (file, sha256 prefix) |
|---|---|---|---|
| V1 | Base control | `sh tools/test_suite_profile.sh` at `e20175b5` | `suite-profile control: 40 cases, 0 failures`, rc 0, 17 s (`control-baseline.log`, `2685aa70`) |
| V2 | Idle control, 150 s, 17:53 (start load 6.51, a tail) | `runwith.sh idle sleep 150`; `analyse.sh` | host 3.23, 2.08, 2.21, 2.08, 2.51, 2.64; visible 1.76, 1.92, 2.04, 1.91, 1.53, 0.64; `load1` 5.78 → 2.77 (`idle.analyse.tsv`, `defd917c`) |
| V3 | worlds-leak under the parent's rule | `suite_profile.sh report --load-rule strict\|fallback` on the run | median 7.010, max 7.380, `loaded` under both; load_start 2.50, load_end 8.72 (`wl-old-rule-report.txt`, `b92e2cba`) |
| V4 | worlds-leak with the sampler, 17:55 (start load 2.50) | `PATH=$PWD/runtime/bin:$PATH runwith.sh wl sh tools/suite_profile.sh run --make gmake --out … -- worlds-leak`; `analyse2.sh` | 379.3 s, rc 0; exact CPU 1,768.8 s, observed tree 1,752.9 s; tree 2.63–4.89 cores per window; E median 2.50, max 2.81; steady `load1` − damped host −0.14 to +0.32 (`wl.analyse2.tsv`, `b39f103c`) |
| V5 | Nightly failing sets | awk over `profile.tsv` (MAKELEVEL 1, rc ≠ 0; MAKELEVEL > 1); sed over the rig log's `gmake: *** [` lines; grep `not remade` | {basis-gate, ui-theme-check} ×3; the level-2 row is `script-gate-drill@sim-bridge`; log identical; only `test` not remade (`nightly-failing-sets.txt`, `0f1b0b07`) |
| V6 | No ignored-error recipe lines | `grep -n -E '^\t[@+]*-' Makefile mk/*.mk; grep -n '\.IGNORE' Makefile mk/*.mk` | no output from either |
| V7 | Adversarial own-only fixture, 18:05 (start load 6.65) | `runwith.sh r-own2 sh scripts-copy/suite_profile.sh run --make gmake -- own` (pid-column wrapper); `analyse2.sh` | exact 232.9 s, observed 91.2, remainder 141.6; E 2.91, 2.82; `ps`-only 5.06, 5.14 (`r-own2.analyse2.tsv`, `f5a8dc82`); the first `ps`-only run read 4.54, 4.79 (`fx-own.analyse.tsv`, `4fec9cce`) |
| V8 | `ps -S` on macOS | `sh -c 'perl burn 1 s; ps -o time=; ps -S -o time=; times'` | `0:00.00`, `0:00.00`; children `0m1.001s`; macOS 26.6.2 (`macos-ps-semantics.txt`, `e72109c2`) |
| V9 | `nohup` escape inside the group, 18:08 | `… -- escape-pg` | tree observed 35.9 s; E 1.93, 2.21 (`r-esc-pg.analyse2.tsv`, `95fbb8de`) |
| V10 | `setsid` escape, 18:09 | `… -- escape-sid`; burner rows in `runs/r-esc-sid/procs.raw.gz` | pid 99763, ppid 1, pgid 99762, 36.02 s by the last sample; tree 0.0; E 2.91, 2.65 (`r-esc-sid.analyse2.tsv`, `223509dd`) |
| V11 | Godot headless target, 18:12 (start load 3.05) | `… -- -o import title-screen-test`; `analyse2.sh … 16 10` | 24.2 s, rc 0; exact 22.6, observed 14.4, remainder 8.2; E 1.90, 2.00, 2.09; `load1` 2.97–3.13 (`r-godot.analyse2-w10.tsv`, `2f195be9`) |
| V12 | `ps` snapshot cost | `/usr/bin/time -p` over 10 `ps -A -o pid=,ppid=,pgid=,lstart=,time=` | real 0.12, user 0.03, sys 0.09; 829 processes (`macos-ps-semantics.txt`) |
| V13 | The legacy profiles lack the new record | `ls $TMPDIR/rig-check/17623c04*.profile`; `awk -F'\t' '{print NF}' … \| sort \| uniq -c` | no `cpu.tsv`; `766 7` |
| V14 | Retrospective estimate on the nightlies | `scripts/retro.sh nightly/<sha>`; `scripts/retro_detail.sh` | the table in §I (`nightly-retro.txt`, `40ea26ff`; `nightly-retro-over5.txt`, `6e377587`); input hashes in `nightly-inputs.sha256` (`74626d9a`) |
| V15 | Profiles outlive the rig clone | `ls $TMPDIR/rig-check/`; `tools/rig_check.sh` lines 77, 80, 113 | 13 `<sha>.profile` directories present, including the three nightlies; the EXIT trap removes only the clone `$dir` (line 80), and `$dir.profile` is deleted only at the start of the next `make test` run of the same sha (line 77) |
| V16 | Outside-load injection, 18:06 and 18:07 | six perl burners started outside the run, then `… -- idle` and `… -- own` | E 7.62, 7.76, 7.73 (`r-ext.analyse2.tsv`, `9fd051f7`); E 7.75, 8.01 (`r-both.analyse2.tsv`, `0775e04d`) |
| V17 | Where the control runs | `grep -n '^ci-fast' Makefile`; `grep -n rig-check-control mk/m45.mk`; `grep -n test_suite_profile tools/test_rig_check.sh` | `ci-fast` does not list `rig-check-control`; `test: rig-check-control` (`mk/m45.mk:57`); `tools/test_rig_check.sh:114` |
| V18 | Uptime around every run | `uptime` before and after | `uptimes.txt` (`f11a67e0`) |
| V19 | Burst evidence | the last row of `runs/r-esc-pg/host.tsv`; `uptimes.txt` | `1795453781 16 20 64 11.50` after `1795453776 12 2 87 5.45` (18:09:41 CET) |
| V20 | The analyses re-derive byte for byte | in a copy of the tarball: `gunzip -k runs/<r>/procs.raw.gz; sh scripts/analyse2.sh runs/<r> $(cat runs/<r>/root.pid) runs/<r>/prof/profile.tsv \| cmp - <r>.analyse2.tsv` for r-own2, r-ext, r-both, wl; `analyse.sh` for idle; `retro.sh` for the nightlies | all identical (checked in `/tmp/i111-verify/`) |
| V21 | **Overnight host control: DONE, read in iteration 113** (launched by the controller in iteration 111) | `/tmp/i111-overnight-tools/host_sampler.sh /tmp/i111-overnight-data/host.tsv`, pid 31503, started 2026-11-23T17:27:33Z, alarm at 13 h; script sha256 `af550012817fa9b24c673b425acedd7e4d90f715a559209f7f35b48425322b57` (re-hashed in iteration 113, unchanged) | 1,552 rows plus the header, 18:28:04 to 07:27:24 CET, every row 30 or 31 s after the last (no gaps); the alarm stopped it (`ps -p 31503`: gone). Two nightly `rig/full` runs inside it. Read per §I in V27 to V32: co-primary, by one row (§I). Copy: `inputs/host.tsv` in `/tmp/i113-v21-evidence/` (`9aec2d92`, identical to the original) |
| V27 | V21 inputs, copied and checked (iteration 113) | `cp -p` of `host.tsv`, `started_utc`, `host_sampler.sh`, both `$TMPDIR/rig-check/<sha>.profile/` and `<sha>{,.golden}.log` into `inputs/`; `awk` row-gap count; `awk` failing sets (MAKELEVEL 1, rc ≠ 0) and `grep 'gmake: \*\*\* \['` per log; `TZ=Europe/Berlin date -r` on `end_ms` against the log mtime | gaps: 30 s ×1,321, 31 s ×230, none longer; both runs `rc=2`, 766 rows of 7 columns (690 at MAKELEVEL 1), failing set `{basis-gate, ui-theme-check}` in profile and log, closure `47d40348…`; `d8b7baf9` `end_ms` → 00:13:51 CET = log mtime 00:13:51. Hashes: `d8b7baf9` `profile.tsv` `4a5a2737`, `load.tsv` `13e0a29d`, `header.txt` `2d4693ed`; `328b01f8` `profile.tsv` `ac81c6fd`, `load.tsv` `4d302247`, `header.txt` `809ff49e`; `spans.tsv` `39a7ab4a` (test spans from the headers, golden spans from `stapledon-rig-nightly.log`) |
| V28 | Per-row outside-CPU estimate (iteration 113) | `sh scripts/v21rows.sh inputs/host.tsv spans.tsv d8b7baf9=…/profile.tsv 328b01f8=…/profile.tsv > rows.tsv` (adapted from iteration 111's `retro.sh`: the same even spread of MAKELEVEL-1 exact CPU, over each 30-s V21 row, subtracted from `iostat` H instead of `load1`) | 1,552 rows: 206 `d8b7baf9`, 222 `328b01f8`, 6 + 6 golden, 16 tail, 1,096 idle; 209 rows in 22:30–00:15, 179 in 05:00–06:30. Control: the spread places 9,443.2 of 9,494.8 s and 10,273.9 of 10,336.0 s of MAKELEVEL-1 CPU in the runs' rows (`rows.tsv`, `919e2a73`; script `2c0e4da9`) |
| V29 | Summary, flip rule, upper bracket, notable rows (iteration 113) | `sh scripts/v21summary.sh rows.tsv > summary.txt`; `sh scripts/v21extra.sh rows.tsv d8b7baf9=… 328b01f8=… > extra.txt` | E max 4.13 (`d8b7baf9`), 3.08 (`328b01f8`; 2.87 within 05:00–06:30); E > 5 in 0 of 206 and 0 of 222; E > 8 in 0 rows of either window. Flip to controller-primary: not met. "Nightlies primary": met by `328b01f8`, missed by `d8b7baf9` on one jump (23:14:56, x 5.03). E_H (no own credit) max 7.17 and 6.80, 0 rows > 8. Idle: H median 2.08, max 8.16; E median 2.14, max 6.64; 7 rows > 5, 0 > 8 (`summary.txt` `55b43a22`, `extra.txt` `007ee519`; scripts `6491299e`, `80985b4f`) |
| V30 | The old rule on the same runs (iteration 113) | `sh scripts/retro.sh inputs/<sha>.profile` (iteration 111's `retro.sh`, unchanged, `6f67f966`); `sort -n` median/max of `load.tsv` | `d8b7baf9`: 207 samples, > 5 / > 8 = 58 / 9, median 3.87, max 14.66, V14-style estimate max 13.58 (17 / 3). `328b01f8`: 224 samples, 71 / 12, median 3.72, max 13.15, estimate max 12.30 (19 / 4) (`oldrule-retro.txt`, `7f7127f0`) |
| V31 | Timing of other host activity (iteration 113; timing only) | `sh scripts/attrib.sh > attrib.txt`: `stapledon-rig-nightly.log` lines, `/tmp/ailang-nightly-eval.stdout` start/done, the first and last bracketed CET timestamp of each burst in `/tmp/ailang-mission-*.log` | golden halves 00:31:44–00:34:41 and 06:16:46–06:19:43; nightly eval 03:00:00–05:39:05; `mission-fleet` 23:53:00–23:53:56; `mission-iteration-fixture` 06:40:07–06:51:12; other fires a few seconds each (`attrib.txt`, `7e4a0a97`; script `73006a3d`). Reads live logs, so not re-derived |
| V32 | The derived files re-derive byte for byte (iteration 113) | `sh scripts/run_all.sh /tmp/i113-verify`; `cmp` each output against the bundle | `rows.tsv`, `summary.txt`, `extra.txt` identical; `oldrule-retro.txt`'s two estimate lines identical. Bundle as published (clean): `SHA256SUMS` `c2d305f1…`; `i113-v21-evidence-clean.tgz` 365,238 B, sha256 `740c9a1020bb83f914af701d163a66f016ff63bc7dd35580d174a949b969b3cc`, at `gs://stapledons-voyage-assets/benchmarks/v21-overnight-iter113/` |
| V22 | What `tools/test_rig_check.sh` asserts about the instrument | `sed -n '105,125p;225,266p' tools/test_rig_check.sh`; `git ls-files \| grep -v '^design_docs\|^\.ailang' \| xargs grep -l -E 'suite_profile\|timed_recipe_shell'` | Line 114: `if sh tools/test_suite_profile.sh > "$T/suite-profile.log" 2>&1; then echo 'rig-check control suite-profile: ok'`. It checks only the exit status, with no case count and no `report` line format. Lines 230, 255 and 262–265 check that `<dir>.profile/profile.tsv` exists and that `^totals` is in the log, which come from `summary` (unchanged). The instrument is referenced only by `CHANGELOG.md`, `tools/rig_check.sh`, `tools/suite_profile.sh`, `tools/test_rig_check.sh` and `tools/test_suite_profile.sh`. So `tools/test_rig_check.sh` needs no edit (AC15). Its `profile-on` cases will run the new CPU sampler, which `cpu-sampler-cleanup` covers. |
| V23 | Today's `report` refuses an rc ≠ 0 header | a scratch copy of the unmodified `17623c04` profile as `n17623c04.{tsv,load.tsv,header.txt}`; `sh tools/suite_profile.sh report --load-rule fallback n17623c04.tsv` (tools at `e20175b5`) | `suite-profile: failed run n17623c04.tsv`, rc 1; the header says `rc=2` (`rc2-refusal.txt`, `7446b3a5`) |
| V24 | Revision-1 re-analysis of the real runs | `sh scripts/analyse3.sh runs/<r> $(cat runs/<r>/root.pid) runs/<r>/prof/profile.tsv` (godot: `… 16 2`) | `r-own2.analyse3.tsv` `f8839fe8`: E 4.06, 4.17, credited 55.0 of 141.6. `wl.analyse3.tsv` `3f01a6ec`: median 2.40, max 2.73, unseen 15.8, credited 0; its `E_even` column shows revision 0's double count when attribution is absent (−2.79 to −1.59). `r-godot.analyse3-w2.tsv` `ac86412d`: max 2.06. `r-ext.analyse3.tsv` `10230793`: 7.63, 7.75. `r-both.analyse3.tsv` `7208f689`: 9.21, 9.98. `r-esc-pg.analyse3.tsv` `8b94d1ff`: 1.78, 1.88. `r-esc-sid.analyse3.tsv` `859726da`: 2.88, 2.69. Each re-derives byte for byte from the tarball (`/tmp/i111-verify2/`). Script `scripts/analyse3.sh` `4d6e7ec7`. |
| V25 | The synthetic cases (2 windows × 6 intervals of 5 s, ncpu 16) | `sh scripts/mksyn.sh D <case>; sh scripts/analyse3.sh D 100 D/profile.tsv` for `cx-spanning`, `cx-inside`, `no-double-count`, `short-inside` | `cx-spanning` `17ee74f2`: rev 1 8.96, 8.96, loaded/loaded; rev 0 4.96, 4.96, comparable/comparable. `cx-inside` `2523a4b6`: credited 240 of 240; 8.96, 5.81. `no-double-count` `b0068620`: rev 1 2.01; rev 0 0.35. `short-inside` `c3b5b307`: rev 1 2.08, 2.08; `ps` only 2.08, 5.23 (strict loaded). All re-derive byte for byte. Script `scripts/mksyn.sh` `bcd5b2d6`. |
| V26 | `rig_check.sh`'s invocation and bounding (controller, round-2 carve-out; no rig time) | `awk 'NR==113' tools/rig_check.sh; awk 'NR==122' tools/rig_check.sh; sed -n '/^bounded()/,/^}/p' tools/rig_check.sh; shasum -a 256 tools/rig_check.sh`; then a probe of `bounded`'s `perl` pattern: child `setpgrp(0, 0)`, `exec sh -c 'ps -o pgid= -p $$'`, against a control without `setpgrp` | Line 113: `bounded "$TEST_S" sh tools/suite_profile.sh run --make gmake --out "$dir.profile" -- $trace -k test …`; line 122 (3.81 fallback) passes the same `-- $trace -k test`; `bounded`'s child runs `setpgrp(0, 0); open STDIN, "<", "/dev/null"; exec @ARGV`; `rig_check.sh` sha256 `37defb61…0c1516` at `e20175b5` (`rig-check-readings.txt`, `de1609bf`). Probe `pid=54004 pgid=54004`; control `pid=54103 pgid=54094` (`bounded-pgid-probe.txt`, `1b204088`) |
