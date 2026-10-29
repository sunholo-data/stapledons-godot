.PHONY: commons-civic-stage commons-civic-assets-check
commons-civic-stage: import ## Stage the pinned playable civic art/config graph as raw export bytes; no authoring changes
	@$(GODOT) --headless --path . --script tools/commons_civic_stage.gd
commons-civic-assets-check: commons-civic-stage ## Real staged GLB/PNG decode plus export-closure/hash negative controls
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_commons_civic_assets.gd > $(SCRATCH)/commons-civic-assets.log 2>&1; rc=$$?; cat $(SCRATCH)/commons-civic-assets.log; test $$rc = 0 && grep -q '^commons-civic-assets: [0-9]* passed, 0 failures$$' $(SCRATCH)/commons-civic-assets.log
export-macos export-pack-check: commons-civic-stage
test: commons-civic-assets-check
