# Approved bounded presentation follow-up; actual normal-sidecar lifecycle gates.
.PHONY: planet-presentation-test moon-lifecycle-test planet-transition-golden planet-bounds-golden planet-cpu-bench
planet-presentation-test: import
	@$(SCRIPT_GATE) planet-presentation-test $(SCRATCH)/planet-presentation.log 600 '^planet-presentation: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_planet_presentation.gd
moon-lifecycle-test: import
	@$(SCRIPT_GATE) moon-lifecycle-test $(SCRATCH)/moon-lifecycle.log 1800 '^moon-lifecycle: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_moon_lifecycle.gd
planet-transition-golden:
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/planet_transition_golden.gd > $(SCRATCH)/planet-transition-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-transition-golden.log; test $$rc = 0 && grep -q '^planet-transition-golden: 0 failures;' $(SCRATCH)/planet-transition-golden.log
planet-bounds-golden:
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/planet_bounds_golden.gd > $(SCRATCH)/planet-bounds-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-bounds-golden.log; test $$rc = 0 && grep -q '^planet-bounds-golden: 0 failures$$' $(SCRATCH)/planet-bounds-golden.log
planet-cpu-bench:
	@$(SCRIPT_GATE) planet-cpu-bench $(SCRATCH)/planet-cpu-bench.log 600 '^planet-cpu-bench: [1-9][0-9]* rows, renders/perf/planet_cpu.json$$' -- $(GODOT_SIM) --headless --path . --script tools/planet_cpu_bench.gd
ship-demo-ci: planet-presentation-test moon-lifecycle-test

.PHONY: glow-planet-golden
glow-planet-golden:
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/glow_planet_golden.gd > $(SCRATCH)/glow-planet-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/glow-planet-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/glow-planet-golden.log && grep -q '^glow-planet-golden: 0 failures$$' $(SCRATCH)/glow-planet-golden.log

.PHONY: exposure-frames-test exposure-frame-capture
exposure-frames-test: import
	@$(SCRIPT_GATE) exposure-frames-test $(SCRATCH)/exposure-frames.log 600 '^exposure-frames: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_exposure_frames.gd
exposure-frame-capture:
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/exposure_frame_capture.gd > $(SCRATCH)/exposure-frame-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/exposure-frame-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/exposure-frame-capture.log && grep -q '^exposure-frame-capture: 0 failures$$' $(SCRATCH)/exposure-frame-capture.log
ship-demo-ci: exposure-frames-test

.PHONY: manual-exposure-test
manual-exposure-test: import
	@$(SCRIPT_GATE) manual-exposure-test $(SCRATCH)/manual-exposure.log 600 '^manual-exposure: [1-9][0-9]* checks 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_manual_exposure.gd
ship-demo-ci: manual-exposure-test

.PHONY: exposure-cpu-bench
exposure-cpu-bench:
	@$(SCRIPT_GATE) exposure-cpu-bench $(SCRATCH)/exposure-cpu-bench.log 600 '^exposure-cpu-bench: OK [1-9][0-9]* profiles, renders/perf/exposure_cpu.json$$' -- $(GODOT_SIM) --headless --path . --script tools/exposure_cpu_bench.gd
