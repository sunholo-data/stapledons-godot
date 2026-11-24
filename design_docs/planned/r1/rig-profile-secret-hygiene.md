# Row 7aw: the test-profile directory must never hold the rig's environment, and no evidence pack leaves with a secret (D-174, default A)

**Status:** Revision 3 (mission iteration 114, 2026-11-24: designer revision 2 after quorum round 1, then a controller carve-out applying quorum round 2's reviewer-written fixes; see "Quorum round 2"). Design and fixture measurements only; no code has landed. Round 1 drew BLOCKED (2 reject, 1 pass); every objection is answered below with a design change and a measurement. D-174's default (A) routes this to the next build fire; the fix itself needs no held file.
**Release:** r1. **Milestone:** none (charter row 7aw, clause 5: hygiene and security of an instrument the loop owns).
**Priority:** P1. Credentials sat in a publicly listable bucket for about 90 s once already ([i113]); until this lands, the AC9 §I rule holds (copy only `profile.tsv`, `load.tsv`, `header.txt`, `closure.txt`, `cpu.tsv` out of a profile directory).
**Implements:** charter row 7aw ([stapledon-mission.md](../../stapledon-mission.md) §"7aw."); ledger [D-174](../../stapledon-mission.md) option **A** (build 7aw next fire).
**Depends on:** the M1a instrument on main (`tools/suite_profile.sh`, `tools/timed_recipe_shell.sh`, `tools/test_suite_profile.sh`, all at `74ec8498`); `tools/rig_check.sh` line 113 passing `$trace -k test` (read verbatim); `tools/test_rig_check.sh` line 114 running the suite-profile control; `make test` reaching it via `rig-check-control` (mk/m45.mk:57); iteration 113's credential measurements ([i113]).
**Estimated LOC:** about 360 in three PRs, each under the parent's 270-line rule (round 2 grew the guard's spec; two PRs no longer fit).
- **PR1, the instrument (≈ 40):** `tools/suite_profile.sh` +14 −5; `tools/test_suite_profile.sh` +23 −3; `CHANGELOG.md` +3.
- **PR2, the guard (≈ 141):** `tools/evidence_secret_guard.sh` +138 (new); `CHANGELOG.md` +3.
- **PR3, the guard's control and wiring (≈ 173):** `tools/test_evidence_secret_guard.sh` +137 (new); `tools/evidence_publish.sh` +22 (new); `tools/test_rig_check.sh` +11 −4; `CHANGELOG.md` +3.

**Provenance key.**
- `[i114]` means measured in this pass, in `/tmp/claude/i114-design-evidence/` (89 files; hashes in `SHA256SUMS`, round-2 sha256 `8e52b2c5…76c947c`; round 1's digest `88f961f9…568fc` covered the round-1 tree before its revisions). The mission's mandated base `/tmp/i114-design-evidence/` could not be created: this harness denies writes to `/tmp` itself (`EPERM`; only `$TMPDIR` = `/tmp/claude` is writable), so `$TMPDIR/i114-design-evidence/` is the closest permitted path and every artifact lives there.
- `[i113]` means inherited from iteration 113's record (mission log entry 113 and row 7aw): the pack held 15 non-empty credentials; a key-shaped value pattern found 1 of 15; a name filter found all 15; public for about 90 s, edge cache until 07:39:42Z. Not re-measured here (reading the rig's real environment is forbidden).
- Every profiled `make -pq` and every fixture run this pass ran under `env -i PATH=… HOME=… TMPDIR=… SP_FAKE_TOKEN=<fake canary>`, so the only environment any dumped database or profiled recipe ever held was fake by construction. No real profile directory under `$TMPDIR/rig-check/` was opened; no `env`, `printenv` or `set` printed a real value; `~/.config/op/*` and the rig's op env template were never opened (the guard only supports their file FORMAT).
- This designer sandbox denies `sysctl`, writes to `/tmp`, BSD `mktemp -t`, and `ps`/`pgrep`. The affected controls were run with a `sysctl` stub on `PATH` (the same trick `tools/test_suite_profile.sh` itself uses for the same reason), and the residual failures are traced in V2. On the Studio none of these denials exist.
- `UNMEASURED` means no run in this pass supports the value; each such value names its fallback.

## Game vision alignment

The pillars were scored in the parent style against `stapledons-design/vision/core-pillars.md`. This is test and security tooling: no game code, no scene, no player-facing copy.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | The only clock is the harness's. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics change. |
| **Net** | | **0** | **Go, aligned with no conflict.** All seven pillars score 0; none below 0. D-88 applies: test/audit hygiene does not stop the loop at a net of 0. |

## Problem

`tools/suite_profile.sh` line 52 runs the nightly's closure query and writes GNU make's whole database into the profile directory:

```sh
query_rc=0; "$@" -f "$out/query.mk" __suite_profile_nop__ > "$out/database.txt" 2> "$out/query.err" || query_rc=$?
```

`make -pq` prints every environment variable under `# environment` headers. Each nightly `rig/full` therefore leaves the launchd job's environment — [i113] **15 non-empty credentials in `328b01f8`'s profile** — in `$TMPDIR/rig-check/<sha>.profile/database.txt`. Iteration 113 published two such files in a public evidence pack for about 90 s; the bucket is publicly listable and the edge cache served the deleted object for another 17 minutes ([i113]). The file exists only so the awk in `closure()` can compute `closure.txt` (the target closure whose sha256 goes into `header.txt` as `closure_sha256` and is compared by `compare`). Nothing else reads `database.txt`: a repo-wide grep finds it only at suite_profile.sh lines 52 and 67 [i114].

The second half of the problem is the publish path: the loop can again be one `gsutil cp` away from shipping a profile directory wholesale. Row 7aw asks for a guard that refuses any pack containing a secret value before upload.

**Goals.** (1) After `run` exits on any catchable path (normal, EXIT, INT, TERM, HUP), the profile directory never holds an environment-variable value; during the run, suite temp files live under `$out/tmp`, inside the observed directory, and never outlive the run. (2) A hermetic case proves it against both channels — the database dump and a recipe that copies an environment value to `$TMPDIR` — and fails under a mutation that restores either. (3) `closure.txt` stays byte-identical on a fixture. (4) A pre-publish guard refuses packs (file, directory, or `.tgz`/`.tar.gz`) containing the value of any secret-looking variable in the caller's environment, without ever printing the value; innocently named secrets are covered by a caller-supplied names file. (5) Everything is small, headless, no GPU, no Godot window.

