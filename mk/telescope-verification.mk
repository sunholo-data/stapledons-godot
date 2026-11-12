# R3 telescope: bounded CPU evidence, actual offline PCK, focused GPU cases.
.PHONY: telescope-verification-test telescope-bench telescope-export-smoke telescope-capture telescope-golden
telescope-verification-test:
	@$(SCRIPT_GATE) telescope-verification-test $(SCRATCH)/observations/verification-test.log 180 '^telescope-verification-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_telescope_verification.gd
telescope-bench:
	@$(SCRIPT_GATE) telescope-bench $(SCRATCH)/observations/bench.log 180 '^telescope-bench: [1-9][0-9]* samples, 0 failures$$' -- $(GODOT) --headless --path . --script tools/telescope_verification.gd -- bench
telescope-export-smoke: observation-bundle
	@$(SCRIPT_GATE) telescope-export-smoke $(SCRATCH)/observations/export-smoke.log 600 '^telescope-export-smoke: [1-9][0-9]* cases, 0 failures$$' -- env GODOT=$(GODOT) sh tools/telescope_export_smoke.sh
telescope-capture:
	@$(SCRIPT_GATE) telescope-capture $(SCRATCH)/observations/capture.log 600 '^telescope-capture: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/telescope_verification.gd -- capture
telescope-golden:
	@$(SCRIPT_GATE) telescope-golden $(SCRATCH)/observations/golden.log 600 '^telescope-golden: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/telescope_verification.gd -- golden
test: telescope-verification-test
golden: telescope-golden

.PHONY: telescope-mask-test
telescope-mask-test:
	@$(SCRIPT_GATE) telescope-mask-test $(SCRATCH)/observations/mask-test.log 60 '^telescope-mask-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_telescope_mask.gd
test: telescope-mask-test

.PHONY: telescope-app-smoke
telescope-app-smoke: export-macos
	@$(SCRIPT_GATE) telescope-app-smoke $(SCRATCH)/observations/app-smoke.log 900 '^telescope-app-smoke: [1-9][0-9]* app, 0 failures$$' -- sh tools/telescope_app_smoke.sh
# Run explicitly for the telescope sprint; keep the shared publication workflow unchanged.
