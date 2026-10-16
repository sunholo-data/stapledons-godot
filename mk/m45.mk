# M4.5 legacy and scene-session audits (D-66/D-68).
.PHONY: parity-m4 replay-positive-control session-audit-test codex-unlocks playthrough-time m45-author
M45_CASES := m4_min_path m4_adversarial m4_transit_harness
M45_STATE := $(SCRATCH)/replay/m4_min_path.vm.ndjson
M45_FIX := tests/fixtures/session_audit
M45_FLAGS := --quiet --package-dir sim --caps FS
M45_TOOL := sim/tools/session_audit.ail
DISPLAY_SAMPLES ?= $(PLAYTHROUGH_OUT)/display_samples.ndjson
DISPLAY_KNOWN ?= tests/fixtures/display_audit/known_findings.json
DISPLAY_WORK = $(SCRATCH)/display-audit/$(notdir $(patsubst %/,%,$(dir $(DISPLAY_SAMPLES))))
.PHONY: display-audit display-audit-controls scene-session-audits playthrough-ai-modes
display-audit: import display-audit-controls ## M4.5bR3 AC4/6: stream scene bindings, lore and AI evidence; rejection controls
	@mkdir -p $(DISPLAY_WORK)
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(DISPLAY_SAMPLES) scene $(DISPLAY_KNOWN) > $(DISPLAY_WORK)/display-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|display-audit|ai-mode|ac4:)' $(DISPLAY_WORK)/display-audit.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-audit.log && grep -q '^display-audit: .* failures=0$$' $(DISPLAY_WORK)/display-audit.log
display-audit-controls: import ## M4.5bR3: strict binding controls and new/stale/unguarded known-findings controls
	@mkdir -p $(DISPLAY_WORK)
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/valid.ndjson control tests/fixtures/display_audit/empty_known.json > $(DISPLAY_WORK)/display-valid.log 2>&1; test $$? = 0 && grep -q 'failures=0$$' $(DISPLAY_WORK)/display-valid.log && grep -q '^ac4: MET$$' $(DISPLAY_WORK)/display-valid.log && ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-valid.log
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known.ndjson control tests/fixtures/display_audit/known_findings.json > $(DISPLAY_WORK)/display-known.log 2>&1; test $$? = 0 && grep -q 'new=0 .* stale=0 failures=0$$' $(DISPLAY_WORK)/display-known.log && ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-known.log
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known_renumbered.ndjson control tests/fixtures/display_audit/known_findings.json > $(DISPLAY_WORK)/display-known-renumbered.log 2>&1; test $$? = 0 && grep -q 'new=0 .* stale=0 failures=0$$' $(DISPLAY_WORK)/display-known-renumbered.log && grep -q '^display-audit known: unbound ' $(DISPLAY_WORK)/display-known-renumbered.log && grep -q '^display-audit known: transit-ISM ' $(DISPLAY_WORK)/display-known-renumbered.log && ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-known-renumbered.log
	@set -e; for spec in 'unbound empty_known.json NEW.unbound' 'stale empty_known.json stale' 'missing empty_known.json missing' 'missing_context empty_known.json missing' 'stale_context empty_known.json stale' 'new_unbound known_findings.json NEW.unbound' 'known known_stale.json stale-known' 'transit_unfolded known_findings.json NEW.transit-ISM' 'different_named_parent known_findings.json NEW.unbound' 'context_drift empty_known.json context-drift' 'context_source empty_known.json context-source' 'context_presence empty_known.json context-source' 'context_hold empty_known.json context-source' 'context_console empty_known.json context-source' 'context_unknown empty_known.json context-unknown'; do \
	  set -- $$spec; case=$$1; known=$$2; reason=$$3; \
	  if $(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/$$case.ndjson control tests/fixtures/display_audit/$$known > $(DISPLAY_WORK)/display-$$case-$$known.log 2>&1; then echo "display control $$case/$$known missed"; exit 1; fi; \
	  if [ "$$case" = different_named_parent ]; then grep -q 'mismatches=0 missing=0 new=1 known=[0-9]* stale=0 failures=1$$' $(DISPLAY_WORK)/display-$$case-$$known.log; fi; \
	  ! grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-$$case-$$known.log; grep -E "^FAIL $$reason([ :]|$$)" $(DISPLAY_WORK)/display-$$case-$$known.log; echo "display control $$case/$$known: rejected"; \
	done
	@echo 'display control valid: PASS'
	@echo 'display control known: PASS'
	@echo 'display control known_renumbered: KNOWN (PASS)'
scene-session-audits: playthrough ## M4.5bR3: time, unlocks and display audits after the scene run (no full replay)
	@$(MAKE) --no-print-directory AILANG=$(AILANG) playthrough-time codex-unlocks display-audit SESSION=$(PLAYTHROUGH_OUT)/session.ndjson

playthrough-ai-modes: ## M4.5bR3: explicit stub/digits scene and display checks, outside make test
	@set -e; for mode in stub digits; do \
	  $(MAKE) --no-print-directory AILANG=$(AILANG) playthrough display-audit AI=$$mode PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/ai-$$mode DISPLAY_SAMPLES=$(SCRATCH)/playthrough/ai-$$mode/display_samples.ndjson; \
	  grep -q "^ai-mode: $$mode .* result=PASS$$" $(SCRATCH)/display-audit/ai-$$mode/display-audit.log; \
	done
	@echo 'playthrough-ai-modes: stub=PASS digits=PASS'

parity-m4:
	@# replay already runs every case on both engines; --sim-only adds only the launch assertion, so one case.
	@AILANG=$(AILANG) python3 tools/replay.py --sim-only --case m4_transit_harness
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry adversarial --args-json '"tests/replays/m4_adversarial.ndjson"' sim/tools/session_refusals.ail > $(SCRATCH)/m45-refusals-vm.txt
	@$(AILANG) run $(M45_FLAGS) --entry adversarial --args-json '"tests/replays/m4_adversarial.ndjson"' sim/tools/session_refusals.ail > $(SCRATCH)/m45-refusals-interp.txt
	@cmp $(SCRATCH)/m45-refusals-vm.txt $(SCRATCH)/m45-refusals-interp.txt
	@cat $(SCRATCH)/m45-refusals-vm.txt
	@grep -q '^state-unchanged=PASS$$' $(SCRATCH)/m45-refusals-vm.txt
	@$(MAKE) AILANG=$(AILANG) replay-positive-control

replay-positive-control:
	@AILANG=$(AILANG) python3 tools/replay.py --sim-only --case m4_min_path --positive-control
	@# cmp is an independent check of that same one-bit copy; expected nonzero.
	@test -f $(SCRATCH)/replay/positive-control/m4_min_path.state.$$(uname -m).ndjson
	@if cmp $(M45_STATE) $(SCRATCH)/replay/positive-control/m4_min_path.state.$$(uname -m).ndjson; then echo 'cmp missed injected divergence'; exit 1; else rc=$$?; test $$rc -eq 1 && echo 'cmp positive control: divergence detected'; fi

# Generate the live state stream without relying on committed digest goldens.
$(M45_STATE): tests/replays/m4_min_path.ndjson sim/*.ail
	@mkdir -p $(SCRATCH)/replay
	@$(AILANG) run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail < $< > $@

codex-unlocks: $(M45_STATE)
	@entry=$(if $(SESSION),codexUnlocks,codexUnlocksLegacy); path='$(if $(SESSION),$(SESSION),$(M45_STATE))'; \
	if [ -n '$(SESSION)' ] && grep -q '"type"[[:space:]]*:[[:space:]]*"input"' "$$path" && ! grep -q '"type"[[:space:]]*:[[:space:]]*"state"' "$$path"; then entry=sceneCodex; fi; \
	env -u AI_LIVE $(AILANG) run $(M45_FLAGS) --bytecode --entry $$entry --args-json "\"$$path\"" $(M45_TOOL) > $(SCRATCH)/m45-codex.txt
	@cat $(SCRATCH)/m45-codex.txt
	@grep -q '^codex-unlocks=PASS$$' $(SCRATCH)/m45-codex.txt
	@# Scope controls: the frozen stream must fail the current expectation and vice versa.
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry codexUnlocks --args-json '"$(M45_STATE)"' $(M45_TOOL) > $(SCRATCH)/m45-legacy-current.txt
	@grep -q '^codex-unlocks=FAIL$$' $(SCRATCH)/m45-legacy-current.txt
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry codexUnlocks --args-json '"$(M45_FIX)/codex.ndjson"' $(M45_TOOL) > $(SCRATCH)/m45-current.txt
	@grep -q '^codex-unlocks=PASS$$' $(SCRATCH)/m45-current.txt
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry codexUnlocksLegacy --args-json '"$(M45_FIX)/codex.ndjson"' $(M45_TOOL) > $(SCRATCH)/m45-current-legacy.txt
	@grep -q '^codex-unlocks=FAIL$$' $(SCRATCH)/m45-current-legacy.txt

playthrough-time:
	@mkdir -p $(SCRATCH)
	@entry=playthroughTime; path='$(if $(SESSION),$(SESSION),$(M45_FIX)/proxy.ndjson)'; \
	if [ -n '$(SESSION)' ] && grep -q '"type"[[:space:]]*:[[:space:]]*"input"' "$$path" && ! grep -q '"type"[[:space:]]*:[[:space:]]*"state"' "$$path"; then entry=sceneTime; fi; \
	env -u AI_LIVE $(AILANG) run $(M45_FLAGS) --bytecode --entry $$entry --args-json "\"$$path\"" $(M45_TOOL) > $(SCRATCH)/m45-time.txt
	@cat $(SCRATCH)/m45-time.txt
	@grep -q '^playthrough-time=PASS$$' $(SCRATCH)/m45-time.txt

session-audit-test:
	@mkdir -p $(SCRATCH)
	@TMPDIR=$(abspath $(SCRATCH)) $(AILANG) test --strict-bytecode sim/tools/session_audit_test.ail
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry auditPure --args-json 0 sim/tools/session_audit_test.ail > $(SCRATCH)/m45-pure.txt
	@grep -q '^session-audit-ok$$' $(SCRATCH)/m45-pure.txt
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry auditTests --args-json 0 sim/tools/session_audit_test.ail > $(SCRATCH)/m45-fixtures.txt
	@grep -q '^session-audit-ok$$' $(SCRATCH)/m45-fixtures.txt
	@set -e; for spec in 'playthroughTime walk_valid' 'playthroughTime walk_ceiling' 'playthroughTime walk_over_limit' 'playthroughTime proxy' 'playthroughTime over_limit' 'playthroughTime bad_leg' 'codexUnlocks simultaneous' 'codexUnlocks late_hint' 'codexUnlocks codex' 'codexUnlocks swapped' 'codexUnlocks missing' 'codexUnlocks early' 'codexUnlocks shrink' 'codexUnlocks wrong_hint' 'codexUnlocks right_hint'; do \
	  set -- $$spec; entry=$$1; fixture=$$2; \
	  $(AILANG) run --quiet --package-dir sim --caps FS --bytecode --entry $$entry --args-json "\"$(M45_FIX)/$$fixture.ndjson\"" sim/tools/session_audit.ail > $(SCRATCH)/m45-$$fixture-vm.txt; \
	  $(AILANG) run --quiet --package-dir sim --caps FS --entry $$entry --args-json "\"$(M45_FIX)/$$fixture.ndjson\"" sim/tools/session_audit.ail > $(SCRATCH)/m45-$$fixture-interp.txt; \
	  cmp $(SCRATCH)/m45-$$fixture-vm.txt $(SCRATCH)/m45-$$fixture-interp.txt; cat $(SCRATCH)/m45-$$fixture-vm.txt; \
	done

m45-author:
	@AILANG_BIN=$(AILANG) $(GODOT) --headless --path . --log-file $(SCRATCH)/m45-author.log --script tools/m45_session.gd