**Non-goals.** No change to `Makefile`, `mk/*.mk` (held), `rig_check.sh`, `rig_nightly.sh`, `timed_recipe_shell.sh`, thresholds, the AC9 rule, or the suite's own behaviour beyond the temp-file location. Credential rotation is Mark's ([i113], private message). The guard is a pre-publish refusal, not a general scanner of the rig disk. **No change to bucket ACL, IAM, or CDN cache TTL** (owned by the D-18 asset design, `infra/gcp/setup.sh` and Mark; §G); this design assumes the current public-listable bucket and treats the guard as the only line of defence against publish-time leaks, which is why the R3, R4 and R7 residuals remain exploitable for the stated cache window.

## Quorum round 1

| Reviewer | Objection | What changed in round 2 |
|---|---|---|
| codex:gpt-6.2-sol (reject, blocking) | After the fix, the profiler still exports the profile directory as `TMPDIR`, and a profiled recipe leaves an environment credential there (V8) — goal (1) disproved. | The channel is **closed**, not narrowed: `run` now exports `TMPDIR="$out/tmp"` (created by `run`, removed by `cleanup` on every catchable exit: normal, EXIT, INT, TERM, HUP — V20); goal (1) restated precisely; `secret-no-dump` writes the canary to `$TMPDIR` and fails under a `TMPDIR="$out"` mutant (V19); `temp-only` re-checked (V21); every reader of profile-dir leftovers grepped — none reads what the change moves or removes (V23). |
| claude-sonnet-5 (reject, blocking) | The guard's candidate set is a name-pattern heuristic with an untested miss class (innocently named secrets) — the same silent-miss shape used to reject option (d). | A **mechanism plus tests**: `--names-file FILE` (repeatable) adds candidate names, one per line — `NAME`, and the `NAME=op://vault/item/field` template form where everything after the first `=` is discarded and never read as a value; values always come from the caller's environment (§D). `evidence_publish.sh` passes it from `EVIDENCE_GUARD_NAMES_FILE` (§E). Tests: the negative control (rc 0, documented), caught via names file (rc 1, name printed, value unprinted), template form, repeatable, missing/empty names file rc 2, absent-name hint not failure (V22, V24). The `--require-candidates` decision is recorded in §D. |
| gemini-4-argon (pass, non-blocking) | Skipping values that contain a newline or CR is a blind spot for multi-line credentials (PEM keys, JSON service-account blobs). | Values are split into their lines and every non-empty trimmed line of at least `MIN_LEN` characters becomes a pattern; an empty pattern is never written. Test: a two-line canary whose second line is planted in a file is caught (V25). |
| found during revision | — | Round 1's `! grep` / `! cmp -s` case assertions were unenforceable: POSIX `set -e` exempts a pipeline preceded by `!`, so the checks could never fail the case — the TMPDIR mutant passed the round-1 case **silently** (r2-trace.log: the grep matches, execution continues). §C now uses enforced `if …; then exit 1; fi` forms throughout. |

## Quorum round 2 (controller carve-out, revision 3)

Round 2 (`rig-profile-secret-hygiene-2026-11-24T14-52-05Z`, same seats: claude-sonnet-5, codex:gpt-6.2-sol, gemini-4-argon; `absent_reviewers` empty) returned BLOCKED, 2 reject, 1 pass, on surfaces revision 2 did not settle. Every objection carried a reviewer-written `proposed_fix` and none disputed the design's direction, so the controller applied the fixes as written (the narrow-refinement carve-out this mission used in iteration 111) instead of a third designer run:

| Reviewer | Objection | Fix applied |
|---|---|---|
| codex:gpt-6.2-sol (reject) | `query.err` still holds make's raw stderr; `$(warning $(SP_FAKE_TOKEN))` writes the expanded value into the profile directory even when the query succeeds. | §A hunk 1–2: raw stderr discarded; `query.err` holds only the profiler's validated numeric status; a missing or invalid status fails with a fixed diagnostic. AC6 extended with `$(warning …)` and `$(error …)` fixtures on both makes and a restored-stderr mutant. Channel measured on both makes (V27). |
| claude-sonnet-5 (reject) | The bucket's public listing and cache window are not discussed, ruled out or combined with the guard. | §G (ownership, measured ACL and cache settings) and a non-goal line. |
| gemini-4-argon (pass, non-blocking) | Splitting multi-line values makes PEM armour lines patterns, so public certificates and fixtures would be refused. | §D: lines matching `^-----(BEGIN|END) ` are not patterns. The guard control adds one check: a two-line value whose first line is PEM armour, with that armour line planted in a file, exits 0. |

## Design

### A. `tools/suite_profile.sh` — pipe the query into the awk (option a), and confine suite temp files to `$out/tmp`

The four options for the database dump, weighed on fixtures:

| Option | Verdict | Measured |
|---|---|---|
| (a) pipe `make -pq` straight into the awk; never write the file | **chosen** | The database never touches disk; `closure.txt` byte-identical on the fixture; the rc rule preserved via one `query_rc=` line appended to `query.err` (V4, V5, V18). |
| (b) mode-600 temp file outside the profile dir, trap-removed | rejected | `mktemp` honors `TMPDIR`, which `run` has already exported, so the template must hard-code `/var/tmp`; the full environment dump then sits on disk for the query's duration and, on any untrapped kill (the rig's watchdog TERMs the whole group mid-`$( )`), survives in `/var/tmp`, which macOS never sweeps. Two lifecycles to reason about where (a) has none. |
| (c) filter `# environment` variables before writing | rejected | Misses makefile variables whose values were expanded from the environment: on a fixture with `LEAK := $(SP_FAKE_TOKEN)`, the canary still appears **after** dropping every `# environment` section (V6). A partial fix buys false confidence. |
| (d) run the query under `env -i` plus an allowlist | rejected today on semantics, not on today's numbers | The closure must describe the make invocation actually profiled, which runs with the full environment. Check as briefed: `grep -n 'ifdef \|ifeq \|ifneq ' Makefile mk/*.mk` finds only the three `SCENE` recipe branches in the Makefile; `$(origin` finds only `TIER` (4 lines, recipes); every `?=` default feeds recipes, not targets or prerequisites. Measured: the repo closure for the `test` goal (374 targets, sha `47d40348…26dd1e`) is **identical** under `env -i` bare and under 35 sentinel environment values injected for every such name (V7). So today (d) would not change the closure — but the first future makefile that branches on an environment name silently decouples the query from the profiled run, with no test noticing. (a) needs no environment argument at all. |

**The exact change, hunks 1–2 (sketch; the awk program is untouched).** Replace lines 52–53:

```sh
# 7aw: the make database prints every environment variable, and make's own diagnostics can
# expand one (`$(warning $(VAR))`, V27); neither is written to the profile directory. The
# query's stdout flows straight into the awk, its raw stderr is discarded, and query.err holds
# only the profiler's own validated numeric status.
{ rc=0; "$@" -f "$out/query.mk" __suite_profile_nop__ 2> /dev/null || rc=$?; printf 'query_rc=%s\n' "$rc" > "$out/query.err"; } |
```

