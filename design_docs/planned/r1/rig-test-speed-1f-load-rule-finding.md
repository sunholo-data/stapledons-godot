# L4 M1b baseline (1f): the comparability rule rejects every run (finding, iteration 110)

**Status:** finding, no code change. Asked as D-173.
**Design:** [rig-test-speed.md](rig-test-speed.md) §1f and AC9. **Sprint:** `R1-RIG-TEST-SPEED`, milestone M1b (1f).
**Evidence:** `gs://stapledons-voyage-assets/benchmarks/l4-1f-iter110/l4-1f-iter110-evidence.tgz`
(47,184 B, sha256 `7d614b673f6e86ab5f5d4aa67534483b55844f97ba4fb6c6fd8c9c9e9042ff57`; the public
URL was re-downloaded and hash-checked).

## What was meant to happen

Row L4's M1b baseline needs at least three comparable serial `tools/rig_check.sh` runs on GNU Make
4.4.1. AC9 decides which runs are comparable from the 1-minute load sampled every 30 s
(`tools/suite_profile.sh report`, line 230): the strict rule needs `max ≤ 5`; the fallback needs
`median ≤ 5` and `max ≤ 8`. `report` also refuses any run whose `make test` failed (`rc` in the
header must be 0). The row's resume predicate was "load ≤ 5 with the GPU and console idle at pick,
then one run per quiet window". At this pick `quiet2.sh` read YES three times (10:38 local, GPU
0/0/0, load 2.65–4.0, console idle).

## What was measured

1. **The nightly has already taken three instrumented serial runs since M1b landed, and none
   counts.** Each `rig/full` since #451 is a profiled gmake run (`<sha>.profile/` beside the rig
   log). `report` on all three, with the headers' `rc` forced to 0 in scratch copies to separate
   the load rule from the rc rule:

   | main | span (s) | CPU (s) | load median | load max | samples > 8 (> 5), of 207 | verdict (both rules) |
   |---|---|---|---|---|---|---|
   | `49314f81` | 6,212.7 | 9,729 | 3.96 | 10.35 | 8 (53) | loaded |
   | `059bad3c` | 6,191.1 | 9,516 | 3.97 | 13.27 | 13 (60) | loaded |
   | `17623c04` | 6,187.9 | 9,517 | 3.51 | 11.74 | 6 (41) | loaded |

   Every median passes the fallback rule; every max fails it. The spans agree within 0.4 %.

2. **The suite makes part of its own load.** `tools/worlds_leak.py` runs four AILANG processes in a
   `ThreadPoolExecutor(max_workers=4)`. Run alone with `gmake worlds-leak` on the quiet rig (main
   `17623c04`, load 2.65 at start, GPU 0, console idle 42 h, no screen sharing), sampled every 15 s:
   379 s, 27 samples, **median 6.26, max 10.86**; the load read 6.86 just after. The independent
   judge re-ran it on a quiet rig with a `ps` sampler: median 5.44, max 8.05, and the `worlds_leak`
   process tree used about 470 % of about 560 % total host CPU (about 84 %). During the nightly runs
   `worlds-leak` peaked at 10.35 (`49314f81`), 11.13 (`059bad3c`) and 7.26 (`17623c04`). So the
   strict rule (`max ≤ 5`) cannot hold for any run that includes `worlds-leak` (both standalone
   medians are above 5), and the fallback's `max ≤ 8` failed in 4 of the 5 runs observed (8.05 to
   11.13; the fifth peaked at 7.26). The other samples over 8 fall in many targets (`strict`, `sim`, `title-screen-test`,
   `ship-demo-launch-test`, `ai-live-guard` and others; `spikes-vs-targets.txt` in the bundle).
   Whether those are the suite's own or the rig's is UNMEASURED.

3. **The after side is unlikely to pass either (reasoning, not measured).** M2's after runs are
   `-j6` and `-j8`. Six lanes that stay busy for a few minutes raise the 1-minute load average by
   about 6 on their own, so a `-j6` run would fail the strict rule (`max ≤ 5`) once its lanes are
   saturated, and the fallback's `median ≤ 5` unless they idle much of the time. No `-j6` run was
   taken.

4. **Every run on main is refused anyway.** All three nightly headers read `rc=2`: main's
   `make test` has been red since 2026-11-13 and 2026-11-17 on two attended targets (row 7as
   `ui-theme-check`, row 7at `basis-gate`, issue #392). `report --load-rule fallback` on the
   unmodified `17623c04` profile prints `failed run …` and exits 1. So a fresh baseline run on main
   would be refused for its rc before the load rule was even read: any baseline needs a green main
   first, or a rule change. This is the strongest reason not to spend a rig slot now.

## Consequence

The 1f baseline cannot be taken as written, on a quiet rig or not, and AC9 is unlikely to pass after M2
even if it were (point 3). Repeating runs "under the same rule" (§1f) would spend 100-minute rig slots on a
verdict that is already known. AC9's own exhaustion rule sends the blockage to Mark: D-173.

The rule's intent (the quorum's round-2 concern: rig noise must not pose as a `-j` effect) is
sound. What it measures, the whole host's load average, counts the run's own processes as noise.

## Re-check commands

```sh
# 1. the report on the nightly profiles (bundle dir n=nightly/<sha>/)
for s in 49314f81 059bad3c 17623c04; do cp nightly/$s*/profile.tsv n$s.tsv; cp nightly/$s*/load.tsv n$s.load.tsv
  sed 's/^rc=.*/rc=0/' nightly/$s*/header.txt > n$s.header.txt; done
sh tools/suite_profile.sh report --load-rule fallback n49314f81.tsv n059bad3c.tsv n17623c04.tsv   # 3 x loaded, rc 1
# 2. worlds-leak alone, sampled
( while :; do printf '%s\t%s\n' "$(date +%s)" "$(sysctl -n vm.loadavg | awk '{print $2}')"; sleep 15; done ) > load.tsv & sp=$!
PATH=$PWD/runtime/bin:$PATH gmake worlds-leak; kill $sp; sort -t$'\t' -k2,2n load.tsv | tail -1
```
