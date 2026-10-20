# Display audit: AC4 verdict after D-77/D-78 A (row 7p)

**Status:** Planned (mission iteration 40, designer, revision round 2, 2026-10-20). **Release:** r1. **Milestone:** M4.5, charter queue row 7p within approved sprint `R1-M4-JOURNEY` (D-66).
**Priority:** P1. Close the AC4 verdict gap after Mark's attended rulings; other clause-4 gates retain their own evidence requirements.
**Implements:** [m4-first-journey.md](m4-first-journey.md) AC4, amended by **D-77 A** and **D-78 A**, attended 2026-10-19 in the [decision ledger](../../stapledon-mission.md#decision-ledger); [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) M4, display acceptance. The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#4-test-requirements) and [Higgs-bubble spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md#6b-dust-grain-impacts-and-the-wall-afterglow-d-60-d-61) remain normative; this row changes no numerical claim or check value.
**Depends on:** the landed five-entry display ratchet and row 7i(j) controls, present at `d6ef45e1`; resolved D-77/D-78 A. Pinned AILANG v0.54.14. No package, simulation, protocol, physics or production UI change.
**Estimated LOC:** about **90 code + test/data lines**: ~40 audit, ~20 make controls, ~30 compact JSON fixture/metadata lines; plus ~15 documentation/sprint-record lines. One implementation step. This exceeds the queue's ~15-line suggestion because explicit validation and four rejection controls replace free-text citation matching.
**Evidence:** Verification log below, pinned to `d6ef45e1` (canon checkout `2ef3656`). This design task delivers only this file; all implementation edits below belong to the executor.

## Game vision alignment

Scored using `game-vision-designer` feature validation against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | Audit metadata and verdicts issue no journey inputs. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy or judgement changes. |
| Time Has Emotional Weight | 0 | 0 | Both clocks and all timing checks retain their current contracts. |
| The Ship Is Home | 0 | 0 | Cards, their priority and the ship scene are unchanged. |
| Grounded Strangeness | 0 | 0 | No world, species or visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | The same four notation captions and one folded-card case remain pinned. Binding, source, lore, new/stale and card-state checks still run. |
| **Net** | | **0** | **Go under D-88 A:** test/audit hygiene inside the D-66-approved sprint, with no negative pillar, does not stop for Mark. |

No mechanism warrants a negative pillar. This records settled rulings and tests their narrow application; it invents no new exception.

## Problem

`tests/display_audit.gd:377` prints bare `ac4: MET` only for an empty `known_entries` array. Otherwise it prints OPEN, regardless of the rulings accepting the entries. The baseline known control reproduces `ac4: OPEN (4 known unbound, 1 known transit-ISM)` with `failures=0` (V1–V4).

**Controller-supplied scene baseline (pristine `d6ef45e`, pinned runtime; not re-run in this file-only revision):** `make scene-session-audits` returned rc 0 in 177 s, ending with `ac4: OPEN (786 known unbound, 42 known transit-ISM)` and `display-audit: samples=716 checks=177686 mismatches=0 missing=0 new=0 known=828 stale=0 failures=0`. This is the old verdict with zero audit failures, not evidence of the proposed implementation. The controller's V9/V10/V10b source measurements are independently re-run below.

The five production pins are four caption entries and one transit-ISM entry. Their `why` strings still describe an unresolved choice: the captions say rewording needs Mark (D-78), and the transit entry has no D-77 citation. Mark has already accepted both cases. The parent AC4 row at line 664 still demands literal zero unbound numerals and the ISM readout on every transit sample; it has not incorporated the amendments (V5–V6).

Queue row 7p suggests matching D-77/D-78 inside `why`. That would let a discussion reference grant acceptance, or a prose typo revoke it. A validated field makes the authority reviewable without making prose executable.

## Goals and non-goals

**Goals.** All five ruling-accepted pins produce a qualified MET verdict. Any otherwise valid known entry without acceptance keeps AC4 OPEN. Invalid acceptance metadata is a loader failure. Empty-known retains the exact `ac4: MET` line. Controls distinguish these outcomes and kill the three required mutations.

**Non-goals.** No caption rewording, card reprioritisation, new finding exemptions, occurrence-band tightening (row 7i(d)), control-list self-count gate (row 7i(l)), replay golden, or other clause-4 closure. No Python. No package, sim, shader, numerical precision, runtime protocol or scene change; existing determinism and physics gates remain applicable to the unchanged game.

## Design

Add optional, tightly validated `accepted_by` metadata to known findings, then compute the verdict from accepted **entries**, not finding occurrences or prose citations.

### 1. Loader validation and the five pins

#### Attended authority (verbatim)

The following question and ANSWERED excerpts are from `design_docs/stapledon-mission.md` at `d6ef45e1`, measured again in V12. Provenance boilerplate is omitted; the rulings are settled.

**D-77, line 191:**

> M4 AC4 says both clocks and the ISM readout show on every transit sample. On the 3D ship, during braking, the Braking notice and the medium-boundary notice take both expanded card slots and fold the transit card (with its ISM readout) for about 2.8 s (42 of 716 samples). Which do you want? **A** — amend AC4: a folded transit card under those two named notices counts as shown (the ratchet already allows exactly this case, nothing else). **B** — keep AC4 literal: change the card priority so the transit card never folds in transit (a visible HUD change, attended). Recommendation: A. Default if unanswered: A stays in force as a pinned known finding, and AC4 stays OPEN only on the unbound labels (row 7i(a)).  **ANSWERED — DECIDED (Mark, attended 2026-10-19): A. Amend AC4: a transit card folded under the Braking notice and the medium-boundary notice counts as shown; the ratchet keeps exactly that case pinned, nothing else.**

The §1 transit identity and its exact `Card_medium_notice`/`Card_notice` pair bind acceptance to the two notices in this ruling; the text identifies the folded ISM readout.

**D-78, line 192:**

> M4 AC4 asks for 0 unbound numerals. After iteration 30 bound every value, four GalaxyMap row CAPTIONS still carry a digit that is notation, not a value: `Cruise 1 - beta`, `  its 1 - beta`, `1 - beta` and `Grains swept (>= 1 um)`. Which do you want? **A** — amend AC4: a constant notation digit in a row caption is not a numeral (the ratchet keeps exactly these four pinned, nothing on screen changes). **B** — reword the four captions digit-free (for example `one minus beta`, `Grains swept (micron and larger)`), a visible copy change, attended. Recommendation: A (the notation is the precise physics label; rewording loses it). Default if unanswered: A stays in force as four pinned known findings, and AC4 closes once D-77 and D-78 are answered.  **ANSWERED — DECIDED (Mark, attended 2026-10-19): A. Amend AC4: a constant notation digit in a row caption (1 - beta, >= 1 um) is not a numeral; the four captions stay pinned and unchanged on screen. With D-77, AC4 closes.**

The §1 four caption identities bind acceptance to exactly the four notation captions in this ruling after the existing digit normalization; the node keeps acceptance on those GalaxyMap row labels.

**D-88, line 202:**

> Row 7i(j) (PR #252: three display-audit control fixtures plus a distinct `context-presence` reason, about 12 lines, test-only) scores pillar net 0, because it is pure test hygiene under the approved D-66 plan. The guardrail "stop for the user at any pillar score of 0 or below" therefore holds its merge. Which do you want? **A** — merge #252, and amend the guardrail: test or audit hygiene inside an already-approved sprint, with no pillar below 0, does not stop (it still stops on any negative pillar). **B** — merge #252 only, and keep the guardrail strict, so every net-0 hygiene row waits for you. **C** — close #252. Recommendation: A (the change kills three surviving mutants of a clause-4 gate, the independent judge scored it 93 with 0 blocking, and net 0 is the honest score for any hygiene row). Default if unanswered: #252 stays open and unmerged, and the loop keeps working other rows.  **ANSWERED — DECIDED (Mark, attended 2026-10-19): A. Merge #252, and amend the guardrail: test or audit hygiene inside an already-approved sprint with no pillar below 0 does not stop for the user; any negative pillar still stops.**

The §1 metadata validator and controls implement audit hygiene inside the D-66-approved sprint; the unchanged net-zero pillar table has no negative pillar, satisfying this ruling.

Keep all current field, row, duplicate and positive-integer `observed_samples` checks. After node/text/card normalization, before appending an entry, call `ruling_valid(entry) -> bool`. Absent `accepted_by` is valid legacy metadata but grants no acceptance. If present, it must be a string with one of these exact values and identities:

| Value | Only permitted normalized identity |
|---|---|
| `D-77` | Kind `transit-ISM`; node `/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_transit`; text `missing ship.ism.glow_w_mN`; folding card the same Cards prefix plus `Card_medium_notice`; accompanying card that prefix plus `Card_notice`. |
| `D-78` | Kind `unbound`; node `/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label`; text exactly one of `Cruise N - beta`, `N - beta`, `  its N - beta`, `Grains swept (>= N um)`. |

#### Fixture literals and ruling mapping (verbatim)

`tests/fixtures/display_audit/known_findings.json:3–44` at `d6ef45e1` contains the following five entries, in order. These are verbatim field excerpts with only `why` lines omitted. `folding_card` and `accompanying_card` are **absent** on all four caption entries; they are not empty strings or nulls (V12).

```json
{
  "findings": [
    {
      "kind": "unbound",
      "node": "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label",
      "text": "Cruise N - beta",
      "observed_samples": 54,
      "row": "M4.5bR3-follow-up"
    },
    {
      "kind": "unbound",
      "node": "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label",
      "text": "N - beta",
      "observed_samples": 624,
      "row": "M4.5bR3-follow-up"
    },
    {
      "kind": "unbound",
      "node": "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label",
      "text": "  its N - beta",
      "observed_samples": 54,
      "row": "M4.5bR3-follow-up"
    },
    {
      "kind": "unbound",
      "node": "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label",
      "text": "Grains swept (>= N um)",
      "observed_samples": 54,
      "row": "M4.5bR3-follow-up"
    },
    {
      "kind": "transit-ISM",
      "node": "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_transit",
      "text": "missing ship.ism.glow_w_mN",
      "observed_samples": 42,
      "folding_card": "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_medium_notice",
      "accompanying_card": "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/Card_notice",
      "row": "M4.5bR3-follow-up"
    }
  ]
}
```

| Fixture source lines | Literal text | Mapping to the `ruling_valid` table above |
|---|---|---|
| 3–10 | `Cruise N - beta` | D-78, unbound row-label node; normalized `Cruise 1 - beta` named at ledger line 192. |
| 11–18 | `N - beta` | D-78, same node; normalized `1 - beta` named at line 192. |
| 19–26 | `  its N - beta` | D-78, same node; normalized `  its 1 - beta` named at line 192, including its two leading spaces. |
| 27–34 | `Grains swept (>= N um)` | D-78, same node; normalized `Grains swept (>= 1 um)` named at line 192. |
| 35–44 | `missing ship.ism.glow_w_mN` | D-77, transit node and the two exact notice-card paths quoted above; the folded ISM case at line 191. |

The leading double space in `"  its N - beta"` is in the fixture, not a typo: re-running the controller's `jq -r '.findings[].text|@json' tests/fixtures/display_audit/known_findings.json` prints `"  its N - beta"` as its third line. Digit normalization (`tests/display_audit.gd:43–44`) substitutes digits only and preserves this whitespace. Every `observed_samples` and `row` literal above remains unchanged; neither field grants acceptance.

Use exact tuple equality, not suffix or substring matches. Unknown IDs, empty/null/non-string values, cross-kind use, other captions/nodes, or a different card pair return false. The loader seam is `if not ruling_valid(entry):`, followed by `check(false, "known-ruling invalid acceptance"); continue`. This stable reason is separate from `known-file invalid entry fields`. Missing metadata must never be defaulted from `why`.

This adds a narrow identity allowlist for acceptance, not another finding matcher. `finding()` continues matching the existing ratchet and checking visible, expanded/folded and non-leaving card states. An accepted entry still must be observed; all new/stale checks and exit-status rules remain intact. Existing digit normalization is preserved, including the renumbered control; D-78 does not introduce a broader exemption for arbitrary unbound entries.

In `known_findings.json`, add `accepted_by: D-78` to the four captions and `accepted_by: D-77` to the transit pin. Rewrite their `why` prose to describe the attended acceptance, explicitly citing the respective ruling. Retain every identity, sample count and `row`. Do not require updating `known_stale.json`: legacy entries without acceptance remain loadable and its extra unobserved entry must still fail `stale-known`.

### 2. Verdict with visible provenance

Extract `ac4_verdict() -> String`; `_run()` prints its result at the current verdict location. Use these concrete seams so the drills below apply:

```gdscript
func ac4_verdict() -> String:
	var accepted_count := 0
	for finding_entry: Dictionary in known_entries:
		if finding_entry.has("accepted_by"): accepted_count += 1
	if known_entries.is_empty(): return "ac4: MET"
	if accepted_count == known_entries.size():
		return "ac4: MET (%d accepted by D-77/D-78)" % accepted_count
	return "ac4: OPEN (%d unaccepted known, %d accepted by D-77/D-78)" % [known_entries.size() - accepted_count, accepted_count]
```

`known_entries` is already script-scope: `tests/display_audit.gd:20` is the unindented declaration `var known_entries: Array = []`, before the first function at line 43; `load_known()` appends to that same array at line 85 (V10). The extracted `ac4_verdict()` therefore reads the existing array without a scope change. Counting presence is safe only after the loader's validation. Its removal is explicitly mutation-tested. Counts are distinct entries: the scene prints `ac4: MET (5 accepted by D-77/D-78)`, not 828 accepted occurrences. OPEN is a verdict, not an audit error: an unaccepted but pinned finding still permits process rc 0 with `failures=0`. Invalid metadata, NEW findings and stale pins still exit nonzero. A verdict alone never overrides the summary or process status.

### 3. Controls in `mk/m45.mk`

V9 enumerates every executable consumer of `ac4:` in the searched build/test/tool paths at this base: (1) `mk/m45.mk:14` echoes matching scene lines with `^(FAIL|display-audit|ai-mode|ac4:)`, but asserts rc, no script error and `^display-audit: .* failures=0$`, not the AC4 verdict; (2) `mk/m45.mk:17` asserts `^ac4: MET$` on `display-valid.log`. `tests/display_audit.gd:377` is the producer. The other `ac4` search hits are hash substrings in AI goldens/replays. Historical evaluation JSONs and `website/src/data/decisions.json` quote the old OPEN verdict as history, not executable consumers; leave them unchanged.

V10 measures the known-file loads: valid uses `empty_known.json`; known **and** known_renumbered both use `known_findings.json`. The `known known_stale.json stale-known` rejection row uses `known_stale.json`; it needs no acceptance migration and must still fail `stale-known`. All **20** current spec rows and their known-file assignments are enumerated in V10. New controls use the files specified below.

Preserve the exact empty-known grep `^ac4: MET$` on `display-valid.log`. Add qualified-MET greps to the existing `display-known.log` and `display-known-renumbered.log` positive controls: `^ac4: MET \(5 accepted by D-77/D-78\)$` with `grep -E`. Retain the existing rc, summary, known-kind (where present) and script-error checks verified in V9; the qualified-MET greps are additional assertions.

Add one positive audit run using **existing `known.ndjson`** and new `known_unaccepted.json`: copy the amended five pins, remove only the transit pin's `accepted_by`, and retain its D-77 prose. Require rc 0, `new=0`, `stale=0`, `failures=0`, no script error and exact `ac4: OPEN (1 unaccepted known, 4 accepted by D-77/D-78)`. Log to `display-known-unaccepted.log`. On verdict mismatch print `display control known_unaccepted verdict missed` and exit 1. This proves prose alone cannot accept a finding, and mixed accepted/unaccepted lists stay OPEN.

Add four small JSON known files, each a copy of the amended production pins with precisely one edit. Reuse `known.ndjson`; add these spec-loop rows:

```text
known known_bad_ruling.json known-ruling
known known_wrong_kind.json known-ruling
known known_wrong_cards.json known-ruling
known known_wrong_caption.json known-ruling
```

Edits respectively: transit `accepted_by` becomes `D-777`; transit `accepted_by` becomes `D-78`; transit `folding_card` becomes the same prefix plus `Card_other`; first caption text becomes `Other N caption` while retaining D-78. The full five-entry copies isolate each invalid field and keep unrelated findings known. Compact JSON is fine; these are five entries, not scene captures. The loader must reject with `^FAIL known-ruling([ :]|$)`. Existing spec-loop rc checking, script-error exclusion, named `missed` and `wrong reason` diagnostics apply unchanged. Other NEW/stale errors after a rejected entry do not substitute for the required loader reason.

Result: four successful audit cases (valid, known, renumbered, unaccepted) and **24 rejection rows**, up from 20. No scene or NDJSON fixture needs changing.

### 4. Parent AC4 and sprint evidence

Amend the existing parent AC4 row, which is not yet amended at this base. Retain zero mismatches, ≥500 samples, both clocks, lore hash checks and the full minimum playthrough. Add: **D-77 A: Transit folded only under the Braking and medium-boundary notices counts as shown; D-78 A: the four pinned row captions' constant notation digits are not numerals. Any other unaccepted known entry keeps AC4 OPEN.** Keep the pins and on-screen text unchanged. Refresh the opening landing-check sentence's obsolete “waits on D-77/D-78” claim; do not rewrite historical measurements.

After the real scene AC passes, amend the AC4 string in `.features[] | select(.id == "M4.5_PLAYTHROUGH_AUDIT") | .acceptance_criteria` in `sprint_R1-M4-JOURNEY.json` and add that feature's `ac4_verdict` object:

```json
{"status":"MET","accepted_entries":5,"accepted_by":["D-77","D-78"],"evidence":".godot/tmp/display-audit/playthrough/display-audit.log"}
```

Append a dated note with the executed command, source revision and measured summary. This records AC4 independently; leave the feature's aggregate `passes` and `completed` null while its remaining gates lack evidence. Do not mark the whole sprint or R1 clause 4 complete.

## Acceptance criteria

Run from the implementation checkout root with default make output paths. Define `W=.godot/tmp/display-audit/playthrough`. Load `controls()` and `drill()` from the Test plan first. `controls()` creates `.godot/tmp`, refreshes default control logs and asserts the 24-row count. AC2–AC4 each call it, so they do not depend on AC1 or drill order. All commands below must exit 0; silent `test`/`grep -q` success is the expected output unless stated. `drill` is defined in the Test plan. These are executor ACs, not claims that this design-only change implements them.

| # | Criterion and shell command | Expected output |
|---|---|---|
| AC1 | `controls` | rc 0; exactly 24 rejection rows, asserted. |
| AC2 | `controls && grep -qx 'ac4: MET' "$W/display-valid.log" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' "$W/display-known.log" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' "$W/display-known-renumbered.log"` | Empty compatibility and both accepted cases match exactly. |
| AC3 | `controls && grep -qx 'ac4: OPEN (1 unaccepted known, 4 accepted by D-77/D-78)' "$W/display-known-unaccepted.log" && grep -q 'new=0 .* stale=0 failures=0$' "$W/display-known-unaccepted.log"` | Mixed list stays OPEN without becoming an audit failure. |
| AC4 | `controls && for k in known_bad_ruling known_wrong_kind known_wrong_cards known_wrong_caption; do if grep -q "^display control known/$k.json: rejected$" .godot/tmp/7p-controls.log && grep -qx 'FAIL known-ruling invalid acceptance' "$W/display-known-$k.json.log"; then :; else exit 1; fi; done` | All four fail for the loader reason. |
| AC5 | `drill "$PWD" M1` | rc 0 only when forced MET is killed by the OPEN control. |
| AC6 | `drill "$PWD" M2` | rc 0 only when accepting all entries is killed by the OPEN control. |
| AC7 | `drill "$PWD" M3` | rc 0 only when dropping validation is killed by the invalid-ID control. |
| AC8 | `PATH="$PWD/runtime/bin:$PATH" make scene-session-audits AILANG="$PWD/runtime/bin/ailang" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/playthrough/display-audit.log && grep -q '^display-audit: .* failures=0$' .godot/tmp/display-audit/playthrough/display-audit.log && ! grep -q 'SCRIPT ERROR:' .godot/tmp/display-audit/playthrough/display-audit.log` | rc 0; real scene qualified MET plus zero failures. Several minutes; required before recording MET. |
| AC9 | `awk '$2 == "AC4" {print}' design_docs/planned/r1/m4-first-journey.md > .godot/tmp/7p-parent-ac4.txt && test "$(wc -l < .godot/tmp/7p-parent-ac4.txt)" -eq 1 && grep -q 'D-77' .godot/tmp/7p-parent-ac4.txt && grep -q 'D-78' .godot/tmp/7p-parent-ac4.txt && grep -q 'OPEN' .godot/tmp/7p-parent-ac4.txt && jq -e 'any(.features[]; .id == "M4.5_PLAYTHROUGH_AUDIT" and .passes == null and .completed == null and .ac4_verdict == {status:"MET",accepted_entries:5,accepted_by:["D-77","D-78"],evidence:".godot/tmp/display-audit/playthrough/display-audit.log"} and any(.acceptance_criteria[]; startswith("AC4:") and contains("D-77") and contains("D-78")))' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | `true`; parent and sprint criterion name both amendments, sprint records this evidence and preserves aggregate null flags. |
| AC10 | `PATH="$PWD/runtime/bin:$PATH" make python-guard && PATH="$PWD/runtime/bin:$PATH" make test AILANG="$PWD/runtime/bin/ailang"` | rc 0 on the Studio rig; merge also requires green fast tier and `rig/full` for the implementation head per CLAUDE.md. |
| AC11 | `git diff --name-only d6ef45e1 -- sim physics shaders ui demos bridge runtime > .godot/tmp/7p-production-paths.txt && test ! -s .godot/tmp/7p-production-paths.txt && git ls-files --others --exclude-standard -- sim physics shaders ui demos bridge runtime ':(exclude)**/*.uid' > .godot/tmp/7p-new-production.txt && test ! -s .godot/tmp/7p-new-production.txt` | Silent; no tracked production/physics/runtime change or new production source. Baseline untracked UID files are not implementation deliverables. |

## Test plan with mutation drills

Test-first: add acceptance metadata, new fixture files and make assertions first. The old loader ignores the additive field and the old verdict reports OPEN, so the new known-MET control is red. Add the validating loader and verdict, reach green, then run AC1–AC7. Finally run the real scene and rig gates; record AC4 only after AC8.

Paste these functions into a POSIX shell before AC1–AC7. Both baseline and mutant make calls in `drill()` pass `SCRATCH="$T/scratch"`; V11 verifies the command-line override and every expanded display-log destination. `import` has no audit-log output or SCRATCH reference (it imports the project at `--path .`); it cannot redirect those display logs back to the default directory. The drill still uses the project import/cache, so keep drills sequential. Each `drill` call takes an **explicit ROOT** and one mutant, validates an unmutated control run with the asserted 24-row count, backs up the current working file, and restores it on every exit. It never uses a git write command. An unapplied mutation exits **3**, not a false kill. A nonzero make result alone is insufficient: require the named control diagnostic and no script error.

```sh
controls() (
  set -eu
  mkdir -p .godot/tmp || exit "$?"
  PATH="$PWD/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH=.godot/tmp AILANG="$PWD/runtime/bin/ailang" \
    > .godot/tmp/7p-controls.log 2>&1 || exit "$?"
  test "$(grep -c ': rejected$' .godot/tmp/7p-controls.log)" -eq 24
)

drill() (
  set -eu
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?M1, M2 or M3 required}
  cd "$ROOT"
  ROOT=$(pwd -P)
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7p.XXXXXX")
  trap 'if test -f "$T/audit.gd"; then cp "$T/audit.gd" "$ROOT/tests/display_audit.gd"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/baseline.log" 2>&1
  test "$(grep -c ': rejected$' "$T/baseline.log")" -eq 24
  cp tests/display_audit.gd "$T/audit.gd"
  case "$mutant" in
    M1) perl -i -pe 's/if accepted_count == known_entries\.size\(\):/if not known_entries.is_empty():/' tests/display_audit.gd ;;
    M2) perl -i -pe 's/if finding_entry\.has\("accepted_by"\):/if true:/' tests/display_audit.gd ;;
    M3) perl -i -pe 's/if not ruling_valid\(entry\):/if false:/' tests/display_audit.gd ;;
    *) exit 2 ;;
  esac
  if cmp -s "$T/audit.gd" tests/display_audit.gd; then
    exit 3
  else
    cmp_rc=$?
    test "$cmp_rc" -eq 1 || exit "$cmp_rc"
  fi
  if (
    set +e
    PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
      SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang"
    make_rc=$?
    exit "$make_rc"
  ) > "$T/mutant.log" 2>&1; then
    exit 1
  else
    rc=$?
  fi
  test "$rc" -ne 0
  ! grep -q 'SCRIPT ERROR:' "$T/mutant.log"
  case "$mutant" in
    M1|M2) grep -q '^display control known_unaccepted verdict missed$' "$T/mutant.log" ;;
    M3) grep -q '^display control known/known_bad_ruling.json missed$' "$T/mutant.log" ;;
  esac
)
```

M1 forces MET whenever entries exist. M2 counts all entries as accepted. M3 bypasses the loader's ruling check; the `D-777` entry then remains an otherwise matching pin, so the first new rejection case exits 0 and make names it as missed. These drills are specified for the implementation seams above; they have not been run on this design-only tree. Drill baseline and mutant logs stay under `$T/scratch/display-audit/playthrough`; neither overwrites the default AC2–AC4 logs. Each of AC2–AC4 also regenerates its own baseline evidence, making those checks independent of run order. Preserve evidence in the executor/evaluator record before scratch cleanup if needed.

## Sub-milestones and estimates

One test-first step, about 90 code/test/data lines plus 15 record lines. Order: fixture assertions → validated field/verdict → control suite and drills → scene evidence → parent amendment/sprint record → independent evaluation and landing gates. Shell glue and Godot own the audit; no AILANG feature work is needed.

## Files

| File | Executor change |
|---|---|
| `tests/display_audit.gd` | `ruling_valid`, validation seam, `ac4_verdict`, print replacement. |
| `tests/fixtures/display_audit/known_findings.json` | Five `accepted_by` fields and current ruling prose; identities/counts unchanged. |
| `tests/fixtures/display_audit/known_unaccepted.json` | New mixed-acceptance positive audit fixture. |
| `tests/fixtures/display_audit/known_bad_ruling.json` | New invalid-ID fixture. |
| `tests/fixtures/display_audit/known_wrong_kind.json` | New D-78-on-transit fixture. |
| `tests/fixtures/display_audit/known_wrong_cards.json` | New D-77-card-pair fixture. |
| `tests/fixtures/display_audit/known_wrong_caption.json` | New D-78-caption fixture. |
| `mk/m45.mk` | Accepted greps, OPEN case with named failure, four spec rows. |
| `design_docs/planned/r1/m4-first-journey.md` | AC4 amendment and stale opening status. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | Amended AC4 criterion, measured note and `ac4_verdict`; preserve aggregate gates. |

**Designer deliverable:** only `design_docs/planned/r1/m4-7p-ac4-verdict.md`. The controller handles commits and any later lifecycle bookkeeping; this task edits no index, ledger, sprint record or implementation file.

## Risks and mitigations

- **Acceptance could grow into a blanket waiver.** Exact normalized identities, kind binding and named cards constrain each ruling; the mixed list proves no automatic prose acceptance. Invalid metadata is a failure, even if a verdict line elsewhere says MET.
- **Normalized digits and generated node suffixes still collapse identities.** This existing ratchet limitation belongs to row 7i(d); retain the current matcher and renumbering controls. This row authorizes only the existing normalized tuples.
- **Two copies of the pinned identities can drift.** The validator deliberately pins the ruling's scope independently of editable metadata. Moving the UI makes validation or NEW/stale checks fail; any later scope amendment must cite authority and update controls.
- **Legacy stale fixture reports OPEN as well as failure.** Expected: its purpose is stale rejection, not acceptance provenance. Do not silently migrate all fixture entries into accepted exceptions.
- **False mutation kills from unrelated failures.** Unmutated baseline, applied-change `cmp`, preserved make rc, script-error guard and exact diagnostic grep are mandatory. Socket binds or writes outside the clone failing under sandbox are **UNINFORMATIVE UNDER SANDBOX**, never successful kills or game failures; rerun on the rig.
- **Runtime cost and incomplete evidence.** The several-minute scene run is deliberately deferred to execution, and the full suite belongs on the Studio rig. AC4 MET alone cannot close replay, performance or aggregate sprint gates.

## Open questions

Open questions: none.

## Verification log

Read-only inspection on 2026-10-20 at `d6ef45e1`; local canon at `2ef3656`. No alternative design for row 7p was found under planned/implemented docs. The requested sibling supplies the structure; recent live-transit and implemented constellation/solar-departure designs were also inspected. Canon pillars, architecture, relevant normative test/ISM sections and R1 M4 acceptance were checked; no canon amendment is needed to implement Mark's existing rulings.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Base and existing verdict | `git rev-parse --short HEAD; sed -n '370,382p' tests/display_audit.gd` | `d6ef45e1`; empty list alone prints MET, otherwise OPEN. |
| V2 | Loader currently lacks ruling metadata validation | `sed -n '55,90p' tests/display_audit.gd` | Validates common fields, row, sample count, kind, card fields, duplicate identity; no `accepted_by`. |
| V3 | Five pins and existing matching guards | `cat tests/fixtures/display_audit/known_findings.json; sed -n '170,192p' tests/display_audit.gd; cat tests/fixtures/display_audit/known.ndjson` | Four caption tuples, one transit tuple; D-78 prose only; exact card state guarded; known fixture exercises all five in two samples. |
| V4 | Baseline controls and existing known verdict | `PATH=$PWD/runtime/bin:$PATH make display-audit-controls AILANG=$PWD/runtime/bin/ailang > /tmp/stapledon-iter40-7p-baseline.log 2>&1; rc=$?; echo "$rc"; grep -c ': rejected$' /tmp/stapledon-iter40-7p-baseline.log; rg -e '^ac4:' -e '^display-audit:' .godot/tmp/display-audit/playthrough/display-known.log` | make rc **0**, **20** rejected; known OPEN `(4 known unbound, 1 known transit-ISM)`, `new=0 known=5 stale=0 failures=0`. Godot also reports sandbox-denied external editor-settings saving: that external-settings operation is **UNINFORMATIVE UNDER SANDBOX**; the in-clone controls completed. |
| V5 | Attended authority and net-zero exception | `rg -n -e '^. D-66 ' -e '^. D-77 ' -e '^. D-78 ' -e '^. D-88 ' design_docs/stapledon-mission.md` | D-66 approved; D-77/D-78 A amend AC4 and close it together; D-88 A permits this net-zero hygiene scope with no negative pillar. |
| V6 | Parent and sprint still need precise AC4 recording | `rg -n 'AC4' design_docs/planned/r1/m4-first-journey.md; jq '.features[] \| select(.id == "M4.5_PLAYTHROUGH_AUDIT") \| {id,acceptance_criteria,passes,completed}' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | Parent AC4 line 664 unamended, opening says waiting; sprint AC4 unamended, aggregate flags null. Preserve that distinction. |
| V7 | Real output paths and make reason checks | `sed -n '1,31p' mk/m45.mk; sed -n '1,10p' Makefile; sed -n '1162,1166p' Makefile` | `SCRATCH=.godot/tmp`, `PLAYTHROUGH_OUT=$(SCRATCH)/playthrough`; DISPLAY_WORK derives its basename `playthrough`; exact scene log path is `.godot/tmp/display-audit/playthrough/display-audit.log`. Spec loop checks nonzero rc and a FAIL reason followed by space, colon or end-of-line; valid control greps bare MET exactly. |
| V8 | External duplicate-PR check unavailable | `gh pr list --repo sunholo-data/stapledons-godot; gh pr list --repo sunholo-data/stapledons-design` | Both could not connect to api.github.com from the designer's sandbox. **Resolved by the controller as V13** (outside the sandbox). Local scope search found no row-7p implementation design. |