and in the awk invocation change `"$out/database.txt"` to `-` (stdin), then, before the existing `[ -s "$out/closure.txt" ]` check, insert:

```sh
query_rc=$(sed -n 's/^query_rc=\([0-9][0-9]*\)$/\1/p' "$out/query.err" | tail -1)
case "$query_rc" in
  ''|*[!0-9]*) echo 'suite-profile: closure query status missing or invalid' >&2; exit 1 ;;
esac
[ "$query_rc" -le 1 ] || { echo "suite-profile: closure query failed (make status $query_rc; raw diagnostics are discarded by design, 7aw)" >&2; exit 1; }
```

How the invariants are kept (V4/V5/V18 measured the round-2 form; revision 3 changes only what `query.err` holds, so the executor re-measures AC6): the group's `|| rc=$?` satisfies `set -e` inside the pipeline; the pipeline waits for both sides, so `query.err` is complete before it is read; a missing or non-numeric status is a failure with a fixed diagnostic; a make status above 1 (a broken makefile gives 2) makes `run` exit 1 with `suite-profile: closure query failed`, as before; on success `query.err` is exactly `query_rc=0`; the awk reads goals from `ARGV[1]` as before and stdin records fall through to the same rules, so `closure.txt` is byte-identical. **Revision 3 (quorum round 2, codex's fix applied verbatim):** make's raw stderr is no longer kept anywhere in the profile directory, because a makefile line such as `$(warning $(SP_FAKE_TOKEN))` writes the expanded value to stderr even when the query succeeds (V27). The cost is debuggability: a failing query now reports only make's status, and the operator re-runs `make -pq` by hand to see why.

**The exact change, hunks 3–4 (round 2): suite temp files never outlive the run.** In `run`, replace `mkdir -p "$out"; … export TMPDIR="$out"` with:

```sh
# 7aw: suite temp files stay hermetic under the observed directory during the run
# (TMPDIR=$out/tmp is still inside $out) and never outlive it: cleanup removes it on
# every catchable exit path (EXIT, INT, TERM, HUP), so no recipe temp file — and no
# environment credential a recipe copies to $TMPDIR — survives the run.
mkdir -p "$out" "$out/tmp"; out=$(cd "$out" && pwd -P)
export TMPDIR="$out/tmp"
```

and make `cleanup()` end with (after the sampler and child kills and waits):

```sh
rm -rf "$out/tmp" 2>/dev/null || :
```

