# Row 7x (clause 5, suite hygiene): one pass predicate for every Godot --script gate, and a ratchet.
# Godot 4.7 exits 0 when a --script test fails to parse, and hangs when a runtime error stops _init before
# quit(), so a gate on rc alone passes a test that never ran. $(SCRIPT_GATE) passes only on rc, no
# SCRIPT ERROR, the test's own summary line and an exit inside the timeout (tools/script_gate.sh).
SG_TOOLS ?= tools
SG_FIX ?= tests/fixtures/script_gate
SCRIPT_GATE = sh $(SG_TOOLS)/script_gate.sh
BOUNDED_RUN = sh $(SG_TOOLS)/bounded_run.sh
CREW_CONSOLE_TIMEOUT_S ?= 300
BOUNDED_TEST_ARTIFACTS ?= /tmp
# Rows of tools/script-gate-baseline.txt: the --script invocations not yet through $(SCRIPT_GATE). A migration
# deletes its rows and lowers this pin with them; script-gate-lint fails on any mismatch, so it never rises
# unseen. 237 at the 7x snapshot (78f390c0), 232 after its five gates, 204 after B2a (28 rows in nine mk files),
# 175 after B3a (29 rows in mk/levels.mk, mk/m5.mk, mk/ai.mk), 119 after B4a (56 rows in the Makefile at line 1080 and below it), 118 after row 7aa (sim-pipeline-test).
SCRIPT_GATE_BASELINE_ROWS := 118
SG_LINT = SCRIPT_GATE_BASELINE_ROWS=$(SCRIPT_GATE_BASELINE_ROWS) sh $(SG_TOOLS)/script_gate_lint.sh
# Gates whose test needs fetched assets keep the target that fetches them (B3; iteration 70 judge survivor:
# constellation-test without starmap-assets was red in a fresh clone, unseen). Checked in make -p by script-gate-lint.
# B4: ship-console-test reads build/ship-baseline (make ship-baseline); without it the test is red in a fresh clone.
SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline
# Pairs in SG_PREREQS, distinct (B4; iteration 71 judge survivor: dropping a pair passed, because the negative control
# and the real check both read the list). script-gate-lint fails on any mismatch; the pin moves with the pairs, and only up.
SG_PREREQS_PAIRS := 4
# Independent guardian: candidate code never enforces its own test deadline.
SG_SUP = perl $(SG_TOOLS)/test_bounded_run.pl guard "$(CURDIR)" "$(BOUNDED_TEST_ARTIFACTS)"

.PHONY: script-gate-lint script-gate-selftest script-gate-drill script-gate-inventory bounded-run-selftest bounded-run-drill
test: script-gate-lint script-gate-selftest script-gate-drill bounded-run-selftest
ci-fast: script-gate-lint script-gate-selftest bounded-run-selftest

script-gate-inventory: ## every --script invocation in the Makefile and mk/*.mk: file:line, target, script, gated/ungated/other, inline rc/SCRIPT ERROR/summary/timeout pieces
	@$(SG_LINT) --inventory

