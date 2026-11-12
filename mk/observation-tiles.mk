# R3-TELESCOPE TS3: offline tile pyramid and bounded presentation cache.
.PHONY: telescope-cache-test observation-tiles
telescope-cache-test:
	@$(SCRIPT_GATE) telescope-cache-test $(SCRATCH)/observations/cache-test.log 180 '^telescope-cache-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_observation_tiles.gd

observation-tiles:
	@test -n "$(OBSERVATION_IMAGE)" && test -n "$(OBSERVATION_TILES)"
	@$(SCRIPT_GATE) observation-tiles $(SCRATCH)/observations/tiles.log 180 '^observation-tiles: [1-9][0-9]* levels, 0 failures$$' -- $(GODOT) --headless --path . --script tools/observation_tiles.gd -- "$(OBSERVATION_IMAGE)" "$(OBSERVATION_TILES)"

test: telescope-cache-test