| V9 | Every executable `ac4:` consumer; preserve existing control assertions | `git grep -n 'ac4' -- mk/ Makefile tests/ scripts/ .github/ tools/; git grep -c 'display-audit' -- mk/m45.mk; sed -n '14,25p' mk/m45.mk; rg -l 'ac4: OPEN' .ailang/state/evaluations website/src/data/decisions.json` | Controller V9 independently reproduced: producer `tests/display_audit.gd:377`; only consumers `mk/m45.mk:14` (echo filter, no AC4 assertion) and `:17` (bare MET assertion on valid). Other hits are hash substrings. Positive control: `mk/m45.mk:19` means **19 matching lines**, not line 19. Known checks rc, zero-new/stale/failure summary and script-error; renumbered additionally checks both known-kind lines. Stale-known checks nonzero rc, reason and script-error, with no AC4 assertion. |
| V10 | Script-scope array and every control's known file | `grep -n 'known_entries' tests/display_audit.gd; nl -ba tests/display_audit.gd \| sed -n '1,55p'; sed -n '15,25p' mk/m45.mk` | Controller V10/V10b independently reproduced: unindented `var known_entries: Array = []` at line 20 precedes first function at 43; append at 85 is inside `load_known`. Known and renumbered both load production pins; stale-known loads `known_stale.json`. Current spec-loop count **20**, counted from the quoted rows below with a scratch Python harness; all assignments and log naming verified at lines 20–24. |
| V11 | Drill SCRATCH override isolates display logs | `sed -n '1,10p;24,25p;1160,1166p' Makefile; sed -n '8,25p' mk/m45.mk; make -n display-audit-controls SCRATCH=/tmp/stapledon-7p-routing/scratch AILANG="$PWD/runtime/bin/ailang"` | Dry-run rc **0**. `SCRATCH := .godot/tmp` is plain, not `override`; command-line assignment wins. `PLAYTHROUGH_OUT` derives from SCRATCH; recursive `DISPLAY_WORK` resolves to `/tmp/stapledon-7p-routing/scratch/display-audit/playthrough`. Python harness asserted the scratch mkdir, absence of `.godot/tmp/display-audit/` anywhere in the expansion, and the unchanged import command `godot --headless --path . --import`. Import writes no display-audit logs and has no SCRATCH-specific output. This measures make routing, not runtime mutant kills; no import or audit was executed in this revision. |
| V12 | Verbatim ruling/fixture evidence, including whitespace | `rg -n -e '^. D-7[78] ' -e '^. D-88 ' design_docs/stapledon-mission.md; nl -ba tests/fixtures/display_audit/known_findings.json; jq -r '.findings[].text\|@json' tests/fixtures/display_audit/known_findings.json; sed -n '43,44p' tests/display_audit.gd` | Ledger rows 191, 192, 202 quoted in §1, with provenance omitted. All five field excerpts and per-literal mappings measured against the file; the third JSON text has **two leading spaces**. `normalized()` replaces digits only. Caption card fields are absent. |