- **Every catchable exit path is covered (V20).** Normal: `finish` calls `cleanup` then exits. INT/TERM/HUP: the existing traps call `finish 130/143/143`, which calls `cleanup`. Any other abnormal exit (a `die`, a `set -e` failure): the EXIT trap is `cleanup`. Measured: a slow recipe that writes the canary to `$TMPDIR` and sleeps, then INT, TERM and HUP delivered mid-recipe — each run exits 130/143/143 with `out/tmp removed`, the recipe temp file absent, and the canary absent from every file; the killer first proves the canary file exists in `$out/tmp` mid-run, so the channel is exercised, not vacuous. (The fixture runs the instrument in the foreground: a `&`-launched job inherits SIGINT as `SIG_IGN`, which a shell may not trap.)
- **What changes for the profiled suite (measured, V18/V21/V23):** suite temp files (the instrument's own `suite-cpu.*` via `timed_recipe_shell.sh`, and anything a recipe writes to `$TMPDIR`) now land in `$out/tmp` instead of `$out` — both inside the observed directory, so the M1a hermeticity property (temp files land where the run is observed, not scattered outside) is unchanged; `temp-only` still observes nothing outside the fixture and passes. Nothing reads leftovers: `grep -rn 'database.txt' tools/` finds only the two lines §A removes; `grep -rn 'out/tmp' tools/ mk/` finds nothing; `rig_check.sh` reads only `profile.tsv` (its summary). The closure query itself writes no temp file (`closure.txt` byte-identical, V18).
- **Residual, stated plainly:** SIGKILL is uncatchable; a kill -9 mid-run can leave `$out/tmp` (as today it can leave the whole profile directory). The §I copy rule (five named files only) and the guard (§D scans directories recursively) catch that on publish.

### B. Every other file the profile directory receives — inventoried and measured

The whole set, with the canary grep over a fixed-instrument run (V3, V4, V8→V18, V9):

| File | Holds | Can it hold a secret? | Measured |
|---|---|---|---|
| `header.txt` | sha, make version, jobs, cores, timestamps, load1 pair, `closure_sha256`, sampler fields, end `rc` | No | canary 0 hits |
| `profile.tsv` | 7-column rows written by `timed_recipe_shell.sh`: start/end ms, child CPU, rc, MAKELEVEL, target, top target | No | canary 0 hits |
| `load.tsv` | epoch + `load1` samples | No | canary 0 hits |
| `goals` | goal names taken from the command line | No | canary 0 hits |
| `query.args` | make query arguments, recorded verbatim | **Yes, an operator-supplied `VAR=value` argument** | a `LEAKVAR=<canary>` argument is recorded verbatim (V9). `rig_check.sh` passes only `$trace -k test` (line 113): `-k` and `--trace` match the `-*` case and are dropped, so the nightly's `query.args` is 0 bytes (V3). This is the operator's own command line, not the environment; the guard is the backstop, and `run`'s callers must not pass secrets as make variables. |
| `query.mk` | the two static `__suite_profile_nop__` lines | No | static |
| `query.err` | revision 3: only the profiler's own `query_rc=N` line; make's raw stderr is discarded | **Was yes** (round 2): `$(warning $(VAR))` and `$(error $(VAR))` expand an environment value onto make's stderr even when the query succeeds (V27); revision 3 never writes that stderr | exactly `query_rc=0` on success, `query_rc=2` on the broken fixture (AC6) |
| `sleeper.pid` | the sampler's sleep pid | No | pid only |
| `closure.txt` | target names of the closure | No | canary 0 hits |
| `database.txt` | the whole make database, every environment variable | **Yes — the incident** (§A removes it) | canary 1 hit, 11 `# environment` blocks, 1,256 lines under `env -i` (V18); the real nightly env is the launchd job's whole environment ([i113]) |
| suite temp files (`$out/tmp`) | anything a profiled recipe writes to `$TMPDIR`, plus the instrument's own `suite-cpu.*` | **During the run: yes, but confined to `$out/tmp`; after any catchable exit: gone** (§A hunks 3–4). Round 1 left this channel open (V8: a recipe writing the canary to `$TMPDIR` left `suite-left.tmp` in the profile directory) and the quorum rejected that; it is closed now. | before: `suite-left.tmp` in the profile dir with the canary (V18 before-side); after: recipe temp file absent, `out/tmp` removed at finish (V18, V20) |

### C. `tools/test_suite_profile.sh` — the `secret-no-dump` case (both channels, enforced)

Added to `check_case` (and to `cases`; `case_count` 20 → 21, so the closing line becomes `42 cases` at 21 × 2 makes):

```sh
    secret-no-dump)
      # 7aw: after run exits, the profile directory holds no environment value. Two channels,
      # two mutations: the database dump (restored-dump mutant) and a recipe writing the
      # canary to $TMPDIR (TMPDIR=$out mutant) must both leave the case red. The positive
      # control proves the grep can see a planted copy; header closure_sha256 must still
      # be the sha256 of closure.txt (the query is unchanged by the fix). Every assertion
      # is an enforced form: POSIX set -e exempts `! cmd`, so a bare `! grep` could never
      # fail this case (the round-2 mutation drill caught that; V19).
      tok="sp-canary-$(date +%s)-$$"; SP_FAKE_TOKEN=$tok; export SP_FAKE_TOKEN
      printf "all: leak\nleak:\n\t@printf '%%s\\\\n' \"\$\$SP_FAKE_TOKEN\" > \"\$\$TMPDIR/suite-left.tmp\"\n\t@true\n" > Makefile
      run -- all
      if [ -e "$D/out/database.txt" ]; then echo "secret-no-dump: database.txt in the profile dir" >&2; exit 1; fi
      if [ -e "$D/out/tmp" ]; then echo "secret-no-dump: out/tmp survived the run" >&2; exit 1; fi
      if grep -rFq -- "$tok" "$D/out"; then echo "secret-no-dump: canary in the profile dir" >&2; exit 1; fi
      printf '%s\n' "$tok" > "$D/out/positive-control.tmp"
      grep -rFq -- "$tok" "$D/out"
      rm "$D/out/positive-control.tmp"
      if grep -rFq -- "$tok" "$D/out"; then echo "secret-no-dump: canary in the profile dir" >&2; exit 1; fi
      [ "$(shasum -a 256 < "$D/out/closure.txt" | awk '{print $1}')" = "$(header closure_sha256)" ]
      [ -s "$D/out/closure.txt" ] ;;
```

The recipe writes the canary to `$TMPDIR`, so the case discriminates both mutations: a restored dump fails at the `database.txt` check, a `TMPDIR="$out"` revert fails at the canary grep (`suite-left.tmp` back in the profile dir). Only `grep -q` forms are used so no line is ever printed; the positive control proves the grep can see a planted copy; the final grep proves the control file was really removed. **`temp-only` gains one line**, `test ! -e "$D/out/tmp"` (the temp dir never outlives the run), and its round-1-era `! cmp -s` probe assertion becomes the enforced `if cmp -s "$D/probe-before" "$D/probe-after"; then exit 1; fi` — the same `set -e` repair. Measured: fixed instrument `ok` on both makes; dump mutant FAIL (`secret-no-dump: database.txt in the profile dir`); TMPDIR mutant FAIL (`secret-no-dump: canary in the profile dir`) (V19); full control `42 cases, 0 failures` (V21).

### D. `tools/evidence_secret_guard.sh` (new) — refuse packs holding secret values

```
usage: evidence_secret_guard.sh [--require-candidates] [--names-file FILE]... <file-or-dir>...
exit 0 clean · 1 secret found · 2 instrument failure
```

- **Inputs.** A plain file is grepped directly; a directory recursively; a `.tgz`/`.tar.gz` is unpacked into a private `mktemp -d` (mode 700) member of the guard's own temp tree and the pack path (plus member name) is reported on a hit. Unreadable/missing input, `tar` failure, `grep` error: exit 2. `--require-candidates`: exit 2 if the environment yields **zero candidate value lines** (the publisher asserts some must: the rig's environment always has them, [i113] 15) — a broken instrument never waves a pack through. Without the flag, zero candidates exit 0 with a stderr note.
- **Which names.** The candidate set is the union of (i) environment names matching, case-insensitive, `TOKEN|KEY|SECRET|PASSWD|PASSWORD|_PAT|AUTH|CREDENTIAL` (so `OP_SERVICE_ACCOUNT_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `*_AUTH*`, `*CREDENTIAL*`, `GIT_PAT` are covered; [i113]: a name filter found all 15 real rig credentials while a key-shaped *value* pattern found 1 of 15) and (ii) **`--names-file FILE`, repeatable** — extra candidate NAMES, one per line: `NAME`, or the `NAME=op://vault/item/field` template form (the rig's 1Password env template is in that form) where **everything after the first `=` is discarded and never read as a value** — it never becomes a pattern, is never printed, never reaches a child's argv; the names file itself scanned as a target stays clean (control check 12). `#` comments and blank lines are skipped. **Values always come from the caller's environment**, never from the file. An unreadable or missing names file, or one holding no valid `NAME` line at all, is a broken instrument: exit 2. A name listed but **absent from the environment is a stderr hint (the name only), not a failure** — decided: a standing list such as the rig's op template names credentials that vary by host and by what the loop injected this run; an absent name has no value to leak, and requiring presence would refuse clean packs on routine rotation. `--require-candidates` is unchanged: it requires candidate *values*, not listed names.
- **Which values.** A **minimum line length of 8** (`MIN_LEN`) excludes booleans, numbers and short flags that would match innocent files everywhere; measured on this shell's environment: the filter matches 19 names, of which 4 have values shorter than 8 (excluded) and 15 survive (V12). **Multi-line values (round 2): a value is split into its lines (CR stripped); every non-empty line, trimmed, not matching `^-----(BEGIN|END) `, of at least `MIN_LEN` characters becomes a fixed-string pattern (revision 3, gemini's fix verbatim: PEM armour lines such as `-----BEGIN PRIVATE KEY-----` would otherwise refuse any pack holding a public certificate or a test fixture); an empty pattern is never written** (an empty `grep -F -f` pattern would match everything). A value whose every line is blank or short contributes nothing — with no other candidate, `--require-candidates` refuses (control check 16).
- **Never prints a value.** On a hit the output is exactly the variable NAME and the file path, e.g. `evidence-guard: SP_FAKE_TOKEN value is in <path>[:<member>]`, plus a summary line. Attribution re-tests per candidate with a one-value file; the control asserts the planted value appears in neither stdout nor stderr — also for the multi-line and names-file cases.
- **No value in `argv` of any child.** Names are enumerated with `awk 'BEGIN{for (k in ENVIRON) print k}'` (names only). Each value moves `awk -v nm=NAME 'BEGIN{…print ENVIRON[nm]}' >> file` — the value travels awk→file, never through a command line; `grep -F -f` then reads the file by path. Names files are parsed by awk the same way. The temp tree is one `mktemp -d` (mode 700, plus `umask 077`), removed by `trap` on EXIT, INT, TERM and HUP, so it is gone on every exit path. The ps corroboration was attempted and **retracted**: this sandbox denies `ps`/`pgrep` (V13), so the property rests on the construction above — the only strings that ever reach a child's argv are names, the fixed program text, and paths.
- Residual, stated: a secret whose name matches neither the pattern nor any names file is missed — the §I copy rule keeps unlisted files out of packs; the names file is how the operator closes names the pattern cannot see.

