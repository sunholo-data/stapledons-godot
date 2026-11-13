# Float64 TAN mirror, independent source registration and FITS/display convention.
.PHONY: observation-coordinate-test
observation-coordinate-test:
	@$(SCRIPT_GATE) observation-coordinate-test $(SCRATCH)/observations/coordinates-test.log 180 '^observation-coordinate-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_projection.gd
test: observation-coordinate-test
