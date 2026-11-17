# Source-literal guard: its lexical edges (7ap)

**Status:** Implemented 2026-11-17 (mission iteration 97, row 7ap; designer GLM 5.3, planner Kimi K3, executor Haiku 5.5; evaluation Sonnet 5.5 91 PASS, `eval_R1-7AP-SOURCE-LITERAL-GUARD-EDGES_round_1_sonnet.json`). Planned 2026-11-17. **Revision 2** (controller, narrow-refinement carve-out after quorum round 2, BLOCKED 3 of 3 with concrete fixes and no direction dispute) applies gemini-4-argon's, oc-kimi-k3's and claude-sonnet-5's fixes verbatim; see the Quorum log. Created 2026-11-17 from mission iteration 97, queue row **7ap** of the charter (verbatim at `design_docs/stapledon-mission.md:563`; the iteration-91 backlog fold-in at `:508`). Designer GLM 5.3 (`pi:ollama/glm-5.3:cloud`, D-146 B rotation), unattended run. Measured at `origin/main` `1e839e2e` (branch `mission/stapledon-iter97-7ap`) on Voights-Mac-Studio.local (arm64, Python 3.14.5, GNU Make 3.81), in a throwaway clone under `/tmp/claude/stap_iter97_dry` with scratch under `/tmp/claude/i97w`; every mutation ran there on copies and was restored with `git checkout --` traps, and the clone is deleted after measurement. Appendix A reproduces the patch verbatim, so the doc does not depend on `/tmp`. **Revision 1** (same day) answers design-quorum round 1 (BLOCKED 2 of 3: gemini-4-argon PASS; oc-kimi-k3 REJECT; claude-sonnet-5 REJECT — neither reject disputes the direction): draft r0's single-quote string consumption alternative is dropped (it silently blinded fail-closed apostrophe-flanked comment pairs — measured, V22), the meta test gains two sub-cases that kill single-`assertIn` deletions, the V3/V8 tree oracle is reproduced inline (Appendix B) and re-run, the real-tree checked set is pinned at AC level (AC12), and the executor's pre-landing PR re-check becomes the blocking AC14 with the controller's `gh` measurement recorded as V21. Re-measured in a fresh throwaway clone under `/tmp/claude/i97r1` (deleted after). **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ap**).
**Priority:** low (clause 5 hygiene). Nothing is red at the base (V1): the guard's 9 tests and the whole harness (38 tests) pass, and `make script-gate-lint` is green. Measured here, the row's holes are real: five mutations of the guard survive with all tests green (V4) — the scan does not read a dictionary written entirely in single-quoted Python literals, nor a GDScript id value behind a `&`/`^` literal prefix, and no control pins the negative-index grammar, the second-pair cross-check, or the unclosed-brace fallback; the fold-in double mutation (`assertEqual(bad, bad)` plus the wrong pair restored at `tools/earth_link_capture.gd:16`) stays green (V4, reproducing the controller's finding); the positive controls can be deleted green (V4); the four 7ah/7al `ci-fast` edges are unpinned — deleting one from the Makefile leaves the lint green (V19); and the fast tier's stderr carries `printf: I/O error` noise, reproduced here under dash with SIGPIPE ignored (V12). Two of the row's claims come back false as stated and are corrected with the measurement: a negative index **is** flagged today, and a second index/id pair in one dictionary **is** cross-checked today — in both cases what actually survives is a grammar-weakening mutation with no control to kill it (V4, V7). This row closes the two real false negatives, gives every surviving mutation a killing control, makes the guard's own assertions prove they can fail, pins the four edges, and drains the pipe. Items (c), (d) and (g) defer with measurements.
**Implements:** row 7ap of the charter (`design_docs/stapledon-mission.md:563`) and the iteration-91 backlog fold-in (`:508`). The guard was built by row 7am ([`m4-7am-alpha-index-literals.md`](m4-7am-alpha-index-literals.md), M2) and reshaped by D-149 ([`m4-d149-earth-link-alpha-index.md`](m4-d149-earth-link-alpha-index.md), D2), which removed the pending mechanism; row (b)'s "stale-pending assertion" no longer exists (V2). The format and scope follow the sibling row 7ao ([`m4-7ao-session-minor-guard-edges.md`](m4-7ao-session-minor-guard-edges.md)), landed yesterday. This serves definition-of-done gate 1 (the fast tier and its targeted gates). No design-repo feature or physics-spec section applies: the sim never reads a plan target's index (7am V7); this row changes no physics, no copy, no asset.
**Depends on:** nothing new. `tools/test_replay.py` is a registered test harness (`tools/python-allowlist.txt:24`), so no new Python file and no allowlist row. The checks need only `python3`, `sh`/`dash`, `make` and `git`, and AC14 alone needs network and `gh` auth (the executor's host has both; this designer sandbox does not, V16); no AILANG, no Godot, no GPU. `shellcheck` and `/bin/dash` are present on this host (V12); AC10 degrades to a verdict-only check if dash is absent.
**Estimated LOC:** 82 changed lines in four files (`git apply --numstat`, V17): `tools/test_replay.py` +61 −7, `tools/script_gate_prereqs.sh` +5 −2, `mk/script-gates.mk` +3 −2, `tests/fixtures/script_gate/prereq_negative.mk.txt` +2 −0. Plus a changelog fragment. No product, asset, shader, golden or `*.ail` change, and no Makefile line is edited (the new pairs only read make's database).
**Evidence:** every codebase claim has a row in the [Verification log](#verification-log), pinned to `1e839e2e`.

## Game vision alignment

Scored by hand against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md`, as the 7ao and 7am tables were. The run is unattended, so the `game-vision-designer` skill held no interview.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. The literals this guard checks are test and tool data; the product map resolves ids at runtime (7am V5). |
| The Ship Is Home | 0 | 0 | No scene, furniture or asset changes. |
| Grounded Strangeness | 0 | 0 | No content changes. |
| We Are Not Built For This | 0 | 0 | No crew or AI changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral test hygiene. Every 0 means "not touched", so a human has no reason to stop it. |

## Problem

Each sub-item was re-measured at `1e839e2e`. The guard is `MapIndex` in `tools/test_replay.py`: `SOURCE_TOKEN` (base line 338) lists each `"index"` and `"id"` literal and each brace, `source_pairs` pairs them within one dictionary's level, and `source_index_pairs` reports a pair whose index is not the id's `data/starmap/stars.json` index. It runs as `python3 tools/test_replay.py MapIndex` (9 tests, 0.24 s; `make replay-map-index`, in `ci-fast`) and the whole file runs 38 tests (V1).

1. **(a) The scan reads one spelling, and four claims need correcting on evidence.** The tree is clean today (V3): of 503 tracked `.gd`/`.py` files (the harness exempted), zero hold a single-quoted `(index, id)` pair (one benign `p['id']` subscript at `tools/exoplanets_ref.py:15`), zero hold a `&"…"`/`^"…"` key or id value, zero hold a negative index, and zero hold a dictionary level with a second index or id token — so nothing is red, and each spelling is a hole a future edit falls through silently. Measured end to end with scratch files (V7):
   - **False negatives, confirmed.** A wrong pair in a single-quoted Python dict (`t = {'index': 1, 'id': 'CNS5:3627'}`) and a wrong pair with a StringName id value (`const A := {&"index": 1, &"id": &"CNS5:3627"}`) both pass the base guard green. The keys with a `&`/`^` prefix were already seen (the regex matches the `"index"` inside `&"index"`); only the **value** was missed, because `"id"\s*:\s*"` does not tolerate the `&` between the colon and the quote.
   - **Premise correction.** A negative index **is** checked today: `{"index": -1, "id": "CNS5:3627"}` is reported `index -1, stars.json 2` at the base (V7). What survives is the grammar mutation: dropping `-?` from `SOURCE_TOKEN` leaves all 9 tests green (V4), because no control holds a negative index. The row's "(`-?` dropped survives)" is the accurate half; "a negative index … is not checked" is not.
   - **Premise correction.** A second index/id pair in one dictionary **is** checked today: `_level_pairs` pairs every index at a level with every id there (a cross product), so `{"index": 2, "id": "CNS5:3627", "index": 1, "id": "HIP 71681"}` reports both cross-wrong entries at the base (V7). What survives is the weakening mutation: replacing the cross product with a first-pair-only `zip` leaves all 9 tests green (V4), because no control holds a two-pair dictionary.
   - **False positives, measured.** A wrong pair quoted in a `#` comment (`tools/_drill_comment.gd`) and one inside a single-quoted Python string (`S = '{"index": 1, "id": "CNS5:3627"}'`) each fail the base guard, naming the line (V6) — fail closed, loud, never a silent pass. A wrong pair flanked by matched apostrophes in a comment (`# node's old pair: {"index": 1, "id": "CNS5:3627"}, per Barnard's audit`) fails the base guard the same way, in both `.gd` and `.py` (V22) — draft r0's single-quote consumption would have swallowed it whole and silently (the quorum's strongest objection, reproduced here); revision 1 drops that consumption instead. The tree holds exactly one comment-line id token today (`tools/bright_star_audit.gd:8`, a `##` doc comment), and it pairs with nothing (no index token at its level).
2. **(b) Two controls are missing and one is obsolete.** No control exercises the unclosed-brace fallback (`for level in frames` at base lines 387–388): deleting it leaves all 9 tests green (V4). The "stale-pending assertion" is **gone**: D-149 deleted `SOURCE_PENDING` and its assertions (`grep -n "SOURCE_PENDING" tools/test_replay.py` is empty; control: the two `assertIn` positive controls sit at base lines 460–461, V2), so G11's drill has nothing left to guard. What remains is G13: deleting both `assertIn` positive controls leaves all 9 tests green (V4). The blind-scan probe confirms the `assertIn`s are live (renaming the token keys turns the guard red at the base, V5) — but only a manual drill says so; nothing permanent tests the guard's own assertions.
3. **The fold-in (iteration-91 backlog, V4).** Weakening `assertEqual(bad, [])` to `assertEqual(bad, bad)` while restoring the wrong pair at `tools/earth_link_capture.gd:16` gives `Ran 9 tests in 0.355s / OK` at `1e839e2e` — the controller's reproduction holds: nothing tests the assertion itself. The positive control pins line 16, so a harmless reformat that shifts the pair fails loudly — by design, kept. The scan sees tracked files only and skips non-catalogue ids such as `Sol` — pre-existing, kept (the enumeration control at the base covers the file list).
4. **(e) The 7ah/7al `ci-fast` edges are unpinned.** 7ao did not touch `SG_PREREQS` (no mention in its doc; the list still holds 5 pairs, pin 5, `mk/script-gates.mk:17,20`). The edges exist as separate rule lines (`Makefile:134`, `Makefile:172`), which make merges into one database line, so a `ci-fast:<target>` pair holds for each (measured before the patch: all four hold in `make -pq`, V19). Deleting `Makefile:134` leaves `make script-gate-lint` green at the base (V19): the fast tier can lose the 7ah guard silently, exactly the regress 7am closed for `replay-map-index` with its M4 pair.
5. **(f) The prerequisite checker prints `printf: I/O error` under the runner.** `tools/script_gate_prereqs.sh` pipes a 472 KB make database into two early-exiting consumers: `grep -q` (line 14, exits at the first match) and `awk … { print; exit }` (line 19, exits at the first matching rule line). Reproduced here (V12): under `dash` with SIGPIPE ignored — the state the Actions harness leaves its children in — the real 5-pair check prints **6** `printf: I/O error` lines (1 from line 14, 5 from line 19) and still exits 0 with the correct verdict; under macOS `/bin/sh` (bash) the same runs are silent, which is why this Mac never showed it. The row's "5 on main's own fast-tier log" is the same mechanism; the exact count depends on how much of `$db` is left unwritten when the consumer quits.
6. **(c) AILANG test catalogues number locally (inert).** Re-measured (V13): 17 catalogue-id pairs whose index differs from `stars.json` in the 6 test `.ail` files (`sim/core_ism_test.ail` 4, `sim/finder_test.ail` 1, `sim/similar_test.ail` 2, `sim/solar_departure_test.ail` 3, `sim/stops_test.ail` 5, `sim/trappist1_test.ail` 2), plus 1 more in the tool `sim/tools/solar_departure_probe.ail` — the row's "17 pairs in 6 files" counts the test catalogues exactly. The numbering is deliberate (7am Problem 4); the guard scans `.gd`/`.py` only, so nothing is red.
7. **(d) `protocol_27_inferred` plans Barnard at 1.** `tests/fixtures/protocol_27_inferred.input.ndjson:3` plans `Gaia DR3 4472832130942575872` ("Barnard's Star") at index 1; `stars.json` holds it at 3 (V14). It is a frozen `ism-compat` recording (`tests/fixtures/README.md:3`: "Do not regenerate the expected file from the new implementation"), and it lives in `tests/fixtures/`, which the log scan (`tests/replays/`) never reads — by design. A provenance question, not a defect.
8. **(g) The `ism-bench` boost ceiling flake.** The ceiling is `report.boost.delta_median_ms <= 0.5` (`tools/ism_service_bench.gd:126`, V15). The row reports one reading of 0.7247 ms under heavy load that passed on the re-run — a timing flake to watch, with the re-run rule 7am's AC10 already names. Nothing to fix in a hygiene row.

## Goals and non-goals

**Goals.**
- **(a)** The scan reads a dictionary written entirely in single-quoted Python literals, and an id value behind a `&`/`^` literal prefix. Each new spelling is caught by a named control, and the wrong-pair drills of V7 turn red.
- **(a)/(b)** The three grammar edges that already hold — the negative index, the second-pair cross-check, the unclosed-brace fallback — each get a control that pins them, so the mutations that survive today (V4) die.
- **(a)** A pair inside a single-quoted Python string, and a pair flanked by matched apostrophes in a comment (`.gd` and `.py`), stay flagged — fail closed, loud, exactly as at the base: draft r0's single-quote consumption alternative blinded the flanked case (V22) and is dropped. The trade, one sentence: the row keeps the base's loud false positives (a pair inside single-quoted string text, and apostrophe-flanked comment pairs) rather than silencing any fail-closed red, because a false negative is worse than a false positive that fails closed.
- **(b)/fold-in** A meta test proves the guard's own assertions can fail: `test_source_literals_match_the_map` must raise on a fixture with one wrong pair (killing `assertEqual(bad, bad)`), and must raise when the scan sees no pair (killing the `assertIn` deletion).
- **(e)** The four 7ah/7al `ci-fast` edges join `SG_PREREQS`; the pin moves 5 → 9 and the negative fixture keeps holding them.
- **(f)** Both make-database consumers drain the pipe. No verdict changes: the positive run keeps its ok line and rc, the negative control keeps its exactly-two named refusals and rc 1.
- The real tree's checked set is byte-identical before and after (V8, V9): the new grammar finds nothing new on the tree and blinds nothing.

**Non-goals.**
- Comment-awareness (a lexer that knows `#` outside strings). The false positive fails closed and is loud (V6), including the apostrophe-flanked case (V22); see Deferred items.
- Any AILANG change, any Makefile edit, any `.gd` product file, any `*.ail`, any new Python file, `ui/galaxy_map.gd`, `design_docs/planned/r3/reasons-to-travel*`, `.ailang/state/sprints/sprint_R3-REASONS.json`, anything under `design_docs/stapledon-mission*`.
- Changing the guard's messages, the ok line, or the `assertIn` line numbers (:10, :16) — the pin is by design (fold-in note).
- The pending mechanism. It was removed for one made ruling (D-149). A future attended hold is a new decision and can bring the code back from git.
- (c), (d), (g): see Deferred items.

## Design

### Classification: TEST-ONLY, loop work

Nothing a player sees or hears changes. Every change is in a test harness, a lint script, a make include and its negative fixture.

### M1. The scan reads the four spellings; every edge gets a control (a, b): `tools/test_replay.py`

- **Grammar.** `SOURCE_TOKEN` gains two alternatives and keeps its shape (patched lines 344–346): a single-quoted index key `'index'\s*:\s*(-?\d+)` and a single-quoted id key and value `'id'\s*:\s*[&^]?'…'` (the `&`/`^` prefix on a single-quoted value since revision 2: GDScript 4 has single-quoted StringName literals too). There is **no** single-quote string consumption: draft r0's `'(?:[^'\\\n]|\\.)*'` alternative blinded matched apostrophes around a pair (V22) and is dropped; only double-quoted strings are consumed whole, exactly as at the base. The double-quoted id alternative gains `[&^]?` before the value's opening quote, so `{&"id": &"CNS5:3627"}` pairs. Keys with a `&`/`^` prefix were already seen (the regex matches at the `"index"` inside `&"index"`); only the **value** was missed. Groups become 1–5 (index double, index single, id double, id single, brace) and `source_pairs` reads them with `is not None` tests, so an index of `0` and the empty string stay distinct. Mixed-quote dictionaries pair by construction: the pairing is per level, not per spelling. Single-quoted GDScript dictionaries are real — measured on Godot 4.7.2.stable (V23) — so the alternatives stay file-type-blind.
- **Safety, measured.** The old and new tokenisers produce identical pair sets over all 503 files: 41 pairs each way, zero blinded, zero gained (V8, re-run on the r1 grammar with the Appendix B oracle); the real-tree check is `16 []` on both, and AC12 pins the full 16-entry checked set by count, list and sha256 (V9). The blinding class that killed draft r0 is real, not theoretical: a matched pair of apostrophes in a comment — `# node's … {"index": 1, "id": "CNS5:3627"} … Barnard's` — spans the pair, and a consumption alternative silently swallows it whole (V22: base red, r0 silently green, r1 red again). GDScript has single-quoted strings (V23), so scoping the alternatives to `.py` would silently stop scanning single-quoted `.gd` dictionaries; the grammar stays unified and the consumption stays out, so every such case fails closed, loud, and the flank controls (`flank.gd`, `flank.py`, `str.py`) die the moment a consumption returns (V11 `sqstr` drill).
- **The control.** One new test, `test_the_7ap_spellings_fail` (patched line 517), holds nine synthetic texts and asserts the exact `bad` and `checked` lists by name: `sq.py` (single-quoted wrong pair), `amp.gd` (StringName key and value, wrong pair), `neg.gd` (negative index), `two.gd` (two pairs in one dictionary; the cross product must report the two cross-wrong entries in order), `unc.gd` (an unclosed dictionary whose level is paired at end of text), `str.py` (a pair inside a single-quoted Python string — still seen, still flagged, fail closed), `flank.gd` (`# node's old pair: {"index": 1, "id": "CNS5:3627"}, per Barnard's audit` — the apostrophe-flanked comment) `flank.py` (`# it's {"index": …, "id": "CNS5:3627"} that's wrong` — the same shape in Python) and `ampsq.gd` (`{'index': …, 'id': &'CNS5:3627'}` — a single-quoted StringName id value; revision 2). Every wrong index is computed from `stars.json` at runtime (`self.at`; `a + 1` for the str and flank texts since revision 2, which r1 had hard-coded as `1`), so no catalogue reorder can make a control pair correct (7am M3 precedent).
- **What each text kills** (all measured, V11): `sq.py` kills the single-quote key alternatives (renamed away), `amp.gd` kills `[&^]?`, `neg.gd` kills the `-?` drop, `two.gd` kills the zip weakening, `unc.gd` kills the fallback deletion, and `str.py`, `flank.gd` and `flank.py` together kill the consumption re-add (`sqstr`: the three texts vanish from the lists — V22's mechanism, run as a drill).
- The comment block above `SOURCE_TOKEN` documents the new grammar, including the two premise corrections (cross-checked, not first-wins), why there is no single-quote consumption (the r0 blinding, V22), and the deferred comment case.

### M2. The meta test: the guard's own assertions must be able to fail (fold-in, G13): `tools/test_replay.py`

`test_the_7ap_guard_test_can_fail` (patched line 540) instantiates a second `MapIndex("test_source_literals_match_the_map")` and patches its `sources`/`stars` with instance attributes — plain unittest, no `mock`, no subprocess, no file writes:

- **Sub-case 1 (the bad-list assertion is live).** The fixture holds the two named positives — `ui/transit_harness.gd` with a correct pair on line 10, `tools/earth_link_capture.gd` with one on line 16 (nine and fifteen leading newlines) — plus `fixture.gd` with one wrong pair. The method must raise. Under the fold-in mutation (`assertEqual(bad, bad)`) the weakened assertion passes and the `assertIn`s are satisfied, so nothing raises and the meta test goes red. This is the controller's exact scenario, made permanent.
- **Sub-case 2 (the positive control is live, both lines).** With the two named positives and `stars = []` (a scan that checks no pair: every id is skipped, `checked` is empty), the method must raise through the `assertIn`. Under G13's mutation (the `assertIn`s deleted) nothing raises and the meta test goes red.
- **Sub-case 3 (the earth_link `assertIn` is live on its own).** With only the `ui/transit_harness.gd` positive seen and the real stars, the method must raise: the `tools/earth_link_capture.gd:16` `assertIn` fails on a scan that misses its pair. Under the single-line deletion of that `assertIn` nothing raises and the meta test goes red (`assertin2` drill, V11).
- **Sub-case 4 (the transit_harness `assertIn` is live on its own).** With only the `tools/earth_link_capture.gd` positive seen, the method must raise: the `ui/transit_harness.gd:10` `assertIn` fails on a scan that misses its pair. Under the single-line deletion of that `assertIn` nothing raises and the meta test goes red (`assertin1` drill, V11). Sub-cases 3 and 4 close the quorum note that sub-case 2 alone kills only the both-lines deletion; each single deletion now has its own killing sub-case, with no residual.

The base guard is 9 tests; the patch makes `MapIndex` 11 and the whole file 40 (V10).

### M3. The 7ah/7al ci-fast edges join SG_PREREQS (e): `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt`

- `SG_PREREQS` gains `ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls`; `SG_PREREQS_PAIRS` moves 5 → 9. One comment line names the new class of pair (guard edges, not asset gates). All four hold in make's merged database (V19).
- The negative fixture gains one merged rule line (`ci-fast: similar-main-guard similar-guard-controls session-minor-guard session-minor-guard-controls`), so the lint recipe's negative control still produces exactly its two named refusals (measured green, V10).
- The drills that prove the pairs are load-bearing, measured (V11): deleting `Makefile:134` fails the lint with `ci-fast lost its prerequisite similar-main-guard` and `… similar-guard-controls` (rc 2); dropping one pair from the list fails the pin check `SG_PREREQS holds 8 pairs (8 distinct) but SG_PREREQS_PAIRS is 9` (rc 2). Neither drill could fail at the base (V19).
- 7ao's (e) was a different item (the two `_adopt_warm` refusals); this row's (e) is unowned and open — measured, not assumed (no `SG_PREREQS` edit in 7ao's doc or patch).

### M4. The make-database consumers drain the pipe (f): `tools/script_gate_prereqs.sh`

Two lines, verdicts untouched:

- Line 14: `printf '%s\n' "$db" | grep -q '^# Make data base'` becomes `… | grep '^# Make data base' >/dev/null`. Plain grep reads its whole input; the exit status semantics are identical (0 found, 1 none, 2 error).
- Line 19: `awk … { print; exit }` becomes `awk … && !seen { print; seen = 1 }`. The first matching line is still the only one printed; awk now reads to end of input instead of quitting early.

A three-line comment records why. Measured (V12): under `dash` with SIGPIPE ignored, the pre-fix script prints 10 `printf: I/O error` lines on the 9-pair check (1 from line 14, 9 from line 19) and the fixed script prints none; both exit 0 with the same ok line; the negative control under dash keeps rc 1 and its exactly-two named diagnostics; macOS `/bin/sh` (bash) is silent either way; `shellcheck` and `shellcheck -s dash` are clean (V12). The other `printf | grep -q` pipes in `tools/` carry small lists that fit the 64 KB pipe buffer, so they cannot produce the noise; this row fixes only the two `$db` consumers the row names.

## Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a1) A comment- and string-aware lexer for the scan | closes the (a) false positive | Deferred. The tree holds one comment-line id token and it pairs with nothing (V3); a wrong pair in a comment fails closed, loud (V6). A lexer is a B8-sized lint for a latent annoyance. |
| (a2) Pin the second pair with `zip` semantics | first pair wins, like the row's wording | Rejected. Under-checking is silent; over-checking is loud. The cross product reports every wrong combination; `two.gd` pins it. |
| (a3) AILANG support in the scan | | Rejected. 7am revision 1 dropped it: the tests number local catalogues deliberately (V13); an opt-out grammar is a design of its own. |
| (a4) Scope the single-quote alternatives to `.py` only (quorum round 1's proposed fix) | | Rejected. GDScript 4 accepts single-quoted strings — measured on Godot 4.7.2.stable: `{'id': 'CNS5:3627'}` prints its value (V23) — so a file-type-scoped grammar would silently stop scanning single-quoted `.gd` dictionaries, trading a measured class for a new one. |
| (a5) Keep r0's consumption and pin the flanked case as a silent pass (quorum round 1's other option: correct the docs, add a text asserting the blindness) | | Rejected. It trades two fail-closed reds for silent greens (V22) — a false negative, which is worse than a false positive that fails closed; the controls would have to assert the blindness itself. Dropping the consumption (chosen) keeps both reds loud. |
| (b1) A subprocess meta-check (run the guard on a mutated copy tree) | like the manual AC5 drill | Rejected. Instantiating the TestCase and patching two instance attributes is plain unittest, runs in-process in 0.2 s, and needs no scratch tree. |
| (b2) Keep the manual drill from D-149's AC5 | | Rejected. It proved the control once, at landing; the meta test proves it on every run. |
| (e1) A second negative fixture for the guard edges | | Rejected. The existing fixture takes one more merged rule line and keeps its exactly-two refusal contract (measured, V10). |
| (f1) Silence the noise (`2>/dev/null`, or `|| true`) | | Rejected. It hides real diagnostics; the consumers should drain the pipe instead. |
| (f2) Rewrite the probes to temp files | no pipes at all | Rejected. Two one-line changes with identical verdicts beat a restructure of a landed, pinned script. |
| (g1) Raise the boost ceiling | | Rejected. One reading under heavy load that passed on the re-run is a flake to watch (V15), not a ceiling to move. |

## Files

Every path the sprint creates or edits:
- `tools/test_replay.py` (M1, M2; Appendix A).
- `mk/script-gates.mk` (M3; the `SG_PREREQS` list line, one comment line, the pin).
- `tests/fixtures/script_gate/prereq_negative.mk.txt` (M3; one rule line, one comment line).
- `tools/script_gate_prereqs.sh` (M4).
- `changelogs/unreleased/2026-11-17-source-literal-guard-edges.md` (new).
- Sprint bookkeeping: `design_docs/planned/r1/m4-7ap-source-literal-guard-edges-sprint.md` and `.ailang/state/sprints/sprint_R1-7AP-SOURCE-LITERAL-GUARD-EDGES.json`. Landing edits (charter row, README index) are routine.

No new script or scene, so no `.uid`; no new Python file, so no allowlist row. The evidence scratch (`$W`) lives in `mktemp -d` and is never committed.

**Do not touch:** everything under Non-goals; in particular no Makefile line — the new pairs read make's database, they do not edit it.

## Conflict surface

`gh` is unreachable from this sandbox (`gh pr diff 435 --name-only -R sunholo-data/stapledons-godot` fails: `tls: failed to verify certificate: x509: OSStatus -26276`, V16), and the three open PRs' head refs are not in this clone's remotes. The evidence is therefore local:

| File | Last 5 commits on `origin/main` (V16) |
|---|---|
| `tools/test_replay.py` | `97833536` (D-149), `93e82d29` (7am), `ceb837ae` (7ai), `fe3a54bc` (7i(c)), `bd594e49` (M4.5s) — all landed |
| `tools/script_gate_prereqs.sh`, `mk/script-gates.mk` | `93e82d29` (7am), `da7afacf` (7aa), `decd5498` (7x B4), `e9d31f94` (7x B4 M1), `20ca402c` (7x B3 M4) — all landed |
| `tests/fixtures/script_gate/prereq_negative.mk.txt` | `93e82d29` (7am), `e9d31f94` (7x B4), `eba3705e` (7x B3) — all landed |

7ao, landing yesterday, measured the same three PRs (#435 `feat/r3-reasons-rt2a` head `52ed3ebc`, #380 head `68e4ca6d`, #373 head `e37b3579`): every one of their hunks sits in the `Makefile`, and none touches a 7ap file. This row edits no Makefile line, so those hunks cannot collide with it textually. No local branch holds edits to the four files (the mission clone has no local-only commits, V16). **Residual risk, stated:** if any of the three PRs has grown edits to `tools/test_replay.py`, `mk/script-gates.mk`, `tools/script_gate_prereqs.sh` or the fixture since 7ao's measurement, it is unmeasured here (`gh` is unreachable from this sandbox, V16). The controller measured it outside the sandbox at pick time (V21, attributed and timestamped: `gh pr diff <n> --name-only` lists 27 / 31 / 57 files for #435 / #380 / #373; 0 / 0 / 0 of them are one of the four 7ap files; the `Makefile` count of 1 per PR is the known-positive control). The executor re-runs the check before landing as the blocking AC14: any hit — or a `gh` failure — halts the landing; if a PR has merged or vanished by then, the executor re-measures the conflict surface against the new `main` instead.

## Acceptance criteria

All checks are headless and run in the executor's full clone. Appendix A must be applied **and committed** first (AC1 does both), so that the mutation traps restore to the patched state, not to the base. No AILANG, Godot or GPU is needed at any point; `python3`, `git`, `make`, `perl`, `dash` and `shellcheck` are the only tools (AC10 and AC11 degrade gracefully if `dash` or `shellcheck` is absent — say so in the evidence rather than skipping). AC14 is the one exception: it needs network and `gh` auth, which the executor's host has and this designer sandbox does not (V16) — in the sandbox it halts with exit 2, which the r1 dry run records as the expected outcome there.

**Preamble** (source it once per shell, from the repo root):

```sh
D=design_docs/planned/r1/m4-7ap-source-literal-guard-edges.md
W=$(mktemp -d "${TMPDIR:-/tmp}/7ap.XXXXXXXX") || exit 1
# fence NAME: the body of the fence opened by a line "```<lang> NAME" in this doc
fence() { awk -v n="$1" '$0 ~ "^```[a-z]+ " n "$" { f = 1; next } f && /^```$/ { exit } f' "$D"; }
fence 7ap.patch > "$W/7ap.patch"
# mut NAME: one guard mutation for one run, written by $W/7ap_mut.py; runs MapIndex and prints its
# FAIL/OK lines; the EXIT trap restores the touched files on any exit, so the mutation never outlives the call
mut() ( git diff --quiet HEAD -- tools/test_replay.py tools/earth_link_capture.gd tools/script_gate_prereqs.sh \
    || { echo "mut: a target file differs from HEAD"; exit 4; }
  trap 'git checkout -- tools/test_replay.py tools/earth_link_capture.gd tools/script_gate_prereqs.sh' EXIT
  python3 "$W/7ap_mut.py" "$1" \
  && python3 tools/test_replay.py MapIndex 2>&1 | grep -E "^(FAIL|ERROR):|^Ran|^FAILED|^OK$" )
cat > "$W/7ap_mut.py" <<'PY'
import sys
n = sys.argv[1]
edits = {
  "foldin": [("tools/test_replay.py", '        self.assertEqual(bad, [])\n', '        self.assertEqual(bad, bad)\n'),
             ("tools/earth_link_capture.gd", '"index": 2', '"index": 1')],
  "assertin": [("tools/test_replay.py", '        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair\n', ''),
               ("tools/test_replay.py", '        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches\n', '')],
  "assertin1": [("tools/test_replay.py", '        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair\n', '')],
  "assertin2": [("tools/test_replay.py", '        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches\n', '')],
  "unclosed": [("tools/test_replay.py", '    for level in frames:  # unclosed braces: the open dictionaries still count\n        out.extend(_level_pairs(level))\n', '')],
  "minus": [("tools/test_replay.py", r'"index"\s*:\s*(-?\d+)|', r'"index"\s*:\s*(\d+)|')],
  "cross": [("tools/test_replay.py", '    return [(min(p, q), i, raw) for p, i in idx for q, raw in ids]',
             '    return [(min(p, q), i, raw) for (p, i), (q, raw) in zip(idx, ids)]')],
  "ampid": [("tools/test_replay.py", r'[&^]?"((?:[^"\\\n]|\\.)*)"', r'"((?:[^"\\\n]|\\.)*)"')],
  "sqindex": [("tools/test_replay.py", r"|\'index\'\s*:\s*(-?\d+)|", r"|\'zindex\'\s*:\s*(-?\d+)|")],
  "sqid": [("tools/test_replay.py", r"|\'id\'\s*:\s*[&^]?\'((?:[^\'\\\n]|\\.)*)\'|", r"|\'zid\'\s*:\s*[&^]?\'((?:[^\'\\\n]|\\.)*)\'|")],
  "ampsqid": [("tools/test_replay.py", r"\'id\'\s*:\s*[&^]?\'(", r"\'id\'\s*:\s*\'(")],  # revision 2 (quorum r2, gemini): the prefix on a single-quoted id value
  "sqstr": [("tools/test_replay.py", r'''r'"(?:[^"\\\n]|\\.)*"|([{}])')''', r'''r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|([{}])')''')],  # re-add the r0 consumption: the flank controls must die
  "sigpipe": [("tools/script_gate_prereqs.sh", "printf '%s\\n' \"$db\" | grep '^# Make data base' >/dev/null",
               "printf '%s\\n' \"$db\" | grep -q '^# Make data base'"),
              ("tools/script_gate_prereqs.sh", "awk -v t=\"$t:\" 'index($0, t) == 1 && $0 !~ /=/ && !seen { print; seen = 1 }'",
               "awk -v t=\"$t:\" 'index($0, t) == 1 && $0 !~ /=/ { print; exit }'")],
}
for path, old, new in edits[n]:
    t = open(path).read()
    assert t.count(old) == 1, (n, path)
    open(path, "w").write(t.replace(old, new))
PY
PAIRS='constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls'
```

Each AC is one command in the block below, marked `# ACn`. Run them in order in one shell after the preamble.

```sh
# AC1
shasum -a 256 "$W/7ap.patch" | cut -d' ' -f1
git apply --check "$W/7ap.patch" && git apply "$W/7ap.patch" \
  && git add tools/test_replay.py tools/script_gate_prereqs.sh mk/script-gates.mk tests/fixtures/script_gate/prereq_negative.mk.txt \
  && git commit -q -m "7ap: source-literal guard lexical edges, meta test, SG_PREREQS 9, pipe drain" && echo committed
git diff --numstat 1e839e2e HEAD -- tools mk tests | awk '{ i += $1; d += $2 } END { print i, d }'
# AC2
make -s --no-print-directory replay-map-index 2>&1 | tail -3; echo rc=$?
# AC3
python3 tools/test_replay.py 2>&1 | tail -3; echo rc=$?
# AC4
mut foldin
# AC5
for m in assertin assertin1 assertin2; do mut "$m" | grep -m1 "^FAIL: test_the_7ap_guard_test_can_fail" | sed "s/^/$m /"; done
# AC6
for m in unclosed minus cross ampid sqindex sqid sqstr ampsqid; do mut "$m" | grep -m1 "^FAIL: test_the_7ap" | sed "s/^/$m /"; done
# AC7 (revision 2: the wrong index is alpha Cen A's stars.json index + 1, read at run time, so no catalogue reorder makes a drill pair correct)
A1=$(python3 -I -c "import json; print([s['id'] for s in json.load(open('data/starmap/stars.json'))['stars']].index('CNS5:3627') + 1)")
printf 'extends SceneTree\n# const OLD := {"index": %d, "id": "CNS5:3627"}\n' "$A1" > tools/_7ap_drill_comment.gd
printf "S = '{\"index\": %d, \"id\": \"CNS5:3627\"}'\n" "$A1" > tools/_7ap_drill_string.py
printf "# node's old pair: {\"index\": %d, \"id\": \"CNS5:3627\"}, per Barnard's audit\n" "$A1" > tools/_7ap_drill_flank.gd
printf "# it's {\"index\": %d, \"id\": \"CNS5:3627\"} that's wrong\n" "$A1" > tools/_7ap_drill_flank.py
git add tools/_7ap_drill_comment.gd tools/_7ap_drill_string.py tools/_7ap_drill_flank.gd tools/_7ap_drill_flank.py
python3 tools/test_replay.py MapIndex > "$W/ac7.log" 2>&1; echo rc=$?
grep -o "tools/_7ap_drill_[a-z]*\.[a-z]*:[0-9]*" "$W/ac7.log" | sort -u
git rm -q --cached tools/_7ap_drill_comment.gd tools/_7ap_drill_string.py tools/_7ap_drill_flank.gd tools/_7ap_drill_flank.py && rm tools/_7ap_drill_comment.gd tools/_7ap_drill_string.py tools/_7ap_drill_flank.gd tools/_7ap_drill_flank.py
# AC8
make -s --no-print-directory script-gate-lint 2>&1 | tail -1; echo rc=$?
# AC9
cp Makefile "$W/Makefile.keep"; perl -ni -e 'print unless /^ci-fast: similar-main-guard similar-guard-controls$/' Makefile
make -s --no-print-directory script-gate-lint > "$W/ac9a.log" 2>&1; echo rc=$?; grep -c "lost its prerequisite similar-" "$W/ac9a.log"
cp "$W/Makefile.keep" Makefile
perl -pi -e 's/ ci-fast:session-minor-guard-controls//' mk/script-gates.mk
make -s --no-print-directory script-gate-lint > "$W/ac9b.log" 2>&1; echo rc=$?; grep -c "SG_PREREQS holds 8 pairs (8 distinct) but SG_PREREQS_PAIRS is 9" "$W/ac9b.log"
git checkout -- mk/script-gates.mk; make -s --no-print-directory script-gate-lint >/dev/null 2>&1; echo restored=$?
# AC10 (no mut: the mutation must outlive the call for the dash drills)
python3 "$W/7ap_mut.py" sigpipe
dash -c 'trap "" PIPE; exec dash tools/script_gate_prereqs.sh Makefile '"$PAIRS" 2>"$W/ac10a.err" >/dev/null; echo rc=$?
grep -c "printf: I/O error" "$W/ac10a.err"
git checkout -- tools/script_gate_prereqs.sh
dash -c 'trap "" PIPE; exec dash tools/script_gate_prereqs.sh Makefile '"$PAIRS" 2>"$W/ac10b.err" >/dev/null; echo rc=$?
grep -c "printf: I/O error" "$W/ac10b.err"
dash tools/script_gate_prereqs.sh tests/fixtures/script_gate/prereq_negative.mk.txt $PAIRS missing-target:x >"$W/ac10c.out" 2>"$W/ac10c.err"; echo rc=$?
grep -c "^script-gate-prereqs: " "$W/ac10c.out"; grep -c "printf: I/O error" "$W/ac10c.err"
# AC11
make -s --no-print-directory python-guard uid-guard >/dev/null 2>&1; echo guards=$?
shellcheck tools/script_gate_prereqs.sh && shellcheck -s dash tools/script_gate_prereqs.sh && echo shellcheck=clean
git diff --check 1e839e2e HEAD -- tools mk tests; echo check=$?
git diff --name-only 1e839e2e HEAD -- tools mk tests
# AC12 (landing-time pin of the real-tree checked set: a legitimate new tracked pair moves it, named;
# a shrunk or changed set with no new pair is a blinding regression)
python3 -I -c "
import hashlib, sys
sys.path.insert(0, 'tools')
import test_replay as t
m = t.MapIndex()
c, b = t.source_index_pairs(m.sources(), m.stars())
print(len(c), b)
print(' '.join(sorted(c)))
print(hashlib.sha256('\n'.join(sorted(c)).encode()).hexdigest())
"
# AC13 (the Appendix B oracle: the V3/V8 tree measurement, re-runnable; blinded and gained must be empty)
fence 7ap.oracle > "$W/7ap.oracle.py"
python3 "$W/7ap.oracle.py"
# AC14 (pre-landing PR re-check, blocking; needs network + gh auth — the executor runs it outside the
# designer sandbox. Any hit on a 7ap file halts the landing; a gh failure halts it too)
for n in 435 380 373; do
  perl -e 'alarm shift; exec @ARGV' 30 gh pr diff "$n" --repo sunholo-data/stapledons-godot --name-only > "$W/pr$n.txt" \
    || { rc=$?; if [ "$rc" = 142 ]; then echo "AC14: gh timed out for PR $n after 30 s (network stall) — halt"; \
         else echo "AC14: gh failed for PR $n, rc $rc (needs network + gh auth)"; fi; exit 2; }
  echo "pr$n files=$(wc -l < "$W/pr$n.txt" | tr -d ' ')"
  if grep -qxE 'tools/test_replay.py|mk/script-gates.mk|tools/script_gate_prereqs.sh|tests/fixtures/script_gate/prereq_negative.mk.txt' "$W/pr$n.txt"; then
    echo "AC14: PR $n touches a 7ap file — halt, rebase onto it"; exit 1
  fi
  echo "pr$n makefile=$(grep -cx Makefile "$W/pr$n.txt")"  # known-positive control: the grep sees a listed file
done
# AC15
rm -rf "$W"; git status --porcelain --untracked-files=all
```

| # | Criterion | Expected |
|---|---|---|
| AC1 | The patch is Appendix A, byte for byte, applies to `1e839e2e`, and is committed | `66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39`, `committed`, `73 11` |
| AC2 | The guard passes the patched tree; 9 → 11 tests | blank, `Ran 11 tests …`, `OK`, `rc=0` |
| AC3 | The whole harness file passes; 38 → 40 tests | `Ran 40 tests …`, blank, `OK`, `rc=0` |
| AC4 | The fold-in double mutation is killed: the weakened assertion with the wrong pair restored goes red on the meta test only | `FAIL: test_the_7ap_guard_test_can_fail (__main__.MapIndex.test_the_7ap_guard_test_can_fail)`, `Ran 11 tests …`, `FAILED (failures=1)` — and **no** `FAIL` for `test_source_literals_match_the_map` (the weakened assertion still passes the real tree; only the meta test sees it) |
| AC5 | G13's mutations are killed: both `assertIn`s deleted, and each single-line deletion, the meta test goes red | three lines: `assertin FAIL: …`, `assertin1 FAIL: …`, `assertin2 FAIL: …`, each `FAIL: test_the_7ap_guard_test_can_fail (__main__.MapIndex.test_the_7ap_guard_test_can_fail)` |
| AC6 | Each grammar edge is pinned: all eight mutations die on the spellings test | eight lines: `unclosed FAIL: …`, `minus FAIL: …`, `cross FAIL: …`, `ampid FAIL: …`, `sqindex FAIL: …`, `sqid FAIL: …`, `sqstr FAIL: …` (the r0 consumption re-added), `ampsqid FAIL: …` (the `[&^]?` on a single-quoted id dropped), each `FAIL: test_the_7ap_spellings_fail (__main__.MapIndex.test_the_7ap_spellings_fail)` |
| AC7 | Both false positives still fail closed: the comment pair, the string pair, and the apostrophe-flanked pair in both languages — nothing is silently consumed | `rc=1`, then exactly four lines: `tools/_7ap_drill_comment.gd:2`, `tools/_7ap_drill_flank.gd:1`, `tools/_7ap_drill_flank.py:1`, `tools/_7ap_drill_string.py:1` |
| AC8 | The lint holds all nine pairs and its negative control | `script-gate-prereqs: ok (9 pairs hold in Makefile: … ci-fast:session-minor-guard-controls)`, `rc=0` |
| AC9 | (e) The new pairs are load-bearing | `rc=2`, `2` (both 7ah refusals by name); then `rc=2`, `1` (the pin message); then `restored=0` |
| AC10 | (f) The pre-fix noise returns with the mutation and is gone with the fix; verdicts never move | `rc=0`, `10`; then `rc=0`, `0`; then `rc=1`, `2`, `0` (the negative control keeps its two named refusals with no I/O error). If `dash` is absent, print `dash absent` and run the three commands with `sh` instead: the verdict columns (`rc=…`, the `2`) still hold, and the two I/O-error counts are skipped — say so in the evidence |
| AC11 | Hygiene gates pass, the code adds no whitespace error, shellcheck is silent, the scope is the four files | `guards=0`, `shellcheck=clean`, `check=0`, then the four paths: `mk/script-gates.mk tests/fixtures/script_gate/prereq_negative.mk.txt tools/script_gate_prereqs.sh tools/test_replay.py` |
| AC12 | The real-tree checked set is pinned at landing time (quorum r1: only 2 of the 16 entries were pinned by `assertIn`) | `16 []`, then the sorted 16 names of V9 (`tests/test_bridge_monitors.gd:15 … ui/transit_harness.gd:10`), then `67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566`. A legitimate new tracked pair moves the pin — name the delta and move it; a shrunk or changed set with no new pair is a blinding regression |
| AC13 | The V3/V8 tree measurement is re-runnable (Appendix B oracle) and the revised grammar blinds nothing, finds nothing new | `files 503`; `old_pairs 41 new_pairs 41`; `blinded []`; `gained []`; `neg_index_pairs []`; `amp_or_caret_tokens 0`; `levels_with_second_token []`; `comment_line_tokens [('tools/bright_star_audit.gd', 8)]` |
| AC14 | The pre-landing PR re-check halts on any hit (blocking; needs network + `gh` auth — the executor's host) | `pr435 files=… makefile=1`, `pr380 files=… makefile=1`, `pr373 files=… makefile=1` (counts re-measured at landing; at pick time 27 / 31 / 57, V21), rc 0; any 7ap-file hit prints `AC14: PR n touches a 7ap file — halt, rebase onto it` and exits 1. Each `gh` call is bounded to 30 s (`perl -e 'alarm …'`, the rig has no GNU `timeout`): a stall prints `AC14: gh timed out for PR n after 30 s (network stall) — halt` (rc 142 inside, exit 2); any other `gh` failure prints `AC14: gh failed for PR n, rc …` (exit 2). Record which one occurred. In the designer sandbox this halts at the first `gh` call with exit 2 (V16) — the dry run records exactly that |
| AC15 | No evidence file is left in the clone | empty |

The mutation traps restore byte-identically on any exit; AC15 proves it. `git diff --check` uses the code pathspec (`tools mk tests`): this doc embeds a patch whose blank context lines carry the standard single leading space, and a whole-tree check would flag the doc itself (7am hit the same thing at landing).

## Test plan: each new or changed check and the mutation that kills it

| Check | Kind | Mutation that kills it | Run against | Measured |
|---|---|---|---|---|
| Single-quoted index alternative | guard grammar | `sqindex`: `\'index\'` renamed `\'zindex\'` in `SOURCE_TOKEN` | `MapIndex` via `mut` | Survives at the base (V4 sq drill passes green); killed: V11 (`FAIL test_the_7ap_spellings_fail`) |
| Single-quoted id alternative | guard grammar | `sqid`: `\'id\'` renamed `\'zid\'` | same | Survives at the base (V7); killed: V11 |
| `[&^]?` on the id value | guard grammar | `ampid`: prefix dropped | same | Survives at the base (V7 amp drill green); killed: V11 |
| `[&^]?` on a single-quoted id value (revision 2) | guard grammar | `ampsqid`: prefix dropped from the single-quoted id alternative | same | Killed: V24 (`FAIL: test_the_7ap_spellings_fail`, `Ran 11 tests`, `FAILED (failures=1)`) |
| `-?` in the index grammar | guard grammar | `minus`: `-?` dropped | same | Survives at the base (V4 M-D, `Ran 9 … OK`); killed: V11 |
| Cross product in `_level_pairs` | guard grammar | `cross`: product weakened to `zip` | same | Survives at the base (V4 M-E); killed: V11 |
| Unclosed-brace fallback | guard grammar | `unclosed`: the two fallback lines deleted | same | Survives at the base (V4 M-C); killed: V11 |
| No single-quote consumption (quorum r1): `str.py` stays flagged | guard grammar | `sqstr`: the r0 consumption alternative re-added | same | Killed: V11 — `str.py:1` vanishes from both lists (the quorum round 1 finding, made a drill) |
| No single-quote consumption: `flank.gd` / `flank.py` stay flagged | guard grammar | `sqstr`: the consumption alternative re-added | same | Killed: V11 — `flank.gd:1` and `flank.py:1` vanish; the base reds of V22 stay red at r1 |
| Bad-list assertion is live | meta (fold-in) | `foldin`: `assertEqual(bad, [])` → `assertEqual(bad, bad)` **and** the wrong pair restored at `tools/earth_link_capture.gd:16` | `test_the_7ap_guard_test_can_fail` sub-case 1 | Survives at the base (V4 M-A, `Ran 9 tests … OK`); killed: V11 (K-A) |
| Positive control is live (both lines) | meta (G13) | `assertin`: both `assertIn` lines deleted | sub-case 2 | Survives at the base (V4 M-B); killed: V11 (K-B) |
| Each `assertIn` live on its own | meta (quorum r1) | `assertin1` / `assertin2`: one `assertIn` line deleted | sub-cases 4 and 3 | Survived sub-case 2 alone (the quorum r1 survivor note — now closed); killed: V11 |
| `SG_PREREQS` new pairs | lint pin | `Makefile:134` deleted | `make script-gate-lint` | Green at the base (V19); red after: V11 (2 named refusals, rc 2) |
| `SG_PREREQS_PAIRS := 9` | lint pin | one pair dropped from the list | same | Red after: V11 (pin message, rc 2) |
| Pipe drain, line 14 and line 19 | stderr hygiene | `sigpipe`: both lines reverted to `grep -q` / `awk … exit` | `dash` with SIGPIPE ignored | 10 `printf: I/O error` pre-fix, 0 after, verdicts identical (V12) |

## Milestones

| Id | Sub-items | Files | Lines | Order |
|---|---|---|---|---|
| M1 | (a) grammar + eight-text control, (b) unclosed text; the comment block | `tools/test_replay.py` | ~44 | 1 |
| M2 | fold-in/G13 meta test, four sub-cases | `tools/test_replay.py` | ~17 | with M1 (same file) |
| M3 | (e) four pairs, pin 9, fixture line | `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt` | ~5 | independent |
| M4 | (f) drain both consumers + comment | `tools/script_gate_prereqs.sh` | ~7 | independent |
| M5 | Evidence and changelog: AC1–AC15, the fragment | `changelogs/unreleased/…` | ~6 | last |

The executor applies Appendix A as one patch and commits it (AC1); the milestones are the units it reports and the evaluator scores. Expected wall time: under 10 minutes of commands — the guard runs in ~0.25 s, the lint in ~10 s, and AC10's dash drills in ~2 s each (V10, V12).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A future edit re-adds a single-quote consumption alternative (draft r0's blinding) | The flank controls and `str.py` die the moment it lands (V11 `sqstr` drill: the three texts vanish from the lists); the patch's comment block says why there is none; the tree re-measured 0 blinded / 0 gained with the revised grammar (V8, Appendix B oracle). |
| Matched apostrophes flank a real pair in a comment or string (the M-a class, V22) | Fail closed, loud, by design — the flank controls pin it by name in both languages, and the Appendix B oracle re-measures the tree (AC13). |
| The cross product over-reports (a dict with two wrong pairs yields up to four entries) | Loud by design; `two.gd` pins the exact two cross-wrong messages. |
| The meta test hardcodes the `:10`/`:16` line pins | The main test's `assertIn`s already pin them (D-149, by design: a harmless shift fails loudly). The meta fixture spells its own texts, so it never reads the real files. |
| A future pair genuinely needs an attended hold (the old `SOURCE_PENDING` use case) | That is a new decision (D-149's precedent); the mechanism is in git history and comes back with its own control. |
| `dash -c 'trap "" PIPE; …'` only approximates the runner's SIGPIPE-ignored state | The mechanism reproduced exactly (10 errors pre-fix, 0 fixed, V12) and the verdicts were identical throughout — the fix is safe even where the noise never appears (bash is silent, V12). |
| A reviewer "simplifies" `!seen` back to `exit`, or `-q` back in | AC10's mutation drill makes the noise return on demand; the comment in the script says why. |
| The four new `SG_PREREQS` pairs make the list longer to read | The pin moves 5 → 9 in the same commit; the comment line names the new class. A dropped pair fails the pin (V11). |
| `shellcheck`/`dash` absent on the executor's host | AC10 and AC11 say what to skip and what to record instead; the verdict columns still run under `sh`. |

## Deferred items

Each has a measured reason.
- **(a) Comment-awareness.** A wrong pair in a `#`/`##` comment fails the guard (V6) — fail closed, loud, and fixable by editing the comment — and so does the apostrophe-flanked case, in both languages (V22; the `flank.gd`/`flank.py` controls pin it). The tree holds one comment-line id token (`tools/bright_star_audit.gd:8`) and it pairs with nothing (V3). Draft r0's consumption alternative silenced exactly the flanked case; it is dropped, and the `sqstr` drill proves the controls die if it returns (V11). A string- and comment-aware lexer is a real lint with its own false-positive surface; not cheap, not silent, deferred.
- **(a) A brace inside a single-quoted string between an index and an id** (quorum r2, gemini) splits the dictionary frame and hides the pair. Pre-existing: the base grammar has no single-quote consumption either, so nothing regresses. Measured on the tree (V25): 58 single-quoted runs contain a brace, and adding a single-quote consumption changes the pairs of **0** of 503 files (control: a synthetic `{"index": 1, 'x': '}', "id": …}` does differ, so the instrument sees the mechanism). Fixing it needs single-quote consumption, which blinds flanked comments (V22), so it waits for comment-awareness, with the comment case above.
- **(c) AILANG local numbering.** 17 pairs in the 6 test `.ail` files plus 1 in the probe tool (V13), all deliberate; the guard scans `.gd`/`.py` only. An AILANG scan needs a local-catalogue opt-out design (which `*.ail` catalogues are self-numbered); that is a design row of its own, filed to the charter if the queue wants it.
- **(d) `protocol_27_inferred` provenance.** Barnard planned at index 1 (`stars.json` 3) in a frozen recording the fixture README forbids regenerating (V14); the log scan never reads `tests/fixtures/`. If the recording is ever re-recorded, it is a new decision with its own row; nothing here changes.
- **(g) The `ism-bench` boost flake.** One 0.7247 ms reading against the 0.5 ms ceiling under heavy load, passing on the re-run (V15). The bench re-run rule (7am AC10) covers it; watch, do not touch.
- **(b) The stale-pending assertion.** Not deferred — **obsolete**: D-149 removed the mechanism (V2). The manual AC5 drill of D-149 is replaced by the permanent meta test (M2).
- **Fold-in notes, kept as they are:** the `:16` pin (a harmless shift fails loudly, by design); tracked-files-only enumeration and the non-catalogue-id skip (`Sol`) — pre-existing 7am behaviour, with the enumeration control unchanged.

## Open questions for the user

None. This is test hygiene; no pillar, spec, ruling or canon text is touched. (The `protocol_27_inferred` provenance of (d) is recorded in Deferred items as a fact with its measurement, not re-opened here.)

## Deliverables

- The Appendix A patch applied and committed with the changelog fragment `changelogs/unreleased/2026-11-17-source-literal-guard-edges.md`.
- Sprint evidence: AC1–AC15 output in the sprint JSON, including AC4's and AC5's `FAIL` lines (four meta mutations), AC6's seven kill lines, AC7's four named drill files, AC10's `10`/`0` pair, AC12's checked-set pin (`16 []`, the sha256, the 16 names), AC13's oracle output, and AC14's three `pr<n>` lines (or its recorded halt).
- Before landing, the executor re-checks PRs #435, #380, #373 against the four files (`gh pr diff <n> --name-only`) as the blocking AC14 per Conflict surface.
- Landing: this doc moves to `design_docs/implemented/r1/`, with a README index row and the charter row 7ap marked done.

## Verification log

Measured at `1e839e2e` in the throwaway clone `/tmp/claude/stap_iter97_dry` (deleted after), on Voights-Mac-Studio.local (arm64), Python 3.14.5, GNU Make 3.81, `dash` present at `/bin/dash`. Scratch scripts (`oracle_7ap.py`, `newscan.py`, the `mut*.sh` drills) are throwaway oracles under `/tmp/claude/i97w` — Python used as an oracle only, never committed (CLAUDE.md, "Python"). Every mutation was restored with `git checkout --` traps; `git status --porcelain` was empty after each series. **Revision 1** re-measured in a fresh throwaway clone under `/tmp/claude/i97r1` (deleted after): V3, V8, V9, V10, V11, V12 and V17 re-ran there, V22 and V23 re-ran the controller's probes, and the V3/V8 oracle is no longer scratch — it is Appendix B, re-runnable as AC13. Controller-measured rows are attributed in-line (V21 ran outside this sandbox, where `gh` and the GitHub TLS path work).

| V | Claim | Command | Observed |
|---|---|---|---|
| V1 | The base is green | `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; `make -s script-gate-lint \| tail -1` | `Ran 9 tests in 0.240s / OK`; `Ran 38 tests in 5.863s / OK`; `script-gate-prereqs: ok (5 pairs hold …)` |
| V2 | (b) The pending mechanism is gone (D-149) | `grep -n "SOURCE_PENDING" tools/test_replay.py; echo rc=$?` with the control `grep -n "assertIn" tools/test_replay.py \| tail -4` | no output, `rc=1`; control: the guard's two positive controls at `:460` (`ui/transit_harness.gd:10`) and `:461` (`tools/earth_link_capture.gd:16`) |
| V3 | (a) The tree holds none of the four spellings | Appendix B oracle (`fence 7ap.oracle > $W/7ap.oracle.py; python3 $W/7ap.oracle.py` — re-runnable, AC13), re-run at r1 over `git ls-files -- '*.gd' '*.py'` (503 files, harness exempted) | 0 gained pairs (no single-quoted pair, no `&`/`^` key or value); 0 negative indices; 0 levels with a second index or id token; 1 comment-line token (`tools/bright_star_audit.gd:8`), pairing with nothing |
| V4 | The five base survivors (row (a)/(b)/fold-in) | each mutation applied to a copy with `git checkout --` restore, then `python3 tools/test_replay.py MapIndex` | `foldin` (`assertEqual(bad, bad)` + wrong pair at `:16`): `Ran 9 tests in 0.355s / OK`; `assertin` (both `assertIn` deleted): OK; `unclosed` (fallback deleted): OK; `minus` (`-?` dropped): OK; `cross` (zip): OK |
| V5 | The `assertIn`s are live at the base, but only a manual drill says so | `SOURCE_TOKEN`'s `"index"`/`"id"` renamed `"zindex"`/`"zid"` in a copy; guard run | `FAIL: test_source_literals_match_the_map` (+3 more FAILs), the rename is caught — D-149's blind control confirmed; the surviving hole is only the `assertin` mutation (V4) |
| V6 | (a) The false positives fail closed | two scratch files `git add`ed: `# const OLD := {"index": 1, "id": "CNS5:3627"}` in a `.gd` comment; `S = '{"index": 1, "id": "CNS5:3627"}'` in a `.py`; guard run; removed | `FAILED (failures=1)`, naming `tools/_drill_comment.gd:3 CNS5:3627 index 1, stars.json 2` and `tools/_drill_string.py:2 …` — both flagged at the base |
| V7 | (a) Two false negatives are real; two claims are premise corrections | four scratch files `git add`ed (single-quoted dict, `&`-prefixed pair, negative index, two-pair dict); guard run at the base (pristine worktree) and on the patch | base catches only `neg` (`index -1, stars.json 2`) and `two` (both cross-wrong entries) — the negative index **is** checked and the second pair **is** cross-checked; the single-quoted dict and the `&`-prefixed pair pass green. Patch catches all four by name |
| V8 | The revised grammar blinds nothing and finds nothing new on the tree | Appendix B oracle (AC13, re-runnable): base and r1 tokenisers over all 503 files, pair sets compared | `old_pairs 41 new_pairs 41`, `blinded []`, `gained []` — identical pair sets (re-run at r1; draft r0's consumption also measured 0-blinded on the tree, but the class was real off-tree, V22, and is now controlled) |
| V9 | The real-tree outcome is identical, and the checked set is pinned | `python3 -I -c "import sys; sys.path.insert(0,'tools'); import test_replay as t; m=t.MapIndex(); c,b=t.source_index_pairs(m.sources(), m.stars()); print(len(c), b)"` at the base (worktree) and on the r1 patch; AC12 adds the sorted list and its sha256 | `16 []` both; the r1 sorted checked list (16 entries: `tests/test_bridge_monitors.gd:15`, `tests/test_bridge_monitors.gd:16`, `tests/test_earth_beams.gd:15`, `tests/test_earth_history.gd:21`, `tests/test_earth_history.gd:22`, `tests/test_earth_log_bridge.gd:14`, `tests/test_earth_log_bridge.gd:15`, `tools/comms_golden.gd:23`, `tools/comms_station_capture.gd:26`, `tools/comms_station_capture.gd:27`, `tools/earth_link_capture.gd:16`, `tools/earth_rate_fixture.gd:10`, `tools/exposure_solar_recovery.gd:22`, `tools/ism_service_bench.gd:5`, `tools/worlds_leak.py:29`, `ui/transit_harness.gd:10`) sha256 `67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` |
| V10 | The patch is green on every gate it touches | `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; `make -s replay-map-index \| tail -3`; `make -s script-gate-lint \| tail -1`; `make -s python-guard uid-guard \| tail -2` | `Ran 11 tests in 0.211s / OK`; `Ran 40 tests in 2.962s / OK`; `Ran 11 tests / OK`; `script-gate-prereqs: ok (9 pairs hold …)`; `python-guard: ok (25 allowlisted…)`, `uid-guard: ok (495 .uid files)` — re-run at r1 |
| V11 | Every mutation the row names is killed by the patch | the AC4–AC10 drills (`mut foldin assertin assertin1 assertin2 unclosed minus cross ampid sqindex sqid sqstr sigpipe` + the perl Makefile/pin drills), each restored by trap — re-run at r1 | `foldin`/`assertin`/`assertin1`/`assertin2`: `FAIL test_the_7ap_guard_test_can_fail` (failures=1; the single deletions die on sub-cases 4 and 3); `unclosed minus cross ampid sqindex sqid sqstr`: `FAIL test_the_7ap_spellings_fail` (sqstr re-adds the r0 consumption and drops `str.py:1`, `flank.gd:1`, `flank.py:1` from the lists — V22's mechanism); Makefile:134 deleted: rc 2, 2 named refusals; pair dropped: rc 2, pin message; `sigpipe`: 10 I/O errors. `git status --porcelain` empty after every series |
| V12 | (f) The noise is SIGPIPE under an ignored-signal harness, and the fix keeps verdicts | `db=$(env -u MAKEFLAGS … make -pq …)`; `dash -c 'trap "" PIPE; …'` and `/bin/sh` equivalents, before and after the fix; `shellcheck` and `shellcheck -s dash`; the negative control under dash | db = 472,548 bytes; pre-fix dash: 6 I/O errors on the 5-pair run (10 on the 9-pair run), rc 0, ok line unchanged; bash: silent; fixed dash: 0 errors, rc 0; negative control: rc 1, exactly `constellation-test lost its prerequisite starmap-assets` + `missing-target has no rule`, 0 errors; shellcheck clean both modes (re-verified at r1: AC10's `10`/`0` pair identical) |
| V13 | (c) The AILANG figure, re-measured | scratch oracle over `git ls-files -- '*.ail'` for local-numbered catalogue ids | 17 differing pairs in the 6 test files (core_ism_test 4, finder_test 1, similar_test 2, solar_departure_test 3, stops_test 5, trappist1_test 2) + 1 in `sim/tools/solar_departure_probe.ail` — the row's "17 pairs in 6 files" is the test catalogues |
| V14 | (d) The fixture's Barnard plan | `grep -n "Barnard" tests/fixtures/protocol_27_inferred.input.ndjson`; `python3 -c` stars.json index; `sed -n '1,3p' tests/fixtures/README.md` | `:3` plans `Gaia DR3 4472832130942575872` at `"index":1`; stars.json index 3; README: "Do not regenerate the expected file from the new implementation" |
| V15 | (g) The flake's ceiling | `grep -n "delta_median" tools/ism_service_bench.gd` | `:126`: `report.passes = … report.boost.delta_median_ms <= 0.5 …` |
| V16 | Conflict surface | `gh pr diff 435 --name-only -R sunholo-data/stapledons-godot`; `git log origin/main -5 --oneline -- <file>` per file; `git log --branches --not --remotes --oneline` in the mission clone | gh fails: `tls: failed to verify certificate: x509: OSStatus -26276`; every file's last commits are landed rows (see Conflict surface); no local-only commits |
| V17 | The patch is exact, applies to the base, and reverts clean | `git diff 1e839e2e HEAD > 7ap.patch; wc -l; shasum -a 256`; `git apply --check` + apply + gates in a fresh worktree at `1e839e2e`; `git apply -R` + re-apply; `git status` | 148 lines, `66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39` (revision 2; r1 was 146 lines, `1558f198…`); apply --check clean; `Ran 11 tests / OK`, lint `ok (9 pairs …)`; reverse-apply clean and re-apply clean; status empty |
| V18 | `script-gate-selftest` red here is environmental, not the patch | `make -s script-gate-selftest \| tail -3` on the patch and on the pristine worktree | both: `FAIL stub-orphan-child: control (sleep N) not visible to pgrep`, `FAIL 1 of 18 cases` — the same macOS pgrep visibility issue 7ao's (g) measured; identical on the base |
| V19 | (e) The four edges exist, hold in make's database, and are unpinned at the base | `sh tools/script_gate_prereqs.sh Makefile ci-fast:replay-map-index ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls`; then `Makefile:134` deleted with perl and `make -s script-gate-lint` | `ok (5 pairs hold …)` before the patch (the four candidate pairs hold); lint rc 0 with the edge deleted — unpinned at the base; red only after the patch (V11) |
| V20 | `make tools-test`'s mktemp step is blocked in this sandbox (pre-existing) | `make -s tools-test` on the patch and on the pristine worktree | both print the harness `OK` then fail at `mktemp: mkdtemp failed … Operation not permitted` (the sandbox blocks `/var/folders`) — identical on the base; AC2/AC3 use the direct forms, which is what the target runs |
| V21 | The three open PRs touch none of the four 7ap files (controller-measured, outside this sandbox) | 2026-11-17T20:04:02Z, controller (Opus 5.5), where `gh` works: for n in 435 380 373: `gh pr view $n --repo sunholo-data/stapledons-godot --json headRefOid`; `gh pr diff $n --repo sunholo-data/stapledons-godot --name-only > prN.txt`; `grep -cxE 'tools/test_replay.py\|mk/script-gates.mk\|tools/script_gate_prereqs.sh\|tests/fixtures/script_gate/prereq_negative.mk.txt' prN.txt`; `grep -cx Makefile prN.txt` | #435 head `52ed3ebc` files=27 hits=0 makefile=1; #380 head `68e4ca6d` files=31 hits=0 makefile=1; #373 head `e37b3579` files=57 hits=0 makefile=1 — the `Makefile` count of 1 per PR is the known-positive control (the grep sees a listed file); the executor re-runs this as the blocking AC14 |
| V22 | Draft r0's single-quote consumption silently blinds apostrophe-flanked pairs (quorum round 1's M-a; controller first measured, re-run here) | three texts through `source_index_pairs`: `flank.gd` = `# node's old pair: {"index": 1, "id": "CNS5:3627"}, per Barnard's audit`; `flank.py` = `# it's {"index": 1, "id": "CNS5:3627"} that's wrong`; `sqgd.gd` = `const Q := {'index': 1, 'id': 'CNS5:3627'}` — run at the base worktree, with Appendix A r0 (sha `58750e4b…`) applied, and with Appendix A r1 applied | base: `flank.gd:1` and `flank.py:1` both bad (`CNS5:3627 index 1, stars.json 2`), `sqgd.gd` invisible (the false negative this row fixes); r0: only `sqgd.gd:1` bad — the two flank reds are silently consumed whole (the controller's exact finding; `sqgd.gd` is the known positive proving the r0 scan still sees pairs); r1: all three bad — no blinding, the gain kept |
| V23 | GDScript 4 accepts single-quoted strings — the quorum's scoping premise is false (M-b; controller first measured, re-run here) | headless Godot probe on this rig: `godot --headless --script probe_sq.gd` with `extends SceneTree` / `var d := {'id': 'CNS5:3627'}` / `print('single-quoted ok ', d['id'])` | Godot 4.7.2.stable.official.ed1daf0bf prints `single-quoted ok CNS5:3627` — GDScript has single-quoted strings, so r0's Safety claim ("cannot occur … GDScript has no single-quoted strings") was false and the `.py`-only scoping of Alternatives (a4) is rejected; single-quoted `.gd` dictionaries stay scanned |
| V24 | Revision 2's code: the str/flank texts use `a + 1`, `ampsq.gd` is added, the single-quoted id takes `[&^]?`; tests pass and the new prefix is load-bearing (controller, 2026-11-17, scratch clone at `1e839e2e` + r1 patch + the three edits) | `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; then `[&^]?` removed from the single-quoted id alternative and `MapIndex` re-run; `git diff 1e839e2e HEAD > r2.patch; wc -l; shasum -a 256; git diff --numstat` | `OK` (11 tests) and `OK` (40 tests); with the prefix dropped: `FAIL: test_the_7ap_spellings_fail (__main__.MapIndex.test_the_7ap_spellings_fail)`, `Ran 11 tests in 0.216s`, `FAILED (failures=1)`; patch 148 lines, sha256 `66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39`, numstat total `73 11` |
| V25 | A brace inside a single-quoted string never splits a real pair on the tree (quorum r2, gemini; controller, 2026-11-17, same scratch clone) | for every file of `source_files()`: `source_pairs` with the r2 `SOURCE_TOKEN` vs the same grammar plus the r0 single-quote consumption; count single-quoted runs `'(?:[^'\\\n]\|\\\\.)*'` that contain `{` or `}`; control text `d = {"index": 1, 'x': '}', "id": "CNS5:3627"}` | `files 503 pairs 41 single_quoted_runs_with_brace 58 files_where_consumption_changes_pairs []`; control: `control_differs True [] [(5, '1', 'CNS5:3627')]` — the instrument sees the mechanism (the pair is split without consumption) and no real file has it |

## Quorum log

Round 1 (2026-11-17): **BLOCKED 2 of 3** — gemini-4-argon PASS; oc-kimi-k3 REJECT; claude-sonnet-5 REJECT. Neither reject disputes the direction.

| Reviewer | Verdict | Objection, one line | How this revision answers it |
|---|---|---|---|
| gemini-4-argon | PASS | — | Nothing asked; the revision only strengthens what it passed: one grammar alternative dropped, two meta sub-cases, three ACs and an inline oracle added. |
| oc-kimi-k3 | REJECT | The single-quote consumption applies to every file and silently swallows an apostrophe-flanked comment pair — V6's own false-positive mechanism — converting a fail-closed red into a silent pass; the 0-blinded measurements rest on deleted scratch; nothing pins the 16-entry checked set. | The consumption alternative is dropped: the flanked case is red again in both languages, measured (V22), and `str.py` changes meaning to pin the fail-closed string case; the flank texts are named controls with a killing mutation (the `sqstr` re-add, V11); every contradicted sentence is corrected (the Safety paragraph, the patch comment block, Deferred items, Alternatives (a4)/(a5)); the V3/V8 oracle is reproduced inline (Appendix B, run by AC13); the full checked set is pinned by AC12 (count, 16 names, sha256), with V9 carrying the list. |
| claude-sonnet-5 | REJECT | The "closed at pick time" PR-conflict claim rests on an unrecorded `gh` measurement, unlike every other V-entry. | V21 records the controller's measurement verbatim — attributed, timestamped, with its known-positive control — and the executor's pre-landing re-check becomes the blocking AC14: any hit, or a `gh` failure, exits non-zero and halts the landing. |

Round 2 (2026-11-17, on revision 1): **BLOCKED 3 of 3** — gemini-4-argon REJECT; oc-kimi-k3 REJECT; claude-sonnet-5 REJECT. None disputes the direction; each carries a concrete fix. Under the mission's narrow-refinement carve-out the controller applied the three fixes verbatim as **revision 2** (no round 3):

| Reviewer | Verdict | Objection, one line | Revision 2 (controller, fixes verbatim) |
|---|---|---|---|
| gemini-4-argon | REJECT | A brace inside a single-quoted string between `'index'` and `'id'` corrupts the frame stack and hides the pair; the single-quoted id alternative lacks the `[&^]?` prefix although GDScript 4 has single-quoted StringName/NodePath literals. | The prefix is added (`\'id\'\s*:\s*[&^]?\'…`), pinned by the new `ampsq.gd` text and the `ampsqid` mutation (V24, AC6). The brace case is measured, as the fix asks: 0 of 503 files change pairs (V25, with a firing control); it is pre-existing at the base and deferred with comment-awareness (Deferred items). |
| oc-kimi-k3 | REJECT | `str.py`, `flank.gd`, `flank.py` hard-code `"index": 1`, so the "a catalogue reorder does not rot the control" claim is false for three of eight texts. | The three texts and their expectations use `a + 1` (always wrong, since the id's index is exactly `a`); AC7's four drill files use the same runtime `a + 1` (`A1=…`). Appendix A, AC1 and V17 pins regenerated (148 lines, `66f65140…`, `73 11`). AC12's real-tree sha is unchanged (the tree is unchanged). |
| claude-sonnet-5 | REJECT | AC14's three `gh pr diff` calls have no time bound, so a network stall hangs the landing. | Each call runs under `perl -e 'alarm shift; exec @ARGV' 30` (the rig has no GNU `timeout`; this is the repo's own perl-alarm bound): rc 142 prints a timeout line, any other failure an auth/network line, both exit 2, and the AC table says to record which. |

## Appendix A. The patch (`7ap.patch`, 148 lines, sha256 `66f65140d506f69abf3526be01a9a76038661e64a1e9fabbcf207c3918892e39`, against `1e839e2e`)

Extract it with the preamble's `fence 7ap.patch`, check it with AC1's `shasum`, and apply it with `git apply "$W/7ap.patch"`. The blank context lines carry the standard single leading space of a unified diff; `git apply` wants them, and the hygiene check in AC11 excludes the doc for exactly that reason.

```diff 7ap.patch
diff --git a/mk/script-gates.mk b/mk/script-gates.mk
index f4504215..9a096753 100644
--- a/mk/script-gates.mk
+++ b/mk/script-gates.mk
@@ -14,10 +14,11 @@ SG_LINT = SCRIPT_GATE_BASELINE_ROWS=$(SCRIPT_GATE_BASELINE_ROWS) sh $(SG_TOOLS)/
 # Gates whose test needs fetched assets keep the target that fetches them (B3; iteration 70 judge survivor:
 # constellation-test without starmap-assets was red in a fresh clone, unseen). Checked in make -p by script-gate-lint.
 # B4: ship-console-test reads build/ship-baseline (make ship-baseline); without it the test is red in a fresh clone.
-SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index
+# 7ap: the 7ah/7al guard targets keep their ci-fast edges (a dropped edge leaves the fast tier green).
+SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index ci-fast:similar-main-guard ci-fast:similar-guard-controls ci-fast:session-minor-guard ci-fast:session-minor-guard-controls
 # Pairs in SG_PREREQS, distinct (B4; iteration 71 judge survivor: dropping a pair passed, because the negative control
 # and the real check both read the list). script-gate-lint fails on any mismatch; the pin moves with the pairs, and only up.
-SG_PREREQS_PAIRS := 5
+SG_PREREQS_PAIRS := 9
 # Outer deadline for the self-tests (round-2 amendment A2): the same process-group supervisor as tools/script_gate.sh,
 # so a broken helper cannot hang make test. Usage: $(SG_SUP) SECS command...
 SG_SUP = perl -e 'use POSIX ":sys_wait_h"; my $$secs = shift; my $$pid = fork; die "fork: $$!" unless defined $$pid; if ($$pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; } my $$end = time + $$secs; my $$st; while (1) { my $$r = waitpid($$pid, WNOHANG); if ($$r == $$pid) { $$st = $$?; last } if (time >= $$end) { kill "TERM", -$$pid; my $$g = time + 2; while (time < $$g) { last if waitpid($$pid, WNOHANG) == $$pid; select(undef, undef, undef, 0.1) } kill "KILL", -$$pid; waitpid($$pid, 0); kill "KILL", -$$pid; exit 142 } select(undef, undef, undef, 0.1) } exit($$st & 127 ? 128 + ($$st & 127) : $$st >> 8)'
diff --git a/tests/fixtures/script_gate/prereq_negative.mk.txt b/tests/fixtures/script_gate/prereq_negative.mk.txt
index 70560276..418e0903 100644
--- a/tests/fixtures/script_gate/prereq_negative.mk.txt
+++ b/tests/fixtures/script_gate/prereq_negative.mk.txt
@@ -8,3 +8,5 @@ planet-textures-check:
 planet-textures-check: planet-assets
 ship-console-test: import ship-baseline
 ci-fast: replay-map-index
+# 7ap: the 7ah/7al ci-fast edges keep holding here too (merged rule line)
+ci-fast: similar-main-guard similar-guard-controls session-minor-guard session-minor-guard-controls
diff --git a/tools/script_gate_prereqs.sh b/tools/script_gate_prereqs.sh
index a6eafed6..f03b84eb 100644
--- a/tools/script_gate_prereqs.sh
+++ b/tools/script_gate_prereqs.sh
@@ -11,12 +11,15 @@ shift
 # The database is printed even though the probe target does not exist (make then exits 2); MAKEFLAGS from an outer
 # make (command-line variables, -n) must not change what the inner one reads.
 db=$(env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL make -pq --no-print-directory -f "$mf" script-gate-prereqs-probe 2>/dev/null)
-printf '%s\n' "$db" | grep -q '^# Make data base' || { echo "script-gate-prereqs: make printed no database for $mf"; exit 1; }
+# 7ap: both consumers below read the database to its end. grep -q and awk's exit both quit at the first
+# match, and dash's builtin printf then reports "I/O error" under the runner (SIGPIPE ignored there);
+# verdicts never changed, only stderr noise reached every fast-tier log.
+printf '%s\n' "$db" | grep '^# Make data base' >/dev/null || { echo "script-gate-prereqs: make printed no database for $mf"; exit 1; }
 fail=0 n=0
 for pair in "$@"; do
   t=${pair%%:*} p=${pair#*:}
   n=$((n + 1))
-  line=$(printf '%s\n' "$db" | awk -v t="$t:" 'index($0, t) == 1 && $0 !~ /=/ { print; exit }')
+  line=$(printf '%s\n' "$db" | awk -v t="$t:" 'index($0, t) == 1 && $0 !~ /=/ && !seen { print; seen = 1 }')
   if [ -z "$line" ]; then echo "script-gate-prereqs: $t has no rule in $mf"; fail=1; continue; fi
   case " ${line#*:} " in
     *" $p "*) ;;
diff --git a/tools/test_replay.py b/tools/test_replay.py
index 93a538c8..06da31fe 100644
--- a/tools/test_replay.py
+++ b/tools/test_replay.py
@@ -335,7 +335,15 @@ def plan_index_mismatches(log_texts, stars):
 #  The pair is taken within one dictionary: SOURCE_TOKEN lists each "index" and "id" literal and each
 # brace, and other string literals are consumed whole, so a "pos": {...} between the keys does not hide
 # the pair, and a nested dictionary's id is never paired with the outer index (both key orders).
-SOURCE_TOKEN = re.compile(r'"index"\s*:\s*(-?\d+)|"id"\s*:\s*"((?:[^"\\\n]|\\.)*)"|"(?:[^"\\\n]|\\.)*"|([{}])')
+#  7ap: single-quoted Python/GDScript keys pair with single-quoted ids, an id value may carry GDScript's &/^
+# literal prefix, and every index at one level pairs with every id there (a second pair in one dictionary is
+# cross-checked, not first-wins). Other single-quoted strings are NOT consumed: a consumption alternative
+# blinded matched apostrophes around a pair (a comment like "node's ... {\"index\": 1, ...} ... Barnard's"
+# lost its pair), so a pair inside single-quoted string text, or flanked by apostrophes in a comment, is
+# still seen and fails closed (comment-awareness is deferred). An unclosed dictionary still counts.
+SOURCE_TOKEN = re.compile(r'"index"\s*:\s*(-?\d+)|\'index\'\s*:\s*(-?\d+)|'
+                          r'"id"\s*:\s*[&^]?"((?:[^"\\\n]|\\.)*)"|\'id\'\s*:\s*[&^]?\'((?:[^\'\\\n]|\\.)*)\'|'
+                          r'"(?:[^"\\\n]|\\.)*"|([{}])')
 SOURCE_EXEMPT = ("tools/test_replay.py",)
 
 
@@ -375,15 +383,17 @@ def source_pairs(text):
     """(start, index, raw id) for each dictionary in text, in source order (dictionary-aware, see SOURCE_TOKEN)."""
     out, frames = [], [[]]
     for m in SOURCE_TOKEN.finditer(text):
-        if m.group(3) == "{":
+        i = m.group(1) if m.group(1) is not None else m.group(2)
+        d = m.group(3) if m.group(3) is not None else m.group(4)
+        if m.group(5) == "{":
             frames.append([])
-        elif m.group(3) == "}":
+        elif m.group(5) == "}":
             if len(frames) > 1:
                 out.extend(_level_pairs(frames.pop()))
-        elif m.group(1) is not None:
-            frames[-1].append((m.start(), "index", m.group(1)))
-        elif m.group(2) is not None:
-            frames[-1].append((m.start(), "id", m.group(2)))
+        elif i is not None:
+            frames[-1].append((m.start(), "index", i))
+        elif d is not None:
+            frames[-1].append((m.start(), "id", d))
     for level in frames:  # unclosed braces: the open dictionaries still count
         out.extend(_level_pairs(level))
     return sorted(out)
@@ -504,6 +514,52 @@ class MapIndex(unittest.TestCase):
                                "q.gd:1 CNS5:3627 index 1, stars.json %d" % a])
         self.assertEqual(checked, ["p.gd:1", "q.gd:1", "ok.gd:1"])  # n.gd: the nested id is not paired with the outer index
 
+    def test_the_7ap_spellings_fail(self):  # control: 7ap spellings, at a wrong index or in a hidden shape, are caught by name
+        stars = self.stars()
+        a, b = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681")
+        texts = [("sq.py", "t = {'index': %d, 'id': 'CNS5:3627'}\n" % (a + 1)),
+                 ("amp.gd", 'const A := {&"index": %d, &"id": &"CNS5:3627"}\n' % (a + 1)),
+                 ("neg.gd", 'const N := {"index": -1, "id": "CNS5:3627"}\n'),
+                 ("two.gd", 'const T := {"index": %d, "id": "CNS5:3627", "index": %d, "id": "HIP 71681"}\n' % (a, b)),
+                 ("unc.gd", 'const U := {"index": %d, "id": "CNS5:3627"\n' % (a + 1)),
+                 ("str.py", "S = '{\"index\": %d, \"id\": \"CNS5:3627\"}'\n" % (a + 1)),
+                 ("flank.gd", "# node's old pair: {\"index\": %d, \"id\": \"CNS5:3627\"}, per Barnard's audit\n" % (a + 1)),
+                 ("flank.py", "# it's {\"index\": %d, \"id\": \"CNS5:3627\"} that's wrong\n" % (a + 1)),
+                 ("ampsq.gd", "const S := {'index': %d, 'id': &'CNS5:3627'}\n" % (a + 1))]
+        checked, bad = source_index_pairs(texts, stars)
+        self.assertEqual(bad, ["sq.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "amp.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "neg.gd:1 CNS5:3627 index -1, stars.json %d" % a,
+                               "two.gd:1 HIP 71681 index %d, stars.json %d" % (a, b),
+                               "two.gd:1 CNS5:3627 index %d, stars.json %d" % (b, a),
+                               "unc.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "str.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "flank.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "flank.py:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "ampsq.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a)])
+        self.assertEqual(checked, ["sq.py:1", "amp.gd:1", "neg.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "two.gd:1", "unc.gd:1", "str.py:1", "flank.gd:1", "flank.py:1", "ampsq.gd:1"])
+
+    def test_the_7ap_guard_test_can_fail(self):  # meta (iteration-91 fold-in): each assertion in the source-literal test is live
+        m = MapIndex("test_source_literals_match_the_map")
+        stars = self.stars()
+        a = self.at(stars, "CNS5:3627")
+        named = [("ui/transit_harness.gd", "\n" * 9 + 'const T := {"index": %d, "id": "CNS5:3627"}\n' % a),
+                 ("tools/earth_link_capture.gd", "\n" * 15 + 'const E := {"index": %d, "id": "CNS5:3627"}\n' % a)]
+        m.sources = lambda: named + [("fixture.gd", 'const BAD := {"index": %d, "id": "CNS5:3627"}\n' % (a + 1))]
+        with self.assertRaises(AssertionError):
+            m.test_source_literals_match_the_map()  # the bad-list assertion fails on the wrong pair; assertEqual(bad, bad) would not
+        m.sources = lambda: named
+        m.stars = lambda: []  # a scan that checks no pair: only the positive control can fail it
+        with self.assertRaises(AssertionError):
+            m.test_source_literals_match_the_map()
+        m.stars = lambda: stars
+        m.sources = lambda: named[:1]  # the scan sees only the transit_harness positive
+        with self.assertRaises(AssertionError):
+            m.test_source_literals_match_the_map()  # the earth_link assertIn fails on a scan that misses its pair
+        m.sources = lambda: named[1:]  # the scan sees only the earth_link positive
+        with self.assertRaises(AssertionError):
+            m.test_source_literals_match_the_map()  # the transit_harness assertIn fails on a scan that misses its pair
+
 
 class AiSession(unittest.TestCase):
     """The committed ai_sim_session log is exactly what tools/gen_ai_session.py writes (AI.3)."""
```

## Appendix B. The blinding oracle (V3/V8, re-runnable)

Quorum round 1 objected that the 0-blinded tree measurements rested on scratch oracles under a deleted
`/tmp`. This is the oracle, inline: it re-implements `source_pairs` for the base grammar (embedded
verbatim) and runs both tokenisers over every tracked `.gd`/`.py` file, printing the blinded/gained
pair deltas and the V3 spelling counts. Run it from the repo root with Appendix A applied, via the
preamble's `fence` (AC13 does exactly this):

```sh
fence 7ap.oracle > "$W/7ap.oracle.py"
python3 "$W/7ap.oracle.py"
```

Both `blinded` and `gained` must print `[]` (V8); the spelling counts must print the V3 zeros. Python is
used as an oracle only, in the executor's scratch `$W`, never committed.

```python 7ap.oracle
# 7ap.oracle (r1): the V3/V8 tree measurement, re-runnable -- base grammar vs the patched SOURCE_TOKEN
# over every tracked .gd/.py file (the harness exempts itself). Run from the repo root, with Appendix A
# applied:  python3 7ap.oracle.py
# Prints: file count, the two pair sets' sizes, blinded/gained deltas (both must be []), and the
# spelling counts the row claims are zero (V3). Python used as an oracle only, never committed.
import re
import sys

sys.path.insert(0, "tools")
import test_replay as t

# SOURCE_TOKEN at 1e839e2e, verbatim (the base this patch is measured against)
BASE = re.compile(r'"index"\s*:\s*(-?\d+)|"id"\s*:\s*"((?:[^"\\\n]|\\.)*)"|"(?:[^"\\\n]|\\.)*"|([{}])')
lp = t._level_pairs  # the pairing rule, unchanged by the patch


def pairs_of(tok, igroups, idgroups, bgroup, text):
    """source_pairs' frame walk for either grammar, via each grammar's group layout."""
    out, frames = [], [[]]
    for m in tok.finditer(text):
        i = next((m.group(g) for g in igroups if m.group(g) is not None), None)
        d = next((m.group(g) for g in idgroups if m.group(g) is not None), None)
        if m.group(bgroup) == "{":
            frames.append([])
        elif m.group(bgroup) == "}":
            if len(frames) > 1:
                out.extend(lp(frames.pop()))
        elif i is not None:
            frames[-1].append((m.start(), "index", i))
        elif d is not None:
            frames[-1].append((m.start(), "id", d))
    for level in frames:  # unclosed braces: the open dictionaries still count
        out.extend(lp(level))
    return sorted(out)


def keyed(pairs, name, text):
    return {(name, text.count("\n", 0, s) + 1, i, raw) for s, i, raw in pairs}


srcs = list(t.MapIndex().sources())
old_set, new_set = set(), set()
for name, text in srcs:
    old_set |= keyed(pairs_of(BASE, (1,), (2,), 3, text), name, text)
    new_set |= keyed(pairs_of(t.SOURCE_TOKEN, (1, 2), (3, 4), 5, text), name, text)
print("files", len(srcs))
print("old_pairs", len(old_set), "new_pairs", len(new_set))
print("blinded", sorted(old_set - new_set))
print("gained", sorted(new_set - old_set))
print("neg_index_pairs", sorted(p for p in new_set if p[2].startswith("-")))
print("amp_or_caret_tokens",
      sum(len(re.findall(r'[&^]"(?:index|id)"', text)) + len(re.findall(r'"id"\s*:\s*[&^]"', text))
          for _, text in srcs))
# levels holding a second index or id token, and index/id tokens on # comment lines (V3)
second, comment = [], []
for name, text in srcs:
    lines = text.splitlines()
    frames = [[]]
    def look(level):
        if level.count("index") >= 2 or level.count("id") >= 2:
            second.append((name, level.count("index"), level.count("id")))
    for m in t.SOURCE_TOKEN.finditer(text):
        i = m.group(1) if m.group(1) is not None else m.group(2)
        d = m.group(3) if m.group(3) is not None else m.group(4)
        if m.group(5) == "{":
            frames.append([])
        elif m.group(5) == "}":
            if len(frames) > 1:
                look(frames.pop())
        elif i is not None or d is not None:
            frames[-1].append("index" if i is not None else "id")
            if lines[text.count("\n", 0, m.start())].lstrip().startswith("#"):
                comment.append((name, text.count("\n", 0, m.start()) + 1))
    for level in frames:
        look(level)
print("levels_with_second_token", sorted(set(second)))
print("comment_line_tokens", sorted(set(comment)))
```
