# Earth constellation guides reuse the sky's current catalogue/observer.
.PHONY: constellation-test constellation-golden constellation-capture constellation-bench
constellation-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_constellations.gd > $(SCRATCH)/constellations.log 2>&1; rc=$$?; cat $(SCRATCH)/constellations.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellations.log && grep -q '^constellations: [0-9]* passed, 0 failures$$' $(SCRATCH)/constellations.log
constellation-golden:
	@$(GODOT) --path . --quit-after 5000 --script tools/constellation_capture.gd -- golden > $(SCRATCH)/constellation-golden.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-golden.log && grep -q '^constellation golden: 33 cases, 0 failures$$' $(SCRATCH)/constellation-golden.log && test "$$(grep -c '^ok    G-CONST' $(SCRATCH)/constellation-golden.log)" = 33
constellation-capture:
	@$(GODOT) --path . --quit-after 5000 --script tools/constellation_capture.gd -- capture > $(SCRATCH)/constellation-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-capture.log && grep -q '^constellation capture: 32 images, 0 failures$$' $(SCRATCH)/constellation-capture.log
constellation-bench:
	@$(GODOT) --path . --quit-after 5000 --script tools/constellation_capture.gd -- bench > $(SCRATCH)/constellation-bench.log 2>&1; rc=$$?; cat $(SCRATCH)/constellation-bench.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/constellation-bench.log && grep -q '^constellation bench: 2 pairs, 0 failures$$' $(SCRATCH)/constellation-bench.log
ship-demo-ci: constellation-test
golden: constellation-golden
