# Small authored-content pilot. Check targets never stage, fetch, generate or re-pin.
MODE ?= runtime
.PHONY: content-contract-test content-budget-test content-stage-test content-pack-test content-check painted-levels-test
content-contract-test:
	@$(SCRIPT_GATE) content-contract $(SCRATCH)/content-contract.log 60 '^content-contract: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/content-contract-engine.log --script tests/test_content_contract.gd
content-budget-test:
	@$(SCRIPT_GATE) content-budget $(SCRATCH)/content-budget.log 60 '^content-budget: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/content-budget-engine.log --script tests/test_content_budget.gd
content-stage-test:
	@$(SCRIPT_GATE) content-stage $(SCRATCH)/content-stage.log 60 '^content-stage: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/content-stage-engine.log --script tests/test_content_stage.gd
content-pack-test:
	@$(SCRIPT_GATE) content-pack $(SCRATCH)/content-pack.log 60 '^content-pack: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/content-pack-engine.log --script tests/test_content_pack.gd
content-check:
	@$(SCRIPT_GATE) content-check $(SCRATCH)/content-check-$(MODE).log 180 '^content-check: 4 bundles, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/content-check-engine.log --script tools/content_check.gd -- --mode $(MODE) --json res://$(SCRATCH)/content-check-$(MODE).json
painted-levels-test:
	@$(SCRIPT_GATE) painted-levels $(SCRATCH)/painted-levels.log 120 '^painted-levels-check: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --log-file $(SCRATCH)/painted-levels-engine.log --script tests/test_painted_levels.gd
# Fixtures only: do not add the full authoring scan or staging as fast-tier prerequisites.
ci-fast: content-budget-test content-pack-test
test: content-contract-test content-budget-test content-stage-test content-pack-test
