.PHONY: commons-civic-stage commons-civic-assets-check commons-civic-playtest-test civic-playtest-export-smoke
commons-civic-stage: import ## Stage the pinned playable civic art/config graph as raw export bytes; no authoring changes
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) commons-civic-stage $(SCRATCH)/commons-civic-stage.log 600 '^commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, 0 failures$$' -- $(GODOT) --headless --path . --script tools/commons_civic_stage.gd
commons-civic-assets-check: commons-civic-stage ## Real staged GLB/PNG decode plus export-closure/hash negative controls
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) commons-civic-assets-check $(SCRATCH)/commons-civic-assets.log 600 '^commons-civic-assets: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_commons_civic_assets.gd
export-macos export-pack-check: commons-civic-stage
test: commons-civic-assets-check commons-civic-playtest-test
commons-civic-playtest-test: commons-civic-stage ## Actual installed world, activity, route and lift regressions
	@$(SCRIPT_GATE) commons-civic-playtest-test $(SCRATCH)/commons-civic-playtest.log 600 '^commons-civic-playtest: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_commons_civic_playtest.gd
publish-dev: civic-playtest-export-smoke
civic-playtest-export-smoke: export-macos ## Same exported app: packed civic art, activity/settings, walk and lift round trip
	@mkdir -p $(SCRATCH)/civic-export-home $(SCRATCH)/civic-export-frames
	@exe=$$(plutil -extract CFBundleExecutable raw -o - "$(APP)/Contents/Info.plist"); env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/civic-export-home" "$(APP)/Contents/MacOS/$$exe" --log-file "$(CURDIR)/$(SCRATCH)/civic-native-engine.log" -- --ship-demo --civic-playtest-smoke --civic-capture="$(CURDIR)/$(SCRATCH)/civic-export-frames" > $(SCRATCH)/civic-native.log 2>&1; rc=$$?; grep -E '^(commons-civic-playtest|current-ship-startup|civic-playtest-smoke)' $(SCRATCH)/civic-native.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/civic-native.log $(SCRATCH)/civic-native-engine.log && grep -Eq '^civic-playtest-smoke: OK packed-art (live-activity|painted-residents) walk lift-roundtrip$' $(SCRATCH)/civic-native.log
