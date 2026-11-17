# Approved PV1-PV3 checks; usable before integration with -f Makefile -f mk/playable-voyage.mk.
.PHONY: playable-voyage-unit playable-voyage-test
test: playable-voyage-unit
ship-demo-ci: playable-voyage-test
playable-voyage-unit:
	@$(SCRIPT_GATE) playable-voyage-unit $(SCRATCH)/playthrough-completion.log 60 '^playthrough-completion: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/playthrough-completion-engine.log --script tests/test_playthrough_completion.gd
playable-voyage-test: playable-voyage-unit
	@env -u AI_LIVE $(MAKE) --no-print-directory playthrough AI=none SCRIPT=tests/playthrough_complete_voyage.json PLAYTHROUGH_OUT=$(SCRATCH)/playthrough/voyage-complete
	@grep -qx 'voyage-completion: PASS 2 commits 2 arrivals 3 ordered reads' $(SCRATCH)/playthrough/voyage-complete/run.log
	@$(MAKE) --no-print-directory display-audit DISPLAY_SAMPLES=$(SCRATCH)/playthrough/voyage-complete/display_samples.ndjson
