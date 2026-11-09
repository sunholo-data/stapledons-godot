# Sprint R3-AI-PANEL-V2: the Live AI panel as lamps, icons and a key check

**Design doc:** [ai-panel-v2.md](ai-panel-v2.md). **Sprint JSON:** `.ailang/state/sprints/sprint_R3-AI-PANEL-V2.json`.
**Branch:** `feat/ai-panel-v2` (clone `~/dev/sunholo-data/stapledons-godot-ai-panel`, from main `13bc0766`).
**Approval:** the visual concept was approved by Mark on 2026-11-09 (attended). **This plan waits for Mark's approval before execution.** The visual landing needs Mark's OK on a dev build (merge rule 4).
**Duration:** one to two working sessions (~1,050 LOC). **Risk:** low to medium (UI rewrite over unchanged rules; one new AILANG entry that touches the network).

## Analysis

- **Velocity.** 196 commits and about 34,500 inserted lines on main in the last 7 days, most of them mission and asset work. Comparable attended UI sprints, such as comms station v2 (PR #379) and the R2 crew console v2 (PR #267), moved 600 to 1,200 LOC of GDScript plus tests across one or two sessions. This one has 620 lines of code and 430 of tests and tools.
- **Registry reuse (mandatory gate).** No milestone adds a package capability. The key check is two GETs in the game's own `ai/` service package, which already does HTTP with `std/net.httpRequest` (`ai/adapters.ail`). Nothing in `sunholo/*` covers "is this provider key valid", and it is game plumbing, not reusable physics or audio. Decision per milestone: P1 `none` (service-local adapter), P2 `none` (UI), P3 `none` (UI), P4 `none` (theme, capture, mutants).
- **AILANG.** One new module, `ai/check.ail`. AILANG prompt version loaded: `v0.16.12` (`ailang prompt --version-active`). The pinned runtime is v0.56.1, and execution uses `AILANG=runtime/bin/ailang` after `make deps`. Syntax gate rows for `ai/check.ail`:
  - **contracts:** skip. It is an I/O shell over `httpRequest` with no numeric invariant worth an `ensures`. The pure classifier `statusOf` is covered by inline tests instead.
  - **effects:** include. `export func check(argsJson: string) -> () ! {IO, FS, Env, Net}`; the classifier is `pure func statusOf(provider: string, code: int) -> string`.
  - **inline tests:** include. `statusOf` table: gemini 200 → ok, 400/401/403 → rejected, 500 → offline, 0 (no response) → offline; openrouter 200 → ok, 401/403 → rejected, 429 → offline.
- **Baseline to measure at P0** (on `13bc0766`): `make ai-settings`, `make ai-live-guard`, `make ai-loopback`, `make ai-pkg-test`, `make ui-theme-check STRICT=1`, `make ai-mutants`. Record pass counts in the JSON so new cases are visible as a delta.

## Milestones

### P0: plan and baseline (docs)
- Design doc, this plan, the JSON; the baseline counts above.
- **Acceptance:** files exist; baseline recorded in the JSON.

### P1: the key check (~230 LOC: 90 code, 140 tests)
- Tests first:
  - `statusOf` inline tests in `ai/check.ail`;
  - in `tests/fixtures/ai_loopback.py`, the GET routes `/v1beta/models` and `/api/v1/key`, answering 200 for the good fake key, 403/401 for the bad one, and a closed port for offline;
  - a `check` section in the `make ai-loopback` driver asserting the six outcomes, no `usage.ndjson` line, and the fake key absent from stdout, stderr and the log;
  - `test_key_check` in `tests/test_ai_settings.gd`: automation refused, no key file → no plan, a key file → an `env -i` plan with `--net-allow-domains` = `LIVE_HOSTS` and `--entry check`, the parse, the async run, the timeout, and a real run to a closed port.
- Then:
  - `ai/check.ail`;
  - `bridge/ai_key_check.gd` (`AiKeyCheck`, amended in execution from methods on `AiBridge`): `plan()`, `start()`, `poll()`, `status()`, the `done(provider, status)` signal; the child runs on a worker thread with a 10 s kill → `offline`.
- **Acceptance (AC7, AC8, AC9):** `make ai-key-check ai-pkg-test ai-live-guard ai-settings` green.

### P2: the badge (~210 LOC: 130 code, 80 tests)
- Tests first: `state_of` table (10 cases, the precedence of design §V1); the label is at most 2 words beside "AI"; the tooltip carries the per-provider and total amounts that `text()` shows today; a `budget` outcome → `ceiling`; 3 failed outcomes → `problem`, and one ok clears it; a `rejected` check → `problem`.
- Then: `ui/ai_indicator.gd`, a drawn pill (`_draw`: ring arc for spent ÷ ceiling, lamp, "AI", the state word, 1 Hz pulse while `working`) on a `Button` kept for focus and click; colours from `StapledonTheme` (`DIM`, `MINT`, `TEAL_LIGHT`, `CORAL`).
- **Acceptance (AC1, AC2):** `make ai-settings` green.

### P3: the panel (~480 LOC: 330 code, 150 tests)
- Tests first:
  - `AiSettings.masked_key`;
  - `ceiling_to_slider` / `slider_to_ceiling` round trip on every 0.01 step from 0.05 to 20;
  - `tile_states` for the four AC4 cases;
  - panel cards for no key, a saved key and Remove (the file is gone);
  - recent dots from this session's usage lines only, at most 8, newest last;
  - the existing AI.9 panel cases, which still pass with the new node names (opt-in disabled without a key, text-only locked by `--text-only`, the ceiling bounds).
- Then: `ui/settings/ai_settings_panel.gd` rewritten as the design's five bands, `ui/settings/ai_settings.gd` gains the pure helpers, and `ui/settings/ai_settings.tscn` is resized (about 640 × 600). Icons are drawn with `_draw` from theme tokens; there are no image assets.
- **Acceptance (AC3–AC6):** `make ai-settings` green; the title screen's Settings path (`tests/test_title_screen.gd`) still opens the panel: `make title-screen-test`.

### P4: theme, mutants, capture, review (~130 LOC: 70 code, 60 tests)
- Mutant rows in `mk/ai.mk`:
  - the check writes a usage line;
  - the check prints the response body;
  - `state_of` has `working` above `problem`;
  - the slider map drops the snap.
  Each must fail a named test.
- `tools/ai_panel_capture.gd` and `make ai-panel-capture` (the six fixture states → `renders/ai_panel/`), opened and inspected.
- Changelog fragment, `.uid` files staged with their scripts, the PR, a cross-family evaluation (`sprint-evaluator`, a different model), then `make publish-dev` for Mark.
- **Acceptance (AC10–AC14):** `make ai-mutants ui-theme-check STRICT=1 uid-guard python-guard` green; `git diff --stat origin/main -- sim/ physics/` empty; at least 6 renders; the dev build is published.

## Order

P0 → P1 → (P2 ∥ P3) → P4. One PR. P2 and P3 both edit `tests/test_ai_settings.gd`, so they run in sequence when one agent does both.

## Validation (targeted; never the full suite locally)

`make ai-settings ai-live-guard ai-loopback ai-pkg-test ai-mutants title-screen-test ui-theme-check STRICT=1 uid-guard python-guard`, plus the GitHub fast tier on the PR. `make golden` is not needed: no shader or physics visual changes.

## Pause points

- **Before execution:** Mark approves this plan.
- **Design OQ1 to OQ3** have recommendations (show the last 4, no remembered checks, no auto-check). Execution follows them unless Mark rules otherwise. None blocks P1.
- **After P4:** Mark's OK on the dev build (visual), then merge.
