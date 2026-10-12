# Approved bounded presentation follow-up; actual normal-sidecar lifecycle gates.
.PHONY: planet-presentation-test moon-lifecycle-test planet-transition-golden planet-bounds-golden planet-cpu-bench
planet-presentation-test: import
	@AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_planet_presentation.gd > $(SCRATCH)/planet-presentation.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-presentation.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/planet-presentation.log && grep -q '^planet-presentation: [0-9]* checks 0 failures$$' $(SCRATCH)/planet-presentation.log
moon-lifecycle-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_moon_lifecycle.gd > $(SCRATCH)/moon-lifecycle.log 2>&1; rc=$$?; cat $(SCRATCH)/moon-lifecycle.log; test $$rc = 0 && grep -q '^moon-lifecycle: [0-9]* checks 0 failures$$' $(SCRATCH)/moon-lifecycle.log
planet-transition-golden:
	@$(GODOT_SIM) --path . --script tools/planet_transition_golden.gd > $(SCRATCH)/planet-transition-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-transition-golden.log; test $$rc = 0 && grep -q '^planet-transition-golden: 0 failures;' $(SCRATCH)/planet-transition-golden.log
planet-bounds-golden:
	@$(GODOT_SIM) --path . --script tools/planet_bounds_golden.gd > $(SCRATCH)/planet-bounds-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-bounds-golden.log; test $$rc = 0 && grep -q '^planet-bounds-golden: 0 failures$$' $(SCRATCH)/planet-bounds-golden.log
planet-cpu-bench:
	@$(GODOT_SIM) --headless --path . --script tools/planet_cpu_bench.gd
ship-demo-ci: planet-presentation-test moon-lifecycle-test

.PHONY: glow-planet-golden
glow-planet-golden:
	@$(GODOT_SIM) --path . --script tools/glow_planet_golden.gd > $(SCRATCH)/glow-planet-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/glow-planet-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/glow-planet-golden.log && grep -q '^glow-planet-golden: 0 failures$$' $(SCRATCH)/glow-planet-golden.log

.PHONY: exposure-frames-test exposure-frame-capture
exposure-frames-test: import
	@AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_exposure_frames.gd > $(SCRATCH)/exposure-frames.log 2>&1; rc=$$?; cat $(SCRATCH)/exposure-frames.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/exposure-frames.log && grep -q '^exposure-frames: [0-9]* checks 0 failures$$' $(SCRATCH)/exposure-frames.log
exposure-frame-capture:
	@$(GODOT_SIM) --path . --script tools/exposure_frame_capture.gd > $(SCRATCH)/exposure-frame-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/exposure-frame-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/exposure-frame-capture.log && grep -q '^exposure-frame-capture: 0 failures$$' $(SCRATCH)/exposure-frame-capture.log
ship-demo-ci: exposure-frames-test

.PHONY: manual-exposure-test
manual-exposure-test: import
	@AILANG_BIN="$$(command -v $(AILANG))" perl -e 'alarm 120; exec @ARGV' $(GODOT) --headless --path . --script tests/test_manual_exposure.gd > $(SCRATCH)/manual-exposure.log 2>&1; rc=$$?; cat $(SCRATCH)/manual-exposure.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/manual-exposure.log && grep -q '^manual-exposure: [0-9]* checks 0 failures$$' $(SCRATCH)/manual-exposure.log
ship-demo-ci: manual-exposure-test

.PHONY: exposure-cpu-bench
exposure-cpu-bench:
	@$(GODOT_SIM) --headless --path . --script tools/exposure_cpu_bench.gd
