# Independent scalar TAN and measured-centroid checks; no network or dependencies.
.PHONY: observation-projection-oracle observation-projection-oracle-negative
observation-projection-oracle: observation-projection-oracle-negative
	@$(SCRIPT_GATE) observation-projection-oracle $(SCRATCH)/observations/projection-oracle.log 60 '^observation-projection-oracle: [1-9][0-9]* passed, 0 failures$$' -- python3 tools/observation_projection_oracle.py --godot "$(GODOT)"
observation-projection-oracle-negative:
	@$(SCRIPT_GATE) observation-projection-oracle-negative $(SCRATCH)/observations/projection-oracle-negative.log 60 '^observation-projection-oracle: [1-9][0-9]* passed, 1 failures$$' 1 -- python3 tools/observation_projection_oracle.py --godot "$(GODOT)" --probe-fault half-pixel
