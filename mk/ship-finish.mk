# Approved PLAYABLE-SHIP-FINISH evidence slice; include after the project Makefile.
.PHONY: ship-finish-test
ship-finish-test:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-ready $(SCRATCH)/ship-finish-ready.log 180 '^ship-review-readiness: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-ready-engine.log --script tests/test_ship_review_readiness.gd
	@$(SCRIPT_GATE) ship-finish-invariants $(SCRATCH)/ship-finish-invariants.log 180 '^painted-levels-invariants: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-invariants-engine.log --script tests/test_painted_levels.gd
