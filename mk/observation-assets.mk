# Large observation inputs/tiles are pinned; runtime always loads offline bytes.
.PHONY: observation-assets observation-assets-check observation-bundle observation-assets-test
observation-assets:
	@$(SCRIPT_GATE) observation-assets $(SCRATCH)/observations/assets.log 1200 '^observation-assets: [1-9][0-9]* plates, [1-9][0-9]* bytes, 0 failures$$' -- GODOT="$(GODOT)" sh tools/observation_assets.sh fetch
observation-assets-check:
	@$(SCRIPT_GATE) observation-assets-check $(SCRATCH)/observations/assets-check.log 300 '^observation-assets: [1-9][0-9]* plates, [1-9][0-9]* bytes, 0 failures$$' -- GODOT="$(GODOT)" sh tools/observation_assets.sh verify
observation-bundle: observation-assets
	@$(SCRIPT_GATE) observation-bundle $(SCRATCH)/observations/bundle.log 300 '^observation-bundle: [1-9][0-9]* plates, 0 failures$$' -- GODOT="$(GODOT)" sh tools/observation_assets.sh bundle
observation-assets-test: observation-assets
	@$(SCRIPT_GATE) observation-assets-test $(SCRATCH)/observations/assets-test.log 180 '^observation-assets-test: [1-9][0-9]* passed, 0 failures$$' -- GODOT="$(GODOT)" sh tools/test_observation_assets.sh