### V10 control-to-file inventory

At the inspected base, the successful `valid` case loads `empty_known.json`; successful `known` and `known_renumbered` load `known_findings.json`. The **20 current rejection spec rows**, quoted from `mk/m45.mk:20` in source order, are:

```text
unbound empty_known.json NEW.unbound
stale empty_known.json stale
missing empty_known.json missing
missing_context empty_known.json missing
stale_context empty_known.json stale
new_unbound known_findings.json NEW.unbound
known known_stale.json stale-known
transit_unfolded known_findings.json NEW.transit-ISM
different_named_parent known_findings.json NEW.unbound
context_drift empty_known.json context-drift
context_source empty_known.json context-source
context_presence empty_known.json context-presence
context_hold empty_known.json context-source
context_console empty_known.json context-source
context_unknown empty_known.json context-unknown
context_absent empty_known.json context-drift
context_presence_parts empty_known.json context-presence
context_crew empty_known.json context-source
review_unbound empty_known.json NEW.unbound
crew_unbound empty_known.json crew-unbound
```

Column order is case, known file, expected reason; paths are under `tests/fixtures/display_audit/`. The loop writes `display-<case>-<knownfile>.log`, so the existing stale row is `display-known-known_stale.json.log`; the new invalid-ID row will be `display-known-known_bad_ruling.json.log`, matching AC4. The proposed unaccepted positive case loads `known_unaccepted.json`; the four proposed rejection rows load their respective `known_bad_ruling.json`, `known_wrong_kind.json`, `known_wrong_cards.json` and `known_wrong_caption.json`. Other assignments stay unchanged; the resulting rejection count is 24.

