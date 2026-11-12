# First information entry must not consume hidden planning/crew intents.
.PHONY: telescope-first-entry-test
telescope-first-entry-test: import
	@$(SCRIPT_GATE) telescope-first-entry-test $(SCRATCH)/observations/first-entry.log 600 '^telescope-first-entry-test: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_telescope_first_entry.gd
