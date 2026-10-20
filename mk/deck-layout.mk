# R2-DECK-LAYOUT (design_docs/planned/r2/deck-layout.md, ledger D-95): the bow evaluator, the deck
# asset check, the pinned baseline and the review captures. Thresholds: art/deck-layout-v2/
# thresholds.json; budgets and pins: art/deck-layout-v2/budgets.json; baseline pins:
# art/deck-layout-v2/baseline.sha256.
.PHONY: deck-layout-eval deck-layout-eval-test deck-assets-check deck-layout-capture ship-baseline
ship-baseline: ## the pinned grounded-bridge-v2 export (the evaluator's positive control) -> build/ship-baseline/ (public bucket, curl)
	@sh tools/ship_baseline.sh fetch
deck-layout-eval: import ## AC2: the shipped bridge against the §D4 thresholds (prints "deck-layout: bridge ok"); LAYOUT=<json> scores a candidate in-engine (search only), ASSETS=<dir> another deck
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tools/deck_layout_eval.gd -- $(if $(LAYOUT),--layout $(LAYOUT)) $(if $(ASSETS),--assets $(ASSETS)) --json $(SCRATCH)/deck-layout-eval.json > $(SCRATCH)/deck-layout-eval.log 2>&1; rc=$$?; grep -E '^(deck-layout|FAIL)' $(SCRATCH)/deck-layout-eval.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-eval.log && grep -q '^deck-layout: bridge ok$$' $(SCRATCH)/deck-layout-eval.log
deck-layout-eval-test: import ship-baseline ## AC1: the pinned baseline reproduces the §D4 'today' numbers; layout A passes in-engine; seeded defects fail faces-bow, spawn-open, pole-ray and station-body
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_deck_layout_eval.gd > $(SCRATCH)/deck-layout-eval-test.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|deck-layout-eval-test)' $(SCRATCH)/deck-layout-eval-test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-eval-test.log && grep -q '^deck-layout-eval-test: [0-9]* passed, 0 failures$$' $(SCRATCH)/deck-layout-eval-test.log
test: deck-layout-eval-test
deck-assets-check: import ## AC7: deck pins (sha256, bytes), GLB budgets (§D5), named nodes, opaque, no painted emission, clean reimport; VRAM with a GPU window; MASTERS=1 checks the masters too. Negative controls: a wrong pin and an emissive prop fail
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tools/deck_assets_check.gd -- $(if $(MASTERS),--masters) > $(SCRATCH)/deck-assets-check.log 2>&1; rc=$$?; grep -E '^(FAIL|deck-assets-check)' $(SCRATCH)/deck-assets-check.log; test $$rc = 0 && grep -q '^deck-assets-check: ok' $(SCRATCH)/deck-assets-check.log
	@for neg in bad_sha emissive; do $(GODOT) --headless --path . --script tools/deck_assets_check.gd -- --budgets res://tests/fixtures/deck_layout/budgets_$$neg.json > $(SCRATCH)/deck-assets-$$neg.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^deck-assets-check: FAIL$$' $(SCRATCH)/deck-assets-$$neg.log || { echo "deck-assets-check: FAIL negative control $$neg passed"; exit 1; }; done; echo "deck-assets-check: negative controls (wrong pin, emissive prop) fail as they must"
test: deck-assets-check
TAG ?= capture
deck-layout-capture: import ## AC11 (GPU window): the shipped bridge's plan, Bow at rest / 0.99c / first stop, Astern, a walk, the console zooms -> renders/deck_layout/$(TAG)/ (+ contact sheet, probe.json). Open every frame
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --path . --script tools/deck_bow_probe.gd -- --layouts=res://art/deck-layout-v2/shipped.json --capture --out=res://renders/deck_layout/$(TAG) > $(SCRATCH)/deck-layout-capture-$(TAG).log 2>&1; rc=$$?; grep -E '^(FAIL|shot|deck-bow-probe)' $(SCRATCH)/deck-layout-capture-$(TAG).log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-capture-$(TAG).log