The new controls, drills, amended scene verdict and full rig suite are future executor checks, not designer measurements. No physics/AILANG defect was discovered. No git write command was used.

## Quorum verification log

Revision round 2 is the one protocol-mandated revision. Round 1 was **BLOCKED**; all objections concerned verification, with no dispute over validated `accepted_by`, qualified MET, controls or drills. Seat status is supplied by the controller, not a newly run quorum:

| Round-1 seat | Presence | Verdict |
|---|---|---|
| `oc-kimi-k3` | Present | REJECT: missing quoted authority/literals, consumer inventory and scope proof. |
| `oc-glm-5-3` | Present | REJECT: missing V9/V10 and explicit evidence for preserved checks. |
| `gemini-4-argon` | Present | PASS; minor correction: drill logs can overwrite AC evidence. |
| `claude-sonnet-5` | Absent | Quota; no verdict. |

| Objection | Round-2 edit and verification |
|---|---|
| K(1): asserted authority | §1 now quotes the D-77/D-78/D-88 question and ANSWERED text verbatim with source line numbers and one scope explanation per ruling (V12). |
| K(2): asserted literals | §1 now quotes all five fixture field tuples, records absent caption-card fields, maps every literal to `ruling_valid` and confirms the two leading spaces by the re-run jq command (V12). |
| K(3), G: AC4 consumers / V9 | §3 enumerates both real consumers, the producer and hash false positives; preserves historical quotes. New V9 records the consumer search and positive control; preserved rc/summary/kind/script-error checks cite it. |
| K(4), G: scope / V10 | §2 proves script scope from the declaration before all functions and the loader append. New V10 and its inventory record every existing case's known file, the shared production pins for renumbering, the legacy stale file, count 20 and exact spec log naming. |
| A: drill log isolation and order | Both drill make calls now use `SCRATCH="$T/scratch"`; V11 checks make precedence, import and all expanded display-log paths. AC2–AC4 each call `controls()` to regenerate baseline evidence independently of AC1 or drill order. No implementation mutation was run. |

