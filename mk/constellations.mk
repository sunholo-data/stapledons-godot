# Earth constellation guides reuse the sky's current catalogue/observer.
.PHONY: constellation-test constellation-golden constellation-capture constellation-bench
constellation-test: import starmap-assets
	@$(SCRIPT_GATE) constellation-test $(SCRATCH)/constellations.log 600 '^constellations: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --quit-after 1200 --script tests/test_constellations.gd
constellation-golden:
	@$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- golden > $(SCRATCH)/constellation-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-golden.log && grep -q '^constellation golden: 33 cases, 0 failures$$' $(SCRATCH)/constellation-golden.log && test "$$(grep -c '^ok    G-CONST' $(SCRATCH)/constellation-golden.log)" = 33
constellation-capture:
	@$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- capture > $(SCRATCH)/constellation-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-capture.log && grep -q '^constellation capture: 32 images, 0 failures$$' $(SCRATCH)/constellation-capture.log
constellation-bench:
	@$(GODOT) $(AUDIO_OFF) --path . --quit-after 5000 --script tools/constellation_capture.gd -- bench > $(SCRATCH)/constellation-bench.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-bench.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-bench.log && grep -q '^constellation bench: 2 pairs, 0 failures$$' $(SCRATCH)/constellation-bench.log
ship-demo-ci: constellation-test
golden: constellation-golden
