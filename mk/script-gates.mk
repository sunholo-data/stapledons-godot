# Row 7x (clause 5, suite hygiene): one pass predicate for every Godot --script gate, and a ratchet.
# Godot 4.7 exits 0 when a --script test fails to parse, and hangs when a runtime error stops _init before
# quit(), so a gate on rc alone passes a test that never ran. $(SCRIPT_GATE) passes only on rc, no
# SCRIPT ERROR, the test's own summary line and an exit inside the timeout (tools/script_gate.sh).
SG_TOOLS ?= tools
SG_FIX ?= tests/fixtures/script_gate
SCRIPT_GATE = sh $(SG_TOOLS)/script_gate.sh
# Rows of tools/script-gate-baseline.txt: the --script invocations not yet through $(SCRIPT_GATE). A migration
# deletes its rows and lowers this pin with them; script-gate-lint fails on any mismatch, so it never rises
# unseen. 237 at the 7x snapshot (78f390c0), 232 after its five gates, 204 after B2a (28 rows in nine mk files),
# 175 after B3a (29 rows in mk/levels.mk, mk/m5.mk, mk/ai.mk).
SCRIPT_GATE_BASELINE_ROWS := 175
SG_LINT = SCRIPT_GATE_BASELINE_ROWS=$(SCRIPT_GATE_BASELINE_ROWS) sh $(SG_TOOLS)/script_gate_lint.sh
# Gates whose test needs fetched assets keep the target that fetches them (B3; iteration 70 judge survivor:
# constellation-test without starmap-assets was red in a fresh clone, unseen). Checked in make -p by script-gate-lint.
SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets
# Outer deadline for the self-tests (round-2 amendment A2): the same process-group supervisor as tools/script_gate.sh,
# so a broken helper cannot hang make test. Usage: $(SG_SUP) SECS command...
SG_SUP = perl -e 'use POSIX ":sys_wait_h"; my $$secs = shift; my $$pid = fork; die "fork: $$!" unless defined $$pid; if ($$pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; } my $$end = time + $$secs; my $$st; while (1) { my $$r = waitpid($$pid, WNOHANG); if ($$r == $$pid) { $$st = $$?; last } if (time >= $$end) { kill "TERM", -$$pid; my $$g = time + 2; while (time < $$g) { last if waitpid($$pid, WNOHANG) == $$pid; select(undef, undef, undef, 0.1) } kill "KILL", -$$pid; waitpid($$pid, 0); kill "KILL", -$$pid; exit 142 } select(undef, undef, undef, 0.1) } exit($$st & 127 ? 128 + ($$st & 127) : $$st >> 8)'

.PHONY: script-gate-lint script-gate-selftest script-gate-drill script-gate-inventory
test: script-gate-lint script-gate-selftest script-gate-drill
ci-fast: script-gate-lint script-gate-selftest

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
	@sh $(SG_TOOLS)/script_gate_prereqs.sh Makefile $(SG_PREREQS)

script-gate-selftest: ## tools/script_gate.sh on stub commands (no Godot): pass, SCRIPT ERROR, hang past the timeout, a command that ignores TERM/ALRM, an orphan child, no summary, a 0 count, wrong rc, env passthrough, bad arguments
	@SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/selftest $(SG_SUP) 120 sh $(SG_TOOLS)/test_script_gate.sh

script-gate-drill: ## + real Godot: the premise (a parse error exits 0), parse-error, runtime-error hang and no-summary fixtures, and make sim's own gate on the parse fixture
	@SCRIPT_GATE_TMP=$(SCRATCH)/script-gate/drill MAKE="$(MAKE)" GODOT="$(GODOT)" $(SG_SUP) 600 sh $(SG_TOOLS)/test_script_gate.sh --godot