Only this design file was edited; no git write command was used. Source inspections and the make dry-run were re-run for V9–V12. The controller's scene baseline remains explicitly attributed above, outside the designer verification table. The proposed implementation, mutation kills, qualified real-scene verdict and rig gates remain executor verification; the existing V8 external-PR limitation remains unresolved.

### Round 2 and the narrow-refinement disposition (controller, 2026-10-20)

Round 2 was **BLOCKED** again: `oc-kimi-k3` REJECT, `oc-glm-5-3` REJECT, `gemini-4-argon` PASS, `claude-sonnet-5@claude-p` absent (quota) both rounds, so the PASS is at N-1 seats. Neither reject disputes the design direction; each names read-only measurements with a concrete `proposed_fix`. Under the narrow-refinement carve-out (`mission-control` Gate 2), the controller ran those measurements outside the sandbox at `d6ef45e1` and recorded them here verbatim. That is the bounded second revision; there is no third quorum round.

| # | Objection answered | Command (controller, outside the sandbox) | Result |
|---|---|---|---|
| V13 | kimi-k3 (1): V8 external PR check | `for p in $(gh pr list --repo sunholo-data/stapledons-godot --state open --json number --jq '.[].number'); do gh pr view $p --json files --jq '[.files[].path\|select(test("display_audit\|mk/m45.mk\|tests/fixtures/display_audit/\|m4-first-journey.md\|sprint_R1-M4-JOURNEY"))]\|length'; done; gh pr list --repo sunholo-data/stapledons-design --state open` | Two open game PRs, #281 and #282 (attended R2-CAMERA-FORWARD): **0** matching files each. Design repo: **0** open PRs. No conflicting implementation is in flight. The executor re-checks `git log d6ef45e1..origin/main -- tests/display_audit.gd mk/m45.mk tests/fixtures/display_audit/` before AC1. If it is non-empty, the row rebases and re-counts the spec rows. |
| V14 | kimi-k3 (2): which known file the real scene loads | `grep -n 'DISPLAY_KNOWN' mk/m45.mk Makefile` | `mk/m45.mk:9 DISPLAY_KNOWN ?= tests/fixtures/display_audit/known_findings.json`. The scene (line 14), interlude (line 111) and crew (line 123) audits all pass `$(DISPLAY_KNOWN)`, and `scene-session-audits` does not override it. So the real scene loads the amended production pins. The interlude and crew audits also print the qualified verdict line but assert nothing on it (V9). |
| V15 | glm-5-3: the miss diagnostic literal is measured, not asserted | Source: `grep -o 'echo "display control [^"]*"' mk/m45.mk` gives `display control $$case/$$known missed`, `… wrong reason (want $$reason)` and `…: rejected`. Measured: on a scratch edit of the `known known_stale.json stale-known` row to `known_findings.json` (restored afterwards, `cmp` clean), `make display-audit-controls SCRATCH=$T/scratch` exited **rc 2** and printed exactly `display control known/known_findings.json missed`. | **Space form, no colon**: only the success echo carries `: rejected`. So M3's `^display control known/known_bad_ruling.json missed$` is the measured byte form. The new `known_unaccepted` echo must use the same convention, as §3 specifies: `display control known_unaccepted verdict missed`. The same run confirms V11 first-party: every log went under `$T/scratch/display-audit/`, and the default `.godot/tmp/display-audit/playthrough/display-valid.log` mtime was unchanged. |

kimi-k3 (3), the seat ratification, is this section. The quorum artifacts are `m4-7p-ac4-verdict-2026-10-20T00-16-36Z.json` (round 1) and the round-2 artifact in the same directory. Both reject objections are recorded with their fixes. The independent evaluator re-checks V13–V15 at execution time.
