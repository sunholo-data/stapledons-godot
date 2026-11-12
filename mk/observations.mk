# R3-TELESCOPE: bounded real-source verification before observation UI work.
.PHONY: observation-pack-test observation-pack-verify observation-fits-test
observation-pack-test:
	@$(SCRIPT_GATE) observation-pack-test $(SCRATCH)/observations/pack-test.log 60 '^observation-pack-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_pack.gd
observation-pack-verify:
	@$(SCRIPT_GATE) observation-pack-verify $(SCRATCH)/observations/pack-verify.log 180 '^observation-pack-verify: [1-9][0-9]* plates, [1-9][0-9]* objects, 0 failures$$' -- $(GODOT) --headless --path . --script tools/observation_pack_verify.gd
ci-fast: observation-pack-test
test: observation-pack-test observation-fits-test
observation-fits-test:
	@$(SCRIPT_GATE) observation-fits-test $(SCRATCH)/observations/fits-test.log 60 '^observation-fits-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_fits.gd
