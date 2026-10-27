# M4.5 legacy and scene-session audits (D-66/D-68).

# Row 7i(c): the real AI=stub scene session, proven on both engines at record time.
M45_SCENE := tests/replays/scene/m4_scene_session
M45_SCENE_WORK := $(SCRATCH)/replay-scene
define M45_SCENE_SHAPE
lines=$$(wc -l < "$$session" | tr -d ' '); bytes=$$(wc -c < "$$session" | tr -d ' '); sha=$$(shasum -a 256 "$$session" | cut -d ' ' -f1); \
record=$$(grep -c '"k":"record"' "$$session" || :); ai_open=$$(grep -c '"k":"ai_open"' "$$session" || :); commit=$$(grep -c '"k":"commit"' "$$session" || :); \
hello=$$(grep -c '"type":"hello"' "$$session" || :); new_game=$$(grep -c '"type":"new_game"' "$$session" || :); quit=$$(grep -c '"type":"quit"' "$$session" || :); input=$$(grep -c '"type":"input"' "$$session" || :); \
test "$$bytes" -gt 0 && test "$$input" -gt 0 && test "$$record" -ge 1 && test "$$ai_open" -ge 1 && test "$$commit" -eq 2 && test "$$hello" -eq 1 && test "$$new_game" -eq 1 && test "$$quit" -eq 1 && test "$$lines" -eq "$$((input + 3))" && test "$$(tail -1 "$$session")" = '{"v":2,"type":"quit"}' || { echo 'scene input shape: FAIL'; exit 1; }
endef
.PHONY: scene-session-fixture replay-scene-record replay-scene
scene-session-fixture: ## Record the real stub playthrough input; CHECK=1 compares without writing data
	@env -u AI_LIVE $(MAKE) playthrough AI=stub SCRIPT=tests/playthrough_min.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/scene-golden
	@set -e; session='$(SCRATCH)/playthrough/scene-golden/session.ndjson'; $(M45_SCENE_SHAPE); \
	test "$$record" -eq 1; test "$$ai_open" -eq 1; \
	echo "scene fixture: lines=$$lines bytes=$$bytes sha256=$$sha record=$$record ai_open=$$ai_open commit=$$commit new_game=$$new_game quit=$$quit"; \
	if [ '$(CHECK)' = 1 ]; then cmp "$$session" '$(M45_SCENE).ndjson'; echo 'scene fixture: identical to a fresh playthrough'; \
	else mkdir -p tests/replays/scene; cp "$$session" '$(M45_SCENE).ndjson'; (cd tests/replays/scene && shasum -a 256 m4_scene_session.ndjson > m4_scene_session.input.sha256); fi

replay-scene-record: ## Explicit arm64 record, retaining the VM/interpreter proof and producer status
	@mkdir -p $(M45_SCENE_WORK)
	@test "$$(uname -m)" = arm64 || { echo 'scene record: arm64 required'; exit 1; }
	@set -e; env -u AI_LIVE $(AILANG) --version > $(M45_SCENE_WORK)/version.log; grep -qx 'AILANG v0.54.18' $(M45_SCENE_WORK)/version.log
	@env -u AI_LIVE AILANG=$(AILANG) python3 tools/replay.py --record $(M45_SCENE).ndjson > $(M45_SCENE_WORK)/record.log 2>&1; rc=$$?; \
	if [ $$rc -ne 0 ]; then cat $(M45_SCENE_WORK)/record.log; exit $$rc; fi; \
	set -e; grep -E '^(replay:|recorded )' $(M45_SCENE_WORK)/record.log > $(M45_SCENE_WORK)/record.txt; \
	test "$$(wc -l < $(M45_SCENE_WORK)/record.txt | tr -d ' ')" -eq 2; grep -Eq '^replay: AILANG v0\.54\.18, arm64 ' $(M45_SCENE_WORK)/record.txt; \
	grep -Eq '^recorded $(M45_SCENE)\.state\.arm64\.sha256 \([0-9]+ replies, [0-9]+ bytes, sha256 [0-9a-f]{64}, VM [0-9.]+ s, interpreter [0-9.]+ s\)$$' $(M45_SCENE_WORK)/record.txt; \
	tee $(M45_SCENE).record.txt < $(M45_SCENE_WORK)/record.txt