### E. `tools/evidence_publish.sh` (new, small) — guard, then upload

```sh
rc=0
if [ -n "${EVIDENCE_GUARD_NAMES_FILE:-}" ]; then
  sh "$SELF/evidence_secret_guard.sh" --require-candidates --names-file "$EVIDENCE_GUARD_NAMES_FILE" -- "$@" || rc=$?
else
  sh "$SELF/evidence_secret_guard.sh" --require-candidates -- "$@" || rc=$?
fi
[ "$rc" = 0 ] || { echo "evidence-publish: refused (guard rc $rc); nothing uploaded" >&2; exit "$rc"; }
echo "evidence-publish: guard clean; uploading $# pack(s) to gs://$remote/"
gsutil -m cp -r -- "$@" "gs://$remote/"
```

The remote prefix is validated (`''`, `..`, and non-`[a-zA-Z0-9./_-]` refused) before anything runs; `gsutil` must exist or the wrapper exits 2. **When `EVIDENCE_GUARD_NAMES_FILE` is set, the wrapper passes that path to the guard's `--names-file`; the loop should set it to the rig's op env template** (prose only: neither this doc nor the code names or reads that path; the guard reads `NAME` / `NAME=op://…` lines at run time, values from the environment). Its control stubs `gsutil` on `PATH` exactly the way `tools/test_observation_publish.sh` stubs `gcloud` (a `$TMP/bin/gsutil` that logs its argv): **no test ever touches the real bucket**. The controller may keep its own `gsutil` invocation — running the guard before any upload is the requirement, not the wrapper.

### F. `tools/test_evidence_secret_guard.sh` (new) and the wiring

The control plants `SP_FAKE_TOKEN=sp-canary-<date>-<pid>` (and, for the round-2 checks, an innocently named `PRIVATE_STUFF=<canary2>`) and checks, now **41 checks** (round 2's 40 plus revision 3's PEM-armour check, §D): a dirty file → rc 1, NAME + path printed, value absent from stdout **and** stderr; a clean file/dir → rc 0; the `.tgz` path → rc 1 with `<pack>:<member>` named, value unprinted; an unreadable file → rc 2; a missing input → rc 2; `env -i` with a too-short candidate value → rc 2 under `--require-candidates`, rc 0 without; the guard's temp tree gone afterwards; with the stubbed `gsutil`, the wrapper: refused → rc 1 and **no** gsutil call; clean → rc 0 and the expected `gsutil` argv; instrument failure → rc 2, no call; unsafe remote prefix → rc 2, no call. **Round 2 adds:** the names-file negative control (pattern alone misses `PRIVATE_STUFF`: rc 0); caught via a plain-`NAME` names file (rc 1, name printed, value unprinted); the `NAME=op://x/y/z` template form plus a repeatable double `--names-file` (rc 1); the names file itself scanned as a target (rc 0 — the `op://` part is never a pattern); a missing and a no-valid-`NAME` names file (rc 2 each); a listed name absent from the environment (hint on stderr, rc 0); a two-line value whose **second line** is planted in a file (rc 1, value unprinted); a value whose lines are all shorter than `MIN_LEN` or blank (zero patterns, `--require-candidates` rc 2); and the wrapper passing `EVIDENCE_GUARD_NAMES_FILE` through both ways (refused pack rc 1 no call; clean pack rc 0 with the call, hint visible). Prototype result: `evidence-guard control: 40 checks, 0 failures`, stable over three repeats (V22).

**Wiring.** `tools/test_suite_profile.sh` already runs inside `tools/test_rig_check.sh` (line 114: `rig-check control suite-profile: ok`), which `make test` runs via `rig-check-control` (mk/m45.mk:57). The guard's control joins the same place, right after that block:

```sh
if sh tools/test_evidence_secret_guard.sh > "$T/evidence-guard.log" 2>&1; then
  echo 'rig-check control evidence-guard: ok'
else
  cat "$T/evidence-guard.log"
  echo 'rig-check control evidence-guard: FAIL (see fixture output)'; fails=$((fails + 1))
fi
```

