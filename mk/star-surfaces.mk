# R2-STAR-SURFACES (design_docs/planned/r2/star-surfaces.md; ledger D-105): resolved stellar surfaces.
# stellar-protocol-test is pure (strict VM == interpreter) and joins ci-fast; star-surface-test runs
# headless in Godot; star-surface-bench and star-surface-capture need a GPU window (rig only).

.PHONY: stellar-protocol-test
stellar-protocol-test: ## AC2, AC7: the 2.13 surface record of every finite star and the emission-time clock (RS-25); strict VM == interpreter
	@mkdir -p $(SCRATCH)/star-surfaces
	@cd sim && $(AILANG) test stellar_surface_test.ail > ../$(SCRATCH)/star-surfaces/sim-test.log 2>&1; rc=$$?; cd .. ; \
	  grep -E '^[0-9]+ tests:' $(SCRATCH)/star-surfaces/sim-test.log; [ $$rc = 0 ] || { tail -40 $(SCRATCH)/star-surfaces/sim-test.log; echo "stellar-protocol: FAIL (sim tests)"; exit 1; }
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry stellarSurfaceVm --args-json 0 sim/stellar_surface_test.ail); \
	  interp=$$($(AILANG) run --quiet --package-dir sim --entry stellarSurfaceVm --args-json 0 sim/stellar_surface_test.ail); \
	  echo "strict stellarSurfaceVm: VM $$got | interpreter $$interp"; [ "$$got" = "$$interp" ] && case "$$got" in "stellar-surface-ok "*) true;; *) false;; esac && \
	  echo "stellar-protocol: OK 5 finite stars (Sun, alpha Cen A and B, Aldebaran, TRAPPIST-1), clock: OK"
test: stellar-protocol-test
ci-fast: stellar-protocol-test

.PHONY: star-surface-test
star-surface-test: import ## AC3, AC5-AC8: the CPU mirror (physics/star_surface.gd): laws, hash, gate, RS-24 flux, the single-spot closed form, colour from temperature, float64 phases, the fader peak, the uniforms
	@mkdir -p $(SCRATCH)/star-surfaces
	@perl -e 'alarm 900; exec @ARGV' $(GODOT) --headless --path . --script tests/test_star_surface.gd > $(SCRATCH)/star-surfaces/test.log 2>&1; rc=$$?; \
	  grep -E '^  (ok|FAIL)|^star-surface' $(SCRATCH)/star-surfaces/test.log; \
	  ! grep -q 'SCRIPT ERROR' $(SCRATCH)/star-surfaces/test.log || { grep -A2 'SCRIPT ERROR' $(SCRATCH)/star-surfaces/test.log | head -20; echo "star-surface: FAIL (script error)"; exit 1; }; \
	  test $$rc = 0 && grep -q '^star-surface: OK (0 failures)$$' $(SCRATCH)/star-surfaces/test.log
test: star-surface-test

.PHONY: star-surface-bench
star-surface-bench: lens-assets ## AC11 (GPU window, Vulkan for GPU time): the map's sky-viewport GPU cost at the Aldebaran stop, Bow view, 2560x1440: <= +0.50 ms at p50
	@mkdir -p $(SCRATCH)/star-surfaces
	@$(GODOT_SIM) --path . --rendering-driver vulkan --script tools/star_surface_bench.gd -- $(if $(BENCH_SIZE),--bench-size=$(BENCH_SIZE)) > $(SCRATCH)/star-surfaces/bench.log 2>&1; rc=$$?; \
	  echo "star-surface-bench: host load $$(uptime | sed 's/.*load/load/')"; grep '^star-surface-bench' $(SCRATCH)/star-surfaces/bench.log; test $$rc = 0 && grep -q '^star-surface-bench: sky GPU' $(SCRATCH)/star-surfaces/bench.log

.PHONY: star-surface-capture
star-surface-capture: lens-assets ## AC12 (GPU window): the stops at protocol 2.13, Auto with and without the map and Realistic, crops and a sheet -> renders/star_surfaces/ss2/ (open them)
	@mkdir -p $(SCRATCH)/star-surfaces
	@$(GODOT_SIM) --path . --script tools/star_surface_capture.gd > $(SCRATCH)/star-surfaces/capture.log 2>&1; rc=$$?; \
	  grep -E '^star-surface-capture' $(SCRATCH)/star-surfaces/capture.log | cut -c1-240; test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/star-surfaces/capture.log && grep -q '^star-surface-capture: OK' $(SCRATCH)/star-surfaces/capture.log
