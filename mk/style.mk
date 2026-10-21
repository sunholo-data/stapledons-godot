# R2-BRIDGE-STYLE (design_docs/planned/r2/bridge-styling-pass.md, ledger D-100): the bridge's toon and
# ink material audit, the HUD theme check and the review captures.
.PHONY: style-test ui-theme-check style-capture
style-test: import ## AC3: every bridge_style mesh is the toon material with exactly the ink next_pass (exclusions keep theirs); style.bridge_nodes exist; lower decks unstyled; the sky layers exist apart and never toon. Negative controls: a seeded PBR bridge surface and a seeded toon sky layer are caught
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_style.gd > $(SCRATCH)/style-test.log 2>&1; rc=$$?; grep -E '^(  ok|  FAIL|style-test)' $(SCRATCH)/style-test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/style-test.log && grep -q '^style-test: [0-9]* passed, 0 failures$$' $(SCRATCH)/style-test.log
test: style-test
ui-theme-check: import ## AC6/AC7: no hard-coded panel styles or colours outside the theme (a report until ST4, then STRICT=1), the OFL fonts and ink border pinned, WCAG 4.5:1. Negative controls: a seeded StyleBoxFlat.new() (strict) and a low-contrast pair fail
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- $(if $(STRICT),--strict) > $(SCRATCH)/ui-theme-check.log 2>&1; rc=$$?; grep -E '^(FAIL|leftover|ui-theme-check)' $(SCRATCH)/ui-theme-check.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/ui-theme-check.log && grep -q '^ui-theme-check: ok$$' $(SCRATCH)/ui-theme-check.log
	@$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --strict --scan=res://tests/fixtures/ui_theme/seeded_override.gd > $(SCRATCH)/ui-theme-neg-override.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^FAIL 1 hard-coded panel styles' $(SCRATCH)/ui-theme-neg-override.log || { echo "ui-theme-check: FAIL negative control (seeded StyleBoxFlat) passed"; exit 1; }
	@$(GODOT) --headless --path . --script tools/ui_theme_check.gd -- --theme-builder=res://tests/fixtures/ui_theme/low_contrast_theme.gd > $(SCRATCH)/ui-theme-neg-contrast.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^FAIL contrast' $(SCRATCH)/ui-theme-neg-contrast.log || { echo "ui-theme-check: FAIL negative control (low contrast) passed"; exit 1; }
	@echo "ui-theme-check: negative controls (seeded StyleBoxFlat, low contrast) fail as they must"
test: ui-theme-check
style-capture: import ## AC10 (GPU window): Bow deep/star/0.99c/first stop, Astern, the console zooms, HUD on and off -> renders/style/$(TAG)/ (contact_sheet.png, style.json; before_after.png against renders/style/before). Open every frame
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --path . --script tools/style_capture.gd -- --tag=$(TAG) $(if $(wildcard renders/style/before/bow_deep.png),--before=res://renders/style/before) > $(SCRATCH)/style-capture-$(TAG).log 2>&1; rc=$$?; grep -E '^(FAIL|shot|style-capture)' $(SCRATCH)/style-capture-$(TAG).log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/style-capture-$(TAG).log