replay-scene: ## VM-only scene golden, input/golden controls, effects and archive unlocks
	@(cd tests/replays/scene && shasum -a 256 -c m4_scene_session.input.sha256)
	@set -e; pin='$(M45_SCENE_WORK)/input-pin-control'; mkdir -p "$$pin"; \
	cp $(M45_SCENE).ndjson "$$pin/m4_scene_session.ndjson"; cp $(M45_SCENE).input.sha256 "$$pin/m4_scene_session.input.sha256"; \
	perl -0777 -i -pe 'substr($$_,0,1)=chr(ord(substr($$_,0,1)) ^ 1)' "$$pin/m4_scene_session.ndjson"; \
	if (cd "$$pin" && shasum -a 256 -c m4_scene_session.input.sha256) > "$$pin/check.log" 2>&1; then echo 'scene input pin control: one-byte divergence was not detected'; exit 1; \
	else rc=$$?; test $$rc -eq 1; grep -qx 'm4_scene_session.ndjson: FAILED' "$$pin/check.log"; fi; \
	echo 'scene input pin control: one-byte change detected'
	@set -e; session='$(M45_SCENE).ndjson'; $(M45_SCENE_SHAPE)
	@set -e; recorded=$$(sed -nE 's#^recorded $(M45_SCENE)\.state\.arm64\.sha256 \([0-9]+ replies, [0-9]+ bytes, sha256 ([0-9a-f]{64}), VM [0-9.]+ s, interpreter [0-9.]+ s\)$$#\1#p' $(M45_SCENE).record.txt); \
	test -n "$$recorded" && test "$$recorded" = "$$(cut -c1-64 $(M45_SCENE).state.arm64.sha256)"
	@grep -Eq '^export func main\(\) -> \(\) ! \{IO\} =' sim/ship.ail && echo 'scene effects: main ! {IO}, --caps IO'
	@env -u AI_LIVE AILANG=$(AILANG) python3 tools/replay.py --sim-only --vm-only --positive-control --scratch $(SCRATCH)/replay --session $(M45_SCENE).ndjson
	@set -e; mkdir -p $(M45_SCENE_WORK); ln -sf '$(abspath $(M45_SCENE).ndjson)' $(M45_SCENE_WORK)/session.ndjson; ln -sf '$(abspath $(SCRATCH)/replay/m4_scene_session.vm.ndjson)' $(M45_SCENE_WORK)/states.ndjson; \
	env -u AI_LIVE $(AILANG) run $(M45_FLAGS) --bytecode --entry sceneCodex --args-json '"$(abspath $(M45_SCENE_WORK)/session.ndjson)"' $(M45_TOOL) > $(M45_SCENE_WORK)/codex.log; \
	cat $(M45_SCENE_WORK)/codex.log; grep -qx 'codex-unlocks=PASS' $(M45_SCENE_WORK)/codex.log
	@echo 'replay-scene: PASS (VM only; interpreter proven at record time, see m4_scene_session.record.txt)'
test: replay-scene

# Row 7o: tools/rig_check.sh posts only status descriptions GitHub accepts (at most 140 characters)
# and still reports a failure when a post is refused; stubs only (gh, git, make), no network.
# Lives here while the Makefile is held; it belongs in tools-test and ci-fast (deferred).
.PHONY: rig-check-control
rig-check-control: ## Row 7o: rig_check.sh status descriptions fit GitHub's 140-character limit
	@sh tools/test_rig_check.sh tools/rig_check.sh
