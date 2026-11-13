# Session content identity and deep isolation of the pinned source index.
.PHONY: observation-pin-test
observation-pin-test:
	@$(SCRIPT_GATE) observation-pin-test $(SCRATCH)/observations/pin-test.log 60 '^observation-pin-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_pin.gd
