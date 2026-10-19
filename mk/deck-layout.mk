# R2-DECK-LAYOUT (design_docs/planned/r2/deck-layout.md, ledger D-90): the layout evaluator, the
# deck asset check, and the review captures. Thresholds: art/deck-layout-v1/thresholds.json;
# budgets and pins: art/deck-layout-v1/budgets.json.
.PHONY: deck-layout-eval deck-layout-eval-test deck-assets-check deck-layout-capture
DECK_LAYOUT_ARGS ?=
deck-layout-eval: import ## AC2/AC3: the shipped deck against the §D4 thresholds (prints "deck-layout: bridge ok" / "commons ok"); LAYOUT=<json> scores a candidate in-engine (search only)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tools/deck_layout_eval.gd -- $(if $(LAYOUT),--layout $(LAYOUT)) $(DECK_LAYOUT_ARGS) > $(SCRATCH)/deck-layout-eval.log 2>&1; rc=$$?; grep -E '^(deck-layout|FAIL)' $(SCRATCH)/deck-layout-eval.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-eval.log
deck-layout-eval-test: import ## AC1: the evaluator reproduces the camera test's counts, refuses bad layouts, and fails seeded bad layouts (boom, sky, dominance)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_deck_layout_eval.gd > $(SCRATCH)/deck-layout-eval-test.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|deck-layout-eval-test)' $(SCRATCH)/deck-layout-eval-test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-eval-test.log && grep -q '^deck-layout-eval-test: [0-9]* passed, 0 failures$$' $(SCRATCH)/deck-layout-eval-test.log
test: deck-layout-eval-test
deck-assets-check: import ## AC6: deck pins (sha256, bytes), GLB budgets (§D6), named nodes, opaque, no painted emission, clean reimport; VRAM with a GPU window; MASTERS=1 checks the masters too. Negative controls: a wrong pin and an emissive prop fail
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tools/deck_assets_check.gd -- $(if $(MASTERS),--masters) > $(SCRATCH)/deck-assets-check.log 2>&1; rc=$$?; grep -E '^(FAIL|deck-assets-check)' $(SCRATCH)/deck-assets-check.log; test $$rc = 0 && grep -q '^deck-assets-check: ok' $(SCRATCH)/deck-assets-check.log
	@for neg in bad_sha emissive; do $(GODOT) --headless --path . --script tools/deck_assets_check.gd -- --budgets res://tests/fixtures/deck_layout/budgets_$$neg.json > $(SCRATCH)/deck-assets-$$neg.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^deck-assets-check: FAIL$$' $(SCRATCH)/deck-assets-$$neg.log || { echo "deck-assets-check: FAIL negative control $$neg passed"; exit 1; }; done; echo "deck-assets-check: negative controls (wrong pin, emissive prop) fail as they must"
test: deck-assets-check
TAG ?= capture
DECK_ASSETS ?=
deck-layout-capture: import ## AC11 (GPU window): every camera view at rest, 0.99c, a guided stop and Sgr A*, two sizes -> renders/deck_layout/$(TAG)/ (+ contact sheets), the sky-mask control and the eval report; DECK_ASSETS=<dir> captures a candidate deck. Open every frame
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --path . --script tools/camera_views_capture.gd -- --out res://renders/deck_layout/$(TAG) $(if $(DECK_ASSETS),--assets $(DECK_ASSETS)) > $(SCRATCH)/deck-layout-capture-$(TAG).log 2>&1; rc=$$?; grep -E '^(FAIL|camera-views-capture)' $(SCRATCH)/deck-layout-capture-$(TAG).log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-capture-$(TAG).log
	@$(GODOT_SIM) --path . --script tools/deck_layout_capture.gd -- --out res://renders/deck_layout/$(TAG) $(if $(DECK_ASSETS),--assets $(DECK_ASSETS)) > $(SCRATCH)/deck-layout-mask-$(TAG).log 2>&1; rc=$$?; grep -E '^(ok|FAIL|deck-layout)' $(SCRATCH)/deck-layout-mask-$(TAG).log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/deck-layout-mask-$(TAG).log
