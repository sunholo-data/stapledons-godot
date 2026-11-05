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
	@$(SCRIPT_GATE) level-test $(SCRATCH)/level-test.log 600 '^level-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_levels.gd
test: level-test
.PHONY: level-runtime-test
level-runtime-test: import ## VF1: manifest camera sources, stage resolution and shared fixed-height/clamp poses
	@$(SCRIPT_GATE) level-runtime-test $(SCRATCH)/level-runtime-test.log 600 '^level-runtime: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_level_runtime.gd
test: level-runtime-test
.PHONY: commons-art-pilot-test commons-pilot-check commons-pilot-capture commons-pilot-golden
.PHONY: commons-backdrop-check commons-backdrop-capture commons-backdrop-golden
.PHONY: commons-life-pilot-test commons-grown-check commons-grown-capture commons-grown-golden commons-grown-motion
test: commons-life-pilot-test
commons-life-pilot-test: ## Resident clock, reduced motion, hidden pause and physical floor controls
	@$(SCRIPT_GATE) commons-life-pilot-test $(SCRATCH)/commons-life-pilot.log 600 '^commons-life-pilot: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_commons_life_pilot.gd
commons-grown-check: ## Connected civic art layers, original geometry/sightline thresholds and routes
	@$(SCRIPT_GATE) commons-grown-check $(SCRATCH)/commons-grown-check.log 600 '^commons-backdrop-validate: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tools/commons_backdrop_validate.gd -- --config res://art/commons-grown-pilot/placements.json
commons-grown-capture: ## Matched real player views of the grown living Commons candidate
	@$(SCRIPT_GATE) commons-grown-capture $(SCRATCH)/commons-grown-capture.log 600 '^commons-pilot-review: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/commons_pilot_review.gd -- --config res://art/commons-grown-pilot/placements.json --out res://renders/view-finish/commons-grown-pilot
commons-grown-golden: lens-assets m4-physics-probe ## Existing CPU/pixel pole references with every grown civic layer present
	@$(GODOT) $(AUDIO_OFF) --path . --script tools/commons_pilot_golden.gd -- --config res://art/commons-grown-pilot/placements.json > $(SCRATCH)/commons-grown-golden.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|commons-pilot-golden)' $(SCRATCH)/commons-grown-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/commons-grown-golden.log && test "$$(grep -c '^ok    G-LVL-' $(SCRATCH)/commons-grown-golden.log)" = 6
commons-grown-motion: ## Eight-second actual Court Astern resident activity study for the gallery
	@$(SCRIPT_GATE) commons-grown-motion $(SCRATCH)/commons-grown-motion.log 600 '^commons-civic-motion: 64 frames, fixed actual court Astern camera,8fps/8seconds$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/commons_civic_motion.gd
commons-backdrop-check: ## Whole-vertex envelope, actual floor, original sightline thresholds and routes
	@$(SCRIPT_GATE) commons-backdrop-check $(SCRATCH)/commons-backdrop-check.log 600 '^commons-backdrop-validate: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tools/commons_backdrop_validate.gd
commons-backdrop-capture: ## Matched actual player views; furniture remains present in both variants
	@$(SCRIPT_GATE) commons-backdrop-capture $(SCRATCH)/commons-backdrop-capture.log 600 '^commons-pilot-review: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/commons_pilot_review.gd -- --config res://art/commons-backdrop-pilot/placements.json --out res://renders/view-finish/commons-backdrop-pilot
commons-backdrop-golden: lens-assets m4-physics-probe ## Existing six pole cases with furniture and macro backdrop installed
	@$(GODOT) $(AUDIO_OFF) --path . --script tools/commons_pilot_golden.gd -- --config res://art/commons-backdrop-pilot/placements.json > $(SCRATCH)/commons-backdrop-golden.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|commons-pilot-golden)' $(SCRATCH)/commons-backdrop-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/commons-backdrop-golden.log && test "$$(grep -c '^ok    G-LVL-' $(SCRATCH)/commons-backdrop-golden.log)" = 6
commons-art-pilot-test: import ## D-133 review loader: real authored GLB, material/transform/collision guards and atomic negative controls
	@$(SCRIPT_GATE) commons-art-pilot-test $(SCRATCH)/commons-art-pilot.log 600 '^commons-art-pilot: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_commons_art_pilot.gd
test: commons-art-pilot-test
commons-pilot-check: import ## Actual pilot pin, floor support, solid/captain/routes and unchanged Commons thresholds
	@$(SCRIPT_GATE) commons-pilot-check $(SCRATCH)/commons-pilot-check.log 600 '^commons-pilot-validate: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tools/commons_pilot_validate.gd
commons-pilot-capture: ## Matched real player-view before/after pilot, rest/cruise/real stop; inspect renders/view-finish/commons-lived-in-pilot
	@$(SCRIPT_GATE) commons-pilot-capture $(SCRATCH)/commons-pilot-capture.log 600 '^commons-pilot-review: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/commons_pilot_review.gd
