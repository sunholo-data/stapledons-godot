# R3-TELESCOPE: bounded real-source verification before observation UI work.
.PHONY: observation-pack-test observation-pack-verify observation-fits-test
.PHONY: telescope-map-test
telescope-map-test:
	@$(SCRIPT_GATE) telescope-map-test $(SCRATCH)/observations/map-test.log 600 '^telescope-map-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_telescope_map.gd
test: telescope-map-test
.PHONY: telescope-live-test
telescope-live-test:
	@$(SCRIPT_GATE) telescope-live-test $(SCRATCH)/observations/live-test.log 180 '^telescope-live-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_telescope_live.gd
test: telescope-live-test
.PHONY: telescope-ui-test object-inspection-test
telescope-ui-test:
	@$(SCRIPT_GATE) telescope-ui-test $(SCRATCH)/observations/ui-test.log 300 '^telescope-ui-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_telescope_ui.gd
object-inspection-test:
	@$(SCRIPT_GATE) object-inspection-test $(SCRATCH)/observations/inspection-test.log 180 '^object-info: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_object_info.gd
test: telescope-ui-test object-inspection-test
observation-pack-test:
	@$(SCRIPT_GATE) observation-pack-test $(SCRATCH)/observations/pack-test.log 60 '^observation-pack-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_pack.gd
observation-pack-verify:
	@$(SCRIPT_GATE) observation-pack-verify $(SCRATCH)/observations/pack-verify.log 180 '^observation-pack-verify: [1-9][0-9]* plates, [1-9][0-9]* objects, 0 failures$$' -- $(GODOT) --headless --path . --script tools/observation_pack_verify.gd
test: observation-pack-test observation-fits-test
ci-fast: observation-import-parity survey-footprint-parity
test: observation-import-test observation-import-parity observation-index-test survey-footprint-test survey-footprint-parity survey-map-test
observation-fits-test:
	@$(SCRIPT_GATE) observation-fits-test $(SCRATCH)/observations/fits-test.log 60 '^observation-fits-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_fits.gd
