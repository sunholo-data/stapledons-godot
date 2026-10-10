# M4.5 scene-independent session audits. UI/bot/display work awaits D-52.
.PHONY: parity-m4 replay-positive-control session-audit-test codex-unlocks playthrough-time m45-author
M45_CASES := m4_min_path m4_adversarial m4_transit_harness
M45_STATE := $(SCRATCH)/replay/m4_min_path.vm.ndjson
M45_FIX := tests/fixtures/session_audit
M45_FLAGS := --quiet --package-dir sim --caps FS
M45_TOOL := sim/tools/session_audit.ail

parity-m4:
	@AILANG=$(AILANG) python3 tools/replay.py --sim-only --case $(M45_CASES)
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
	@env -u AI_LIVE $(AILANG) run $(M45_FLAGS) --bytecode --entry $(if $(SESSION),codexUnlocks,codexUnlocksLegacy) --args-json '"$(if $(SESSION),$(SESSION),$(M45_STATE))"' $(M45_TOOL) > $(SCRATCH)/m45-codex.txt
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
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry playthroughTime --args-json '"$(if $(SESSION),$(SESSION),$(M45_FIX)/proxy.ndjson)"' $(M45_TOOL) > $(SCRATCH)/m45-time.txt
	@cat $(SCRATCH)/m45-time.txt
	@grep -q '^playthrough-time=PASS$$' $(SCRATCH)/m45-time.txt

session-audit-test:
	@mkdir -p $(SCRATCH)
	@TMPDIR=$(abspath $(SCRATCH)) $(AILANG) test --strict-bytecode sim/tools/session_audit_test.ail
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry auditPure --args-json 0 sim/tools/session_audit_test.ail > $(SCRATCH)/m45-pure.txt
	@grep -q '^session-audit-ok$$' $(SCRATCH)/m45-pure.txt
	@$(AILANG) run $(M45_FLAGS) --bytecode --entry auditTests --args-json 0 sim/tools/session_audit_test.ail > $(SCRATCH)/m45-fixtures.txt
	@grep -q '^session-audit-ok$$' $(SCRATCH)/m45-fixtures.txt
	@set -e; for spec in 'playthroughTime proxy' 'playthroughTime over_limit' 'playthroughTime bad_leg' 'codexUnlocks codex' 'codexUnlocks swapped' 'codexUnlocks missing' 'codexUnlocks early' 'codexUnlocks shrink' 'codexUnlocks wrong_hint' 'codexUnlocks right_hint'; do \
	  set -- $$spec; entry=$$1; fixture=$$2; \
	  $(AILANG) run --quiet --package-dir sim --caps FS --bytecode --entry $$entry --args-json "\"$(M45_FIX)/$$fixture.ndjson\"" sim/tools/session_audit.ail > $(SCRATCH)/m45-$$fixture-vm.txt; \
	  $(AILANG) run --quiet --package-dir sim --caps FS --entry $$entry --args-json "\"$(M45_FIX)/$$fixture.ndjson\"" sim/tools/session_audit.ail > $(SCRATCH)/m45-$$fixture-interp.txt; \
	  cmp $(SCRATCH)/m45-$$fixture-vm.txt $(SCRATCH)/m45-$$fixture-interp.txt; cat $(SCRATCH)/m45-$$fixture-vm.txt; \
	done

m45-author:
	@AILANG_BIN=$(AILANG) $(GODOT) --headless --path . --log-file $(SCRATCH)/m45-author.log --script tools/m45_session.gd
