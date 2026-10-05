# Approved bounded presentation follow-up; actual normal-sidecar lifecycle gates.
.PHONY: planet-presentation-test moon-lifecycle-test planet-transition-golden planet-bounds-golden planet-cpu-bench
planet-presentation-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_planet_presentation.gd > $(SCRATCH)/planet-presentation.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-presentation.log; test $$rc = 0 && grep -q '^planet-presentation: [0-9]* checks 0 failures$$' $(SCRATCH)/planet-presentation.log
moon-lifecycle-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_moon_lifecycle.gd > $(SCRATCH)/moon-lifecycle.log 2>&1; rc=$$?; cat $(SCRATCH)/moon-lifecycle.log; test $$rc = 0 && grep -q '^moon-lifecycle: [0-9]* checks 0 failures$$' $(SCRATCH)/moon-lifecycle.log
planet-transition-golden:
	@$(GODOT_SIM) --path . --script tools/planet_transition_golden.gd > $(SCRATCH)/planet-transition-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-transition-golden.log; test $$rc = 0 && grep -q '^planet-transition-golden: 0 failures;' $(SCRATCH)/planet-transition-golden.log
planet-bounds-golden:
	@$(GODOT_SIM) --path . --script tools/planet_bounds_golden.gd > $(SCRATCH)/planet-bounds-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-bounds-golden.log; test $$rc = 0 && grep -q '^planet-bounds-golden: 0 failures$$' $(SCRATCH)/planet-bounds-golden.log
planet-cpu-bench:
	@$(GODOT_SIM) --headless --path . --script tools/planet_cpu_bench.gd
ship-demo-ci: planet-presentation-test moon-lifecycle-test
