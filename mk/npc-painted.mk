.PHONY: npc-painted-ingest npc-painted-assets-check npc-painted-test npc-painted-capture
npc-painted-ingest: ## Slice preserved NPC paintings, uniformly downscale and align feet
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-ingest-engine.log --script tools/npc_painted_assets.gd -- --ingest
npc-painted-assets-check: ## Actual PNG alpha, anchor, height and source/portrait/hash closure
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-assets-engine.log --script tools/npc_painted_assets.gd > $(SCRATCH)/npc-assets.log 2>&1; rc=$$?; grep -E '^(FAIL|painted-npc-assets)' $(SCRATCH)/npc-assets.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/npc-assets.log && grep -q '^painted-npc-assets: 5 identities, 25 poses, 0 failures$$' $(SCRATCH)/npc-assets.log
npc-painted-test: ## Opt-in crowd installation, portrait identity, camera poses and negative controls
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --log-file $(SCRATCH)/npc-pilot-engine.log --script tests/test_painted_npc_pilot.gd > $(SCRATCH)/npc-pilot.log 2>&1; rc=$$?; grep -E '^(FAIL|painted-npc-pilot)' $(SCRATCH)/npc-pilot.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/npc-pilot.log && grep -q '^painted-npc-pilot: [0-9]* passed, 0 failures$$' $(SCRATCH)/npc-pilot.log
npc-painted-capture: ## Opt-in lineup, pose sheet and unchanged actual Commons Bow/Astern cameras
	@mkdir -p $(SCRATCH)
	@$(GODOT) --path . --log-file $(SCRATCH)/npc-capture-engine.log --script tools/npc_painted_capture.gd > $(SCRATCH)/npc-capture.log 2>&1; rc=$$?; grep -E '^(FAIL|npc-capture|painted-npc-capture)' $(SCRATCH)/npc-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/npc-capture.log && grep -q '^painted-npc-capture: 8 frames, 0 failures$$' $(SCRATCH)/npc-capture.log
test: npc-painted-assets-check npc-painted-test
