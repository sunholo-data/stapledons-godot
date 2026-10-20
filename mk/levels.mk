# R2-LEVELS (design_docs/planned/r2/levels.md, design_docs/levels/README.md, ledger D-103): the
# level pipeline's shared commands. Every level uses the same ones; a level doc never invents a test.
.PHONY: levels-backlog-test level-test
levels-backlog-test: ## AC1: the backlog parses (statuses from the fixed set); --next never offers a level in S0/S3/S5; a bad-status fixture fails
	@sh tools/levels_backlog.sh --check
	@if sh tools/levels_backlog.sh --check --file tests/fixtures/levels/backlog_bad_status.md > /dev/null 2>&1; then echo "levels-backlog-test: FAIL the bad-status fixture passed"; exit 1; fi
	@out=$$(sh tools/levels_backlog.sh --next --file tests/fixtures/levels/backlog_attended.md); \
	  for want in "level-eval garden" "level-assets-check farms" "levels-regress bridge" "regress-capture bridge"; do echo "$$out" | grep -qx "$$want" || { echo "levels-backlog-test: FAIL --next missing '$$want'"; exit 1; }; done; \
	  for id in commons homes workshops; do if echo "$$out" | grep -q " $$id$$"; then echo "levels-backlog-test: FAIL --next offered $$id (attended stage)"; exit 1; fi; done; \
	  echo "levels-backlog-test: ok (bad status fails; --next offers S1/S2/S4/landed only, never S0/S3/S5)"
test: levels-backlog-test
level-test: import ## AC2/AC3: stapledons.level/1 schema cases, LevelGreybox (box and arc pieces, colliders, WALK_ surfaces), multi-height walk, route transfers, the bridge walk unchanged
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_levels.gd > $(SCRATCH)/level-test.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|level-test)' $(SCRATCH)/level-test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/level-test.log && grep -q '^level-test: [0-9]* passed, 0 failures$$' $(SCRATCH)/level-test.log
test: level-test
LEVEL ?= bridge
.PHONY: level-eval level-eval-test
level-eval: import ## AC8 (S2): a level against its thresholds (prints "level-eval: <id> ok"); LEVEL=<id>, LAYOUT=<json> scores a candidate (search only)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tools/level_eval.gd -- --level $(LEVEL) $(if $(LAYOUT),--layout $(LAYOUT)) --json $(SCRATCH)/level-eval-$(LEVEL).json > $(SCRATCH)/level-eval-$(LEVEL).log 2>&1; rc=$$?; grep -E '^(level-eval|FAIL)' $(SCRATCH)/level-eval-$(LEVEL).log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/level-eval-$(LEVEL).log && grep -qE '^level-eval: [a-z_]+ ok$$' $(SCRATCH)/level-eval-$(LEVEL).log
level-eval-test: import ## AC5: the mock Commons greybox's numbers (positive control), a roofed tier passes with its band edge on the slab model, the bridge measured as exported, and seeded unreached / pole-ray / band-top / find-sight defects each fail by name
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_level_eval.gd > $(SCRATCH)/level-eval-test.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|level-eval-test)' $(SCRATCH)/level-eval-test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/level-eval-test.log && grep -q '^level-eval-test: [0-9]* passed, 0 failures$$' $(SCRATCH)/level-eval-test.log
test: level-eval-test