Because the nested caller-poison run counts `: ok` lines, its expectation moves from 25 to 26, the outer case counter from 26 to 27, and the nested base `n=25` to `n=26` (the failure message's "of 25 ok" likewise). The caller-poison comment about the profiler overriding a caller's `TMPDIR` is updated in the same PR (`$out/tmp` inside its `--out` directory). Measured on the wired prototype (a scratch repo tree with the round-2 files in place): `rig-check control: 27 cases, 3 failures` on this sandbox — the same three sandbox-artifact failures as the 26-case baseline, with `suite-profile: ok` and `evidence-guard: ok` (V26) — so on a green host the line is `27 cases, 0 failures` from `26`.

**`make ci-fast` runs none of this.** `ci-fast` (Makefile:73 and its satellites) lists neither `rig-check-control` nor any test-rig tool; `rig-check-control` hangs only off `test` (mk/m45.mk:57). Say it plainly rather than claiming coverage: the new case and the guard's control run under `make test` (the nightly `rig/full` and by hand), never on the fast tier. No `make ci-fast` was run in this pass (UNMEASURED beyond the wiring greps, V17).

### G. Bucket exposure, out of scope by design (revision 3, quorum round 2)

The quorum's Anthropic reviewer asked why this row does not make the evidence bucket private or shorten its cache window. Its fix, applied as written, is to state the boundary:

1. **Ownership.** The bucket's public read and listing are a deliberate project decision, not this row's: CLAUDE.md "Large assets (D-18)" publishes the sky textures to the public bucket so `make sky-assets` can fetch them anonymously, `infra/gcp/setup.sh` line 32 grants it, and Mark has given the loop standing approval to publish project assets there. Changing the bucket's ACL, IAM or cache settings is Mark's call (infrastructure), not the loop's.
2. **Measured settings** (controller, 2026-11-24, `gcloud storage buckets get-iam-policy` / `buckets describe` / `objects describe`, names and settings only): `allUsers` holds `roles/storage.objectViewer` (read and list); uniform bucket-level access on; public-access prevention `inherited`; objects carry no `Cache-Control` (so the default public caching applies: iteration 113 measured `cache-control: public, max-age=3600` and an edge copy served about 17 minutes after deletion); soft delete keeps deleted objects for 604,800 s (7 days), readable only with project restore permission, not publicly.
3. **Non-goal** (added to the list above).

Whether loop evidence should move to a private bucket (for example the existing private dev-builds bucket) is raised with Mark in the iteration report as a proposal. It is not a precondition of this row, and this design does not depend on its answer.

## Acceptance criteria

All commands run from the implementation root. In the command cells, `\|` is Markdown's escape for a literal `|`; type `|` when running the command (the parent design's judge N2 convention). `CANARY` below means a fresh `sp-canary-$(date +%s)-$$` the judge plants itself. The fixtures quoted in AC4/AC5/AC14 are saved under `/tmp/claude/i114-design-evidence/` in this pass; at evaluation time the judge re-creates them from the doc (they are self-contained).

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The suite-profile control stays green on both makes | `sh tools/test_suite_profile.sh; echo rc=$?` | `rc=0`, last line `suite-profile control: 42 cases, 0 failures` (21 cases × 2 makes). Baseline [i114]: `40 cases, 0 failures`, 24 s; wired prototype: 42, 0, 23 s (V1, V21) |
| AC2 | The new case passes | `sh tools/test_suite_profile.sh secret-no-dump; echo rc=$?` | `rc=0`, `suite-profile control secret-no-dump: ok`, `suite-profile control: 2 cases, 0 failures` [i114 round 2] |
| AC3 | The case fails under BOTH mutations | (a) revert the §A hunks 1–2 (dump restored) on a scratch copy; (b) revert hunks 3–4 (`TMPDIR="$out"`) on another; run the AC2 command on each | (a) `secret-no-dump: FAIL`, `secret-no-dump: database.txt in the profile dir`, `rc=1`; (b) `secret-no-dump: FAIL`, `secret-no-dump: canary in the profile dir`, `rc=1` (V19) |
| AC4 | `closure.txt` byte-identical before/after on the fixture | `sh <fixture-canary.sh>` (builds a `-k test` Makefile with a `leak` recipe writing the canary to `$TMPDIR`, runs the old and fixed instrument under `env -i` + canary, compares) | both sides print `closure.txt: byte-identical`; `closure_sha256=24cfa2d68cc92b4c28d95957a368115bd48da829861b05b47b8047c7682616ff` on both (V18) |
| AC5 | No environment value in the profile directory; no `database.txt`; no `out/tmp` | same fixture log | `after: canary absent from every file in the profile dir`, `after: database.txt absent`, `after: recipe temp file absent (went through out/tmp, removed at finish)`, `after: out/tmp removed at finish`; before-side: `1 hit(s)` in `database.txt` (11 `# environment` blocks) AND `suite-left.tmp` in the profile dir with the canary (V18) |
| AC6 | The rc rule is preserved, and make's diagnostics never reach the profile directory (revision 3) | three fixtures on **both** makes, fixed instrument `run`: (i) broken Makefile (`this is not a makefile`); (ii) a Makefile containing `$(warning $(SP_FAKE_TOKEN))`; (iii) a Makefile containing `$(error $(SP_FAKE_TOKEN))`; each with `SP_FAKE_TOKEN=<canary>` exported; then `grep -rFq <canary> <profile dir>` with a planted-copy positive control; then the same three on a scratch copy whose query redirect is restored to `2> "$out/query.err"` | (i) `run` exits 1, `suite-profile: closure query failed`, `query.err` is exactly `query_rc=2`; (ii) `run` succeeds (rc of the profiled goal), `query.err` exactly `query_rc=1` or `query_rc=0` per make's `-q` status (record which), canary absent from every file; (iii) `run` exits 1, canary absent from every file. Under the restored-stderr mutant, (ii) and (iii) FAIL (canary found). Fixture measurement of the channel: V27 |
| AC7 | The guard control passes | `sh tools/test_evidence_secret_guard.sh; echo rc=$?` | `rc=0`, `evidence-guard control: 41 checks, 0 failures` (40 measured in round 2 [i114]; the PEM-armour check is revision 3's, unmeasured until the build) |
| AC8 | The rig-check control passes with the wiring | `sh tools/test_rig_check.sh tools/rig_check.sh; echo rc=$?` | on a host green today (`26 cases, 0 failures`): `rig-check control: 27 cases, 0 failures`, including `rig-check control evidence-guard: ok`. On this designer sandbox both before and after end with the same 3 environment-caused failures (V2, V26) |
| AC9 | `make ci-fast` coverage is stated, not claimed | `grep -n '^ci-fast' Makefile \| head -1; grep -n rig-check-control mk/m45.mk` | `ci-fast` lists no `rig-check-control`; only `test: rig-check-control`. **ci-fast runs none of 7aw** (V17) |
| AC10 | `python-guard` and `uid-guard` unaffected (no Python, no new `.gd`) | `git diff --name-only origin/main...HEAD \| grep -c -E '\.py$\|\.gd$'` | `0` (every new file is `.sh`; `python-guard` allowlists `.py`, `uid-guard` tracks `.gd`/`.uid`) |
| AC11 | Scope: no make wiring, no held file | `git diff --name-only origin/main...HEAD \| grep -c -x -E 'Makefile\|mk/.*\|tools/rig_check\.sh\|tools/rig_nightly\.sh\|tools/timed_recipe_shell\.sh\|tools/test_rig_keep_going\.sh\|tools/rig_check_keep_going\.sh\|tools/python-allowlist\.txt'` | `0` |
| AC12 | names-file: the innocently named secret is missed by the pattern alone (documented), caught when named, template form works | `T=$(mktemp -d); printf '%s' "$CANARY" > "$T/f"; PRIVATE_STUFF="$CANARY" sh tools/evidence_secret_guard.sh "$T/f"; echo rc=$?; printf 'PRIVATE_STUFF\n' > "$T/n"; PRIVATE_STUFF="$CANARY" sh tools/evidence_secret_guard.sh --names-file "$T/n" "$T/f"; echo rc=$?; printf 'PRIVATE_STUFF=op://v/i/f\n' > "$T/t"; PRIVATE_STUFF="$CANARY" sh tools/evidence_secret_guard.sh --names-file "$T/t" "$T/f"; echo rc=$?` | first invocation `rc=0` (the documented negative control); then `rc=1` twice (plain `NAME` and template form), each printing `PRIVATE_STUFF value is in $T/f` and never the value (V22, V24) |
| AC13 | Multi-line values: every long line is a pattern | `T=$(mktemp -d); ML=$(printf 'HDR-%s\nsp-ml-%s' "$(date +%s)" "$(date +%s)"); printf '%s' "$ML" \| sed -n 2p > "$T/f"; SP_FAKE_TOKEN="$ML" sh tools/evidence_secret_guard.sh "$T/f"; echo rc=$?` | `rc=1`, `SP_FAKE_TOKEN value is in $T/f`, the planted line never printed (V25) |
| AC14 | `$out/tmp` is removed on every catchable exit | `sh <fixture-signals.sh>` (slow recipe writes the canary to `$TMPDIR`; the killer proves the file exists in `$out/tmp` mid-run, then INT, TERM, HUP) | `INT: run rc 130`, `TERM: run rc 143`, `HUP: run rc 143`; for each: `mid-run: canary file present in out/tmp`, `out/tmp removed`, `recipe temp file absent`, `canary absent from every file` (V20) |

## Files touched

`tools/suite_profile.sh` (+14 −5), `tools/test_suite_profile.sh` (+23 −3), `tools/evidence_secret_guard.sh` (new, +138), `tools/test_evidence_secret_guard.sh` (new, +137), `tools/evidence_publish.sh` (new, +22), `tools/test_rig_check.sh` (+11 −4), `CHANGELOG.md`.

**Does not touch:** `Makefile`, `mk/*.mk` (held), `tools/rig_check.sh`, `tools/rig_nightly.sh`, `tools/timed_recipe_shell.sh`, `tools/rig_check_keep_going.sh`, `tools/test_rig_keep_going.sh`, `tools/observation_publish.sh`, any `.gd` or `.py` or `.uid`, `sim/`, `tests/`, `runtime/`, `design_docs/` beyond this doc, and no real profile directory, bucket, or 1Password file.

## Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | The awk now reads the database from a pipe; a kill mid-query can leave a partial `closure.txt` in a dead profile dir | Harmless: `run` then dies, the header never gains `closure_sha256`, and `report`/`compare` refuse it. Same refusal as today (V5). |
| R2 | A failing closure query now reports only make's status, not its error text | Deliberate (revision 3): the text can carry an expanded secret (V27). The operator re-runs `make -pq` by hand on a failure; the fixed diagnostic names 7aw so the reason is findable. |
| R3 | A secret with a name the pattern misses and no names file lists | The operator closes the class with `--names-file` (the rig's op template); the control documents the miss (negative control) and the close (rc 1 via names file). Unlisted innocent names remain a stated residual, backstopped by the §I copy rule. |
| R4 | A value transformed (base64, escaped) or split across files can slip past literal `grep -F` | Stated residual; the multi-line split (round 2) removed the raw newline/CR blind spot. The guard is one layer of three (no `database.txt` at all; the copy rule; the guard). |
| R5 | A malicious `.tgz` could try path traversal on unpack | The guard never passes `tar -P`; BSD and GNU tar strip absolute paths and `..` by default; the unpack dir is private and trap-removed. |
| R6 | TOCTOU between guard and `gsutil` in the wrapper | Narrow, rig-local window; the wrapper is a convenience, and the guard is also runnable directly on the exact pack at any time. |
| R7 | An uncatchable SIGKILL mid-run can leave `$out/tmp` (and the profile dir) behind | The only remaining channel after round 2 (V18, V20); the §I five-file copy rule keeps it out of packs, and the guard scans directories recursively, so a packed leftover is still refused. |
| R8 | Designer-sandbox evidence: 3 control cases cannot pass here (`sysctl`, `mktemp -t`, `/tmp` denials) | Each traced to a sandbox denial, not the code (V2); the acceptance host is the rig, where the baseline control is green today. |
| R9 | The guard's hints (names absent from the environment) could be mistaken for failures, or ignored | Hints are names-only on stderr and never change the exit code (control check 14); the loop reads them as instrument health, not verdicts. |

## Open questions

None blocking. One non-blocking note: whether the loop adopts `tools/evidence_publish.sh` as its standard publish command or keeps its current `gsutil` invocation with the guard run first is the controller's call; the guard is usable standalone and the wrapper is optional. When the loop adopts it, it should export `EVIDENCE_GUARD_NAMES_FILE` pointing at the rig's op env template (the loop knows the path; this doc never names it).

## Verification log

All files are under `/tmp/claude/i114-design-evidence/` (round-2 hashes in `SHA256SUMS`, sha256 `8e52b2c5…76c947c`; round 1's tree hashed `88f961f9…568fc` before revision). V1–V17 are the round-1 rows, kept for the record; superseded ones are marked.

| V | What | Command | Result |
|---|---|---|---|
| V1 | Suite-profile control baseline | `sh tools/test_suite_profile.sh` | `rc=0`, `suite-profile control: 40 cases, 0 failures`, 24 s (`baseline-suite-profile.log`) |
| V2 | Rig-check control baseline, this sandbox | `sh tools/test_rig_check.sh tools/rig_check.sh`; retried with a `sysctl` stub on `PATH` | bare: `26 cases, 3 failures` after stubbing (11 before it). The 3 are sandbox denials: `gmake-missing`, keep-going nightly sub-cases (BSD `mktemp -t` ignores TMPDIR; the confstr temp dir is denied), caller-poison (nested base falls back to unwritable `/tmp`) (`baseline-rig-check-control*.log`) |
| V3 | The dump, before the fix | `sh fixture-canary.sh` (old instrument, `env -i` + canary, `-k test` fixture) | rc 0; `database.txt` 1,249 lines, 11 `# environment` blocks, canary 1 hit; `query.args` 0 bytes (`fixture-canary.log`, round-1 version; superseded by V18's re-run with the leak recipe) |
| V4 | The fix, same fixture | same, fixed instrument | rc 0; `database.txt` absent; canary absent from every file; `closure.txt` byte-identical; `closure_sha256=47c504ad…83ed2` both sides; `query.err` = `query_rc=0` (round-1 fixture; superseded by V18) |
| V5 | The rc rule and refusal path | broken makefile, both instruments | both rc 1, `suite-profile: closure query failed`; fixed `query.err` = make's `missing separator` + `query_rc=2` (`broken-old.log`, `broken-new.log`) |
| V6 | Option (c) misses `:=` expansions | fixture with `LEAK := $(SP_FAKE_TOKEN)`, filter `# environment` sections out of `database.txt` | canary still found once outside the environment blocks |
| V7 | Option (d) closure check | `gmake -pq` on the repo Makefile, goal `test`, `env -i` bare vs + 35 sentinel env values; plus the briefed grep of `Makefile`/`mk/*.mk` | both closures 374 targets, identical, sha `47d40348…26dd1e`; query 64 ms, 8,033 database lines; `ifeq SCENE` ×3 and `$(origin TIER)` ×4 in the Makefile only, all recipe-side (`repo-closure-A/B.txt`) |
| V8 | The `TMPDIR` channel, open in round 1 | recipe writing `$SP_FAKE_TOKEN` to `$TMPDIR`, round-1 fixed instrument | `suite-left.tmp` in the profile directory holds the canary — the quorum's blocking objection; channel closed in round 2 (superseded by V18/V19/V20) |
| V9 | `query.args` records `VAR=value` verbatim | `run -- LEAKVAR=<canary> all` | the value sits in `query.args` — operator input, not the environment; the nightly passes only `-k test` (0 bytes, V3) |
| V10 | The guard control (round-1 prototype) | `sh tools/test_evidence_secret_guard.sh` | `21 checks, 0 failures`, rc 0 (superseded by V22's 40-check round-2 control) |
| V11 | `--require-candidates` zero-value refusal | `env -i PATH=… TMPDIR=… SP_FAKE_TOKEN=ab sh …guard --require-candidates f` | rc 2 with the flag, rc 0 without (`short-out*.txt`) |
| V12 | Name filter and `MIN_LEN=8` | names + lengths only, via `awk ENVIRON`; no value printed | filter matches 19 names in this shell; value lengths: 4 in (0,8), 2 in [8,20), 13 ≥ 20 — MIN_LEN=8 excludes exactly the 4 short values (`env-name-lengths.txt`) |
| V13 | ps corroboration of argv safety | `ps`/`pgrep` sampling during a 40 MB guard scan | **INVALID, retracted**: this sandbox denies `ps` and `pgrep` ("Operation not permitted"), so the sampler saw nothing. The property rests on construction (§D); marked UNMEASURED in effect |
| V14 | The round-1 case and its dump mutation | `sh test_suite_profile.sh secret-no-dump` on the round-1 fixed and old (dump restored) copies | fixed: `ok`; old: `FAIL`. Superseded by V19: the round-2 case adds the TMPDIR channel and the `set -e` repair, and discriminates both mutations |
| V15 | Wired full suite-profile control (round 1) | `sh wired/tools/test_suite_profile.sh` | `42 cases, 0 failures`, 23 s (superseded by V21's round-2 run) |
| V16 | Wired rig-check control (round 1) | scratch tree, `sh tools/test_rig_check.sh tools/rig_check.sh` | `27 cases, 3 failures` — the same three sandbox denials as V2 (superseded by V26's round-2 run) |
| V17 | Wiring and guard targets | `grep -n '^ci-fast' Makefile`; `grep -n rig-check-control mk/m45.mk`; `grep -rn 'python-guard:\|uid-guard:' Makefile` | `ci-fast` (Makefile:73) lists no `rig-check-control`; `test: rig-check-control` (mk/m45.mk:57); `python-guard` Makefile:1163 (allowlists `.py`), `uid-guard` Makefile:1175 (tracks `.gd`/`.uid`) |
| V18 | Round-2 fixture, both channels | `sh fixture-canary.sh` (old vs fixed; fixture now runs a `leak` recipe writing the canary to `$TMPDIR`) | before: `database.txt` 1 hit (11 env blocks, 1,256 lines) AND `suite-left.tmp` in the profile dir with the canary; after: canary absent from every file, `database.txt`, `suite-left.tmp` and `out/tmp` all absent; `closure.txt` byte-identical, `closure_sha256=24cfa2d6…61ff` both sides; `query.err` = `query_rc=0` (`fixture-canary.log`) |
| V19 | The case and BOTH mutations | single-case control on fixed, mutant-dump (§A hunks 1–2 reverted) and mutant-tmpdir (hunks 3–4 reverted) trees | fixed: `ok`, `2 cases, 0 failures`; mutant-dump: `FAIL` `secret-no-dump: database.txt in the profile dir`; mutant-tmpdir: `FAIL` `secret-no-dump: canary in the profile dir` (`r2-secret-no-dump-runs.log`). Pre-repair, the TMPDIR mutant passed the round-1 case **silently** — `r2-trace.log` shows the `! grep` matching with execution continuing, because `set -e` exempts negated pipelines; §C's enforced forms fix that |
| V20 | `$out/tmp` removal on every catchable exit | `sh fixture-signals.sh` (recipe writes canary to `$TMPDIR` then sleeps; the killer proves the canary file exists in `out/tmp` mid-run, then signals) | INT rc 130, TERM rc 143, HUP rc 143; each: `mid-run: canary file present in out/tmp`, `out/tmp removed`, `recipe temp file absent`, `canary absent from every file` (`fixture-signals.log`, `killer-*.log`). The fixture runs the instrument in the foreground: a `&`-launched job inherits SIGINT as `SIG_IGN` (untrappable), first measured rc 0 |
| V21 | Full wired control (round 2) | `sh wired/tools/test_suite_profile.sh` | `42 cases, 0 failures`, 23 s; `temp-only: ok` (nothing outside the fixture; the new `test ! -e "$D/out/tmp"` holds); `secret-no-dump: ok` (`r2-full-suite-profile.log`) |
| V22 | Guard control (round 2) | `sh proto/tools/test_evidence_secret_guard.sh` | `40 checks, 0 failures`, ×3 repeats (`guard-test-run.log`) |
| V23 | Readers of profile-dir leftovers | `grep -rn 'database.txt' tools/`; `grep -rn 'out/tmp' tools/ mk/`; profile-dir reads in `rig_check.sh` | `database.txt` only at suite_profile.sh lines 52/67 (both removed by §A); **zero** readers of `out/tmp` anywhere in `tools/`+`mk/`; `rig_check.sh` reads only `profile.tsv` (its summary) (`readers-of-out.log`) |
| V24 | names-file behaviours | control checks 9–14 (V22's run) | negative control rc 0 (pattern alone misses `PRIVATE_STUFF`); plain `NAME` rc 1, name printed, value unprinted; template `NAME=op://x/y/z` + repeatable rc 1; the names file itself scanned rc 0 (after-`=` never a pattern); missing and no-valid-`NAME` names files rc 2; a name absent from the environment = hint on stderr, rc 0 |
| V25 | multi-line split | control checks 15–16 (V22's run) | a two-line canary's **second** line planted in a file: rc 1, value unprinted; a value whose lines are all shorter than `MIN_LEN` or blank: zero patterns, `--require-candidates` rc 2 — never an empty pattern |
| V26 | Wired rig-check control (round 2) | scratch repo with the round-2 files, `sh tools/test_rig_check.sh tools/rig_check.sh` under `env -i` + sysctl stub | `27 cases, 3 failures` — the same three sandbox denials as V2; `rig-check control suite-profile: ok`, `rig-check control evidence-guard: ok`; caller-poison `0 of 26 ok` (nested fails for the same sandbox reasons); 62 s (`wired-rig-check-control-r2.log`) |
| V27 | `$(warning)` and `$(error)` expand an environment value onto stderr (controller, revision 3) | fixture Makefiles with `$(warning w-$(SP_FAKE_TOKEN))` and `$(error e-$(SP_FAKE_TOKEN))`, `env -i PATH=… SP_FAKE_TOKEN=<canary> {make,gmake} -pq -f <fixture> all` | warning: rc 1, canary on stderr 1, on stdout 1 (the database); error: rc 2, stderr 1, stdout 1; identical on `make` 3.81 and `gmake`. The stdout copy goes only to the awk pipe; the stderr copy is what revision 3 stops keeping |