commons-pilot-golden: lens-assets m4-physics-probe ## Six existing CPU/pixel pole cases with the actual review furniture installed; no global golden-count change
	@$(GODOT) $(AUDIO_OFF) --path . --script tools/commons_pilot_golden.gd > $(SCRATCH)/commons-pilot-golden.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|commons-pilot-golden)' $(SCRATCH)/commons-pilot-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/commons-pilot-golden.log && test "$$(grep -c '^ok    G-LVL-' $(SCRATCH)/commons-pilot-golden.log)" = 6 && grep -q '^commons-pilot-golden: 0 failures$$' $(SCRATCH)/commons-pilot-golden.log
.PHONY: level-export-test
level-export-test: import ## VF2: real pack JSON closure with missing manifest, greybox and lift negative controls
	@$(SCRIPT_GATE) level-export-test $(SCRATCH)/level-export-test.log 600 '^level-export: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_level_export.gd
test: level-export-test
.PHONY: level-golden-test level-stage
level-golden-test: import ## VF1: paired no-star baseline cannot mistake the nearby captain for a pole marker
	@$(SCRIPT_GATE) level-golden-test $(SCRATCH)/level-golden-test.log 600 '^level-golden: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_level_golden.gd
test: level-golden-test
level-stage: import ## Explicit authoring command: reproducibly cook LEVEL's layout and manifest; tests only verify their pins
	@$(GODOT) --headless --path . --script tools/level_stage.gd -- --level $(LEVEL)
LEVEL ?= bridge
.PHONY: level-eval level-eval-test
level-eval: import ## AC8 (S2): a level against its thresholds (prints "level-eval: <id> ok (N surfaces, M samples)"); LEVEL=<id>, LAYOUT=<json> scores a candidate (search only)
	@$(SCRIPT_GATE) level-eval $(SCRATCH)/level-eval-$(LEVEL).log 600 '^level-eval: [a-z0-9_]+ ok \([1-9][0-9]* surfaces, [1-9][0-9]* samples\)$$' -- $(GODOT_SIM) --headless --path . --script tools/level_eval.gd -- --level $(LEVEL) $(if $(LAYOUT),--layout $(LAYOUT)) --json $(SCRATCH)/level-eval-$(LEVEL).json
level-eval-test: import ## AC5: the mock Commons greybox's numbers (positive control), a roofed tier passes with its band edge on the slab model, the bridge measured as exported, and seeded unreached / pole-ray / band-top / find-sight defects each fail by name
	@$(SCRIPT_GATE) level-eval-test $(SCRATCH)/level-eval-test.log 600 '^level-eval-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_level_eval.gd
test: level-eval-test
.PHONY: levels-regress levels-regress-pin
levels-regress: import ## AC10 (S6/S7): every landed level against art/levels/<id>/baseline.json; negative controls: a box seeded on the bridge and a changed document must each fail
	@$(SCRIPT_GATE) levels-regress $(SCRATCH)/levels-regress.log 600 '^levels-regress: ok \([1-9][0-9]* levels: [a-z0-9_, ]+\)$$' -- $(GODOT_SIM) --headless --path . --script tools/levels_regress.gd
	@$(SCRIPT_GATE) levels-regress-seed-box $(SCRATCH)/levels-regress-seed-box.log 600 '^FAIL bridge: numbers moved from the baseline' 1 -- $(GODOT_SIM) --headless --path . --script tools/levels_regress.gd -- --seed-box bridge
	@$(SCRIPT_GATE) levels-regress-fake-sha $(SCRATCH)/levels-regress-fake-sha.log 600 '^FAIL bridge: its document [^ ]* changed \(sha256 00000000, ' 1 -- $(GODOT_SIM) --headless --path . --script tools/levels_regress.gd -- --fake-sha bridge
	@echo "levels-regress: negative controls (a seeded box, a changed document) fail as they must, each for its own reason"
test: levels-regress
levels-regress-pin: import ## re-pin LEVEL's baseline from today's numbers (deliberate; add the printed sha256 to the level doc's change log)
	@$(GODOT_SIM) --headless --path . --script tools/levels_regress.gd -- --pin $(LEVEL) 2>&1 | grep -E '^(levels-regress|FAIL)'
TAG ?= capture
.PHONY: level-capture
level-capture: import ## AC14 (GPU window): LEVEL's stages and surfaces through each view at rest and 0.99c -> renders/levels/$(LEVEL)/$(TAG)/ (+ contact sheet, metrics.json, frames.sha256); fails on a missing or blank frame. Open every frame
	@$(SCRIPT_GATE) level-capture $(SCRATCH)/level-capture-$(LEVEL).log 600 '^level-capture: [a-z0-9_]+ [1-9][0-9]* frames$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/level_capture.gd -- --level $(LEVEL) $(if $(LAYOUT),--layout $(LAYOUT)) --tag $(TAG)