script-gate-lint: ## row 7x ratchet: every --script gate runs through $(SCRIPT_GATE) or is a row of tools/script-gate-baseline.txt, the asset prerequisites in SG_PREREQS hold, and the scanned makefiles are closed under include (negative control: tests/fixtures/script_gate/lint_negative.mk.txt fails on exactly its planted rows)
	@mkdir -p $(SCRATCH)/script-gate
	@if SCRIPT_GATE_FILES=$(SG_FIX)/lint_negative.mk.txt SCRIPT_GATE_BASELINE=$(SG_FIX)/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=2 \
	    SCRIPT_GATE_ALL_MAKEFILES="$(SG_FIX)/lint_negative.mk.txt tools/stray.mk" sh $(SG_TOOLS)/script_gate_lint.sh > $(SCRATCH)/script-gate/lint-negative.log 2>&1; then \
	    echo "script-gate-lint: FAIL the negative control passed"; exit 1; fi; \
	  L=$(SCRATCH)/script-gate/lint-negative.log; \
	  test "$$(grep -c '^script-gate-lint: unguarded' $$L)" = 3 && grep -q 'not on the baseline: gate-after tests/after.gd$$' $$L && grep -q 'not on the baseline: bare-new tests/y.gd$$' $$L && grep -q 'not on the baseline: mixed tests/m2.gd$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: stale' $$L)" = 1 && grep -q 'SCRIPT_GATE_BASELINE_ROWS: stale tests/gone.gd$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: include outside' $$L)" = 3 && grep -q ' tools/outside.mk$$' $$L && grep -qF ' $$(EXTRA).mk' $$L && grep -q ' \.\./stray.mk$$' $$L \
	  && test "$$(grep -c '^script-gate-lint: makefile not scanned: tools/stray.mk ' $$L)" = 1 \
	  && ! grep -qE 'gated-ok|baselined|comment\.gd|tests/m1\.gd|tests/q\.gd|mk/style\.mk' $$L \
	  || { cat $$L; echo "script-gate-lint: FAIL the negative control flagged the wrong rows"; exit 1; }
	@if SCRIPT_GATE_FILES=$(SG_FIX)/lint_negative.mk.txt SCRIPT_GATE_BASELINE=$(SG_FIX)/lint_negative_baseline.txt SCRIPT_GATE_BASELINE_ROWS=3 \
	    sh $(SG_TOOLS)/script_gate_lint.sh > $(SCRATCH)/script-gate/lint-pin.log 2>&1 \
	    || ! grep -q 'the baseline has 2 rows but SCRIPT_GATE_BASELINE_ROWS is 3' $(SCRATCH)/script-gate/lint-pin.log; then \
	    cat $(SCRATCH)/script-gate/lint-pin.log; echo "script-gate-lint: FAIL the pin control (2 rows, pin 3) was not refused"; exit 1; fi
	@$(SG_LINT)
	@if sh $(SG_TOOLS)/script_gate_prereqs.sh $(SG_FIX)/prereq_negative.mk.txt $(SG_PREREQS) missing-target:x > $(SCRATCH)/script-gate/prereqs-negative.log 2>&1 \
	    || test "$$(grep -c '^script-gate-prereqs: ' $(SCRATCH)/script-gate/prereqs-negative.log)" != 2 \
	    || ! grep -q '^script-gate-prereqs: constellation-test lost its prerequisite starmap-assets ' $(SCRATCH)/script-gate/prereqs-negative.log \
	    || ! grep -q '^script-gate-prereqs: missing-target has no rule' $(SCRATCH)/script-gate/prereqs-negative.log; then \
	    cat $(SCRATCH)/script-gate/prereqs-negative.log; echo "script-gate-lint: FAIL the prerequisite control (constellation-test without starmap-assets) was not refused by name"; exit 1; fi
	@test "$(words $(SG_PREREQS))" = "$(SG_PREREQS_PAIRS)" && test "$(words $(sort $(SG_PREREQS)))" = "$(SG_PREREQS_PAIRS)" \
	  || { echo "script-gate-lint: SG_PREREQS holds $(words $(SG_PREREQS)) pairs ($(words $(sort $(SG_PREREQS))) distinct) but SG_PREREQS_PAIRS is $(SG_PREREQS_PAIRS): the pin moves with the pairs, and only up"; exit 1; }
	@sh $(SG_TOOLS)/script_gate_prereqs.sh Makefile $(SG_PREREQS)

script-gate-selftest: ## tools/script_gate.sh on stub commands (no Godot): pass, SCRIPT ERROR, hang past the timeout, a command that ignores TERM/ALRM, an orphan child, no summary, a 0 count, wrong rc, env passthrough, bad arguments
	@$(SG_SUP) 120 -- sh $(SG_TOOLS)/test_script_gate.sh

script-gate-drill: ## + real Godot: the premise (a parse error exits 0), parse-error, runtime-error hang and no-summary fixtures, and make sim's own gate on the parse fixture
	@MAKE="$(MAKE)" GODOT="$(GODOT)" $(SG_SUP) 600 -- sh $(SG_TOOLS)/test_script_gate.sh --godot

bounded-run-selftest: ## row 7ad hermetic runner, relay and actual raw Make controls
	@perl $(SG_TOOLS)/test_bounded_run.pl selftest "$(CURDIR)" "$(BOUNDED_TEST_ARTIFACTS)"

bounded-run-drill: ## targeted causal mutations; independent guardian, no aggregate dependency
	@perl $(SG_TOOLS)/test_bounded_run.pl mutants "$(CURDIR)" "$(BOUNDED_TEST_ARTIFACTS)"