test: rig-check-control

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
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(DISPLAY_SAMPLES) scene $(DISPLAY_KNOWN) > $(DISPLAY_WORK)/display-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|display-audit|ai-mode|ac4:)' $(DISPLAY_WORK)/display-audit.log; test $$rc = 0 && if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-audit.log; then echo "display audit $(DISPLAY_WORK)/display-audit.log script error"; exit 1; fi && grep -q '^display-audit: .* failures=0$$' $(DISPLAY_WORK)/display-audit.log
display-audit-controls: import ## M4.5bR3: strict binding controls and new/stale/unguarded known-findings controls
	@mkdir -p $(DISPLAY_WORK)
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/valid.ndjson control tests/fixtures/display_audit/empty_known.json > $(DISPLAY_WORK)/display-valid.log 2>&1; test $$? = 0 && grep -q 'failures=0$$' $(DISPLAY_WORK)/display-valid.log && grep -q '^ac4: MET$$' $(DISPLAY_WORK)/display-valid.log && if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-valid.log; then echo "display audit $(DISPLAY_WORK)/display-valid.log script error"; exit 1; fi
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known.ndjson control tests/fixtures/display_audit/known_findings.json > $(DISPLAY_WORK)/display-known.log 2>&1; test $$? = 0 && grep -q 'new=0 .* stale=0 failures=0$$' $(DISPLAY_WORK)/display-known.log && grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(DISPLAY_WORK)/display-known.log && if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-known.log; then echo "display audit $(DISPLAY_WORK)/display-known.log script error"; exit 1; fi
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known_renumbered.ndjson control tests/fixtures/display_audit/known_findings.json > $(DISPLAY_WORK)/display-known-renumbered.log 2>&1; test $$? = 0 && grep -q 'new=0 .* stale=0 failures=0$$' $(DISPLAY_WORK)/display-known-renumbered.log && grep -q '^display-audit known: unbound ' $(DISPLAY_WORK)/display-known-renumbered.log && grep -q '^display-audit known: transit-ISM ' $(DISPLAY_WORK)/display-known-renumbered.log && grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(DISPLAY_WORK)/display-known-renumbered.log && if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-known-renumbered.log; then echo "display audit $(DISPLAY_WORK)/display-known-renumbered.log script error"; exit 1; fi
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/known.ndjson control tests/fixtures/display_audit/known_unaccepted.json > $(DISPLAY_WORK)/display-known-unaccepted.log 2>&1; test $$? = 0 && grep -q 'new=0 .* stale=0 failures=0$$' $(DISPLAY_WORK)/display-known-unaccepted.log && if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-known-unaccepted.log; then echo "display audit $(DISPLAY_WORK)/display-known-unaccepted.log script error"; exit 1; fi
	@grep -Eq '^ac4: OPEN \(1 unaccepted known, 4 accepted by D-77/D-78\)$$' $(DISPLAY_WORK)/display-known-unaccepted.log || { echo 'display control known_unaccepted verdict missed'; exit 1; }
	@set -e; n=0; for spec in 'unbound empty_known.json NEW.unbound' 'stale empty_known.json stale' 'missing empty_known.json missing' 'missing_context empty_known.json missing' 'stale_context empty_known.json stale' 'new_unbound known_findings.json NEW.unbound' 'known known_stale.json stale-known' 'transit_unfolded known_findings.json NEW.transit-ISM' 'different_named_parent known_findings.json NEW.unbound' 'context_drift empty_known.json context-drift' 'context_source empty_known.json context-source' 'context_presence empty_known.json context-presence' 'context_hold empty_known.json context-source' 'context_console empty_known.json context-source' 'context_unknown empty_known.json context-unknown' 'context_absent empty_known.json context-drift' 'context_presence_parts empty_known.json context-presence' 'context_crew empty_known.json context-source' 'review_unbound empty_known.json NEW.unbound' 'crew_unbound empty_known.json crew-unbound' 'known known_bad_ruling.json known-ruling' 'known known_wrong_kind.json known-ruling' 'known known_wrong_cards.json known-ruling' 'known known_wrong_caption.json known-ruling' 'known known_wrong_accompanying.json known-ruling' 'known known_wrong_transit_node.json known-ruling' 'known known_wrong_transit_text.json known-ruling' 'known known_wrong_caption_node.json known-ruling' 'known known_wrong_transit_kind.json known-ruling' 'known known_wrong_caption_kind.json known-ruling' 'known known_nonstring_ruling.json known-ruling'; do \
	  n=$$((n + 1)); set -- $$spec; case=$$1; known=$$2; reason=$$3; \
	  if $(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- tests/fixtures/display_audit/$$case.ndjson control tests/fixtures/display_audit/$$known > $(DISPLAY_WORK)/display-$$case-$$known.log 2>&1; then echo "display control $$case/$$known missed"; exit 1; fi; \
	  if [ "$$case" = different_named_parent ]; then grep -q 'mismatches=0 missing=0 new=1 known=[0-9]* stale=0 failures=1$$' $(DISPLAY_WORK)/display-$$case-$$known.log; fi; \
	  if grep -q 'SCRIPT ERROR:' $(DISPLAY_WORK)/display-$$case-$$known.log; then echo "display control $$case/$$known script error"; exit 1; fi; grep -E "^FAIL $$reason([ :]|$$)" $(DISPLAY_WORK)/display-$$case-$$known.log || { echo "display control $$case/$$known wrong reason (want $$reason)"; exit 1; }; echo "display control $$case/$$known: rejected"; \
	done; test $$n -eq 31 || { echo "display control rows: $$n, want 31"; exit 1; }
	@echo 'display control valid: PASS'
	@echo 'display control known: PASS'
	@echo 'display control known_renumbered: KNOWN (PASS)'
	@echo 'display control known_unaccepted: OPEN (PASS)'
scene-session-audits: playthrough ## M4.5bR3: time, unlocks and display audits after the scene run (no full replay)
	@$(MAKE) --no-print-directory AILANG=$(AILANG) playthrough-time codex-unlocks display-audit SESSION=$(PLAYTHROUGH_OUT)/session.ndjson

playthrough-ai-modes: ## M4.5bR3: explicit stub/digits scene and display checks, outside make test; R2-INTERLUDE I4: the guided crossing's review and the Archive's telling in each mode
	@set -e; for mode in stub digits; do \
	  $(MAKE) --no-print-directory AILANG=$(AILANG) playthrough display-audit AI=$$mode PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/ai-$$mode DISPLAY_SAMPLES=$(SCRATCH)/playthrough/ai-$$mode/display_samples.ndjson; \
	  grep -q "^ai-mode: $$mode .* result=PASS$$" $(SCRATCH)/display-audit/ai-$$mode/display-audit.log; \
	  $(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_interlude.json AI=$$mode PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/ai-$$mode-interlude; \
	  grep -E "^narration: $$mode state=(told voiced=1|authored voiced=0)$$" $(SCRATCH)/playthrough/ai-$$mode-interlude/run.log; \
	done
	@echo 'playthrough-ai-modes: stub=PASS digits=PASS (R2-INTERLUDE I4: the review reached, the Archive asked; stub told and voiced, digits refused)'

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

# R2-INTERLUDE I3 (AC8): the guided crossing's playthrough (tests/playthrough_interlude.json: the
# Alpha Centauri leg, an orders crew under critical_only, holds answered on the review's Hold page,
# every review page read, Brake) and the display audit of every sampled frame against the same
# known file (no entry added); the negative control (an unbound review label) is in
# display-audit-controls.
.PHONY: display-audit-interlude
INTERLUDE_OUT := $(SCRATCH)/playthrough/interlude
display-audit-interlude: import display-audit-controls ## R2-INTERLUDE AC8: a guided crossing with crew, every review page sampled and audited
	@$(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_interlude.json PLAYTHROUGH_OUT=$(INTERLUDE_OUT)
	@mkdir -p $(SCRATCH)/display-audit/interlude
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(INTERLUDE_OUT)/display_samples.ndjson interlude $(DISPLAY_KNOWN) > $(SCRATCH)/display-audit/interlude/display-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|display-audit)' $(SCRATCH)/display-audit/interlude/display-audit.log; test $$rc = 0 && if grep -q 'SCRIPT ERROR:' $(SCRATCH)/display-audit/interlude/display-audit.log; then echo "display audit $(SCRATCH)/display-audit/interlude/display-audit.log script error"; exit 1; fi && grep -q '^display-audit: .* new=0 .* failures=0$$' $(SCRATCH)/display-audit/interlude/display-audit.log && grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(SCRATCH)/display-audit/interlude/display-audit.log

# R2-CREW-CONSOLE-V2 V7 (AC14): the Crew console's playthrough (tests/playthrough_crew.json: a
# consent crew at rest, the board, offers sent from calls, a concern and a decline answered, every
# member's call opened) and the display audit of every sampled frame (no entry added to the known
# file); the negative control (an unbound label on the call window, crew_unbound) is in
# display-audit-controls.
.PHONY: display-audit-crew
CREW_OUT := $(SCRATCH)/playthrough/crew
display-audit-crew: import display-audit-controls ## R2-CREW-CONSOLE-V2 AC14: the Crew console's board and calls sampled and audited (every Label a binding)
	@$(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_crew.json PLAYTHROUGH_OUT=$(CREW_OUT)
	@mkdir -p $(SCRATCH)/display-audit/crew
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(CREW_OUT)/display_samples.ndjson crew $(DISPLAY_KNOWN) > $(SCRATCH)/display-audit/crew/display-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|display-audit)' $(SCRATCH)/display-audit/crew/display-audit.log; test $$rc = 0 && if grep -q 'SCRIPT ERROR:' $(SCRATCH)/display-audit/crew/display-audit.log; then echo "display audit $(SCRATCH)/display-audit/crew/display-audit.log script error"; exit 1; fi && grep -q '^display-audit: .* new=0 .* failures=0$$' $(SCRATCH)/display-audit/crew/display-audit.log && grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(SCRATCH)/display-audit/crew/display-audit.log
